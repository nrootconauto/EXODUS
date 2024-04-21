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
/* generates routines allowing calling HolyC routines from C
 * you wouldn't want to touch this file without a ten foot pole
 *
 * macros are att syntax */
/* clang-format off */
/* don't make clang-format mess up the format specifiers */
#include <stdio.h>
#include <string.h>

#define NARGS 10

#ifdef _WIN32
  #include <direct.h>
static char *savedregs[] = {"rbx"}, *argregs[] = {"rcx", "rdx", "r8", "r9"};
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
  #define mkdir(a, b) _mkdir(a)
#else
  #include <sys/stat.h>
static char *savedregs[] = {"rbx"},
            *argregs[] = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"};
// STARTS STK ARGS FROM RBP+0x10
  #define STARTSTKARG 0x10
#endif

#define Arrlen(a) (sizeof a / sizeof a[0])
#define Min(a, b)          \
  ({                       \
    __auto_type __a = (a); \
    __auto_type __b = (b); \
    __a > __b ? __b : __a; \
  })

enum {
  SavedRegCnt = Arrlen(savedregs),
  ArgRegCnt = Arrlen(argregs),
};

#define PushReg(reg)        "\tpush\t%%" #reg "\n"
#define PushImm(imm)        "\tpush\t$" #imm "\n"
#define MovRegReg(src, dst) "\tmov\t%%" #src ",%%" #dst "\n"
#define PushMem(off, base)  "\tpush\t" #off "(%%" #base ")\n"
#define CallReg(reg)        "\tcall\t*%%" #reg "\n"
#define PopReg(reg)         "\tpop\t%%" #reg "\n"
#define AddImm(reg, imm)    "\tadd\t$" #imm ",%%" #reg "\n"
#define Ret                 "\tret\n"
#define Prolog              PushReg(rbp) MovRegReg(rsp, rbp)
#define Epilog              PopReg(rbp) Ret

#define NCall    "FFI_CALL_TOS_%d"
#define ZeroBp   "FFI_CALL_TOS_0_ZERO_BP"
#define CustomBp "FFI_CALL_TOS_1_CUSTOM_BP"

static void preludeasm(FILE *fp) {
  for (int i = 0; i < NARGS; ++i)
    fprintf(fp, ".global " NCall "_\n", i);
  fprintf(fp, ".global %s_\n", ZeroBp);
  fprintf(fp, ".global %s_\n", CustomBp);
  fprintf(fp, ".text\n");
}

static void saveregs(FILE *fp) {
  for (int i = 0; i < SavedRegCnt; ++i)
    fprintf(fp, PushReg(%s), savedregs[i]);
}

static void pushstkargs(FILE *fp, int nargs) {
  /* the -1's here are for the first arg (fun ptr) */
  int remain = nargs - (ArgRegCnt - 1);
  /* num of args is too small to use stack args */
  if (remain <= 0)
    return;
  /* we've exhausted the register argument space, so now push stack args
   * start from the top since it's the stack
   * each elem is 8 bytes */
  int addr = STARTSTKARG / 8 + remain - 1;
  for (int i = nargs; i > ArgRegCnt - 1; i--, addr--)
    fprintf(fp, PushMem(%#x, rbp), addr * 8);
}

static void pushregargs(FILE *fp, int nargs) {
  int cnt = Min(nargs, ArgRegCnt - 1);
  for (int i = cnt; i >= 1 /* 0 is the fun ptr */; i--)
    fprintf(fp, PushReg(%s), argregs[i]);
}

static void popsavedregs(FILE *fp) {
  /* STDCALL is argpop (it pops its stack args), so no "add $num,%rsp" needed */
  for (int i = SavedRegCnt - 1; i >= 0; --i)
    fprintf(fp, PopReg(%s), savedregs[i]);
}

static void callfun(FILE *fp) {
  fprintf(fp, CallReg(%s), argregs[0]);
}

static void ncallasm(FILE *fp, int nargs) {
  fprintf(fp, NCall "_:\n", nargs);
  fprintf(fp, Prolog);
  saveregs(fp);
  pushstkargs(fp, nargs);
  pushregargs(fp, nargs);
  callfun(fp);
  popsavedregs(fp);
  fprintf(fp, Epilog);
}

static void zerobpasm(FILE *fp) {
  fputs(ZeroBp "_:\n", fp);
  fprintf(fp, PushReg(rbp));
  saveregs(fp);
  fprintf(fp, PushImm(0x0)); // fake return addr (consult backtrace.c)
  fprintf(fp, PushImm(0x0)); // fake rbp
  fprintf(fp, MovRegReg(rsp, rbp));
  callfun(fp);
  fprintf(fp, AddImm(rsp, 0x10)); // cleanup stk
  popsavedregs(fp);
  fprintf(fp, Epilog);
}

/* consult MPSetProfilerInt (fake RBP) */
static void custombpasm(FILE *fp) {
  fputs(CustomBp "_:\n", fp);
  fprintf(fp, PushReg(rbp));
  saveregs(fp);
  fprintf(fp, MovRegReg(%s, rbp), argregs[1]);
  fprintf(fp, PushReg(%s), argregs[2]);
  callfun(fp);
  popsavedregs(fp);
  fprintf(fp, Epilog);
}

static void castarg1(FILE *fp, char c) {
  fprintf(fp, "(void *)(%c)", c);
}

static void castargn(FILE *fp, int nargs, char c) {
  for (int i = 1; i < nargs; i++)
    fprintf(fp, ", (uint64_t)(%c)", c++);
}

static void defun(FILE *fp, char const *name, int nargs) {
  fprintf(fp, "uint64_t %s_(void *p", name);
  for (int i = 1; i < nargs; i++)
    fprintf(fp, ", uint64_t arg%d", i);
  fprintf(fp, ");\n");
}

static void defmacro(FILE *fp, char const *name, int nargs) {
  char c = 'a';
  fprintf(fp, "#define %s(%c", name, c++);
  for (int i = 1; i < nargs; i++)
    fprintf(fp, ", %c", c++);
  fprintf(fp, ")\t%s_(", name);
  c = 'a';
  castarg1(fp, c++);
  castargn(fp, nargs, c);
  fprintf(fp, ")\n");
}

static void ncall(FILE *fp, int nargs) {
  /* defines a fun prototype and creates a macro
   * that casts args and calls into it */
  char buf[0x100];
  snprintf(buf, sizeof buf, NCall, nargs);
  /* +1 for the first arg (fun ptr) */
  defun(fp, buf, nargs + 1);
  defmacro(fp, buf, nargs + 1);
}

static void zerobp(FILE *fp) {
  defun(fp, ZeroBp, 1);
  defmacro(fp, ZeroBp, 1);
}

static void custombp(FILE *fp) {
  /* call with
   *   arg0: fun to call
   *   arg1: fake rbp
   *   arg2: arg to fun at arg0 */
  defun(fp, CustomBp, 3);
  defmacro(fp, CustomBp, 3);
}

int main(int argc, char **argv) {
  char path[0x400], header[0x400], asmout[0x400];
  if (argc < 3)
    strcpy(path, ".");
  else {
    strcpy(path, argv[1]);
    strcat(path, "/");
    strcat(path, argv[2]);
    mkdir(argv[2], 0755);
  }
  strcpy(header, path);
  strcat(header, "/callconv.h");
  strcpy(asmout, path);
  strcat(asmout, "/callconv.s");
  FILE *fp = fopen(header, "wb");
  fputs("#pragma once\n#include <stdint.h>\n", fp);
  for (int i = 0; i < NARGS; ++i)
    ncall(fp, i);
  zerobp(fp);
  custombp(fp);
  fclose(fp);
  fp = fopen(asmout, "wb");
  preludeasm(fp);
  for (int i = 0; i < NARGS; ++i)
    ncallasm(fp, i);
  zerobpasm(fp);
  custombpasm(fp);
#ifndef _WIN32
  fputs(".section .note.GNU-stack,\"\",@progbits\n", fp);
#endif
  fclose(fp);
}

/* CITATIONS:
 * [1]
 * https://learn.microsoft.com/en-us/cpp/build/stack-usage?view=msvc-170#stack-allocation
 *     (https://archive.md/4HDA0#selection-2085.429-2085.1196)
 */
