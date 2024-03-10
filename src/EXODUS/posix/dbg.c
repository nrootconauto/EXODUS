/*-*- vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8                        :vi -*-│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2024 1fishe2fishe                                                  │
│                                                                              │
│ See end of file for extended copyright information and citations.            │
╚─────────────────────────────────────────────────────────────────────────────*/
#include <ucontext.h>

#include <inttypes.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <map/map.h>

#include <EXODUS/backtrace.h>
#include <EXODUS/dbg.h>
#include <EXODUS/misc.h>
#include <EXODUS/tos_aot.h>
#include <EXODUS/tos_callconv.h>
#include <EXODUS/types.h>

static void routine(int sig, argign siginfo_t *siginfo, void *_ctx) {
  /* Block signals temporarily.
   * Will be unblocked later by DebuggerLand */
  sigset_t all;
  sigfillset(&all);
  sigprocmask(SIG_BLOCK, &all, NULL);
  ucontext_t *ctx = _ctx;
#ifdef __linux__
  #define REG(x) (u64) ctx->uc_mcontext.gregs[REG_##x]
  /* glibc: sysdeps/unix/sysv/linux/x86/sys/ucontext.h
   * musl:  arch/x86_64/bits/signal.h */
  u64 regs[] = {
      REG(RAX), REG(RCX), REG(RDX),
      REG(RBX), REG(RSP), REG(RBP),
      REG(RSI), REG(RDI), REG(R8),
      REG(R9),  REG(R10), REG(R11),
      REG(R12), REG(R13), REG(R14),
      REG(R15), REG(RIP), (u64)ctx->uc_mcontext.fpregs,
      REG(EFL),
  };
#elif defined(__FreeBSD__)
  #define REG(X) (u64) ctx->uc_mcontext.mc_##X
  u64 regs[] = {
      REG(rax),    REG(rcx), REG(rdx),
      REG(rbx),    REG(rsp), REG(rbp),
      REG(rsi),    REG(rdi), REG(r8),
      REG(r9),     REG(r10), REG(r11),
      REG(r12),    REG(r13), REG(r14),
      REG(r15),    REG(rip), (u64)ctx->uc_mcontext.mc_fpstate,
      REG(rflags),
  };
#endif
  BackTrace(regs[5] /*RBP*/, regs[15] /*RIP*/);
  static CSymbol *sym;
  if (!sym)
    sym = map_get(&symtab, "DebuggerLand");
  FFI_CALL_TOS_2(sym->val, sig, (u64)regs);
}

void SetupDebugger(void) {
  struct sigaction sa = {
      .sa_sigaction = routine,
      .sa_flags = SA_SIGINFO | SA_NODEFER,
      /* NODEFER because we want to catch signals in the debugger too */
  };
  sigemptyset(&sa.sa_mask);
  int const sigs[] = {SIGTRAP, SIGBUS, SIGSEGV, SIGPIPE, SIGILL};
  for (u64 i = 0; i < Arrlen(sigs); i++)
    sigaction(sigs[i], &sa, NULL);
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
