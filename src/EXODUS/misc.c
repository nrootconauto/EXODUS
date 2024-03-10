/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <stdlib.h>
#include <string.h>

#include <EXODUS/misc.h>
#include <EXODUS/types.h>

/* ctype.h
 * isalpha: Bt(char_bmp_alpha, c)
 * isalnum: Bt(char_bmp_alpha_numeric, c)
 * ... and so on
 * Why? I wanted to be sort of orthodox in my code (and failed) and I thought
 * using BT for ctype routines was really cool. */
const u32 char_bmp_hex_numeric[16] = {0x0000000, 0x03FF0000, 0x7E, 0x7E, 0, 0,
                                      0,         0,          0,    0,    0, 0,
                                      0,         0,          0,    0},
          char_bmp_alpha[16] = {0x0000000,  0x00000000, 0x87FFFFFF, 0x07FFFFFE,
                                0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
                                0,          0,          0,          0,
                                0,          0,          0,          0},

          char_bmp_alpha_numeric[16] = {0x0000000,  0x03FF0000, 0x87FFFFFF,
                                        0x07FFFFFE, 0xFFFFFFFF, 0xFFFFFFFF,
                                        0xFFFFFFFF, 0xFFFFFFFF, 0,
                                        0,          0,          0,
                                        0,          0,          0,
                                        0},
          char_bmp_dec_numeric[16] = {0x0000000, 0x03FF0000, 0, 0, 0, 0, 0, 0,
                                      0,         0,          0, 0, 0, 0, 0, 0};

u64 Bt(void const *addr, u64 idx) {
  u64 ret;
  asm("bt    %[idx],(%[addr])\n"
      "setc  %%al\n"
      "movzx %%al,%[ret]\n"
      : [ret] "=r"(ret)
      : [addr] "r"(addr), [idx] "r"(idx)
      : "rax");
  return ret;
}

char *stpcpy2(char *restrict dst, char const *src) {
  u64 sz = strlen(src);
  return (char *)memcpy(dst, src, sz + 1) + sz;
}

/* Thanks Apple[1] */
void *memmem2(void *haystk, u64 haystklen, void *needle, u64 needlelen) {
  char *cur, *lim, *cl = haystk, *cs = needle;
  if (!haystklen || !needlelen)
    return NULL;
  if (haystklen < needlelen)
    return NULL;
  if (needlelen == 1)
    return memchr(haystk, *cs, haystklen);
  lim = cl + haystklen - needlelen;
  for (cur = cl; cur <= lim; cur++)
    if (*cur == *cs && !memcmp(cur, cs, needlelen))
      return cur;
  return NULL;
}

void *mempcpy2(void *restrict dst, void *src, u64 sz) {
  return (char *)memcpy(dst, src, sz + 1) + sz;
}

void _dtor(void *_p) {
  void **p = _p;
  free(*p);
}

/* CITATIONS:
 * [1]
 * https://opensource.apple.com/source/Libc/Libc-825.26/string/FreeBSD/memmem.c.auto.html
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
