// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#define _WIN32_WINNT 0x0602 /* [2] (GetProcessMitigationPolicy) */
#include <windows.h>
#include <memoryapi.h>
#include <processthreadsapi.h>
#include <sysinfoapi.h>

#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#include <exodus/alloc.h>
#include <exodus/misc.h>
#include <exodus/types.h>

// popcnt(to) == 1
#define ALIGN(x, to) ((x + to - 1) & ~(to - 1))
#define MEM          MEM_RESERVE | MEM_COMMIT
#define ALLOC(addr, sz, pagflags) \
  VirtualAlloc((void *)addr, sz, vflags, pagflags)

void *NewVirtualChunk(u64 sz, bool exec) {
  static bool running;
  static bool init;
  static u64 ag, cur = 0x10000, max = (1ull << 31) - 1;
  static DWORD vflags = MEM_RESERVE | MEM_COMMIT;
  void *ret;
  while (LBts(&running, 0))
    while (Bt(&running, 0))
      __builtin_ia32_pause();
  if (veryunlikely(!init)) {
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    ag = si.dwAllocationGranularity;
    HANDLE proc = GetCurrentProcess();
    PROCESS_MITIGATION_ASLR_POLICY aslr;
    /* If DEP is disabled, don't let RW pages pile on RWX pages to avoid OOM */
    GetProcessMitigationPolicy(proc, ProcessASLRPolicy, &aslr, sizeof aslr);
    if (!aslr.EnableBottomUpRandomization)
      vflags |= MEM_TOP_DOWN;
    PROCESS_MITIGATION_DYNAMIC_CODE_POLICY wxallowed;
    /* Disable ACG */
    GetProcessMitigationPolicy(proc, ProcessDynamicCodePolicy, &wxallowed,
                               sizeof wxallowed);
    wxallowed.ProhibitDynamicCode = 0;
    SetProcessMitigationPolicy(ProcessDynamicCodePolicy, &wxallowed,
                               sizeof wxallowed);
    init = true;
  }
  if (exec) {
    /* thanks [1].
     * Climbs up from a low address and queries the memory region,
     * checks for size and availability, rinse and repeat */
    MEMORY_BASIC_INFORMATION mbi;
    u64 region = cur;
    while (verylikely(region <= max) &&
           VirtualQuery((void *)region, &mbi, sizeof mbi)) {
      region = (u64)mbi.BaseAddress + mbi.RegionSize;
      /*
       * VirtualAlloc() will round down to alloc granularity
       * but mbi.BaseAddress is aligned to page boundary.
       * may overlap, align
       */
      u64 addr = ALIGN((u64)mbi.BaseAddress, ag);
      if (mbi.State & MEM_FREE && sz <= region - addr) {
        ret = ALLOC(addr, sz, PAGE_EXECUTE_READWRITE);
        cur = (u64)ret + sz;
        goto ret;
      }
    }
    ret = NULL;
  } else /* VirtualAlloc will return NULL on failure */
    ret = ALLOC(NULL, sz, PAGE_READWRITE);
ret:
  LBtr(&running, 0);
  return ret;
}

void FreeVirtualChunk(void *ptr, argign u64 sz) {
  VirtualFree(ptr, 0, MEM_RELEASE);
}

/* CITATIONS:
 * [1] https://stackoverflow.com/a/54732489 (https://archive.md/ugIUC)
 * [2]
 * https://learn.microsoft.com/en-us/cpp/porting/modifying-winver-and-win32-winnt?view=msvc-170
 *     (https://archive.is/1VQzm)
 */
