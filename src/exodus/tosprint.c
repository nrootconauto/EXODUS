// mode:c;indent-tabs-mode:nil;c-basic-offset:2;tab-width:8;coding:utf-8
// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <vec/vec.h>

#include <exodus/misc.h>
#include <exodus/shims.h>
#include <exodus/tosprint.h>
#include <exodus/types.h>

/* No null termination */
static i64 unescapestr(char *str, char *where) {
  char const *to;
  char *ret = where;
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
    if (where)
      __builtin_memcpy(ret, to, 2);
    ret += 2;
    str++;
    continue;
  checkascii:
    if (!Bt(char_bmp_alpha_numeric, c) &&
        !strchr(" ~!@#$%^&*()_+|{}[]\\;':\",./<>?", c)) {
      if (where)
        snprintf(ret, 5, "\\%o", (u8)c);
      ret += 4;
      str++;
      continue;
    }
    if (where)
      *ret = *str;
    ++ret, ++str;
  }
  return ret - where;
}

/*
 * Could've used normal snprintf here but this is cooler
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
  return snprintf(s, buflen, "%ji.%ji", integ, imaxabs(dec));
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
#define FmtTyp(fmt, T)                                \
  do {                                                \
    snprintf(buf, sizeof buf, fmt, ((T *)argv)[arg]); \
    vec_pusharr(&ret, buf, strlen(buf));              \
  } while (0)
    switch (*start) {
    case 'd':
    case 'i':
      FmtTyp("%ji", i64);
      break;
    case 'u':
      FmtTyp("%ju", u64);
      break;
    case 'x':
      FmtTyp("%jx", u64);
      break;
    case 'f':
    case 'n': {
      union {
        f64 f;
        i64 i;
      } u = {.i = argv[arg]};
      /* 7: ansf precision in TempleOS */
      fmtfloat(buf, sizeof buf, u.f, 7);
      vec_pusharr(&ret, buf, strlen(buf));
    } break;
    case 'p':
      FmtTyp("%p", void *);
      break;
    case 'c': {
      /* HolyC has multichar literals (e.g. 'abcdefg')
       * so we need to stamp it out in a string */
      __builtin_memcpy(buf, argv + arg, 8);
      buf[8] = 0;
      u64 len = strlen(buf);
      while (--aux >= 0)
        vec_pusharr(&ret, buf, len);
    } break;
    case 's': {
      char *tmp = ((char **)argv)[arg];
      u64 len = strlen(tmp);
      while (--aux >= 0)
        vec_pusharr(&ret, tmp, len);
    } break;
    case 'q': {
      char *str = ((char **)argv)[arg];
      i64 escsz = unescapestr(str, NULL);
      vec_reserve(&ret, escsz);
      unescapestr(str, ret.data + ret.length);
      ret.length += escsz;
    } break;
    case '%':
      vec_push(&ret, '%');
      break;
    }
    ++start;
  }
}

void TOSPrint(char const *fmt, i64 argc, i64 *argv) {
  vec_char_t cleanup(_dtor) s = MStrPrint(fmt, argc, argv);
  writefd(1, (u8 *)s.data, s.length);
}
