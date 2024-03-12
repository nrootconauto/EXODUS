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
#include <stdbool.h>
#include <stdint.h>

#include <EXODUS/alloc.h>
#include <EXODUS/misc.h>
#include <EXODUS/shims.h>
#include <EXODUS/types.h>

// popcnt(to) == 1
#define ALIGN(x, to)                ((x + to - 1) & ~(to - 1))
#define PROT                        PROT_READ | PROT_WRITE
#define FLAGS                       MAP_PRIVATE | MAP_ANON
#define MMAP(hint, sz, prot, flags) mmap((void *)(hint), sz, prot, flags, -1, 0)

/* Sort of a bump allocator that resumes from the previous mapping (for R|W|X).
 * We get the unmapped region in the lower 2 gigs
 * (after the mapped binary/brk heap in some systems) and just keep bumping
 * and mapping from there. MAP_FIXED doesn't seem to care about already
 * allocated pages but the initial pivot address seems to be enough. */
void *NewVirtualChunk(u64 sz, bool exec) {
  static bool running;
  static bool init;
  static u64 pagsz, cur, max = UINT32_MAX >> 1;
  while (LBts(&running, 0))
    while (Bt(&running, 0))
      __builtin_ia32_pause();
  if (veryunlikely(!init)) {
    pagsz = sysconf(_SC_PAGESIZE);
    /* Refer to posix/shims.c */
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
  LBtr(&running, 0);
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
