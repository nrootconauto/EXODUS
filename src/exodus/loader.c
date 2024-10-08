// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <map/map.h>
#include <vec/vec.h>

#include <exodus/alloc.h>
#include <exodus/loader.h>
#include <exodus/misc.h>
#include <exodus/shims.h>

map_sym_t symtab;

/* These routines are just copied from TempleOS and I haven't put much effort in
 * making them pretty */
static void LoadOneImport(u8 **_src, u8 *module_base);
static void SysSymImportsResolve(u8 *st_ptr);
static void LoadPass1(u8 *src, u8 *module_base);
static vec_void_t LoadPass2(u8 *src, u8 *module_base);

typedef struct __attribute__((packed, may_alias)) {
  u16 jmp;
  u8 module_align_bits, reserved;
  u8 bin_signature[4];
  i64 org, patch_table_offset, file_size;
  u8 data[];
} CBinFile;

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

static void LoadOneImport(u8 **_src, u8 *module_base) {
  u8 *src = *_src, *ptr = NULL;
  u64 i = 0;
  bool first = true;
  u8 etype;
  CSymbol *sym;
  while ((etype = *src++)) {
    ptr = module_base + *(u32 *)src;
    src += 4;
    u8 *st_ptr = src;
    src += strlen((char *)st_ptr) + 1;
    // first occurance of a string means
    // repeat this until another name is found
    if (!*st_ptr)
      goto iet;
    if (!first) {
      *_src = st_ptr - 5;
      return;
    } else {
      first = false;
      if ((sym = map_get(&symtab, (char *)st_ptr))) {
        if (sym->type != HTT_IMPORT_SYS_SYM)
          i = (u64)sym->val;
      } else {
        flushprint(stderr, "Unresolved reference %s\n", (char *)st_ptr);
        map_set(&symtab, (char *)st_ptr,
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

static void SysSymImportsResolve(u8 *st_ptr) {
  CSymbol *sym = map_get(&symtab, (char *)st_ptr);
  if (!sym)
    return;
  if (sym->type != HTT_IMPORT_SYS_SYM)
    return;
  LoadOneImport(&sym->module_header_entry, sym->module_base);
  sym->type = HTT_INVALID;
}

static void LoadPass1(u8 *src, u8 *module_base) {
  u8 *ptr, *st_ptr;
  u8 etype;
  while ((etype = *src++)) {
    u64 i = *(u32 *)src;
    src += 4;
    st_ptr = src;
    src += strlen((char *)st_ptr) + 1;
    switch (etype) {
    case IET_REL32_EXPORT ... IET_IMM64_EXPORT:
      if (etype != IET_IMM32_EXPORT && etype != IET_IMM64_EXPORT)
        i += (u64)module_base;
      map_set(&symtab, (char *)st_ptr,
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
        ptr = module_base + *(u32 *)src;
        *(u32 *)ptr = *(u32 *)ptr + (u64)module_base;
      }
      break;
    }
  }
}

static vec_void_t LoadPass2(u8 *src, u8 *module_base) {
  vec_void_t ret;
  vec_init(&ret);
  u8 etype;
  while ((etype = *src++)) {
    u32 i = *(u32 *)src;
    src += 4;
    src += strlen((char *)src) + 1;
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
