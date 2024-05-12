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
#include <windows.h>
#include <winnt.h>
#include <libloaderapi.h>
#include <process.h>
#include <processthreadsapi.h>
#include <synchapi.h>
#include <timeapi.h>

#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include <exodus/callconv.h>
#include <exodus/dbg.h>
#include <exodus/loader.h>
#include <exodus/main.h>
#include <exodus/misc.h>
#include <exodus/seth.h>
#include <exodus/shims.h>
#include <exodus/vfs.h>

typedef struct {
  HANDLE thread, event;
  SRWLOCK mtx;
  u64 awakeat;
  int core_num;
  void *profiler_int;
  u64 profiler_freq, next_prof_int;
  vec_void_t funcptrs;
} CCore;

static CCore cores[MP_PROCESSORS_NUM];
static _Thread_local CCore *self;
static u64 nproc;

static void ThreadRoutine(void *arg) {
  self = arg;
  VFsThrdInit();
  SetupDebugger();
  void *fp;
  int iter;
  vec_foreach(&self->funcptrs, fp, iter) {
    FFI_CALL_TOS_0_ZERO_BP(fp);
  }
}

u64 CoreNum(void) {
  return self->core_num;
}

/* TempleOS does not yield contexts automatically
 * (everything is a coroutine) so we need a brute force solution */
void InterruptCore(u64 core) {
  CCore *c = cores + core;
  CONTEXT ctx = {.ContextFlags = CONTEXT_FULL};
  SuspendThread(c->thread);
  GetThreadContext(c->thread, &ctx);
  ctx.Rsp -= 8;
  ((u64 *)ctx.Rsp)[0] = ctx.Rip;
  static CSymbol *sym;
  if (!sym)
    sym = map_get(&symtab, "Yield");
  ctx.Rip = (u64)sym->val;
  SetThreadContext(c->thread, &ctx);
  ResumeThread(c->thread);
}

void CreateCore(vec_void_t ptrs) {
  CCore *c = cores + nproc;
  *c = (CCore){
      .funcptrs = ptrs,
      .core_num = nproc,
      .event = CreateEvent(NULL, FALSE, FALSE, NULL),
  };
  InitializeSRWLock(&c->mtx);
  c->thread = (HANDLE)_beginthread(ThreadRoutine, 0, c);
  SetThreadPriority(c->thread, THREAD_PRIORITY_HIGHEST);
  nproc++;
  /* Win32 cannot thread names unless it's MSVC[1]
   * or Clang due to Microsoft adding Clang-cl to their toolchain.
   * There IS a way to do this on GCC, but it's stupid[2].
   * Not to mention taskmgr doesn't show thread names as far as I'm aware. */
}

void WakeCoreUp(u64 core) {
  CCore *c = cores + core;
  /* the timeSetEvent callback will automatiacally
   * wake things up so just wait for the event. */
  AcquireSRWLockExclusive(&c->mtx);
  SetEvent(c->event);
  c->awakeat = 0;
  ReleaseSRWLockExclusive(&c->mtx);
}

static u32 inc;

static void incinit(void) {
  static bool init;
  if (verylikely(init))
    return;
  TIMECAPS tc = {0};
  timeGetDevCaps(&tc, sizeof tc);
  inc = tc.wPeriodMin;
  init = true;
}

static u64 ticks;

/* We need this for accurate μs ticks, and just passing millisecnds to
 * WaitForSingleObject in SleepUs is inaccurate enough to mess with input. */
static void tickscb(u32 id, u32 msg, u64 userptr, u64 dw1, u64 dw2) {
  (void)id;
  (void)msg;
  (void)userptr;
  (void)dw1;
  (void)dw2;
  ticks += inc;
  for (u64 i = 0; i < nproc; ++i) {
    CCore *c = cores + i;
    AcquireSRWLockExclusive(&c->mtx);
    u64 wake = c->awakeat;
    if (ticks >= wake && wake > 0) {
      SetEvent(c->event);
      c->awakeat = 0;
    }
    ReleaseSRWLockExclusive(&c->mtx);
  }
}

static u64 elapsedus(void) {
  static bool init;
  if (veryunlikely(!inc))
    incinit();
  if (veryunlikely(!init)) {
    timeSetEvent(inc, inc, tickscb, 0, TIME_PERIODIC);
    init = true;
  }
  return ticks;
}

static void irq0(u32 id, u32 msg, u64 userptr, u64 dw1, u64 dw2) {
  (void)id;
  (void)msg;
  (void)userptr;
  (void)dw1;
  (void)dw2;
  static void *fp;
  if (veryunlikely(!fp))
    fp = map_get(&symtab, "IntCore0TimerHndlr")->val;
  FFI_CALL_TOS_1(fp, inc);
}

void InitIRQ0(void) {
  static bool init;
  if (!inc)
    incinit();
  if (init)
    return;
  timeSetEvent(inc, inc, irq0, 0, TIME_PERIODIC);
  init = true;
}

/* There's no SIGPROF on Windows, so we just jump to the profiler interrupt */
static void profcb(u32 id, u32 msg, u64 userptr, u64 dw1, u64 dw2) {
  (void)id;
  (void)msg;
  (void)userptr;
  (void)dw1;
  (void)dw2;
  for (u64 i = 0; i < nproc; ++i) {
    CCore *c = cores + i;
    AcquireSRWLockExclusive(&c->mtx);
    if (c->profiler_int && ticks >= c->next_prof_int) {
      CONTEXT ctx = {.ContextFlags = CONTEXT_FULL};
      SuspendThread(c->thread);
      GetThreadContext(c->thread, &ctx);
      ctx.Rsp -= 16;
      ((u64 *)ctx.Rsp)[1] = ctx.Rip; /* return addr */
      ((u64 *)ctx.Rsp)[0] = ctx.Rip; /* arg */
      ctx.Rip = (u64)c->profiler_int;
      SetThreadContext(c->thread, &ctx);
      ResumeThread(c->thread);
      c->next_prof_int = c->profiler_freq / 1000. + ticks;
    }
    ReleaseSRWLockExclusive(&c->mtx);
  }
}

void SleepUs(u64 us) {
  CCore *c = self;
  u64 curticks = elapsedus();
  AcquireSRWLockExclusive(&c->mtx);
  c->awakeat = curticks + us / 1000;
  ReleaseSRWLockExclusive(&c->mtx);
  WaitForSingleObject(c->event, us / 1000); /* failsafe for tickscb() */
}

void MPSetProfilerInt(void *fp, i64 idx, i64 freq) {
  static bool init;
  if (veryunlikely(!init)) {
    incinit();
    timeSetEvent(inc, inc, profcb, 0, TIME_PERIODIC);
    init = true;
  }
  CCore *c = cores + idx;
  AcquireSRWLockExclusive(&c->mtx);
  c->profiler_freq = freq;
  c->profiler_int = fp;
  c->next_prof_int = 0;
  ReleaseSRWLockExclusive(&c->mtx);
}

/* CITATIONS:
 * [1] https://ofekshilon.com/2009/04/10/naming-threads/
 *     (https://archive.li/MIMDo)
 * [2] http://www.programmingunlimited.net/siteexec/content.cgi?page=mingw-seh
 *     (https://archive.is/s6Lnb)
 */
