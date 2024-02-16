/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#pragma once

/* MISCELLANEOUS
 * AKA DUMPING GROUND FOR STUFF THAT
 * DO NOT DESERVE A SEPERATE FILE */

#include "types.h"
#include <stddef.h>
#include <stdint.h>

/* ctype.h routines
 * Bt(bitmapname, c) */
u64 Bt(void *addr, u64 idx);
extern u32 char_bmp_hex_numeric[16], char_bmp_alpha[16],
    char_bmp_alpha_numeric[16], char_bmp_dec_numeric[16];

/* ATTRIBS */
#define argign     __attribute__((unused))
#define noret      __attribute__((noreturn))
#define cleanup(x) __attribute__((cleanup(x)))
void _dtor(void *_p);

/* BRANCH CTRL */
#define unlikely(a...)     __builtin_expect(!!(a), 0)
#define veryunlikely(a...) __builtin_expect_with_probability(!!(a), 0, .999)
#define likely(a...)       __builtin_expect(!!(a), 1)
#define verylikely(a...)   __builtin_expect_with_probability(!!(a), 1, .999)

/* SAFE MACROS */
#define Min(x, y)              \
  ({                           \
    typeof(x) XRes = (x);      \
    typeof(y) YRes = (y);      \
    XRes < YRes ? XRes : YRes; \
  })

#define Max(x, y)              \
  ({                           \
    typeof(x) XRes = (x);      \
    typeof(y) YRes = (y);      \
    XRes > YRes ? XRes : YRes; \
  })

#ifndef NDEBUG
  #define Unreachable()     \
    do {                    \
      asm volatile("int3"); \
      for (;;)              \
        ;                   \
    } while (0)
#else
  #define Unreachable() __builtin_unreachable()
#endif

/* SSE */
typedef char uxmm __attribute__((vector_size(16), aligned(1)));
// typedef long long axmm __attribute__((vector_size(16), aligned(16)));

#ifndef __clang__
  #define loaddqu(a...)      __builtin_ia32_loaddqu((char const *)(a))
  #define storedqu(dst, src) __builtin_ia32_storedqu((char *)(dst), (uxmm)(src))
// #define movntdq(dst, src)  __builtin_ia32_movntdq((axmm *)(dst), (axmm)(src))
#else
  #define loaddqu(a...)      (*(uxmm *)(a))
  #define storedqu(dst, src) (*(uxmm *)(dst) = (src))
// #define movntdq(dst, src)  __builtin_nontemporal_store(src, (axmm *)dst)
#endif

/* STRINGS (MINGW IS NOT REALLY POSIX) */
/* Trivia: GCC will just automatically replace any stpcpy call it sees with MOVs
 *         and strcpy+ADD rax,r64 for long strings of unknown size.
 *         Clang doesn't do this. */
char *stpcpy2(char *restrict dst, char const *src);
void *memmem2(void *haystk, u64 haystklen, void *needle, u64 needlelen);
void *mempcpy2(void *restrict dst, void *src, u64 sz);
#define flushprint(f, a...) \
  do {                      \
    fprintf(f, a);          \
    fflush(f);              \
  } while (0)

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
