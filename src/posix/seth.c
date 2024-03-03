/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
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
#include <stdatomic.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <ucontext.h>
#include <unistd.h>

#include "tos_callconv.h"
#include "vendor/vec.h"

#include "dbg.h"
#include "ffi.h"
#include "main.h"
#include "misc.h"
#include "seth.h"
#include "tos_aot.h"
#include "types.h"
#include "vfs.h"

typedef struct {
  pthread_t thread;
  /*
   * Is this thread sleeping?
   * On all platforms, futexes are four-byte integers
   * that must be aligned on a four-byte boundary.
   * -- man 2 futex
   * FreeBSD: specify UMTX_OP_WAIT_UINT instead of UMTX_OP_WAIT
   */
  _Alignas(4) _Atomic(u32) is_sleeping;
  int core_num;
  /* U0 (*profiler_int)(U8 *rip) */
  void profiler_int;
  i64 profiler_freq;
  struct itimerval profile_timer;
  /* HolyC function pointers it needs to execute on launch
   * (especially important for Core 0) */
  vec_void_t funcptrs;
} CCore;

static CCore cores[MP_PROCESSORS_NUM];
static _Thread_local CCore *self;

// CTRL+C equiv. in TempleOS
static void ctrlaltc(argign int sig) {
  static CSymbol *sym;
  sigset_t set;
  sigemptyset(&set);
  sigaddset(&set, SIGUSR1);
  pthread_sigmask(SIG_UNBLOCK, &set, NULL);
  if (!sym)
    sym = map_get(&symtab, "Yield");
  FFI_CALL_TOS_0(sym->val);
}

static void div0(argign int sig) {
  sigset_t set;
  sigemptyset(&set);
  sigaddset(&set, SIGFPE);
  pthread_sigmask(SIG_UNBLOCK, &set, NULL);
  HolyThrow("DivZero");
}
static void ProfRt(int sig, siginfo_t *info, void *_ctx);
static void *ThreadRoutine(void *arg) {
  VFsThrdInit();
  SetupDebugger();
  struct sigaction sigfpe = {.sa_handler = div0},
                   holysigint = {.sa_handler = ctrlaltc},
                   holyprof = {.sa_sigaction = ProfRt};
  sigaction(SIGFPE, &sigfpe, NULL);
  sigaction(SIGUSR1, &holysigint, NULL);
  sigaction(SIGPROF, &holyprof, NULL);
  self = arg;
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

/*
 * =====TEMPLEOS EXCERPT=====
 * How do you use the FS and GS segment registers.
 * MOV RAX,FS:[RAX] : FS can be set with a WRMSR,
 * but displacement is RIP relative, so it's tricky to use.  FS is used for
 * the current CTask, GS for CCPU.
 * ========HOW I DO IT=======
 * We do not use FS directly. The host operating system occupies it already
 * so we will simply make changes to the compiler to allow &Fs->code_heap.
 * ================= TRIVIA =================
 * I tried copying the machine code of these routines because they're called
 * so frequently (3~400k/s), but TLS on Windows calls a function to get the
 * thread-local variable so I really can't because it messes up all the
 * registers.
 */
static _Thread_local void *Fs, *Gs;

void *GetFs(void) {
  return Fs;
}

void SetFs(void *f) {
  Fs = f;
}

void *GetGs(void) {
  return Gs;
}

void SetGs(void *g) {
  Gs = g;
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
  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_setstacksize(&attr, MiB(128));
  pthread_create(&c->thread, &attr, ThreadRoutine, c);
  char buf[0x10];
  snprintf(buf, sizeof buf, "Seth(Core%d)", c->core_num);
  /* pthread_setname_np only works on Linux and FreeBSD
   * maybe: reference libc/thread/pthread_setname_np.c
   *        in cosmopolitan libc for future ports */
  pthread_setname_np(c->thread, buf);
  n++;
}

#ifdef __linux__
  #define Awake(l) syscall(SYS_futex, l, FUTEX_WAKE, UINT32_C(1), NULL, NULL, 0)
#elif defined(__FreeBSD__)
  #define Awake(l) _umtx_op(l, UMTX_OP_WAKE, UINT32_C(1), NULL, NULL)
#endif

void WakeCoreUp(u64 core) {
  CCore *c = cores + core;
  if (atomic_exchange_explicit(&c->is_sleeping, 0, memory_order_acquire))
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
  atomic_store_explicit(&c->is_sleeping, 1, memory_order_release);
  Sleep(&c->is_sleeping, UINT32_C(1),
        &(struct timespec){
            .tv_nsec = (us % 1000000) * 1000,
            .tv_sec = us / 1000000,
        });
}

#ifdef __linux__
  #define REG(x)  (u64) ctx->uc_mcontext.gregs[REG_##x]
  #define REG_RIP REG(RIP)
#elif defined(__FreeBSD__)
  #define REG(X)  (u64) ctx->uc_mcontext.mc_##X
  #define REG_RIP REG(rip)
#endif

static void ProfRt(argign int sig, argign siginfo_t *info, void *_ctx) {
  CCore *c = self;
  ucontext_t *ctx = _ctx;
  sigset_t set;
  sigemptyset(&set);
  sigaddset(&set, SIGPROF);
  pthread_sigmask(SIG_UNBLOCK, &set, NULL);
  if (cores[c].profiler_int) {
    FFI_CALL_TOS_1(c->profiler_int, REG_RIP);
    c->profile_timer = (struct itimerval){
        .it_value.tv_usec = c->profiler_freq,
        .it_interval.tv_usec = c->profiler_freq,
    };
  }
}

void MPSetProfilerInt(void *fp, i64 idx, i64 freq) {
  if (fp) {
    CCore *c = cores + idx;
    c->profiler_int = fp;
    c->profiler_freq = freq;
    c->profile_timer = (struct itimerval){
        .it_value = {.tv_sec = 0, .tv_usec = f},
        .it_interval = {.tv_sec = 0, .tv_usec = f},
    };
    setitimer(ITIMER_PROF, &c->profile_timer, NULL);
  } else
    setitimer(ITIMER_PROF, &(struct itimerval){0}, NULL);
}

/*═════════════════════════════════════════════════════════════════════════════╡
│ EXODUS: Executable Divine Operating System in Userspace                      │
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ This file is part of EXODUS.                                                 │
│                                                                              │
│ Permission to use, copy, modify, and/or distribute this software for         │
│ any purpose with or without fee is hereby granted, provided that the         │
│ above copyright notice and this permission notice appear in all copies.      │
│                                                                              │
│ THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL                │
│ WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED                │
│ WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE             │
│ AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL         │
│ DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR        │
│ PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER               │
│ TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR             │
│ PERFORMANCE OF THIS SOFTWARE.                                                │
╚─────────────────────────────────────────────────────────────────────────────*/
