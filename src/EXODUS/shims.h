/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#pragma once

#include <stdbool.h>

#include <EXODUS/types.h>

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
#ifdef _WIN32
void handlectrlc(void);
#else
/* Get safely allocatable region in lower 31 bits of memory */
u64 get31(void);
#endif

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
