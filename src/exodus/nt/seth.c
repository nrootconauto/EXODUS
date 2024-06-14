// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#include <windows.h>
#include <winnt.h>
#include <winternl.h>
#include <libloaderapi.h>
#include <memoryapi.h>
#include <process.h>
#include <processthreadsapi.h>
#include <synchapi.h>
#include <timeapi.h>

#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <exodus/abi.h>
#include <exodus/alloc.h>
#include <exodus/dbg.h>
#include <exodus/loader.h>
#include <exodus/main.h>
#include <exodus/misc.h>
#include <exodus/nt/ntdll.h>
#include <exodus/seth.h>
#include <exodus/shims.h>
#include <exodus/vfs.h>
#include <exodus/x86.h>

// sigaltstack isn't a thing on NT, look at profcb
#define SIGSTKSZ 8192

typedef struct {
  CONTEXT ctx;
  HANDLE thread, timer;
  u8 *altstack;
  i64 core_num;
  u8 *profiler_int;
  u64 profiler_freq, next_prof_int;
  vec_void_t funcptrs;
} CCore;

static CCore cores[MP_PROCESSORS_NUM];
static _Thread_local CCore *self;
static u64 nproc;
static u64 pf_prof_active;
static MMRESULT pf_prof_timer;
static bool iswine;

static DWORD __stdcall Seth(void *arg) {
  self = arg;
  VFsThrdInit();
  SetupDebugger();
  void *fp;
  int iter;
  vec_foreach(&self->funcptrs, fp, iter) {
    fficallnullbp(fp);
  }
  return 0;
}

u64 CoreNum(void) {
  return self->core_num;
}

/* TempleOS does not yield contexts automatically
 * (everything is a coroutine) so we need a brute force solution */
void InterruptCore(u64 core) {
  static CSymbol *sym;
  CCore *c = cores + core;
  CONTEXT ctx = {.ContextFlags = CONTEXT_FULL};
  SuspendThread(c->thread);
  GetThreadContext(c->thread, &ctx);
  if (veryunlikely(!sym))
    sym = map_get(&symtab, "Yield");
  ctx.Rsp = (u64)c->altstack + SIGSTKSZ;
  *(u64 *)(ctx.Rsp -= 8) = ctx.Rip; /* return addr */
  ctx.Rip = (u64)sym->val;
  SetThreadContext(c->thread, &ctx);
  ResumeThread(c->thread);
}

void CreateCore(vec_void_t ptrs) {
  CCore *c = cores + nproc;
  *c = (CCore){
      .funcptrs = ptrs,
      .core_num = nproc,
      .thread = CreateThread(NULL, 0x10000, Seth, c, CREATE_SUSPENDED, NULL),
      .timer = CreateWaitableTimerEx(NULL, NULL, 0, TIMER_ALL_ACCESS),
      // Windows doesn't like malloced memory for stacks
      .altstack = VirtualAlloc(NULL, SIGSTKSZ, MEM_RESERVE | MEM_COMMIT,
                               PAGE_READWRITE),
  };
  SetThreadPriority(c->thread, THREAD_PRIORITY_HIGHEST);
  ResumeThread(c->thread);
  nproc++;
}

void WakeCoreUp(u64 core) {
  CCore *c = cores + core;
  SetWaitableTimer(c->timer, &(LARGE_INTEGER){0}, 0, NULL, NULL, FALSE);
}

static u32 inc;

static void incinit(void) {
  static bool init;
  if (verylikely(init))
    return;
  iswine = GetProcAddress(GetModuleHandle("ntdll.dll"), "wine_get_version");
  NtSetTimerResolution(iswine ? 10000 : 5000, TRUE, &(ULONG){0});
  TIMECAPS tc = {0};
  timeGetDevCaps(&tc, sizeof tc);
  inc = tc.wPeriodMin;
  init = true;
}

static u64 elapsedms(void) {
  return getticksus() / 1e3;
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
  fficall(fp, inc);
}

void InitIRQ0(void) {
  static bool init;
  incinit();
  if (init)
    return;
  timeSetEvent(inc, inc, irq0, 0, TIME_PERIODIC);
  init = true;
}

noret static void proftramp(void) {
  CCore *c = self;
  fficallcustombp(c->ctx.Rbp, c->profiler_int, c->ctx.Rip);
  NtContinue(&c->ctx, FALSE);
  __builtin_trap(); // shouldn't ever execute
}

/* There's no SIGPROF on Windows, so we just jump to the profiler interrupt */
static void profcb(u32 id, u32 msg, u64 userptr, u64 dw1, u64 dw2) {
  (void)id;
  (void)msg;
  (void)userptr;
  (void)dw1;
  (void)dw2;
  for (u64 i = 0; i < nproc; ++i) {
    if (!Bt(&pf_prof_active, i))
      continue;
    CCore *c = cores + i;
    if (elapsedms() < c->next_prof_int || !c->profiler_int)
      continue;
    CONTEXT ctx = {.ContextFlags = CONTEXT_FULL};
    SuspendThread(c->thread);
    GetThreadContext(c->thread, &ctx);
    if (ctx.Rip > INT32_MAX) // crude check for HolyC
      goto rel;
    c->ctx = ctx;
    ctx.Rsp = (u64)c->altstack + SIGSTKSZ; // sigaltstack()
    *(u64 *)(ctx.Rsp -= 8) = ctx.Rip;      // return addr
    ctx.Rip = (u64)proftramp;
    SetThreadContext(c->thread, &ctx);
  rel:
    ResumeThread(c->thread);
    c->next_prof_int = c->profiler_freq + elapsedms();
  }
}

void SleepMillis(u64 ms) {
  CCore *c = self;
  LARGE_INTEGER delay = {.QuadPart = -ms * 10000 /* 1ms = 10000 units */};
  SetWaitableTimer(c->timer, &delay, 0, NULL, NULL, FALSE);
  WaitForSingleObject(c->timer, INFINITE);
}

void MPSetProfilerInt(void *fp, i64 idx, i64 freq) {
  CCore *c = cores + idx;
  if (fp) {
    c->profiler_freq = freq / 1e3;
    c->profiler_int = fp;
    c->next_prof_int = 0;
    if (!pf_prof_timer) {
      // TIME_KILL_SYNCHRONOUS only delays the return of timeKillEvent
      pf_prof_timer = timeSetEvent(inc, inc, profcb, 0, TIME_PERIODIC);
      if (!pf_prof_timer) {
        flushprint(stderr, "timeSetEvent failed\n");
        terminate(1);
      }
    }
    LBts(&pf_prof_active, idx);
  } else if (LBtr(&pf_prof_active, idx)) {
    timeKillEvent(pf_prof_timer);
    pf_prof_timer = 0;
  }
}
