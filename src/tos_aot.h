/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#pragma once

#include "vendor/map.h"
#include "vendor/vec.h"

#include "types.h"

typedef struct {
  u32 type;
  union {
    u8 *val; // CHashExport
    struct {
      u8 *module_base, *module_header_entry; // CHashImport
    };
  };
} CSymbol;

typedef map_t(CSymbol) map_sym_t;
extern map_sym_t symtab;

vec_void_t LoadHCRT(char const *s);

/* clang-format off */

#define HTT_INVALID         0
#define HTT_EXPORT_SYS_SYM  0x00001 //CHashExport
#define HTT_IMPORT_SYS_SYM  0x00002 //CHashImport
#define HTT_DEFINE_STR      0x00004 //CHashDefineStr
#define HTT_GLBL_VAR        0x00008 //CHashGlblVar
#define HTT_CLASS           0x00010 //CHashClass
#define HTT_INTERNAL_TYPE   0x00020 //CHashClass
#define HTT_FUN             0x00040 //CHashFun
#define HTT_WORD            0x00080 //CHashAC only in AutoComplete table
#define HTT_DICT_WORD       0x00100 //CHashGeneric only in AutoComplete tbl
#define HTT_KEYWORD         0x00200 //CHashGeneric $$LK,"KEYWORD",A="FF:::/Compiler/OpCodes.DD,KEYWORD"$$
#define HTT_ASM_KEYWORD     0x00400 //CHashGeneric $$LK,"ASM_KEYWORD",A="FF:::/Compiler/OpCodes.DD,ASM_KEYWORD"$$
#define HTT_OPCODE          0x00800 //CHashOpcode
#define HTT_REG             0x01000 //CHashReg
#define HTT_FILE            0x02000 //CHashGeneric
#define HTT_MODULE          0x04000 //CHashGeneric
#define HTT_HELP_FILE       0x08000 //CHashSrcSym
#define HTT_FRAME_PTR       0x10000 //CHashGeneric
#define HTG_TYPE_MASK       0x1FFFF

#define IET_END               0
//reserved
#define IET_REL_I0            2 //Fictitious
#define IET_IMM_U0            3 //Fictitious
#define IET_REL_I8            4
#define IET_IMM_U8            5
#define IET_REL_I16           6
#define IET_IMM_U16           7
#define IET_REL_I32           8
#define IET_IMM_U32           9
#define IET_REL_I64           10
#define IET_IMM_I64           11
#define IEF_IMM_NOT_REL       1
//reserved
#define IET_REL32_EXPORT      16
#define IET_IMM32_EXPORT      17
#define IET_REL64_EXPORT      18 //Not implemented
#define IET_IMM64_EXPORT      19 //Not implemented
#define IET_ABS_ADDR          20
#define IET_CODE_HEAP         21 //Not really used
#define IET_ZEROED_CODE_HEAP  22 //Not really used
#define IET_DATA_HEAP         23
#define IET_ZEROED_DATA_HEAP  24 //Not really used
#define IET_MAIN              25

/* clang-format on */
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
