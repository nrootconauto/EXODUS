/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <windows.h>
#include <wincon.h>
#include <winerror.h>
#include <winternl.h>
#include <direct.h> /* _mkdir */
#include <io.h>     /* _chsize_s */
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
#include <stdbool.h>
#include <stdio.h> /* big brother Microsoft wants you to use stdio.h for SEEK_SET */
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include <vec/vec.h>

#include <EXODUS/ffi.h>
#include <EXODUS/misc.h>
#include <EXODUS/nt/ddk.h>
#include <EXODUS/shims.h>

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

/* W routines are faster than A routines because A routines convert to WTF16 and
 * call W routines internally, so better to use simple quick routines instead
 * of whatever Windows has for converting text */

/* ASCII to wide char string */
static void a2wcs(char const *s, WCHAR *ws, i64 sz) {
  i64 i;
  for (i = 0; i < sz; ++i)
    ws[i] = s[i];
  ws[i] = 0;
}

/* wide char string to ASCII */
static void wcs2a(WCHAR const *ws, char *s, i64 sz) {
  i64 i;
  for (i = 0; i < sz; ++i)
    s[i] = ws[i] & 0xFF;
  s[i] = 0;
}

bool fexists(char const *path) {
  WCHAR buf[MAX_PATH];
  a2wcs(path, buf, strlen(path));
  return PathFileExistsW(buf);
}

bool isdir(char const *path) {
  WCHAR buf[MAX_PATH];
  a2wcs(path, buf, strlen(path));
  return PathIsDirectoryW(buf);
}

/* emulated stack frame */
typedef struct {
  HANDLE fh;
  char const *cwd;
  char *strcur;
  char findbuf[MAX_PATH], entbuf[MAX_PATH];
  WIN32_FIND_DATAA data;
} delstkframe;

typedef vec_t(delstkframe *) delstk;

static delstkframe *stkcur(delstk *v) {
  return v->data[v->length - 1];
}

static delstkframe *stkpop(delstk *v) {
  return v->data[v->length-- - 1];
}

/* works in the same spirit as std::filesystem::remove_all */
/* Ugly because I manually flattened out the recursive function.
 * SHFileOperation is too slow to be used here. */
void deleteall(char *s) {
  if (!PathIsDirectoryA(s)) {
    DeleteFileA(s);
    return;
  }
  delstk stk = {0};
  delstkframe *cur;
func:
  cur = malloc(sizeof *cur);
  if (!stk.length)
    cur->cwd = s;
  else {
    cur->cwd = stkcur(&stk)->entbuf; // parent dir
  }
  cur->data = (WIN32_FIND_DATAA){0};
  cur->strcur = stpcpy2(cur->findbuf, cur->cwd);
  strcpy(cur->strcur, "\\*.*");
  cur->fh = FindFirstFileA(cur->findbuf, &cur->data);
  if (veryunlikely(cur->fh == INVALID_HANDLE_VALUE))
    goto endfunc;
  cur->strcur = stpcpy2(cur->entbuf, cur->cwd);
  do {
    if (!strcmp(cur->data.cFileName, ".") || !strcmp(cur->data.cFileName, ".."))
      continue;
    cur->strcur = stpcpy2(cur->entbuf, cur->cwd);
    cur->strcur = stpcpy2(cur->strcur, "\\");
    strcpy(cur->strcur, cur->data.cFileName);
    if (PathIsDirectoryA(cur->entbuf)) {
      vec_push(&stk, cur);
      goto func;
    } else {
      DeleteFileA(cur->entbuf);
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
  cur = stkpop(&stk);
  goto dir;
}

typedef FILE_NAMES_INFORMATION FileInfo;

static bool traversedir(char const *path, void cb(FileInfo *d, void *_user0),
                        void *user0) {
  bool ret = true;
  NTSTATUS st;
  HANDLE h;
  IO_STATUS_BLOCK iosb;
  /* [2] */
  _Alignas(LONG) WCHAR buf[0x8000], pathbuf[MAX_PATH];
  FileInfo *di;
  a2wcs(path, pathbuf, strlen(path));
  h = CreateFileW(pathbuf, FILE_LIST_DIRECTORY,
                  FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
                  OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
  if (veryunlikely(h == INVALID_HANDLE_VALUE))
    return false;
  while (true) {
    st = NtQueryDirectoryFile(h, NULL, NULL, NULL, &iosb, buf, sizeof buf,
                              FileNamesInformation, FALSE, NULL, FALSE);
    if (!NT_SUCCESS(st)) {
      /* we've reached the end if st == STATUS_NO_MORE_FILES,
       * if anything else, it's a failure */
      if (st != STATUS_NO_MORE_FILES)
        ret = false;
      break;
    }
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
  return ret;
}

static void listdircb(FileInfo *d, void *user0) {
  vec_str_t *p = user0;
  i64 len = d->FileNameLength / sizeof(WCHAR);
  if (verylikely(len <= 37)) {
    char buf[len + 1], *dup;
    wcs2a(d->FileName, buf, len);
    dup = HolyMAlloc(sizeof buf);
    memcpy(dup, buf, sizeof buf);
    vec_push(p, dup);
  }
}

char **listdir(char const *path) {
  vec_str_t ls;
  vec_init(&ls);
  if (veryunlikely(!traversedir(path, listdircb, &ls)))
    return NULL;
  vec_push(&ls, NULL);
  u64 sz = ls.length * sizeof ls.data[0];
  char **ret = memcpy(HolyMAlloc(sz), ls.data, sz);
  vec_deinit(&ls);
  return ret;
}

static void fsizecb(FileInfo *d, void *user0) {
  i64 *p = user0;
  if (!wcscmp(d->FileName, L".") || !wcscmp(d->FileName, L".."))
    return;
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
    return ret;
  }
}

bool dirmk(char const *path) {
  return !mkdir(path);
}

bool truncfile(char const *path, i64 sz) {
  int fd = _open(path, _O_RDWR | _O_BINARY);
  if (veryunlikely(fd == -1))
    return false;
  bool ret = !_chsize_s(fd, sz);
  _close(fd);
  return ret;
}

u64 unixtime(char const *path) {
  struct _stati64 st;
  _stati64(path, &st);
  return st.st_mtime;
}

bool readfile(char const *path, u8 *buf, i64 sz) {
  int fd = _open(path, _O_RDONLY | _O_BINARY);
  bool ret = sz == _read(fd, buf, sz);
  _close(fd);
  return ret;
}

bool writefile(char const *path, u8 const *data, i64 sz) {
  int fd = _open(path, _O_WRONLY | _O_CREAT | _O_BINARY, _S_IREAD | _S_IWRITE);
  bool ret = sz == _write(fd, data, sz);
  _close(fd);
  return ret;
}

i64 getticksus(void) {
  static LARGE_INTEGER freq;
  if (veryunlikely(!freq.QuadPart)) {
    QueryPerformanceFrequency(&freq);
    freq.QuadPart /= INT64_C(1000000);
  }
  LARGE_INTEGER ticks;
  QueryPerformanceCounter(&ticks);
  return ticks.QuadPart / freq.QuadPart;
}

bool seekfd(int fd, i64 off) {
  return -1 != _lseeki64(fd, off, SEEK_SET);
}

noret static BOOL WINAPI ctrlchndlr(argign DWORD dw) {
  terminate(ERROR_CONTROL_C_EXIT);
}

void handlectrlc(void) {
  SetConsoleCtrlHandler(&ctrlchndlr, 1);
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
