#pragma once

// clang-format off
#ifndef __ASSEMBLER__

#include <stdbool.h>

#include <mapmacro.h>

#include <exodus/misc.h>
#include <exodus/types.h>

#define _CASTI64(a...) ((i64)(a))

#define _ARGC_ARGV_HELPER(a...) _ARGC_ARGV(((i64[]){0, a}))
#define _ARGC_ARGV(a)           Arrlen(a) - 1, a + (Arrlen(a) > 1)
// needed to match args (eval order)
#define _EVAL_MATCH_ARGS(a, b...) a(b)

#define _fficall(fp, a...) fficall((void *)fp, _ARGC_ARGV_HELPER(a))
#define fficall(a...)      _EVAL_MATCH_ARGS(_fficall, MAP_LIST(_CASTI64, a))

#define _fficallnullbp(fp, a...) \
   fficallnullbp((void *)fp, _ARGC_ARGV_HELPER(a))
#define fficallnullbp(a...) \
   _EVAL_MATCH_ARGS(_fficallnullbp, MAP_LIST(_CASTI64, a))

#define _fficallcustombp(rbp, fp, a...) \
  fficallcustombp((void *)rbp, (void *)fp, _ARGC_ARGV_HELPER(a))
#define fficallcustombp(a...) \
  _EVAL_MATCH_ARGS(_fficallcustombp, MAP_LIST(_CASTI64, a))

// look at abi.s
extern i64 (fficall)(void *fp, i64 argc, i64 *argv);
extern i64 (fficallnullbp)(void *fp, i64 argc, i64 *argv);
extern i64 (fficallcustombp)(void *rbp, void *fp, i64 argc, i64 *argv);

#else
.macro .endfn  name:req bnd vis
#ifndef _WIN32
  .size "\name",.-"\name"
  .type "\name",@function
#endif
  .ifnb \bnd
    .\bnd "\name"
  .endif
  .ifnb \vis
    .\vis "\name"
  .endif
  .align 16,0xcc
.endm
.macro .text.hot
  .section .text.hot,"ax",@progbits
.endm
#endif // __ASSEMBLER__
