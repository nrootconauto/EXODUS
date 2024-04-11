#pragma once

#include <exodus/types.h>

void VFsThrdInit(void);
void VFsSetDrv(u8 d);
u8 VFsGetDrv(void);
void VFsSetPwd(char const *pwd);
bool VFsDirMk(char const *to);
bool VFsDel(char const *p);
u64 VFsFUnixTime(char const *name);
i64 VFsFSize(char const *name);
int VFsFOpen(char const *path, bool rw);
void VFsFTrunc(char const *name, u64 sz);
bool VFsFWrite(char const *name, u8 const *data, u64 len);
u8 *VFsFRead(char const *name, u64 *len);
bool VFsFExists(char const *path);
bool VFsIsDir(char const *path);
char **VFsDir(void);
void VFsMountDrive(u8 let, char const *path);
