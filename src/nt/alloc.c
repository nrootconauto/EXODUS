/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#define _WIN32_WINNT 0x0602
#include <windows.h>
#include <memoryapi.h>
#include <processthreadsapi.h>
#include <sysinfoapi.h>

#include <limits.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#include "../alloc.h"
#include "../misc.h"
#include "../types.h"

#define ALIGN(x, to) ((x + to - 1) & ~(to - 1))
#define MEM          MEM_RESERVE | MEM_COMMIT
#define ALLOC(addr, sz, mem, pagflags) \
  VirtualAlloc((void *)addr, sz, mem, pagflags)

void *NewVirtualChunk(u64 sz, bool exec) {
  static _Atomic(bool) running;
  static u64 ag, flags64, cur = 0x10000;
  const u64 max = UINT32_MAX >> 1;
  void *ret;
  while (atomic_exchange_explicit(&running, true, memory_order_acquire))
    while (atomic_load_explicit(&running, memory_order_relaxed))
      __builtin_ia32_pause();
  if (!ag) {
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    ag = si.dwAllocationGranularity;
    /* TODO: something to do with DynamicCodePolicy */
    PROCESS_MITIGATION_ASLR_POLICY aslr;
    GetProcessMitigationPolicy(GetCurrentProcess(), ProcessASLRPolicy, &aslr,
                               sizeof aslr);
    if (!aslr.EnableBottomUpRandomization)
      flags64 = MEM_TOP_DOWN;
  }
  if (exec) {
    /* thanks [1]. x86_64 trampolines sound interesting[2] */
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
        ret = ALLOC(addr, sz, MEM, PAGE_EXECUTE_READWRITE);
        cur = (u64)ret + sz;
        goto ret;
      }
    }
    ret = NULL;
  } else /* VirtualAlloc will return NULL on failure */
    ret = ALLOC(NULL, sz, MEM | flags64, PAGE_READWRITE);
ret:
  atomic_store_explicit(&running, false, memory_order_release);
  return ret;
}

void FreeVirtualChunk(void *ptr, argign u64 sz) {
  VirtualFree(ptr, 0, MEM_RELEASE);
}

/* CITATIONS:
 * [1] https://stackoverflow.com/a/54732489 (https://archive.md/ugIUC)
 * [2] https://www.ragestorm.net/blogs/?p=107 (https://archive.md/lR0Mn)
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
