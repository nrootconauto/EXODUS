/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#include <limits.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>

#include "alloc.h"
#include "misc.h"
#include "shims.h"
#include "types.h"

// log2(to) == 0
#define ALIGN(x, to)                ((x + to - 1) & ~(to - 1))
#define PROT                        PROT_READ | PROT_WRITE
#define FLAGS                       MAP_PRIVATE | MAP_ANON
#define MMAP(hint, sz, prot, flags) mmap((void *)(hint), sz, prot, flags, -1, 0)

void *NewVirtualChunk(u64 sz, bool exec) {
  static _Atomic(bool) running;
  static bool init;
  static u64 pagsz, cur, max = UINT32_MAX >> 1;
  while (atomic_exchange_explicit(&running, true, memory_order_acquire))
    while (atomic_load_explicit(&running, memory_order_relaxed))
      __builtin_ia32_pause();
  if (veryunlikely(!init)) {
    pagsz = sysconf(_SC_PAGESIZE);
    cur = ALIGN(get31(), pagsz);
    init = true;
  }
  sz = ALIGN(sz, pagsz);
  u8 *ret;
  if (exec) {
    if (veryunlikely(cur + sz > max)) {
      ret = NULL;
      goto ret;
    }
    ret = MMAP(cur, sz, PROT | PROT_EXEC, FLAGS | MAP_FIXED);
    if (veryunlikely(ret == MAP_FAILED)) {
      ret = NULL;
      goto ret;
    }
    cur = (u64)ret + sz;
  } else {
    ret = MMAP(NULL, sz, PROT, FLAGS);
    if (veryunlikely(ret == MAP_FAILED))
      ret = NULL;
  }
ret:
  atomic_store_explicit(&running, false, memory_order_release);
  return ret;
}

void FreeVirtualChunk(void *ptr, u64 sz) {
  munmap(ptr, sz);
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
