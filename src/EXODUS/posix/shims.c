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
#include <sys/resource.h>
#include <sys/syscall.h>
#include <unistd.h>

#ifdef __FreeBSD__
  #include <kvm.h>
  #include <sys/param.h>
  #include <sys/sysctl.h>
  #include <sys/user.h>
  #include <libprocstat.h>
  #include <machine/sysarch.h>
#endif

#ifdef __linux__
  #if __has_include(<asm/prctl.h>)
    #include <asm/prctl.h>
  #else // musl
    #define ARCH_SET_GS 0x1001
  #endif
#endif

#include <inttypes.h>
#include <locale.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <vec/vec.h>

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
   * so we don't have to care about long path names */
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

static bool traversedir(char const *path,
                        void cb(struct dirent *e, void *_user0), void *user0) {
  DIR *dir = opendir(path);
  if (veryunlikely(!dir))
    return false;
  struct dirent *ent;
  while ((ent = readdir(dir)))
    cb(ent, user0);
  closedir(dir);
  return true;
}

static void listdircb(struct dirent *e, void *user0) {
  vec_str_t *v = user0;
  /* max strlen() should be 37 because CDIR_FILENAME_LEN is 38
   * fat32 legacy. will break opening ISOs if touched. */
  if (verylikely(strlen(e->d_name) <= 37))
    vec_push(v, HolyStrDup(e->d_name));
}

char **listdir(char const *path) {
  vec_str_t cleanup(_vecdtor) ls = {0};
  if (veryunlikely(!traversedir(path, listdircb, &ls)))
    return NULL;
  vec_push(&ls, NULL);
  return memdup(HolyMAlloc, ls.data, sizeof(char *) * ls.length);
}

static void fsizecb(struct dirent *e, void *user0) {
  i64 *i = user0;
  if (verylikely(strlen(e->d_name) <= 37))
    ++*i;
}

i64 fsize(char const *path) {
  if (!isdir(path)) {
    struct stat st;
    if (veryunlikely(-1 == stat(path, &st)))
      return -1;
    return st.st_size;
  } else {
    i64 ret = 0;
    if (veryunlikely(!traversedir(path, fsizecb, &ret)))
      return -1;
    return ret - 2; /* ".", ".." */
  }
}

bool dirmk(char const *path) {
  return !mkdir(path, 0700);
}

static void _closefd(int *fd) {
  close(*fd);
}

bool truncfile(char const *path, i64 sz) {
  int cleanup(_closefd) fd = open(path, O_RDWR);
  if (veryunlikely(fd == -1))
    return false;
  return !ftruncate(fd, sz);
}

u64 unixtime(char const *path) {
  struct stat st;
  stat(path, &st);
  return st.st_mtime;
}

/* readv/writev probably will not yield measurable perf benefits */
bool readfile(char const *path, u8 *buf, i64 sz) {
  int cleanup(_closefd) fd = open(path, O_RDONLY);
  return sz == read(fd, buf, sz);
}

bool writefile(char const *path, u8 const *data, i64 sz) {
  int cleanup(_closefd) fd = open(path, O_WRONLY | O_CREAT, 0666);
  return sz == write(fd, data, sz);
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
  int addrfd = open("/proc/sys/vm/mmap_min_addr", O_RDONLY);
  u64 ret;
  /* mmap pivot, also minimum address if we don't find any maps
   * in the lower 32 bits
   * mmap_min_addr is a number, 0x1f is more than enough */
  char buf[0x20];
  buf[read(addrfd, buf, 0x1f)] = 0;
  sscanf(buf, "%ju", &ret);
  close(addrfd);
  i64 readb;
  enum {
    MAPSBUFSIZ = 0x8000
  };
  char maps[MAPSBUFSIZ], *s = maps;
  int mapsfd = open("/proc/self/maps", O_RDONLY);
  while ((readb = read(mapsfd, s, BUFSIZ)) > 0 && s - maps < MAPSBUFSIZ)
    s += readb;
  *s = 0;
  close(mapsfd);
  u64 start, end, prev = ret;
  for (s = maps;; s++) {
    sscanf(s, "%jx-%jx", &start, &end);
    if (prev < max && max <= start) {
      ret = prev;
      break;
    }
    prev = end;
    s = strchr(s, '\n');
    /* always {prev,start} < max. prev >= max can't happen
     * This means there's nothing mapped in >32bits (practically impossible) */
    if (!s)
      return start;
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
  for (e = vments; e != vments + cnt; e++) {
    if (prev < max && max <= e->kve_start)
      break;
    prev = e->kve_end;
  }
  procstat_freeprocs(ps, kproc);
  procstat_freevmmap(ps, vments);
  procstat_close(ps);
  return prev;
#endif
}

void preparetls(void) {
  /* we store pointers (not the struct itself)
   * to Fs on gs:0x28 and Gs on gs:0x50
   * blame Microsoft for this */
#define Fsgs ((u8 *)malloc(0x30) - 0x28)
#ifdef __linux__
  syscall(SYS_arch_prctl, ARCH_SET_GS, (u64)Fsgs);
#elif defined(__FreeBSD__)
  amd64_set_gsbase(Fsgs);
#endif
}

void prepare(void) {
  setlocale(LC_ALL, "C");
  struct rlimit rl;
  getrlimit(RLIMIT_NOFILE, &rl);
  rl.rlim_cur = rl.rlim_max;
  setrlimit(RLIMIT_NOFILE, &rl);
  preparetls();
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
