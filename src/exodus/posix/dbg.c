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
#include <ucontext.h>

#include <inttypes.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <map/map.h>

#include <exodus/backtrace.h>
#include <exodus/callconv.h>
#include <exodus/dbg.h>
#include <exodus/loader.h>
#include <exodus/misc.h>
#include <exodus/types.h>

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
  FFI_CALL_TOS_2(sym->val, sig, regs);
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
