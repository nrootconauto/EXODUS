// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
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
  #include <sys/thr.h>
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

#include <exodus/ffi.h>
#include <exodus/misc.h>
#include <exodus/shims.h>
#include <exodus/types.h>

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
  vec_str_t cleanup(_dtor) ls = {0};
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

bool seekfd(int fd, i64 off) {
  return -1 != lseek(fd, off, SEEK_SET);
}

i64 getticksus(void) {
  static i64 start;
  static bool init;
  if (veryunlikely(!init)) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    start = ts.tv_nsec / 1e3 + ts.tv_sec * 1e6;
    init = true;
  }
  struct timespec cur;
  clock_gettime(CLOCK_MONOTONIC, &cur);
  return cur.tv_nsec / 1e3 + cur.tv_sec * 1e6 - start;
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
  /* msync will return -1 on invalid addrs so exploit that [1] */
  /* I could keep track of allocations in a tree and check from there
   * but MS_ASYNC already ensures it's only touching the VMAs and checking
   * validity (linux src mm/msync.c) and it's going to make allocation code
   * so much more complicated
   *
   * on top of that speed difference is negligible as it is a matter of 120ns or
   * 20ns per query (tested with an rb tree)
   */
  u64 ptr = (u64)p & ~(pag - 1);
  return -1 != msync((void *)ptr, pag, MS_ASYNC);
}

/* Gets minimum address that's allocatable without overwriting anything
 * premapped if such a thing exists.
 *
 * With mmap_min_addr(Linux)/0x10000(FreeBSD) as the start pivot, we loop
 * through the mapped entries and return the first we can find.
 */
#define DFTADDR      0x10000u // minimum MAP_FIXED possible alloc addr on both
#define MAXADDR      ((UINT32_MAX >> 1) - 1)

u64 findregion(u64 sz) {
#ifdef __linux__
  static u64 mmap_min_addr, pagsz;
  static char *buf;
  if (veryunlikely(!mmap_min_addr)) {
    int fd = open("/proc/sys/vm/mmap_min_addr", O_RDONLY);
    char numbuf[0x20];
    if (fd != -1) {
      numbuf[read(fd, numbuf, 0x1f)] = 0;
      sscanf(numbuf, "%ju", &mmap_min_addr);
      close(fd);
    } else
      mmap_min_addr = DFTADDR;
    pagsz = sysconf(_SC_PAGESIZE);
  }
  sz = ALIGNNUM(sz, pagsz);
  u64 start, end, prev = ALIGNNUM(mmap_min_addr, pagsz), ret;
  FILE *fp = fopen("/proc/self/maps", "r");
  if (!fp) {
    flushprint(stderr, ST_ERR_ST ": /proc/self/maps not found\n");
    return -1ul;
  }
  while (getline(&buf, &(u64){0}, fp) > 0) {
    sscanf(buf, "%jx-%jx", &start, &end);
    if (start > prev && start - prev >= sz) {
      ret = (i64)(MAXADDR - prev) < 0 ? -1ul : prev;
      goto fin;
    }
    prev = ALIGNNUM(end, pagsz);
  }
  ret = -1ul;
fin:
  fclose(fp);
  return ret;
#elif defined(__FreeBSD__)
  static struct procstat *ps;
  static struct kinfo_proc *kproc;
  static bool init;
  if (veryunlikely(!init)) {
    ps = procstat_open_sysctl();
    kproc = procstat_getprocs(ps, KERN_PROC_PID, getpid(), &(u32){0});
    init = true;
  }
  unsigned cnt;
  struct kinfo_vmentry *vments, *e;
  vments = procstat_getvmmap(ps, kproc, &cnt); // takes around 100μs
  u64 prev = DFTADDR, start, end;
  for (e = vments; e != vments + cnt; e++) {
    start = e->kve_start, end = e->kve_end;
    if (prev < MAXADDR && MAXADDR <= start && start - prev >= sz)
      break;
    prev = end;
  }
  procstat_freevmmap(ps, vments);
  return prev;
#endif
}

long getthreadid(void) {
  long ret; // pid_t is actually int in Linux but I didn't ask
#ifdef __linux__
  ret = syscall(SYS_gettid);
#elif defined(__FreeBSD__)
  thr_self(&ret);
#else
  #error unsupported
#endif
  return ret;
}

static void nofsgsbase(argign int sig) {
  flushprint(stderr, ST_ERR_ST ": Your processor is older than Ivy Bridge\n");
  terminate(1);
}

void preparetls(void) {
  /* we store pointers (not the struct itself)
   * to Fs on gs:0x28 and Gs on gs:0x50
   * blame Microsoft for this */
#define Fsgs (p = ((u8 *)malloc(0x30) - 0x28))
  void *p;
#ifdef __linux__
  int ret = syscall(SYS_arch_prctl, ARCH_SET_GS, (u64)Fsgs);
#elif defined(__FreeBSD__)
  int ret = amd64_set_gsbase(Fsgs);
#endif
  if (!ret) // man 2 arch_prctl / sys/amd64/amd64/sys_machdep.c
    return;
  flushprint(
      stderr, ST_ERR_ST
      ": failed setting GS segment register base, retrying with WRGSBASE\n");
  signal(SIGILL, nofsgsbase);
  asm("wrgsbase %0" : : "r"(p));
  signal(SIGILL, SIG_DFL);
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
