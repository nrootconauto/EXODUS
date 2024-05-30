// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include <exodus/misc.h>
#include <exodus/types.h>

/* ctype.h the TempleOS way
 * isalpha: Bt(char_bmp_alpha, c)
 * isalnum: Bt(char_bmp_alpha_numeric, c)
 * ... and so on */
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
#define Bitop(name, inst, a...)            \
  bool name(void a *addr, u64 idx) {       \
    bool ret = false;                      \
    asm(#inst " %[idx],(%[addr])\n"        \
        : "=@ccc"(ret)                     \
        : [idx] "r"(idx), [addr] "r"(addr) \
        : "cc", "memory");                 \
    return ret;                            \
  }

Bitop(Bt, bt, const);
Bitop(LBts, lock bts);
Bitop(LBtr, lock btr);
Bitop(LBtc, lock btc);

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

void *mempcpy2(void *restrict dst, void const *src, u64 sz) {
  return (char *)memcpy(dst, src, sz) + sz;
}

void *memdup(void *alloc(u64 _sz), void const *src, u64 sz) {
  return memcpy(alloc(sz), src, sz);
}

void _dtor(void *_p) {
  /* works with vec_* quoth ISO/IEC 9899:1999 6.7.2.1.13 because
   * all vec_* structures have the malloced ptr as their first member */
  void **p = _p;
  free(*p);
}

/* CITATIONS:
 * [1]
 * https://opensource.apple.com/source/Libc/Libc-825.26/string/FreeBSD/memmem.c.auto.html
 */
