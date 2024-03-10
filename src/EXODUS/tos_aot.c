/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <map/map.h>
#include <vec/vec.h>

#include <EXODUS/alloc.h>
#include <EXODUS/misc.h>
#include <EXODUS/shims.h>
#include <EXODUS/tos_aot.h>

#define ReadNum(x, T)                          \
  ({                                           \
    T __val;                                   \
    __builtin_memcpy(&__val, x, sizeof __val); \
    __val;                                     \
  })

map_sym_t symtab;

void LoadOneImport(u8 **_src, u8 *module_base) {
  u8 *src = *_src, *ptr = NULL;
  u64 i = 0;
  bool first = true;
  u8 etype;
  CSymbol *sym;
  while ((etype = *src++)) {
    ptr = module_base + ReadNum(src, u32);
    src += 4;
    u8 *st_ptr = src;
    src += strlen(st_ptr) + 1;
    // first occurance of a string means
    // repeat this until another name is found
    if (!*st_ptr)
      goto iet;
    if (!first) {
      *_src = st_ptr - 5;
      return;
    } else {
      first = false;
      if ((sym = map_get(&symtab, st_ptr))) {
        if (sym->type != HTT_IMPORT_SYS_SYM)
          i = (u64)sym->val;
      } else {
        flushprint(stderr, "Unresolved reference %s\n", st_ptr);
        map_set(&symtab, st_ptr,
                (CSymbol){
                    .type = HTT_IMPORT_SYS_SYM,
                    .module_base = module_base,
                    .module_header_entry = st_ptr - 5,
                });
      }
    }
#define REL(T)                           \
  {                                      \
    u64 off = (u8 *)i - ptr - sizeof(T); \
    memcpy(ptr, &off, sizeof(T));        \
  }
#define IMM(T) \
  { memcpy(ptr, &i, sizeof(T)); }
  iet:
    switch (etype) {
    case IET_REL_I8:
      REL(i8);
      break;
    case IET_REL_I16:
      REL(i16);
      break;
    case IET_REL_I32:
      REL(i32);
      break;
    case IET_REL_I64:
      REL(i64);
      break;
    case IET_IMM_U8:
      IMM(u8);
      break;
    case IET_IMM_U16:
      IMM(u16);
      break;
    case IET_IMM_U32:
      IMM(u32);
      break;
    case IET_IMM_I64:
      IMM(i64);
      break;
    }
  }
  *_src = src - 1;
}

void SysSymImportsResolve(u8 *st_ptr) {
  CSymbol *sym = map_get(&symtab, st_ptr);
  if (!sym)
    return;
  if (sym->type != HTT_IMPORT_SYS_SYM)
    return;
  LoadOneImport(&sym->module_header_entry, sym->module_base);
  sym->type = HTT_INVALID;
}

void LoadPass1(u8 *src, u8 *module_base) {
  u8 *ptr, *st_ptr;
  u8 etype;
  while ((etype = *src++)) {
    u64 i = ReadNum(src, u32);
    src += 4;
    st_ptr = src;
    src += strlen(st_ptr) + 1;
    switch (etype) {
    case IET_REL32_EXPORT ... IET_IMM64_EXPORT:
      if (etype != IET_IMM32_EXPORT && etype != IET_IMM64_EXPORT)
        i += (u64)module_base;
      map_set(&symtab, st_ptr,
              (CSymbol){
                  .type = HTT_EXPORT_SYS_SYM,
                  .val = (void *)i,
              });
      SysSymImportsResolve(st_ptr);
      break;
    case IET_REL_I0 ... IET_IMM_I64:
      src = st_ptr - 5;
      LoadOneImport(&src, module_base);
      break;
    case IET_ABS_ADDR:
      for (u64 j = 0; j < i; j++, src += sizeof(u32)) {
        ptr = module_base + ReadNum(src, u32);
        __builtin_memcpy(ptr, &(u32){ReadNum(ptr, u32) + (u64)module_base}, 4);
      }
      break;
    }
  }
}

vec_void_t LoadPass2(u8 *src, u8 *module_base) {
  vec_void_t ret;
  vec_init(&ret);
  u8 etype;
  while ((etype = *src++)) {
    u32 i = ReadNum(src, u32);
    src += 4;
    src += strlen(src) + 1;
    switch (etype) {
    case IET_MAIN: {
      vec_push(&ret, module_base + i);
    } break;
    case IET_ABS_ADDR: {
      src += 4 * i;
    } break;
    case IET_CODE_HEAP:
    case IET_ZEROED_CODE_HEAP: {
      src += 4 + 4 * i;
    } break;
    case IET_DATA_HEAP:
    case IET_ZEROED_DATA_HEAP: {
      src += 8 + 4 * i;
    } break;
    }
  }
  return ret;
}

typedef struct {
  u16 jmp;
  u8 module_align_bits, reserved;
  u8 bin_signature[4];
  i64 org, patch_table_offset, file_size;
  u8 data[];
} __attribute__((packed, may_alias)) CBinFile;

vec_void_t LoadHCRT(char const *name) {
  i64 sz;
  if (-1 == (sz = fsize(name))) {
    flushprint(stderr, "Can't find file / filesystem error\n");
    terminate(1);
  }
  int fd = openfd(name, false);
  if (fd == -1) {
    flushprint(stderr, "Can't open \"%s\"\n", name);
    terminate(1);
  }
  void *bfh_addr;
  readfd(fd, bfh_addr = NewVirtualChunk(sz, true), sz);
  closefd(fd);
  CBinFile *bfh = bfh_addr;
  if (memcmp(bfh->bin_signature, "TOSB" /*BIN_SIGNATURE_VAL*/, 4)) {
    flushprint(stderr, "invalid file '%s'\n", name);
    terminate(1);
  }
  u8 *patchtable = bfh_addr + bfh->patch_table_offset, *code = bfh->data;
  LoadPass1(patchtable, code);
  return LoadPass2(patchtable, code);
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
