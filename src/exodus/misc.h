#pragma once

/* MISCELLANEOUS
 * AKA DUMPING GROUND FOR STUFF THAT
 * DO NOT DESERVE A SEPERATE FILE */

#include <inttypes.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include <exodus/types.h>

/* Bit/atomic routines the TempleOS way because I'm too cool for stdatomic.h
 *
 * addr is a bit array
 * L prefixed: atomic
 *
 * Bt:   addr[idx] -> rax
 * LBtr: addr[idx] -> rax, addr[idx] = 1
 * LBts: addr[idx] -> rax, addr[idx] = 0
 * LBtc: addr[idx] -> rax, addr[idx] = ~addr[idx]
 */
bool Bt(void const *addr, u64 idx);
bool LBtr(void *addr, u64 idx);
bool LBts(void *addr, u64 idx);
bool LBtc(void *addr, u64 idx);

/* ctype.h routines
 * Bt(bitmapname, c) */
extern const u32 char_bmp_hex_numeric[16], char_bmp_alpha[16],
    char_bmp_alpha_numeric[16], char_bmp_dec_numeric[16];

/* TOS DEFINES */
#define MP_PROCESSORS_NUM UINT64_C(128)
enum {
  SF_ARG1 = 0x10,
#define SF_ARG1 SF_ARG1
  SF_ARG2 = 0x18,
#define SF_ARG2 SF_ARG2
  SF_ARG3 = 0x20,
#define SF_ARG3 SF_ARG3
  SF_ARG4 = 0x28,
#define SF_ARG4 SF_ARG4
};
/* $BG,RED$ */
#define Bgred "\e[0;31m"
/* $BG$ */
#define Bgrst     "\e[0m"
#define ST_ERR_ST Bgred "CRITICAL" Bgrst

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

/* QoL MACROS */
#define Min(x, y)              \
  ({                           \
    __auto_type XRes = (x);    \
    __auto_type YRes = (y);    \
    XRes < YRes ? XRes : YRes; \
  })

#define Max(x, y)              \
  ({                           \
    __auto_type XRes = (x);    \
    __auto_type YRes = (y);    \
    XRes > YRes ? XRes : YRes; \
  })

// requirement: popcnt(to) == 1
#define ALIGNNUM(x, to) ((x + to - 1) & ~(to - 1))

#define Arrlen(a) (sizeof a / sizeof a[0])

#ifndef NDEBUG
  #define Unreachable()                                                       \
    do {                                                                      \
      flushprint(stderr, "Unreachable code @ '%s' L%d func:'%s'\n", __FILE__, \
                 __LINE__, __func__);                                         \
      asm volatile("int3");                                                   \
      for (;;)                                                                \
        ;                                                                     \
    } while (0)
#else
  #define Unreachable() __builtin_unreachable()
#endif

/* I could really use some user-defined literals in C, like 128_MiB
 * A really neat C++ feature, I'm not gonna lie */
#define KiB(b) (1024 * (u64)(b))
#define MiB(b) (1024 * KiB(b))
#define GiB(b) (1024 * MiB(b))

/* STRINGS (MINGW IS NOT REALLY POSIX) */
/* Trivia: GCC will just automatically replace any stpcpy call it sees with MOVs
 *         and strcpy+ADD rax,r64 for long strings of unknown size.
 *         Clang doesn't do this. */
char *stpcpy2(char *restrict dst, char const *src);
void *memmem2(void *haystk, u64 haystklen, void *needle, u64 needlelen);
void *mempcpy2(void *restrict dst, void const *src, u64 sz);
void *memdup(void *alloc(u64 _sz), void const *src, u64 sz);

// CLI I/O might interfere with output, happens frequently with NT
#define flushprint(f, a...) \
  do {                      \
    fprintf(f, a);          \
    fflush(f);              \
  } while (0)
