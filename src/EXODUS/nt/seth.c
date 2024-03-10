/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <windows.h>
#include <winnt.h>
#include <libloaderapi.h>
#include <process.h>
#include <processthreadsapi.h>
#include <synchapi.h>
#include <timeapi.h>

#include <inttypes.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include <EXODUS/dbg.h>
#include <EXODUS/main.h>
#include <EXODUS/misc.h>
#include <EXODUS/seth.h>
#include <EXODUS/shims.h>
#include <EXODUS/tos_aot.h>
#include <EXODUS/tos_callconv.h>
#include <EXODUS/vfs.h>

typedef struct {
  HANDLE thread, event, mtx;
  _Atomic(u64) awakeat;
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
  static int n = 0;
  if (!n)
    nproc = mp_cnt();
  CCore *c = cores + n;
  *c = (CCore){
      .funcptrs = ptrs,
      .core_num = n,
      .mtx = CreateMutex(NULL, FALSE, NULL),
      .event = CreateEvent(NULL, FALSE, FALSE, NULL),
  };
  c->thread = (HANDLE)_beginthread(ThreadRoutine, 0, c);
  SetThreadPriority(c->thread, THREAD_PRIORITY_HIGHEST);
  ++n;
  /* Win32 cannot thread names unless it's MSVC[1]
   * or Clang due to Microsoft adding Clang-cl to their toolchain.
   * There IS a way to do this on GCC, but it's stupid[2].
   * Not to mention taskmgr doesn't show thread names as far as I'm aware. */
}

void WakeCoreUp(u64 core) {
  CCore *c = cores + core;
  /* the timeSetEvent callback will automatiacally
   * wake things up so just wait for the event. */
  /* TODO: Try SuspendThread() and passing CONTEXT to tickscb? */
  WaitForSingleObject(c->mtx, INFINITE);
  SetEvent(c->event);
  ReleaseMutex(c->mtx);
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
 * WaitForSingleObject in SleepUs is inaccurate enough mess with input. */
static void tickscb(u32 id, u32 msg, u64 userptr, u64 dw1, u64 dw2) {
  (void)id;
  (void)msg;
  (void)userptr;
  (void)dw1;
  (void)dw2;
  ticks += inc;
  for (u64 i = 0; i < nproc; ++i) {
    CCore *c = cores + i;
    WaitForSingleObject(c->mtx, INFINITE);
    u64 wake = atomic_load_explicit(&c->awakeat, memory_order_acquire);
    if (ticks >= wake && wake > 0) {
      SetEvent(c->event);
      atomic_store_explicit(&c->awakeat, 0, memory_order_release);
    }
    ReleaseMutex(c->mtx);
  }
}

static u64 elapsedus(void) {
  if (veryunlikely(!inc)) {
    incinit();
    timeSetEvent(inc, inc, tickscb, 0, TIME_PERIODIC);
  }
  return ticks;
}

static void profcb(u32 id, u32 msg, u64 userptr, u64 dw1, u64 dw2) {
  (void)id;
  (void)msg;
  (void)userptr;
  (void)dw1;
  (void)dw2;
  for (u64 i = 0; i < nproc; ++i) {
    CCore *c = cores + i;
    WaitForSingleObject(c->mtx, INFINITE);
    if (c->profiler_int && elapsedus() >= c->next_prof_int) {
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
    ReleaseMutex(c->mtx);
  }
}

void SleepUs(u64 us) {
  CCore *c = self;
  u64 curticks = elapsedus();
  WaitForSingleObject(c->mtx, INFINITE);
  atomic_store_explicit(&c->awakeat, curticks + us / 1000,
                        memory_order_release);
  ReleaseMutex(c->mtx);
  WaitForSingleObject(c->event, INFINITE);
}

void MPSetProfilerInt(void *fp, i64 idx, i64 freq) {
  static bool init;
  if (veryunlikely(!init)) {
    incinit();
    timeSetEvent(inc, inc, profcb, 0, TIME_PERIODIC);
    init = true;
  }
  CCore *c = cores + idx;
  WaitForSingleObject(c->mtx, INFINITE);
  c->profiler_freq = freq;
  c->profiler_int = fp;
  c->next_prof_int = 0;
  ReleaseMutex(c->mtx);
}

/* CITATIONS:
 * [1] https://ofekshilon.com/2009/04/10/naming-threads/
 *     (https://archive.li/MIMDo)
 * [2] http://www.programmingunlimited.net/siteexec/content.cgi?page=mingw-seh
 *     (https://archive.is/s6Lnb)
 */
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
