/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
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

#include <EXODUS/alloc.h>
#include <EXODUS/misc.h>
#include <EXODUS/types.h>

// popcnt(to) == 1
#define ALIGN(x, to) ((x + to - 1) & ~(to - 1))
#define MEM          MEM_RESERVE | MEM_COMMIT
#define ALLOC(addr, sz, pagflags) \
  VirtualAlloc((void *)addr, sz, vflags, pagflags)

void *NewVirtualChunk(u64 sz, bool exec) {
  static bool running;
  static bool init;
  static u64 ag, cur = 0x10000, max = UINT32_MAX >> 1;
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
    /* If DEP is disabled, don't let RW pages pile on RWX pages to save space */
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
