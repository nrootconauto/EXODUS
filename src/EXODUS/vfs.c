/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <ctype.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include <EXODUS/alloc.h>
#include <EXODUS/ffi.h>
#include <EXODUS/misc.h>
#include <EXODUS/shims.h>
#include <EXODUS/vfs.h>

_Thread_local char thrd_pwd[0x200], thrd_drv;

static char mount_points['z' - 'a' + 1][0x100];

static char *VFsFNameAbs(char const *path) {
  char *cur, *prev, ret[0x200];
  cur = stpcpy2(ret, mount_points[thrd_drv - 'A']);
  *cur++ = '/';
  cur = stpcpy2(prev = cur, thrd_pwd + 1);
  if (likely(cur != prev))
    *cur++ = '/';
  strcpy(cur, path);
  return strdup(ret);
}

void VFsThrdInit(void) {
  strcpy(thrd_pwd, "/");
  thrd_drv = 'T';
}

void VFsSetDrv(u8 d) {
  if (veryunlikely(!Bt(char_bmp_alpha, d)))
    return;
  thrd_drv = d & ~0x20;
}

u8 VFsGetDrv(void) {
  return thrd_drv;
}

void VFsSetPwd(char const *pwd) {
  strcpy(thrd_pwd, pwd ?: "/");
}

bool VFsDirMk(char const *to) {
  char cleanup(_dtor) *p = VFsFNameAbs(to);
  switch ((isdir(p) << 1) | fexists(p)) {
  case 0b11:
    return true;
  case 0b10:
    Unreachable();
  case 0b01:
    return false;
  case 0b00:
    return dirmk(p);
  default:
    Unreachable();
  }
}

bool VFsDel(char const *p) {
  char cleanup(_dtor) *path = VFsFNameAbs(p);
  if (!fexists(path))
    return false;
  deleteall(path);
  return !fexists(path);
}

i64 VFsFSize(char const *name) {
  char cleanup(_dtor) *fn = VFsFNameAbs(name);
  if (!fexists(fn))
    return -1;
  return fsize(fn);
}

int VFsFOpen(char const *path, bool rw) {
  char cleanup(_dtor) *p = VFsFNameAbs(path);
  return openfd(p, rw);
}

void VFsFTrunc(char const *name, u64 sz) {
  char *p = VFsFNameAbs(name);
  bool b = truncfile(p, sz);
  free(p);
  if (veryunlikely(!b))
    HolyThrow("SysError");
}

u64 VFsFUnixTime(char const *name) {
  char cleanup(_dtor) *fn = VFsFNameAbs(name);
  if (!fexists(fn))
    return 0;
  return unixtime(fn);
}

bool VFsFWrite(char const *name, u8 const *data, u64 len) {
  if (!name)
    return false;
  char cleanup(_dtor) *p = VFsFNameAbs(name);
  return writefile(p, data, len);
}

u8 *VFsFRead(char const *name, u64 *lenp) {
  if (!name)
    return NULL;
  char cleanup(_dtor) *p = VFsFNameAbs(name);
  if (!fexists(p) || isdir(p))
    return NULL;
  i64 sz;
  if (-1 == (sz = fsize(p)))
    return NULL;
  /* HolyMAlloc throws 'OutMem' on failure */
  u8 *data = HolyMAlloc(sz + 1);
  if (veryunlikely(!readfile(p, data, sz))) {
    HolyFree(data);
    return NULL;
  }
  data[sz] = 0;
  if (lenp)
    *lenp = sz;
  return data;
}

char **VFsDir(void) {
  char cleanup(_dtor) *path = VFsFNameAbs("");
  if (unlikely(!isdir(path)))
    return NULL;
  return listdir(path);
}

bool VFsIsDir(char const *path) {
  char cleanup(_dtor) *p = VFsFNameAbs(path);
  return isdir(p);
}

bool VFsFExists(char const *path) {
  char cleanup(_dtor) *absp = VFsFNameAbs(path);
  return fexists(absp);
}

void VFsMountDrive(u8 let, char const *path) {
  if (veryunlikely(!Bt(char_bmp_alpha, let)))
    return;
  strcpy(mount_points[(let | 0x20) - 'a'], path);
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
