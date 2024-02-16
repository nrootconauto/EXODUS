/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <sys/stat.h>
#include <dirent.h>
#include <fcntl.h>
#include <fts.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

#include <inttypes.h>
#include <signal.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#include "vendor/vec.h"

#include "ffi.h"
#include "misc.h"
#include "shims.h"
#include "types.h"

noret void terminate(int i) {
  _Exit(i);
}

i64 writefd(int fd, u8 *data, u64 sz) {
  return write(fd, data, sz);
}

i64 readfd(int fd, u8 *buf, u64 sz) {
  return read(fd, buf, sz);
}

int openfd(char const *path, bool rw) {
  return open(path, rw ? (O_RDWR | O_CREAT) : O_RDONLY, 0666);
}

void closefd(int fd) {
  close(fd);
}

bool fexists(char const *path) {
  return !access(path, F_OK);
}

bool isdir(char const *path) {
  struct stat s;
  stat(path, &s);
  return !!S_ISDIR(s.st_mode);
}

/* works in the same spirit as std::filesystem::remove_all */
void deleteall(char *s) {
  if (!isdir(s)) {
    unlink(s);
    return;
  }
  FTS *fts = fts_open((char *const[]){s, NULL},
                      FTS_PHYSICAL /* Don't follow symlinks */, NULL);
  if (!fts)
    return;
  FTSENT *ent;
  /* fts changes directory while traversing,
   * so we don't have to care about long path names
   * it also returns ./.. */
  while ((ent = fts_read(fts))) {
    switch (ent->fts_info) {
    /* FTS_D comes before its contents
     * dir/
     * ├──a/
     * │  └── file1
     * └──file2
     * traversal order:
     *    dir   (FTS_D)  can't remove, has contents
     *    a     (FTS_D)  can't remove, has contents
     *    file1 (FTS_F)  file, remove it
     *    a     (FTS_DP) empty folder, may remove
     *    file2 (FTS_F)  file, remove it
     *    dir   (FTS_DP) empty folder, may remove
     */
    case FTS_D:
      continue;
    case FTS_DP:
      rmdir(ent->fts_accpath);
      break;
    case FTS_F: // for clarity
    default:
      unlink(ent->fts_accpath);
    }
  }
  fts_close(fts);
}

char **listdir(char const *path) {
  vec_str_t ls;
  DIR *dir = opendir(path);
  if (veryunlikely(!dir))
    return NULL;
  vec_init(&ls);
  struct dirent *ent;
  while ((ent = readdir(dir))) {
    /* max strlen() should be 37 because CDIR_FILENAME_LEN is 38
     * fat32 legacy. will break opening ISOs if touched. */
    if (strlen(ent->d_name) <= 37)
      vec_push(&ls, HolyStrDup(ent->d_name));
  }
  vec_push(&ls, NULL); /* accepts NULL terminated pointer array */
  closedir(dir);
  u64 sz = ls.length * sizeof ls.data[0];
  char **ret = memcpy(HolyMAlloc(sz), ls.data, sz);
  vec_deinit(&ls);
  return ret;
}

bool dirmk(char const *path) {
  return !mkdir(path, 0700);
}

bool truncfile(char const *path, i64 sz) {
  int fd = open(path, O_RDWR);
  if (veryunlikely(fd == -1))
    return false;
  bool ret = !ftruncate(fd, sz);
  close(fd);
  return ret;
}

i64 fsize(char const *path) {
  if (!isdir(path)) {
    struct stat st;
    if (veryunlikely(-1 == stat(path, &st)))
      return -1;
    return st.st_size;
  } else {
    DIR *d = opendir(path);
    i64 i = 0;
    while (readdir(d))
      ++i;
    closedir(d);
    return i;
  }
}

u64 unixtime(char const *path) {
  struct stat st;
  stat(path, &st);
  return st.st_mtime;
}

/* readv/writev probably will not yield measurable perf benefits */
bool readfile(char const *path, u8 *buf, i64 sz) {
  int fd = open(path, O_RDONLY);
  bool ret = sz == read(fd, buf, sz);
  close(fd);
  return ret;
}

bool writefile(char const *path, u8 const *data, i64 sz) {
  int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0666);
  bool ret = sz == write(fd, data, sz);
  close(fd);
  return ret;
}

i64 getticksus(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return ts.tv_nsec / INT64_C(1000) + ts.tv_sec * INT64_C(1000000);
}

bool seekfd(int fd, i64 off) {
  return -1 != lseek(fd, off, SEEK_SET);
}

u64 mp_cnt(void) {
  static u64 cnt;
  if (!cnt) {
    cnt = sysconf(_SC_NPROCESSORS_ONLN);
    cnt = Min(cnt, (u64)128 /* MP_PROCESSORS_NUM */);
  }
  return cnt;
}

void unblocksigs(void) {
  sigset_t all;
  sigfillset(&all);
  sigprocmask(SIG_UNBLOCK, &all, NULL);
}

bool isvalidptr(void *p) {
  static u64 pag;
  if (!pag)
    pag = sysconf(_SC_PAGESIZE);
  /* round down to page boundary
   *   0b100101010 (x)
   * & 0b111110000 <- ~(0b10000 - 1)
   * --------------
   *   0b100100000
   */
  /* msync will return -1 on invalid addrs so exploit that.[1] */
  /* TODO: maybe keep track of allocated virtual chunks
   * instead of relying on msnyc, though I need to
   * test performance for that scenario
   */
  u64 ptr = (u64)p & ~(pag - 1);
  return -1 != msync((void *)ptr, pag, MS_ASYNC);
}

/* CITATIONS:
 * [1] https://renatocunha.com/2015/12/msync-pointer-validity/
 *     (https://archive.md/Aj0S4)
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
