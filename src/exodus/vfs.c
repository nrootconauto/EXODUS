// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#include <ctype.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include <exodus/alloc.h>
#include <exodus/ffi.h>
#include <exodus/misc.h>
#include <exodus/shims.h>
#include <exodus/vfs.h>

_Thread_local char thrd_pwd[0x200], thrd_drv;

static char mount_points['z' - 'a' + 1][0x200];

static char *VFsFNameAbs(char const *path) {
  char *cur, *prev, ret[0x200];
  cur = stpcpy2(ret, mount_points[thrd_drv - 'A']);
  *cur++ = '/';
  cur = stpcpy2(prev = cur, thrd_pwd + 1);
  *cur++ = '/';
  cur -= cur - 1 == prev;
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
  thrd_drv = toupper(d);
}

u8 VFsGetDrv(void) {
  return thrd_drv;
}

void VFsSetPwd(char const *pwd) {
  strcpy(thrd_pwd, pwd ?: "/");
}

bool VFsDirMk(char const *to) {
  char cleanup(_dtor) *p = VFsFNameAbs(to);
  return fexists(p) ? isdir(p) : dirmk(p);
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
  strcpy(mount_points[toupper(let) - 'A'], path);
}
