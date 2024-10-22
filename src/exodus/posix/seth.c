// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#ifdef __linux__
  #include <linux/futex.h>
  #include <sys/syscall.h>
#elif defined(__FreeBSD__)
  #include <sys/types.h>
  #include <sys/umtx.h>
#endif
#include <inttypes.h>
#include <pthread.h>
#include <signal.h>
#ifndef sigev_notify_thread_id // glibc doesn't define this in normal signal.h,
                               // musl and FreeBSD do
  #define sigev_notify_thread_id _sigev_un._tid // glibc asm-generic/siginfo.h
#endif
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <ucontext.h>
#include <unistd.h>

#include <vec/vec.h>

#include <exodus/abi.h>
#include <exodus/dbg.h>
#include <exodus/ffi.h>
#include <exodus/loader.h>
#include <exodus/main.h>
#include <exodus/misc.h>
#include <exodus/seth.h>
#include <exodus/shims.h>
#include <exodus/types.h>
#include <exodus/vfs.h>

typedef struct {
  pthread_t thread;
  /*
   * Is this thread sleeping?
   * On all platforms, futexes are four-byte integers
   * that must be aligned on a four-byte boundary.
   * -- man 2 futex
   * FreeBSD: specify UMTX_OP_WAIT_UINT instead of UMTX_OP_WAIT
   */
  _Atomic(u32) is_sleeping;
  int core_num;
  long tid;
  /* U0 (*profiler_int)(U8 *rip) */
  void *profiler_int;
  timer_t profile_timer;
  /* HolyC function pointers it needs to execute on launch
   * (especially important for Core 0) */
  vec_void_t funcptrs;
} CCore;

static CCore cores[MP_PROCESSORS_NUM];
static _Thread_local CCore *self;
static u64 pf_prof_active;

#define masksignals(a, va...) masksignals(a, (int[]){va, 0})
static void (masksignals)(int how, int *sigs) {
  int i;
  sigset_t set;
  sigemptyset(&set);
  while ((i = *sigs++))
    sigaddset(&set, i);
  pthread_sigmask(how, &set, NULL);
}

// CTRL+C equiv. in TempleOS
static void ctrlaltc(argign int sig) {
  static CSymbol *sym;
  masksignals(SIG_UNBLOCK, SIGUSR1);
  if (!sym)
    sym = map_get(&symtab, "Yield");
  fficall(sym->val);
}

static void div0(argign int sig) {
  masksignals(SIG_UNBLOCK, SIGFPE);
  HolyThrow("DivZero");
}

static void profcb(int sig, siginfo_t *info, void *_ctx);

static void *ThreadRoutine(void *arg) {
  VFsThrdInit();
  SetupDebugger();
  static struct sa {
    int sig;
    struct sigaction sa;
  } ints[] = {
      {SIGFPE,  {.sa_handler = div0, .sa_flags = SA_ONSTACK}                 },
      {SIGUSR1, {.sa_handler = ctrlaltc, .sa_flags = SA_ONSTACK}             },
      {SIGPROF, {.sa_sigaction = profcb, .sa_flags = SA_SIGINFO | SA_ONSTACK}},
  };
  for (struct sa *s = ints; s != ints + Arrlen(ints); s++)
    sigaction(s->sig, &s->sa, NULL);
  self = arg;
  preparetls();
  // don't mess up HolyC memory, especially in TASK_CONTEXT_SAVE/RESTORE
  // where RSP is LEA'd to the task context save area
  stack_t ss = {
      .ss_sp = malloc(SIGSTKSZ),
      .ss_size = SIGSTKSZ,
  };
  sigaltstack(&ss, NULL);
  self->tid = getthreadid();
  /* IET_MAIN routines + kernel entry point <- Core 0.
   * CoreAPSethTask() <- else
   *   ZERO_BP so the return addr&rbp is 0 and
   *   stack traces don't climb up the C stack.
   */
  void *fp;
  int iter;
  vec_foreach(&self->funcptrs, fp, iter) {
    fficallnullbp(fp);
  }
  /* does not actually return */
  return NULL;
}

u64 CoreNum(void) {
  return self->core_num;
}

void InterruptCore(u64 core) {
  CCore *c = cores + core;
  /* Unixes cant remotely suspend threads so we use a signal handler */
  pthread_kill(c->thread, SIGUSR1);
}

void CreateCore(vec_void_t ptrs) {
  static int n = 0;
  CCore *c = cores + n;
  *c = (CCore){
      .funcptrs = ptrs,
      .core_num = n,
  };
  pthread_create(&c->thread, NULL, ThreadRoutine, c);
  char buf[0x10];
  snprintf(buf, sizeof buf, "Seth(Core%d)", c->core_num);
  /* pthread_setname_np only works on Linux and FreeBSD
   * maybe: reference libc/thread/pthread_setname_np.c
   *        in cosmopolitan libc for future ports */
  pthread_setname_np(c->thread, buf);
  n++;
}

/* porting IRQ_TIMER and firing the signal to all Seth threads
 * was an option, but that introduced way too much lag and
 * HANDLE_SYSF_KEY_EVENT didn't like it */
static void irq0(argign int sig) {
  static void *fp;
  static i64 prev;
  struct timespec ts;
  i64 ms;
  if (veryunlikely(!fp))
    fp = map_get(&symtab, "IntCore0TimerHndlr")->val;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  ms = ts.tv_sec * 1e3 + ts.tv_nsec / 1e6;
  /* FreeBSD's tick resolution is abysmal
   * (~10ms with inconsistencies from my observations)
   * and it's probably only adjustable in sysctl or some other
   * kernel config so we must adjust between the fired signal intervals
   *
   * "it’s probably best to assume a resolution of 10 ms."
   *     ──Quoth FreeBSD Forums[1]
   */
  fficall(fp, prev ? ms - prev : 1);
  prev = ms;
}

/* emulate PIT interrupt (IRQ 0) */
static void *pit_thrd(argign void *arg) {
  const struct sigaction sa = {.sa_handler = irq0};
  sigaction(SIGALRM, &sa, NULL);
  struct sigevent ev = {
      .sigev_notify = SIGEV_THREAD_ID,
      .sigev_signo = SIGALRM,
      .sigev_notify_thread_id = getthreadid(),
  };
  timer_t t;
  timer_create(CLOCK_MONOTONIC, &ev, &t);
  /* on real TempleOS, SYS_TIMER0_PERIOD is 1192Hz (~839μs/it) */
  struct itimerspec in = {
      .it_value.tv_nsec = 1e6,
      .it_interval.tv_nsec = 1e6,
  };
  timer_settime(t, 0, &in, NULL);
  while (true)
    pause();
  return NULL;
}

void InitIRQ0(void) {
  static bool init;
  if (init)
    return;
  pthread_t t;
  pthread_create(&t, NULL, pit_thrd, NULL);
  pthread_setname_np(t, "PIT (IRQ 0)");
  init = true;
}

#ifdef __linux__
  #define Awake(l) syscall(SYS_futex, l, FUTEX_WAKE, 1u, NULL, NULL, 0)
#elif defined(__FreeBSD__)
  #define Awake(l) _umtx_op(l, UMTX_OP_WAKE, 1u, NULL, NULL)
#endif

void WakeCoreUp(u64 core) {
  CCore *c = cores + core;
  if (LBtr(&c->is_sleeping, 0))
    Awake(&c->is_sleeping);
}

#ifdef __linux__
  #define Sleep(l, val, t...) syscall(SYS_futex, l, FUTEX_WAIT, val, t, NULL, 0)
#elif defined(__FreeBSD__)
  #define Sleep(l, val, t...) \
    _umtx_op(l, UMTX_OP_WAIT_UINT, val, (void *)sizeof(struct timespec), t)
#endif

void SleepMillis(u64 ms) {
  CCore *c = self;
  LBts(&c->is_sleeping, 0);
  Sleep(&c->is_sleeping, 1u,
        &(struct timespec){
            .tv_nsec = (ms % 1000) * 1e6,
            .tv_sec = ms / 1e3,
        });
}

#ifdef __linux__
  #define REG(x) ctx->uc_mcontext.gregs[REG_##x]
  #define RegRip REG(RIP)
  #define RegRbp REG(RBP)
#elif defined(__FreeBSD__)
  #define REG(X) ctx->uc_mcontext.mc_##X
  #define RegRip REG(rip)
  #define RegRbp REG(rbp)
#endif

static void profcb(argign int sig, argign siginfo_t *info, void *_ctx) {
  CCore *c = self;
  ucontext_t *ctx = _ctx;
  if (RegRip > INT32_MAX) // crude check for HolyC
    return;
  /* fake RBP because profcb is called from the kernel and
   * we need the context of the HolyC side (ctx) instead
   * or ProfRep will print bogus */
  fficallcustombp(RegRbp, c->profiler_int, RegRip);
}

void MPSetProfilerInt(void *fp, i64 idx, i64 freq) {
  CCore *c = cores + idx;
  if (fp) {
    c->profiler_int = fp;
    struct sigevent ev = {
        .sigev_notify = SIGEV_THREAD_ID,
        .sigev_signo = SIGPROF,
        .sigev_notify_thread_id = c->tid,
    };
    timer_create(CLOCK_MONOTONIC, &ev, &c->profile_timer);
    struct itimerspec in = {
        .it_value.tv_nsec = freq * 1e3,
        .it_interval.tv_nsec = freq * 1e3,
    };
    timer_settime(c->profile_timer, 0, &in, NULL);
    LBts(&pf_prof_active, idx);
  } else if (LBtr(&pf_prof_active, idx)) {
    timer_settime(c->profile_timer, 0, &(struct itimerspec){0}, NULL);
    timer_delete(c->profile_timer);
  }
}

/* CITATIONS:
 * [1]:
 * https://forums.freebsd.org/threads/buildworld-and-kernel-scheduler-questions.79073/page-2#post-498518
 * (https://archive.is/N3KlX#selection-4059.100-4059.150)
 */
