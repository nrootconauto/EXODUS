// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#include <stdbool.h>

#include <exodus/misc.h>
#include <exodus/shims.h>
#include <exodus/types.h>
#include <exodus/x86.h>

#define AddU16(to, a)          \
  do {                         \
    *(u16 *)to = (a) & 0xFFff; \
    to += 2;                   \
  } while (0)
#define AddU32(to, a)              \
  do {                             \
    *(u32 *)to = (a) & 0xFFffFFff; \
    to += 4;                       \
  } while (0)
#define AddU64(to, a)      \
  do {                     \
    *(u64 *)to = (u64)(a); \
    to += 8;               \
  } while (0)

/* The maximum length of an Intel 64 and IA-32 instruction remains 15 bytes.
 * ──Quoth Intel® 64 and IA-32 Architectures
 *         Software Developer’s Manual section 2.3.11
 */
#define X86_PROLOG() \
  u8 buf[16], *orig; \
  if (!to)           \
    to = buf;        \
  orig = to
#define X86_EPILOG() return to - orig

#define EXTENDED_REGS(R, I, B)    \
  ((I != -1 && (I & 0x8)) || /**/ \
   (B != -1 && (B & 0x8)) || /**/ \
   (R != -1 && (R & 0x8)))

// imm<n>: 2^(n-1) max for encoding two's complement signed integers
#define IMM_MAX(n)     ((1ll << (n - 1)) - 1)
#define IMM8_MAX       IMM_MAX(8)
#define IMM16_MAX      IMM_MAX(16)
#define IMM32_MAX      IMM_MAX(32)
#define IsImm8(a)      (-IMM8_MAX <= (a) && (a) <= IMM8_MAX)
#define IsImm16(a)     (-IMM16_MAX <= (a) && (a) <= IMM16_MAX)
#define IsImm32(a)     (-IMM32_MAX <= (a) && (a) <= IMM32_MAX)
#define IsWithinU32(a) (0 <= (a) && (a) <= ((1ll << 32) - 1))

// I tried documenting the code as much as possible, but this is just
// gibberish if you aren't familiar with x86_64 and the Intel manual

/* _64: REX.W
 * r: number after /digit or destination reg if /r
 * s: SIB.scale factor: 2 bits, i*2^s, excess scale bits will be ignored
 * i: SIB.index: 3 bits
 * b: SIB.base: 3 bits
 * o: offset
 *
 * -1 for ignored value
 * exempli gratia, SIB_BEGIN(a, RCX, -1, -1, R13, 0x10)
 *                 for `rcx,qword ptr[r13+0x10]`
 */
#define SIB_BEGIN(_64, r, s, i, b, o)                            \
  do {                                                           \
    i64 R = (r), S = (s), I = (i), B = (b), _B, O = (o);         \
    /* S must be an exponent of 2, else ignore */                \
    S = !S || (S & (S - 1)) ? -1 : __builtin_ctzll(S);           \
    if (B == RIP) {                                              \
      if (_64 || EXTENDED_REGS(R, I, B))                         \
        *to++ = rexprefix(_64, R, 0, 0);                         \
    } else {                                                     \
      if ((I != -1 || B == R12) && S == -1 /* RIZ, see below */) \
        I = 0x4;                                                 \
      if (_64 || EXTENDED_REGS(R, I, B)) {                       \
        *to++ = rexprefix(_64, R, I, B);                         \
      }                                                          \
    }

// R12 -> RSP|0x8, R13 -> RBP|0x8, so we reg&0x7(0b111) to check
#define SIB_END()                                                              \
  if (B == RIP) { /* RIP-relative addressing */                                \
    *to++ = ((R & 0x7) << 3) | 0x5;                                            \
    AddU32(to, O);                                                             \
  } else if (I == -1 && (B & 0x7) != RSP) {                                    \
    /* No I(and subsequentely S is ignored) of SIB, only [base+offset] R12 and \
     * RSP are treated specially because they're [SIB] instead of [r/m] */     \
    if (!O && (B & 0x7) != RBP) {                                              \
      /* RBP and R13(== RBP|0x8) can't be encoded w/                           \
       * MODRM.mod bits 0b00 when O is 0 * so skip for O == 0 */               \
      *to++ = ((R & 0x7) << 3) | (B & 0x7);                                    \
    } else {                                                                   \
      *to++ = (IsImm8(O) ? 0x40 : 0x80) /* MODRM.mod bits (disp8/disp32) */    \
            | ((R & 0x7) << 3) | (B & 0x7);                                    \
      if (IsImm8(O))                                                           \
        *to++ = O;                                                             \
      else                                                                     \
        AddU32(to, O);                                                         \
    }                                                                          \
  } else {                                                                     \
    /* ModR/M byte */                                                          \
    if (B == -1)                                                               \
      *to++ = ((R & 0x7) << 3) | 0x4; /* MODRM.mod -> 0b00: see below */       \
    else                                                                       \
      *to++ = (IsImm8(O) ? 0x40 : 0x80) /* MODRM.mod disp8/disp32 */           \
            | ((R & 0x7) << 3) | 0x4;                                          \
    /* SIB byte */                                                             \
    if (S == -1) {                                                             \
      /* most likely user mistake, probably wanted -1 on I but we still        \
       * support it using RIZ (special-purpose zero-only register) */          \
      S = 0, I = 0x4;                                                          \
    }                                                                          \
    if ((_B = B) == -1) {                                                      \
      B = 0x5; /* MODRM.mod -> 0b00, SIB.base = 0b101 - no base, disp32 */     \
    }                                                                          \
    *to++ = (S << 6) | ((I & 0x7) << 3) | (B & 0x7);                           \
    if (IsImm8(O) && _B != -1)                                                 \
      *to++ = O & 0xFF;                                                        \
    else                                                                       \
      AddU32(to, O);                                                           \
  }                                                                            \
  }                                                                            \
  while (0)

// w: REX.W
// reg: number after /digit or destination reg if /r
// idx: SIB.index extension
// base: SIB.base/MODRM.rm
static u8 rexprefix(bool w, i64 reg, i64 idx, i64 base) {
  // these two are for SIB, qv. SIB_BEGIN
  if (idx == -1)
    idx = 0;
  if (base == -1)
    base = 0;
  reg &= 0x8, idx &= 0x8, base &= 0x8;
  reg = !!reg, idx = !!idx, base = !!base;
  return 0x40 | (w << 3) | (reg << 2) | (idx << 1) | base;
}

static u8 modrmregreg(i64 dst, i64 src) {
  return (0b000000011 << 6)  // MODRM.mod register-direct addressing
       | ((src & 0x7) << 3)  // MODRM.reg
       | ((dst & 0x7) << 0); // MODRM.rm
}

i64 x86ret(u8 *to, u16 imm) {
  X86_PROLOG();
  if (!imm)
    *to++ = 0xc3;
  else {
    *to++ = 0xc2;
    *to++ = (imm & 0x00FF) >> 0;
    *to++ = (imm & 0xFF00) >> 8;
  }
  X86_EPILOG();
}

i64 x86leave(u8 *to, argign i64 dummy) {
  X86_PROLOG();
  *to++ = 0xc9;
  X86_EPILOG();
}

i64 x86pushf(u8 *to, argign i64 dummy) {
  X86_PROLOG();
  *to++ = 0x9c;
  X86_EPILOG();
}

i64 x86pushreg(u8 *to, i64 reg) {
  X86_PROLOG();
  // 50+ rd
  if (reg >= R8)
    *to++ = rexprefix(false, 0, 0, reg);
  *to++ = 0x50 + (reg & 0x7);
  X86_EPILOG();
}

i64 x86popf(u8 *to, argign i64 dummy) {
  X86_PROLOG();
  *to++ = 0x9d;
  X86_EPILOG();
}

i64 x86pushimm(u8 *to, i64 imm) {
  X86_PROLOG();
  if (IsImm8(imm)) {
    // 6A ib
    *to++ = 0x6a;
    *to++ = imm & 0xFF;
  } else if (IsWithinU32(imm)) {
    // 68 id
    *to++ = 0x68;
    AddU32(to, imm);
  } else {
    flushprint(stderr, "%jx: wrong immediate size\n", imm);
    terminate(1);
  }
  X86_EPILOG();
}

i64 x86popreg(u8 *to, i64 reg) {
  X86_PROLOG();
  // 58+ rd
  if (reg >= R8)
    *to++ = rexprefix(false, 0, 0, reg);
  *to++ = 0x58 + (reg & 0x7);
  X86_EPILOG();
}

i64 x86lea(u8 *to, i64 dst, i64 s, i64 i, i64 b, i64 off) {
  X86_PROLOG();
  // REX.W + 8D /r
  SIB_BEGIN(true, dst, s, i, b, off);
  *to++ = 0x8d;
  SIB_END();
  X86_EPILOG();
}

i64 x86subimm(u8 *to, i64 dst, i64 imm) {
  X86_PROLOG();
  if (IsImm8(imm)) {
    // REX.W + 83 /5 ib
    *to++ = rexprefix(true, 5, 0, dst);
    *to++ = 0x83;
    *to++ = modrmregreg(dst, 5);
    *to++ = imm & 0xFF;
  } else if (IsImm32(imm)) {
    // REX.W + 81 /5 id
    *to++ = rexprefix(true, 5, 0, dst);
    *to++ = 0x81;
    *to++ = modrmregreg(dst, 5);
    AddU32(to, imm);
  } else {
    flushprint(stderr, "%jx: wrong immediate size\n", imm);
    terminate(1);
  }
  X86_EPILOG();
}

i64 x86addimm(u8 *to, i64 dst, i64 imm) {
  X86_PROLOG();
  if (IsImm8(imm)) {
    // REX.W + 83 /0 ib
    *to++ = rexprefix(true, 0, 0, dst);
    *to++ = 0x83;
    *to++ = modrmregreg(dst, 0);
    *to++ = imm & 0xFF;
  } else if (IsImm32(imm)) {
    // REX.W + 81 /0 id
    *to++ = rexprefix(true, 0, 0, dst);
    *to++ = 0x81;
    *to++ = modrmregreg(dst, 0);
    AddU32(to, imm);
  } else {
    flushprint(stderr, "%jx: wrong immediate size\n", imm);
    terminate(1);
  }
  X86_EPILOG();
}

i64 x86movregreg(u8 *to, i64 dst, i64 src) {
  X86_PROLOG();
  // REX.W + 89 /r
  *to++ = rexprefix(true, src, 0, dst);
  *to++ = 0x89;
  *to++ = modrmregreg(dst, src);
  X86_EPILOG();
}

i64 x86movimm(u8 *to, i64 dst, i64 imm) {
  X86_PROLOG();
  // we only implement instructions that modify the whole 64 bits
  // so no mov r/m16, imm16 (w/ 0x66)
  if (IsWithinU32(imm)) { // u32
    // B8+ rd id
    if (dst >= R8) // R8d, R15d, et al
      *to++ = rexprefix(false, 0, 0, dst);
    *to++ = 0xb8 + (dst & 0x7);
    AddU32(to, imm);
  } else if (IsImm32(imm)) {
    // C7 /0 iw: sign-extend from i32
    if (dst >= R8) // R8d, R15d, et al
      *to++ = rexprefix(false, 0, 0, dst);
    *to++ = 0xc7;
    *to++ = modrmregreg(dst, 0);
    AddU32(to, imm);
  } else {
    // REX.W + B8+ rd io: movabs
    *to++ = rexprefix(true, 0, 0, dst);
    *to++ = 0xb8 + (dst & 0x7);
    AddU64(to, imm);
  }
  X86_EPILOG();
}

i64 x86movsib2reg(u8 *to, i64 dst, i64 s, i64 i, i64 b, i64 off) {
  X86_PROLOG();
  // REX.W + 8B /r
  SIB_BEGIN(true, dst, s, i, b, off);
  *to++ = 0x8b;
  SIB_END();
  X86_EPILOG();
}

i64 x86jmpreg(u8 *to, i64 reg) {
  X86_PROLOG();
  // FF /4
  if (reg >= R8)
    *to++ = rexprefix(false, 4, 0, reg);
  *to++ = 0xff;
  *to++ = modrmregreg(reg, 4);
  X86_EPILOG();
}

i64 x86jmpsib(u8 *to, i64 s, i64 i, i64 b, i64 off) {
  X86_PROLOG();
  // FF /4
  SIB_BEGIN(0, 4, s, i, b, off);
  *to++ = 0xff;
  SIB_END();
  X86_EPILOG();
}

i64 x86callreg(u8 *to, i64 reg) {
  X86_PROLOG();
  // FF /2
  if (reg >= R8)
    *to++ = rexprefix(false, 2, 0, reg);
  *to++ = 0xff;
  *to++ = modrmregreg(reg, 2);
  X86_EPILOG();
}

i64 x86callsib(u8 *to, i64 s, i64 i, i64 b, i64 off) {
  X86_PROLOG();
  // FF /2
  SIB_BEGIN(0, 2, s, i, b, off);
  *to++ = 0xff;
  SIB_END();
  X86_EPILOG();
}

i64 x86andimm(u8 *to, i64 dst, i64 imm) {
  X86_PROLOG();
  if (IsImm8(imm)) {
    // REX.W + 83 /4 ib
    *to++ = rexprefix(true, 4, 0, dst);
    *to++ = 0x83;
    *to++ = modrmregreg(dst, 4);
    *to++ = imm & 0xFF;
  } else if (IsImm32(imm)) {
    // REX.W + 81 /4 id
    *to++ = rexprefix(true, 4, 0, dst);
    *to++ = 0x81;
    *to++ = modrmregreg(dst, 4);
    AddU32(to, imm);
  } else {
    flushprint(stderr, "%jd: wrong immediate size\n", imm);
    terminate(1);
  }
  X86_EPILOG();
}

#ifdef EX_TEST_CODEGEN
  #include <stdio.h>

void terminate(int) {}

int main(void) {
  u8 buf[0x800];
  i64 off = 0;
  Addcode(buf, off, x86pushreg, RBP);
  Addcode(buf, off, x86movregreg, RBP, RSP);
  Addcode(buf, off, x86andimm, RBP, -0x1000);
  Addcode(buf, off, x86pushreg, RSI);
  Addcode(buf, off, x86pushreg, RDI);
  Addcode(buf, off, x86pushreg, R10);
  Addcode(buf, off, x86pushreg, R12);
  Addcode(buf, off, x86lea, RDI, -1, -1, RIP, 0);
  Addcode(buf, off, x86lea, RDI, -1, -1, RBP, 0x10);
  Addcode(buf, off, x86movimm, RAX, 0x1122334455667788);
  Addcode(buf, off, x86movimm, R8, 0x1122334455667788);
  Addcode(buf, off, x86movimm, RAX, 0x7FFFffff);
  Addcode(buf, off, x86movimm, R15, 0x7FFFffff);
  Addcode(buf, off, x86callsib, -1, -1, R13, 0);
  Addcode(buf, off, x86callsib, 0, RAX, R12, 0);  // offset with RIZ
  Addcode(buf, off, x86callsib, -1, RAX, R13, 0); // offset with RIZ
  Addcode(buf, off, x86callsib, 8, R13, -1, 0);
  Addcode(buf, off, x86callsib, 8, R13, RBP, 0x7FFFffff);
  Addcode(buf, off, x86callsib, 8, R12, RSP, 0);
  Addcode(buf, off, x86movsib2reg, RBP, 8, R12, RBP, 0x18);
  Addcode(buf, off, x86movsib2reg, R12, 8, R12, R12, 0x18);
  Addcode(buf, off, x86movsib2reg, RSP, -1, -1, RSP, 0x18);
  Addcode(buf, off, x86subimm, RSP, 0x20);
  Addcode(buf, off, x86addimm, RSP, 0x20);
  Addcode(buf, off, x86addimm, R15, 0x20);
  Addcode(buf, off, x86subimm, R15, 0x20);
  Addcode(buf, off, x86addimm, R15, -0x20);
  Addcode(buf, off, x86addimm, R15, 0x7FFFffff);
  Addcode(buf, off, x86callreg, R15);
  Addcode(buf, off, x86jmpreg, R15);
  Addcode(buf, off, x86jmpreg, RCX);
  Addcode(buf, off, x86popreg, R15);
  Addcode(buf, off, x86popreg, R10);
  Addcode(buf, off, x86popreg, RDI);
  Addcode(buf, off, x86popreg, RSI);
  Addcode(buf, off, x86leave, 0);
  Addcode(buf, off, x86ret, 0);
  Addcode(buf, off, x86ret, 0x1234);
  Addcode(buf, off, x86pushimm, -0x7F);
  for (int i = 0; i < off; i++)
    if (buf[i] >= 0x10)
      printf("%#hhx ", buf[i]);
    else {
      char s[16];
      sprintf(s, "0x0%hhx ", buf[i]); // clean hex print
      fputs(s, stdout);
    }
  putchar('\n');
}

#endif
