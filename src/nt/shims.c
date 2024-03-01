/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <windows.h>
#include <wincon.h>
#include <winerror.h>
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

#include "vendor/vec.h"

#include "ffi.h"
#include "misc.h"
#include "shims.h"

noret void terminate(int i) {
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
  return open(path, rw ? (_O_RDWR | _O_CREAT) : _O_RDONLY,
              _S_IREAD | _S_IWRITE);
}

void closefd(int fd) {
  _close(fd);
}

bool fexists(char const *path) {
  if (strchr(path, '*') || strchr(path, '?'))
    return false;
  return PathFileExistsA(path);
}

bool isdir(char const *path) {
  if (strchr(path, '*') || strchr(path, '?'))
    return false;
  /* PathIsDirectoryA returns 0x10 but bool converts it to 1
   * thanks to C99 enforcing it */
  return PathIsDirectoryA(path);
}

/* Ugly because I manually flattened out the recursive function.
 * SHFileOperation is too slow to be used here. */
typedef struct {
  int cur, size;
  void *states[];
} Stk;

static Stk *stacknew(void) {
  Stk *ret = malloc(sizeof *ret);
  *ret = (Stk){.size = 0, .cur = -1};
  return ret;
}

static void stackpush(Stk *restrict *sp, void *p) {
  Stk *s = *sp;
  /* size is always 1 bigger than cur because indexing, so add 2 */
  if (s->cur + 2 > s->size) {
    s->size |= 1;
    s->size *= 2;
    s = realloc(s, sizeof(Stk) + sizeof(void *) * s->size);
    *sp = s;
  }
  s->cur++;
  s->states[s->cur] = p;
}

static void *stackcur(Stk *restrict s) {
  return s->states[s->cur];
}

static void *stackpop(Stk *restrict s) {
  return s->states[s->cur--];
}

struct deleteall {
  HANDLE fh;
  char const *cwd;
  char *strcur, *fnp; /* ptr to filename
                               ↓
                        <path>/????? */
  char findbuf[0x200], entbuf[0x200];
  WIN32_FIND_DATAA data;
};

/* works in the same spirit as std::filesystem::remove_all */
void deleteall(char *s) {
  if (!PathIsDirectoryA(s)) {
    DeleteFileA(s);
    return;
  }
  void *lbl = &&func;
  Stk *restrict stk = stacknew();
  struct deleteall *restrict cur, *tmp;
func:
  cur = malloc(sizeof *cur);
  if (stk->cur == -1)
    cur->cwd = s;
  else {
    tmp = stackcur(stk); // parent dir
    cur->cwd = tmp->entbuf;
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
      stackpush(&stk, cur);
      lbl = &&dir;
      goto func;
    } else {
      DeleteFileA(cur->entbuf);
    }
  dir:
  } while (FindNextFileA(cur->fh, &cur->data));
  FindClose(cur->fh);
  RemoveDirectoryA(cur->cwd);
endfunc:
  free(cur);
  if (stk->cur == -1) {
    free(stk);
    return;
  }
  cur = stackpop(stk);
  goto *lbl;
}

char **listdir(char const *path) {
  vec_str_t ls;
  WIN32_FIND_DATAA data;
  char findbuf[0x200];
  char *cur = stpcpy2(findbuf, path);
  cur = stpcpy2(cur, "\\*.*");
  /* FindFirstFileA/FindNextFileA also returns ./.., see above */
  HANDLE fh = FindFirstFileA(findbuf, &data);
  if (veryunlikely(fh == INVALID_HANDLE_VALUE))
    return NULL;
  vec_init(&ls);
  do {
    if (strlen(data.cFileName) <= 37)
      vec_push(&ls, HolyStrDup(data.cFileName));
  } while (FindNextFileA(fh, &data));
  FindClose(fh);
  vec_push(&ls, NULL);
  u64 sz = ls.length * sizeof ls.data[0];
  char **ret = memcpy(HolyMAlloc(sz), ls.data, sz);
  vec_deinit(&ls);
  return ret;
}

bool dirmk(char const *path) {
  return !mkdir(path);
}

bool truncfile(char const *path, i64 sz) {
  int fd = _open(path, _O_RDWR | _O_BINARY);
  if (veryunlikely(fd == -1))
    return false;
  /* I'm not particularly fond of the fact that _chsize_s
   * is one of those "safe" routines, but I have to use it since
   * it's the one that supports 64-bit sizes */
  bool ret = !_chsize_s(fd, sz);
  _close(fd);
  return ret;
}

i64 fsize(char const *path) {
  if (!isdir(path)) {
    struct _stati64 st;
    if (veryunlikely(-1 == _stati64(path, &st)))
      return -1;
    return st.st_size;
  } else {
    WIN32_FIND_DATAA data;
    char findbuf[0x200];
    char *cur = stpcpy2(findbuf, path);
    cur = stpcpy2(cur, "\\*.*");
    HANDLE fh = FindFirstFileA(findbuf, &data);
    if (veryunlikely(fh == INVALID_HANDLE_VALUE))
      return -1;
    i64 ret = 0;
    do {
      if (strlen(data.cFileName) <= 37)
        ++ret;
    } while (FindNextFileA(fh, &data));
    FindClose(fh);
    return ret;
  }
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
  int fd = _open(path, _O_WRONLY | _O_TRUNC | _O_CREAT | _O_BINARY,
                 _S_IREAD | _S_IWRITE);
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
  const char s[] = "User abort.\n";
  write(2, s, sizeof s - 1);
  terminate(ERROR_CONTROL_C_EXIT);
  // return TRUE;
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
  const DWORD mask = PAGE_READONLY          //
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
