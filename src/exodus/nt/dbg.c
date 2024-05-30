// mode:c;indent-tabs-mode:nil;c-basic-offset:2;tab-width:8;coding:utf-8
// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#define _WIN32_WINNT 0x501 /* [2] */
#include <windows.h>
#include <winnt.h>
#include <errhandlingapi.h>

#include <exodus/backtrace.h>
#include <exodus/abi.h>
#include <exodus/dbg.h>
#include <exodus/ffi.h>
#include <exodus/loader.h>
#include <exodus/types.h>

static LONG WINAPI VEHandler(EXCEPTION_POINTERS *info) {
  u64 sig;
#define E(code) EXCEPTION_##code
  switch (info->ExceptionRecord->ExceptionCode) {
  case E(ACCESS_VIOLATION):
  case E(ARRAY_BOUNDS_EXCEEDED):
  case E(DATATYPE_MISALIGNMENT):
  case E(FLT_DENORMAL_OPERAND):
  case E(FLT_INEXACT_RESULT):
  case E(FLT_INVALID_OPERATION):
  case E(FLT_OVERFLOW):
  case E(FLT_STACK_CHECK):
  case E(FLT_UNDERFLOW):
  case E(ILLEGAL_INSTRUCTION):
  case E(IN_PAGE_ERROR):
  case E(INVALID_DISPOSITION):
  case E(STACK_OVERFLOW):
    sig = 0;
    break;
  case E(BREAKPOINT):
  case STATUS_SINGLE_STEP: /*[1]*/
    sig = 5 /*SIGTRAP*/;
    break;
  case E(FLT_DIVIDE_BY_ZERO):
  case E(INT_DIVIDE_BY_ZERO):
    return E(CONTINUE_SEARCH);
  default:
    return E(CONTINUE_EXECUTION);
  }
#define REG(x) (u64) info->ContextRecord->x
  u64 regs[] = {
      REG(Rax),    REG(Rcx), REG(Rdx),
      REG(Rbx),    REG(Rsp), REG(Rbp),
      REG(Rsi),    REG(Rdi), REG(R8),
      REG(R9),     REG(R10), REG(R11),
      REG(R12),    REG(R13), REG(R14),
      REG(R15),    REG(Rip), (u64)&info->ContextRecord->FltSave,
      REG(EFlags),
  };
  BackTrace(REG(Rbp), REG(Rip));
  static CSymbol *sym;
  if (!sym)
    sym = map_get(&symtab, "DebuggerLandWin");
  fficall(sym->val, sig, regs);
  return E(CONTINUE_EXECUTION);
}

static LONG WINAPI Div0Handler(EXCEPTION_POINTERS *info) {
  switch (info->ExceptionRecord->ExceptionCode) {
  case E(FLT_DIVIDE_BY_ZERO):
  case E(INT_DIVIDE_BY_ZERO):
    HolyThrow("DivZero");
  default:
    return E(CONTINUE_EXECUTION);
  }
}

void SetupDebugger(void) {
  /* Quoth MSDN[2]:
   * If the First parameter is nonzero, the handler is the first handler to be
   * called until a subsequent call to AddVectoredExceptionHandler is used to
   * specify a different handler as the first handler.*/
  /* Thus we register VEHandler last to make it execute first. */
  AddVectoredExceptionHandler(1, Div0Handler);
  AddVectoredExceptionHandler(1, VEHandler);
}

/* CITATIONS:
 * [1] https://stackoverflow.com/a/16426963 (https://archive.md/sZzVj)
 * [2]
 * https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-addvectoredexceptionhandler
 *     (https://archive.is/oCszM)
 */
