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
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#include <limits.h>
#include <stdbool.h>
#include <stdint.h>

#include <exodus/alloc.h>
#include <exodus/misc.h>
#include <exodus/shims.h>
#include <exodus/types.h>

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
