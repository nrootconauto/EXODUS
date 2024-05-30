// mode:c;indent-tabs-mode:nil;c-basic-offset:2;tab-width:8;coding:utf-8
// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
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

void *NewVirtualChunk(u64 sz, bool exec) {
  static u64 pagsz;
  if (veryunlikely(!pagsz))
    pagsz = sysconf(_SC_PAGESIZE);
  sz = ALIGN(sz, pagsz);
  u8 *ret;
  if (exec) {
    ret = MMAP(NULL, sz, PROT | PROT_EXEC, FLAGS | MAP_32BIT);
    if (verylikely(ret != MAP_FAILED))
      return ret;
    /* Refer to posix/shims.c */
    u64 res = findregion(sz);
    if (veryunlikely(res == -1ul))
      return NULL;
    ret = MMAP(res, sz, PROT | PROT_EXEC, FLAGS | MAP_FIXED);
  } else
    ret = MMAP(NULL, sz, PROT, FLAGS);
  if (ret == MAP_FAILED)
    return NULL;
  return ret;
}

void FreeVirtualChunk(void *ptr, u64 sz) {
  munmap(ptr, sz);
}
