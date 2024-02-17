/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <stdio.h>
#include <string.h>

#define NARGS 9

#ifdef _WIN32
static char *savedregs[] = {"rbx", "rdi", "rsi", "r12", "r13", "r14", "r15"};
static char *argregs[] = {"rcx", "rdx", "r8", "r9"};
  /* STK ARGS START FROM RBP+0x30 [1]
   * first stack arg: +0x30
   * r9 home  +0x28
   * r8 home  +0x20
   * rdx home +0x18
   * rcx home +0x10
   * ret addr +0x8
   *          rbp
   */
  #define STARTSTKARG 0x30
#else
static char *savedregs[] = {"rbx", "r12", "r13", "r14", "r15"};
static char *argregs[] = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"};
// STARTS STK ARGS FROM RBP+0x10
  #define STARTSTKARG 0x10
#endif
enum {
  SavedRegs = sizeof savedregs / sizeof savedregs[0],
  ArgRegs = sizeof argregs / sizeof argregs[0],
};

static void preludeasm(FILE *fp) {
  fputs(".intel_syntax noprefix\n", fp);
  for (int i = 0; i < NARGS; ++i)
    fprintf(fp, ".global FFI_CALL_TOS_%d\n", i);
  fprintf(fp, ".global FFI_CALL_TOS_0_ZERO_BP\n");
  fprintf(fp, ".text\n");
}
static void ncallasm(FILE *fp, int nargs) {
  fprintf(fp, "FFI_CALL_TOS_%d:\n", nargs);
  fputs("push rbp\nmov rbp,rsp\n", fp);
  for (int i = 0; i < SavedRegs; ++i)
    fprintf(fp, "push %s\n", savedregs[i]);
  int i = nargs;
  for (int j = STARTSTKARG + 8 * (nargs - ArgRegs); i > ArgRegs - 1;
       --i, j -= 8)
    fprintf(fp, "push QWORD PTR [rbp+%#x]\n", j);
  for (; i > 0; --i)
    fprintf(fp, "push %s\n", argregs[i]);
  fprintf(fp, "call %s\n", argregs[0]);
  // STDCALL doesnt need argpop
  for (int i = SavedRegs - 1; i >= 0; --i)
    fprintf(fp, "pop %s\n", savedregs[i]);
  fputs("pop rbp\nret\n", fp);
}

static void ncall(FILE *fp, int nargs) {
  fprintf(fp, "uint64_t FFI_CALL_TOS_%d(void *p", nargs);
  for (int i = 0; i < nargs; ++i)
    fprintf(fp, ",uint64_t arg%d", i);
  fprintf(fp, ");\n");
}

static void zerobp(FILE *fp) {
  fputs("uint64_t FFI_CALL_TOS_0_ZERO_BP(void *p);\n", fp);
}

static void zerobpasm(FILE *fp) {
  fputs("FFI_CALL_TOS_0_ZERO_BP:\n", fp);
  fputs("push rbp\n", fp);
  for (int i = 0; i < SavedRegs; ++i)
    fprintf(fp, "push %s\n", savedregs[i]);
  fputs("push 0x0\n", fp); // fake return addr (consult backtrace.c)
  fputs("push 0x0\n", fp); // fake rbp
  fputs("mov rbp,rsp\n", fp);
  fprintf(fp, "call %s\n", argregs[0]);
  fputs("add rsp,0x10\n", fp); // cleanup stk
  for (int i = SavedRegs - 1; i >= 0; --i)
    fprintf(fp, "pop %s\n", savedregs[i]);
  fputs("pop rbp\n", fp);
  fputs("ret\n", fp);
}

int main(int argc, char **argv) {
  char path[0x400], header[0x400], asmout[0x400];
  if (argc < 2)
    strcpy(path, "./");
  else
    strcpy(path, argv[1]);
  strcpy(header, path);
  strcat(header, "/tos_callconv.h");
  strcpy(asmout, path);
  strcat(asmout, "/callconv.s");
  FILE *fp = fopen(header, "wb");
  fputs("#pragma once\n#include <stdint.h>\n", fp);
  for (int i = 0; i < NARGS; ++i)
    ncall(fp, i);
  zerobp(fp);
  fclose(fp);
  fp = fopen(asmout, "wb");
  preludeasm(fp);
  for (int i = 0; i < NARGS; ++i)
    ncallasm(fp, i);
  zerobpasm(fp);
  fputs(".section .note.GNU-stack,\"\",@progbits\n", fp);
  fclose(fp);
}

/* CITATIONS:
 * [1]
 * https://learn.microsoft.com/en-us/cpp/build/stack-usage?view=msvc-170#stack-allocation
 *     (https://archive.md/4HDA0#selection-2085.429-2085.1196)
 */
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
