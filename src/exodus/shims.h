#pragma once

#include <stdbool.h>

#include <exodus/types.h>

void terminate(int i);
i64 writefd(int fd, u8 *data, u64 sz);
i64 readfd(int fd, u8 *buf, u64 sz);
int openfd(char const *path, bool rw);
void closefd(int fd);
bool fexists(char const *path);
bool isdir(char const *path);
/* not const because fts has the wrong interface */
void deleteall(char *path);
char **listdir(char const *path);
i64 getticksus(void);
/* VFsFTrunc will be called AFTER the fd is closed, do not worry */
bool truncfile(char const *path, i64 sz);
u64 unixtime(char const *path);
bool readfile(char const *path, u8 *buf, i64 sz);
bool writefile(char const *path, u8 const *data, i64 sz);
i64 fsize(char const *path);
bool dirmk(char const *path);
u64 mp_cnt(void);
void unblocksigs(void);
bool seekfd(int fd, i64 off);
bool isvalidptr(void *p);
void prepare(void);
#ifndef _WIN32
/* Get safely allocatable region in lower 31 bits of memory */
u64 findregion(u64 sz);
/* set GS register base for Fs/Gs (on Windows we just use the TEB sneakily) */
void preparetls(void);
long getthreadid(void);
#endif
