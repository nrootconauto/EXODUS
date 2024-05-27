#pragma once

#include <exodus/misc.h>
#include <exodus/types.h>

#define Addcode(bin, off, f, a...) off += f(bin ? bin + off : NULL, a)

// if you look closely R8~R15 is just 0x8|(RAX~RDI)
// as a result R12 and R13 respectively share the
// fine nuances of MODRM.mod of RSP and RBP
enum /* clang-format off */ {
  RAX, RCX, RDX, RBX, RSP, RBP, RSI, RDI,
  R8 , R9 , R10, R11, R12, R13, R14, R15,
  RIP
} /* clang-format on */;

i64 x86movregreg(u8 *to, i64 dst, i64 src);
i64 x86ret(u8 *to, u16 arity);
i64 x86leave(u8 *to, argign i64 dummy);
i64 x86pushreg(u8 *to, i64 reg);
i64 x86pushimm(u8 *to, i64 imm);
i64 x86popreg(u8 *to, i64 reg);
i64 x86lea(u8 *to, i64 dst, i64 s, i64 i, i64 b, i64 off);
i64 x86subimm(u8 *to, i64 dst, i64 imm);
i64 x86addimm(u8 *to, i64 dst, i64 imm);
i64 x86movimm(u8 *to, i64 dst, i64 imm);
i64 x86callreg(u8 *to, i64 reg);
i64 x86callsib(u8 *to, i64 s, i64 i, i64 b, i64 off);
i64 x86andimm(u8 *to, i64 dst, i64 imm);
