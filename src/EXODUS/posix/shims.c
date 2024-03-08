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
/* clang-format off */
#ifdef __FreeBSD__
  #include <kvm.h>
  #include <sys/param.h>
  #include <sys/sysctl.h>
  #include <sys/user.h>
  #include <libprocstat.h>
#endif
/* clang-format on */

#include <inttypes.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include <vendor/vec.h>

#include <EXODUS/ffi.h>
#include <EXODUS/misc.h>
#include <EXODUS/shims.h>
#include <EXODUS/types.h>

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
  return open(path, rw ? O_RDWR | O_CREAT : O_RDONLY, 0666);
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
  return S_ISDIR(s.st_mode);
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
  int fd = open(path, O_WRONLY | O_CREAT, 0666);
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
    cnt = Min(cnt, MP_PROCESSORS_NUM);
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

/* Gets minimum address that's safely allocatable without overwriting anything
 * premapped if such a thing exists.
 * Linux: read /proc/self/maps, use sysctl vm.mmap_min_addr to get minimum addr
 * FreeBSD: use libprocstat, there's no kernel lower limit to mmap, though
 *          MAP_FIXED with 0 gave me an error
 * (remarks: The FreeBSD way is bad for dumping data and getting a view, and
 *           the Linux way maybe has some speed tradeoff)
 * then with mmap_min_addr(Linux)/0x10000(FreeBSD) as the start pivot, we loop
 * thrugh the mapped entries and see the last entry - ie, previous end is below
 * max and current start is over max.
 *
 * What if there's something mapped just at the 31bit edge?
 *   Tough luck, but I haven't seen anything that does that.
 *   If anything it's around 0x400000 (on Fedora)
 */
u64 get31(void) {
  u64 max = UINT32_MAX >> 1;
#ifdef __linux__
  int addrfd = open("/proc/sys/vm/mmap_min_addr", O_RDONLY), main(int, char **);
  u64 ret;
  /* mmap pivot, also minimum address if we don't find any maps
   * in the lower 32 bits */
  char buf[0x20];
  buf[read(addrfd, buf, 0x1f)] = 0;
  sscanf(buf, "%ju", &ret);
  close(addrfd);
  i64 readb;
  /* ELF is mapped directly on its start address instead of using ASLR */
  if ((u64)main < max) {
    enum {
      MAPSBUFSIZ = 0x8000
    };
    char maps[MAPSBUFSIZ], *s = maps;
    int mapsfd = open("/proc/self/maps", O_RDONLY);
    while ((readb = read(mapsfd, s, BUFSIZ)) > 0 && s - maps < MAPSBUFSIZ)
      s += readb;
    *s = 0;
    close(mapsfd);
    u64 start, end = 0, prev = ret;
    s = maps;
    while (true) {
      if (end)
        prev = end;
      sscanf(s, "%jx-%jx", &start, &end);
      if (prev < max && max <= start)
        break;
      /* We won't hit a null before a newline or finding something anyway */
      while (*s++ != '\n')
        ;
    }
    ret = prev;
  }
  return ret;
#elif defined(__FreeBSD__)
  struct procstat *ps = procstat_open_sysctl();
  /* FreeBSD mandates cnt to be unsigned int */
  u32 cnt;
  struct kinfo_proc *kproc =
      procstat_getprocs(ps, KERN_PROC_PID, getpid(), &(u32){0});
  struct kinfo_vmentry *vments = procstat_getvmmap(ps, kproc, &cnt), *e;
  u64 prev = 0x10000;
  for (u32 i = 0; i < cnt; i++) {
    e = vments + i;
    if (i)
      prev = e[-1].kve_end;
    if (prev < max && max <= e->kve_start)
      break;
  }
  procstat_freeprocs(ps, kproc);
  procstat_freevmmap(ps, vments);
  procstat_close(ps);
  return prev;
#endif
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
