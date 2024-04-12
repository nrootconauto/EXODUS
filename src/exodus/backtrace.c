/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ exodus: executable divine operating system in userspace                      │
│                                                                              │
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for citations.                                               │
│                                                                              │
│ This software is provided 'as-is', without any express or implied            │
│ warranty. In no event will the authors be held liable for any damages        │
│ arising from the use of this software.                                       │
│                                                                              │
│ Permission is granted to anyone to use this software for any purpose,        │
│ including commercial applications, and to alter it and redistribute it       │
│ freely, subject to the following restrictions:                               │
│                                                                              │
│ 1. The origin of this software must not be misrepresented; you must not      │
│    claim that you wrote the original software. If you use this software      │
│    in a product, an acknowledgment in the product documentation would be     │
│    appreciated but is not required.                                          │
│ 2. Altered source versions must be plainly marked as such, and must not be   │
│    misrepresented as being the original software.                            │
│ 3. This notice may not be removed or altered from any source distribution.   │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <vec/vec.h>

#include <exodus/backtrace.h>
#include <exodus/loader.h>
#include <exodus/misc.h>

static vec_str_t sortedsyms;
static char unknown[] = "UNKNOWN";

static int compar(void const *_a, void const *_b) {
  char *const *a = _a, *const *b = _b;
  CSymbol *as = map_get(&symtab, *a);
  CSymbol *bs = map_get(&symtab, *b);
  /* this is ok because vals are in signed int bit range */
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
        flushprint(stderr, "%s [%p+%#jx] (%p)\n", last, ptr, ptr - oldp, curp);
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
__attribute__((used, visibility("default"))) char const *WhichFun(u8 *ptr) {
  sortsyms();
  char const *last = unknown, *s;
  int iter;
  CSymbol *sym;
  vec_foreach(&sortedsyms, s, iter) {
    sym = map_get(&symtab, s);
    if (sym->val >= ptr)
      return s;
    last = s;
  }
  return last;
}
