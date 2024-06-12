// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wincon.h>
#include <winerror.h>
#include <winternl.h>
#include <direct.h> /* _mkdir */
#include <io.h>     /* _chsize_s */
#include <mbctype.h>
#include <memoryapi.h>
#include <processthreadsapi.h>
#include <profileapi.h>
#include <shlwapi.h>

/* mingw does not supply this (???) */
#ifndef ERROR_CONTROL_C_EXIT
  #define ERROR_CONTROL_C_EXIT 0x23C
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h> /* _O_* */

#include <inttypes.h>
#include <locale.h>
#include <stdbool.h>
#include <stdio.h> /* big brother Microsoft wants you to use stdio.h for SEEK_SET */
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include <vec/vec.h>

#include <exodus/ffi.h>
#include <exodus/misc.h>
#include <exodus/nt/ntdll.h>
#include <exodus/shims.h>

noret void terminate(int i) {
  while (true)
    TerminateProcess(GetCurrentProcess(), i);
  Unreachable();
}

i64 writefd(int fd, u8 *data, u64 sz) {
  return _write(fd, data, sz);
}

i64 readfd(int fd, u8 *buf, u64 sz) {
  return _read(fd, buf, sz);
}

int openfd(char const *path, bool rw) {
  return _open(path, _O_BINARY | (rw ? _O_RDWR | _O_CREAT : _O_RDONLY),
               _S_IREAD | _S_IWRITE);
}

void closefd(int fd) {
  _close(fd);
}

bool fexists(char const *path) {
  return PathFileExistsA(path);
}

bool isdir(char const *path) {
  return PathIsDirectoryA(path);
}

/* emulated stack frame */
typedef struct {
  HANDLE fh;
  char const *cwd;
  char buf[MAX_PATH], *strcur;
  WIN32_FIND_DATAA data;
} delstkframe;

typedef vec_t(delstkframe *) delstk;

static delstkframe *stkcur(delstk *v) {
  return v->data[v->length - 1];
}

/* basically std::filesystem::remove_all */
/* SHFileOperation (w/ FOF_NO_UI) is too slow
 *   when called directly for 10 layers of directories with 9 files each
 *     SHFileOperation: 5s
 *     this: 0.3s
 *   used from DelTree for 30 layers of directories with 29 files each
 *     SHFileOperation: 30s
 *     this: 0.7s
 * it's probably because SHFileOperation calls into Explorer and does a bunch
 * of other stuff. on a side note, *NIX utilizing FTS can do it 10x faster
 */
void deleteall(char *s) {
  if (!PathIsDirectoryA(s)) {
    DeleteFileA(s);
    return;
  }
  delstk stk = {0};
  delstkframe *cur;
func:
  cur = malloc(sizeof *cur);
  cur->cwd = stk.length ? stkcur(&stk)->buf /* parent dir */ : s;
  cur->strcur = stpcpy2(cur->buf, cur->cwd);
  cur->strcur = stpcpy2(cur->strcur, "\\*.*");
  cur->fh =
      FindFirstFileExA(cur->buf, FindExInfoBasic, &cur->data,
                       FindExSearchNameMatch, NULL, FIND_FIRST_EX_LARGE_FETCH);
  if (veryunlikely(cur->fh == INVALID_HANDLE_VALUE))
    goto endfunc;
  /*  -3  cur
   *   ↓  ↓
   * \\*.*\0 */
  cur->strcur -= 3;
  do {
    if (!strcmp(cur->data.cFileName, ".") || !strcmp(cur->data.cFileName, ".."))
      continue;
    strcpy(cur->strcur, cur->data.cFileName);
    if (cur->data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
      vec_push(&stk, cur);
      goto func;
    } else {
      DeleteFileA(cur->buf);
    }
  dir:; /* Clang wants a semicolon here */
  } while (FindNextFileA(cur->fh, &cur->data));
  FindClose(cur->fh);
  RemoveDirectoryA(cur->cwd);
endfunc:
  free(cur);
  if (!stk.length) {
    free(stk.data);
    return;
  }
  cur = vec_pop(&stk);
  goto dir;
}

typedef FILE_NAMES_INFORMATION FileInfo;

static bool traversedir(char const *path, void cb(FileInfo *d, void *_user0),
                        void *user0) {
  NTSTATUS st;
  HANDLE h;
  IO_STATUS_BLOCK iosb;
  /* [2] */
  _Alignas(LONG) WCHAR buf[0x8000];
  FileInfo *di;
  h = CreateFileA(path, FILE_LIST_DIRECTORY,
                  FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
                  OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
  if (veryunlikely(h == INVALID_HANDLE_VALUE))
    return false;
  while (NT_SUCCESS(st = NtQueryDirectoryFile(h, NULL, NULL, NULL, &iosb, buf,
                                              sizeof buf, FileNamesInformation,
                                              FALSE, NULL, FALSE))) {
    di = (FileInfo *)buf;
    while (true) {
      cb(di, user0);
      /* 0 signifies the end of the buffer */
      if (unlikely(!di->NextEntryOffset))
        break;
      di = (FileInfo *)((u8 *)di + di->NextEntryOffset);
    }
  }
  CloseHandle(h);
  /* we've reached the end if st == STATUS_NO_MORE_FILES,
   * if anything else, it's a failure */
  return st == STATUS_NO_MORE_FILES;
}

/* mbsrtowcs/wcsrtombs are too weird to use
 * and I don't want to deal with locales */

static void wcs2a(char *dst, WCHAR const *src, i64 sz) {
  while (sz--)
    *dst++ = *src++;
  *dst = 0;
}

static void listdircb(FileInfo *d, void *user0) {
  vec_str_t *p = user0;
  i64 len = d->FileNameLength / sizeof(WCHAR);
  if (verylikely(len <= 37)) {
    char *dup = HolyMAlloc(len + 1);
    wcs2a(dup, d->FileName, len);
    vec_push(p, dup);
  }
}

char **listdir(char const *path) {
  vec_str_t cleanup(_dtor) ls = {0};
  if (veryunlikely(!traversedir(path, listdircb, &ls)))
    return NULL;
  vec_push(&ls, NULL);
  return memdup(HolyMAlloc, ls.data, sizeof(PSTR[ls.length]));
}

static void fsizecb(FileInfo *d, void *user0) {
  i64 *p = user0;
  if (verylikely(d->FileNameLength / sizeof(WCHAR) <= 37))
    ++*p;
}

i64 fsize(char const *path) {
  if (!isdir(path)) {
    struct _stati64 st;
    if (veryunlikely(-1 == _stati64(path, &st)))
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
  return !mkdir(path);
}

static void _closefd(int *fd) {
  _close(*fd);
}

bool truncfile(char const *path, i64 sz) {
  int cleanup(_closefd) fd = _open(path, _O_RDWR | _O_BINARY);
  if (veryunlikely(fd == -1))
    return false;
  return !_chsize_s(fd, sz);
}

u64 unixtime(char const *path) {
  struct _stati64 st;
  _stati64(path, &st);
  return st.st_mtime;
}

bool readfile(char const *path, u8 *buf, i64 sz) {
  int cleanup(_closefd) fd = _open(path, _O_RDONLY | _O_BINARY);
  return sz == _read(fd, buf, sz);
}

bool writefile(char const *path, u8 const *data, i64 sz) {
  int cleanup(_closefd) fd =
      _open(path, _O_WRONLY | _O_CREAT | _O_BINARY, _S_IREAD | _S_IWRITE);
  return sz == _write(fd, data, sz);
}

bool seekfd(int fd, i64 off) {
  return -1 != _lseeki64(fd, off, SEEK_SET);
}

i64 getticksus(void) {
  static i64 start, freq;
  static bool init;
  if (veryunlikely(!init)) {
    LARGE_INTEGER lfreq, lstart;
    QueryPerformanceFrequency(&lfreq);
    freq = lfreq.QuadPart;
    QueryPerformanceCounter(&lstart);
    start = lstart.QuadPart;
    init = true;
  }
  LARGE_INTEGER lticks;
  QueryPerformanceCounter(&lticks);
  return (lticks.QuadPart - start) * 1e6 / freq;
}

noret static BOOL __stdcall ctrlchndlr(DWORD dw) {
  (void)dw;
  terminate(ERROR_CONTROL_C_EXIT);
}

void prepare(void) {
  SetConsoleCtrlHandler(ctrlchndlr, 1);
  setlocale(LC_ALL, "C.UTF-8");
  _setmbcp(_MB_CP_LOCALE); /* [3] */
  SetConsoleCP(CP_UTF8);
  SetConsoleOutputCP(CP_UTF8);
}

u64 mp_cnt(void) {
  static u64 cnt;
  if (veryunlikely(!cnt)) {
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    cnt = si.dwNumberOfProcessors;
    cnt = Min(cnt, MP_PROCESSORS_NUM);
  }
  return cnt;
}

void unblocksigs(void) {}

bool isvalidptr(void *p) {
  const u64 mask = PAGE_READONLY          //
                 | PAGE_READWRITE         //
                 | PAGE_WRITECOPY         //
                 | PAGE_EXECUTE           //
                 | PAGE_EXECUTE_READ      //
                 | PAGE_EXECUTE_READWRITE //
                 | PAGE_EXECUTE_WRITECOPY;
  MEMORY_BASIC_INFORMATION mbi;
  /* Thanks [1] */
  if (VirtualQuery(p, &mbi, sizeof mbi))
    return !!(mbi.Protect & mask);
  return false;
}

/* CITATIONS:
 * [1] https://stackoverflow.com/a/35576777 (https://archive.md/ehBq4)
 * [2]
 * https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/ns-ntifs-_file_names_information
 * (https://archive.is/00lXG)
 * [3]
 * https://git.lighttpd.net/lighttpd/lighttpd1.4/src/commit/4ebc8afa04ece0ed5c661bec5ab49c7614477f03/src/server.c#L2285
 * (https://archive.is/QWFMu#selection-89791.3-89963.1)
 */
