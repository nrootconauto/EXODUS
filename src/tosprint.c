/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <inttypes.h>
#include <math.h>
#include <stdio.h>

#include "vendor/vec.h"

#include "misc.h"
#include "shims.h"
#include "tosprint.h"
#include "types.h"

static char *unescapestr(char *str, char *where) {
  char const *to;
  char c;
  while ((c = *str)) {
    switch (c) {
#define E(c, e) \
  case c:       \
    to = e;     \
    break
      E('\\', "\\\\");
      E('\a', "\\a");
      E('\b', "\\b");
      E('\f', "\\f");
      E('\n', "\\n");
      E('\r', "\\r");
      E('\t', "\\t");
      E('\v', "\\v");
      E('\"', "\\\"");
#undef E
    default:
      goto checkascii;
    }
    __builtin_memcpy(where, to, 2);
    where += 2;
    str++;
    continue;
  checkascii:
    if (!Bt(char_bmp_alpha_numeric, c) &&
        !strchr(" ~!@#$%^&*()_+|{}[]\\;':\",./<>?", c)) {
      snprintf(where, 5, "\\%o", (u8)c);
      where += 4;
      str++;
      continue;
    }
    *where++ = *str++;
  }
  *where = 0;
  return where;
}

/*
 * (excerpt from his notes)
 * ----09/19/13 18:14:38----
 *
 * WWW.OSDEV.ORG is asking how to print floats in PrintF().
 *
 * It turns-out I have a really fast routine for, say, "%12.6f".  On numbers,
 * you go backward.  I use a stack data structure to reverse digits.  I look at
 * the 6. I forget.  I think I subtract the integer part from decimal.  Then, I
 * multiply by 10 to the 6th from an array look-up table.  Then, I make it into
 * a 64-bit integer and print push the digits on the stack, like you would
 * expect.  I print the zeros and the decimal.  I print the Int, or if I have to
 * multiply it, I multiply by a look-up table power ot ten array.
 *
 * (This cuts corners, makes beautiful use of having 64-bit word size, is
 * elegant and fast.  Unfortuinately, printf is silly being ultra fast.  I get
 * problems if you specify "%50.30f"  Mine craps-out, unless the number is tiny.
 * It sounds bad, but you just have to be careful not to overdo precision. It
 * gives you all the precision in the double, but if you do way more than a
 * double has, well mine fucks up.  Don't over do the format size beyond 64-bit
 * integer sitting in the decimal region.
 */
static int fmtfloat(char *s, u64 buflen, double f, int _prec) {
  i64 prec = pow(10, _prec);
  i64 integ = f, dec = f * prec;
  dec -= integ * prec;
  /* The C standard mandates labs() to take a long, but Windows uses
   * long long for 64-bit integers. As a result I am forced to cast it to
   * long and use %ld for the compiler to shut the fuck up */
  return snprintf(s, buflen, "%" PRIi64 ".%ld", integ, labs((long)dec));
}

static vec_char_t MStrPrint(char const *fmt, argign u64 argc, i64 *argv) {
  char buf[0x200];
  vec_char_t ret;
  vec_init(&ret);
  char const *start = fmt, *end;
  i64 arg = -1;
  while (1) {
    arg++;
    end = strchr(start, '%');
    if (!end)
      end = start + strlen(start);
    vec_pusharr(&ret, start, end - start);
    if (!*end)
      return ret;
    start = end + 1;
    if (*start == '-')
      start++;
    while (Bt(char_bmp_dec_numeric, *start))
      start++;
    if (*start == '.') {
      start++;
      while (Bt(char_bmp_dec_numeric, *start))
        start++;
    }
    while (strchr("t,$/", *start))
      ++start;
    i64 aux = 1;
    if (*start == '*') {
      aux = argv[arg++];
      start++;
    } else if (*start == 'h') {
      while (Bt(char_bmp_dec_numeric, *start)) {
        aux *= 10;
        aux += *start - '0';
        ++start;
      }
    }
#define FmtTyp(fmt, T)                   \
  do {                                   \
    union {                              \
      T t;                               \
      i64 i;                             \
    } u = {.i = argv[arg]};              \
    snprintf(buf, sizeof buf, fmt, u.t); \
    vec_pusharr(&ret, buf, strlen(buf)); \
  } while (0)
    switch (*start) {
    case 'd':
    case 'i':
      FmtTyp("%" PRId64, i64);
      break;
    case 'u':
      FmtTyp("%" PRIu64, u64);
      break;
    case 'x':
      FmtTyp("%" PRIx64, u64);
      break;
    case 'f':
    case 'n': {
      union {
        f64 f;
        i64 i;
      } u = {.i = argv[arg]};
      /* 7: ansf precision in TempleOS */
      fmtfloat(buf, sizeof buf, 7, u.f);
    } break;
    case 'p':
      FmtTyp("%p", void *);
      break;
    case 'c':
      /* HolyC has multichar literals (e.g. 'abcdefg')
       * so we need to stamp it out in a string */
      while (--aux >= 0) {
        union {
          char s[9];
          i64 i;
        } u = {.i = argv[arg]};
        vec_pusharr(&ret, u.s, strlen(u.s));
      }
      break;
    case 's':
      while (--aux >= 0) {
        char *tmp = ((char **)argv)[arg];
        vec_pusharr(&ret, tmp, strlen(tmp));
      }
      break;
    case 'q': {
      char *str = ((char **)argv)[arg];
      char esc[strlen(str) * 4 + 1];
      unescapestr(str, esc);
      vec_pusharr(&ret, esc, strlen(esc));
    } break;
    case '%':
      vec_push(&ret, '%');
      break;
    }
    ++start;
  }
}

void TOSPrint(char const *fmt, i64 argc, i64 *argv) {
  vec_char_t s = MStrPrint(fmt, argc, argv);
  writefd(1, s.data, s.length);
  vec_deinit(&s);
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
