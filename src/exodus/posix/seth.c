/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ exodus: executable divine operating system in userspace                      │
│                                                                              │
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for citations.                                               │
│                                                                              │
│ This software is provided 'as-is', without any express or implied            │
│ warranty. In no event will the authors be held liable for any damages        │
│ arising from the use of this software.                                       │
│                                                                              │
│ Permission is granted to anyone to use this software for any purpose,        │
│ including commercial applications, and to alter it and redistribute it       │
│ freely, subject to the following restrictions:                               │
│                                                                              │
│ 1. The origin of this software must not be misrepresented; you must not      │
│    claim that you wrote the original software. If you use this software      │
│    in a product, an acknowledgment in the product documentation would be     │
│    appreciated but is not required.                                          │
│ 2. Altered source versions must be plainly marked as such, and must not be   │
│    misrepresented as being the original software.                            │
│ 3. This notice may not be removed or altered from any source distribution.   │
╚─────────────────────────────────────────────────────────────────────────────*/
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
#ifndef sigev_notify_thread_id // glibc doesn't define this
  #define sigev_notify_thread_id _sigev_un._tid
#endif
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <ucontext.h>
#include <unistd.h>

#include <vec/vec.h>

#include <exodus/callconv.h>
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
  /* U0 (*profiler_int)(U8 *rip) */
  void *profiler_int;
  i64 profiler_freq;
  struct itimerval profile_timer;
  /* HolyC function pointers it needs to execute on launch
   * (especially important for Core 0) */
  vec_void_t funcptrs;
} CCore;

static CCore cores[MP_PROCESSORS_NUM];
static _Thread_local CCore *self;

#define masksignals(a, va...) masksignals_(a, (int[]){va, 0})
static void masksignals_(int how, int *sigs) {
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
  FFI_CALL_TOS_0(sym->val);
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
      {SIGFPE,  {.sa_handler = div0}                            },
      {SIGUSR1, {.sa_handler = ctrlaltc}                        },
      {SIGPROF, {.sa_sigaction = profcb, .sa_flags = SA_SIGINFO}},
  };
  for (struct sa *s = ints, *end = ints + Arrlen(ints); s != end; s++)
    sigaction(s->sig, &s->sa, NULL);
  self = arg;
  preparetls();
  /* IET_MAIN routines + kernel entry point <- Core 0.
   * CoreAPSethTask() <- else
   *   ZERO_BP so the return addr&rbp is 0 and
   *   stack traces don't climb up the C stack.
   */
  void *fp;
  int iter;
  vec_foreach(&self->funcptrs, fp, iter) {
    FFI_CALL_TOS_0_ZERO_BP(fp);
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
static void irq0(int) {
  static void *fp;
  if (veryunlikely(!fp))
    fp = map_get(&symtab, "IntCore0TimerHndlr")->val;
  FFI_CALL_TOS_0(fp);
}

/* emulate PIT interrupt (IRQ 0) */
static void *pit_thrd(void *) {
  sigaction(SIGALRM, &(struct sigaction){.sa_handler = irq0}, NULL);
  struct sigevent ev = {
      .sigev_notify = SIGEV_THREAD_ID,
      .sigev_signo = SIGALRM,
      .sigev_notify_thread_id = gettid(),
  };
  timer_t t;
  timer_create(CLOCK_MONOTONIC, &ev, &t);
  /* on real TempleOS, SYS_TIMER0_PERIOD is 1192Hz (~839μs/it) */
  struct itimerspec in = {
      .it_value.tv_nsec = 1000000,
      .it_interval.tv_nsec = 1000000,
  };
  timer_settime(t, 0, &in, NULL);
  while (true)
    pause();
  return NULL;
}

void InitIRQ0(void) {
  pthread_create(&(pthread_t){0}, NULL, pit_thrd, NULL);
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

void SleepUs(u64 us) {
  CCore *c = self;
  /* Cannot call the Sleep function if we are sleeping.
   * So to remove extra code, just store 1 */
  LBts(&c->is_sleeping, 0);
  Sleep(&c->is_sleeping, 1u,
        &(struct timespec){
            .tv_nsec = (us % 1000000) * 1000,
            .tv_sec = us / 1000000,
        });
}

#ifdef __linux__
  #define REG(x) (u64) ctx->uc_mcontext.gregs[REG_##x]
  #define RegRip REG(RIP)
  #define RegRbp REG(RBP)
#elif defined(__FreeBSD__)
  #define REG(X) (u64) ctx->uc_mcontext.mc_##X
  #define RegRip REG(rip)
  #define RegRbp REG(rbp)
#endif

static void profcb(argign int sig, argign siginfo_t *info, void *_ctx) {
  if (!self)
    return;
  CCore *c = self;
  ucontext_t *ctx = _ctx;
  sigset_t set;
  sigemptyset(&set);
  sigaddset(&set, SIGPROF);
  if (veryunlikely(!c->profiler_int) ||
      !pthread_equal(pthread_self(), c->thread))
    return;
  /* fake RBP because profcb is called from the kernel and
   * we need the context of the HolyC side (ctx) instead
   * or ProfRep will print bogus */
  FFI_CALL_TOS_1_CUSTOM_BP(c->profiler_int, RegRbp, RegRip);
  c->profile_timer = (struct itimerval){
      .it_value.tv_usec = c->profiler_freq,
      .it_interval.tv_usec = c->profiler_freq,
  };
  pthread_sigmask(SIG_UNBLOCK, &set, NULL);
}

void MPSetProfilerInt(void *fp, i64 idx, i64 freq) {
  if (verylikely(fp)) {
    CCore *c = cores + idx;
    c->profiler_int = fp;
    c->profiler_freq = freq;
    c->profile_timer = (struct itimerval){
        .it_value.tv_usec = freq,
        .it_interval.tv_usec = freq,
    };
    setitimer(ITIMER_PROF, &c->profile_timer, NULL);
  } else
    setitimer(ITIMER_PROF, &(struct itimerval){0}, NULL);
}
