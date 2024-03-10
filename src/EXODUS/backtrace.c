/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <vec/vec.h>

#include <EXODUS/backtrace.h>
#include <EXODUS/misc.h>
#include <EXODUS/tos_aot.h>

static vec_str_t sortedsyms;
static char unknown[] = "UNKNOWN";

static int compar(void const *_a, void const *_b) {
  char *const *a = _a, *const *b = _b;
  CSymbol *as = map_get(&symtab, *a);
  CSymbol *bs = map_get(&symtab, *b);
  return (i64)as->val - (i64)bs->val;
}

static void sortsyms(void) {
  static bool init = false;
  if (init)
    return;
  // vec_reserve(&sortedsyms, symtab's length);
  /* needs to walk the whole map to get len.
   * most likely negligible speed tradeof, probably the reason why rxi didn't
   * add it. */
  map_iter_t it = map_iter(&symtab);
  char *k;
  while ((k = map_next(&symtab, &it)))
    vec_push(&sortedsyms, k);
  qsort(sortedsyms.data, sortedsyms.length, sizeof(char *), compar);
  init = true;
}

void BackTrace(u64 _rbp, u64 _rip) {
  sortsyms();
  fputc('\n', stderr);
  u8 *rbp = (u8 *)_rbp, *ptr = (u8 *)_rip, *oldp, *curp, **tmp;
  char const *last = unknown, *s;
  int iter;
  CSymbol *sym;
  while (rbp) {
    oldp = NULL;
    last = unknown;
    // iterates over symbols in order to find out where we are
    vec_foreach(&sortedsyms, s, iter) {
      sym = map_get(&symtab, s);
      curp = sym->val;
      if (curp >= ptr) {
        /* Note: if the numbers are wildly off the norm then it's probably:
         * 1) stack corruption
         * 2) some jit'd user cmd line code */
        /* function name [function addr+offset from rip] (%rip) */
        flushprint(stderr, "%s [%p+%#" PRIx64 "] (%p)\n", last, ptr, ptr - oldp,
                   curp);
        goto next;
      }
      oldp = curp;
      last = s;
    }
  next:
    tmp = (u8 **)rbp;
    ptr = tmp[1], rbp = tmp[0];
    /* x86_64 stk
     * [RBP+16 and higher] args (before call)
     * [RBP+8] return addr (set on call)
     * [RBP]   prev. RBP (set on callee's mov rbp,rsp)
     *
     * [RBP] might not be set if the function doesn't
     *       use the stack, but we don't account for that
     *       because the HolyC compiler always inserts that,
     *       and raw asm routines are too irregular to consider
     *
     * stack grows down (rsp -= n) */
  }
  fputc('\n', stderr);
}

/* (gdb) p (char*)WhichFun($pc) */
__attribute__((used, visibility("default"))) char *WhichFun(u8 *ptr) {
  sortsyms();
  char const *last = unknown, *s;
  int iter;
  CSymbol *sym;
  u64 len;
  vec_foreach(&sortedsyms, s, iter) {
    sym = map_get(&symtab, s);
    if (sym->val >= ptr) {
      len = strlen(s);
      return strcpy(malloc(len + 1), s);
    }
    last = s;
  }
  len = strlen(last);
  return strcpy(malloc(len + 1), last);
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
