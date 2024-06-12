// vi: set et ft=c ts=2 sts=2 sw=2 fenc=utf-8 :vi
//
// Copyright 2024 1fishe2fishe
// Refer to the LICENSE file for license info.
// Any citation links are provided at the end of the file.
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <dyad/dyad.h>
#include <isocline.h>

#include <exodus/abi.h>
#include <exodus/alloc.h>
#include <exodus/loader.h>
#include <exodus/main.h>
#include <exodus/misc.h>
#include <exodus/seth.h>
#include <exodus/shims.h>
#include <exodus/sound.h>
#include <exodus/tosprint.h>
#include <exodus/types.h>
#include <exodus/vfs.h>
#include <exodus/window.h>
#include <exodus/x86.h>

/* HolyC -> C FFI */
void HolyFree(void *ptr) {
  static CSymbol *sym;
  if (!sym)
    sym = map_get(&symtab, "_FREE");
  fficall(sym->val, ptr);
}

void *HolyMAlloc(u64 sz) {
  static CSymbol *sym;
  if (!sym)
    sym = map_get(&symtab, "_MALLOC");
  return (void *)fficall(sym->val, sz, NULL);
}

void *HolyCAlloc(u64 sz) {
  return memset(HolyMAlloc(sz), 0, sz);
}

char *HolyStrDup(char const *str) {
  return memdup(HolyMAlloc, str, strlen(str) + 1);
}

noret void HolyThrow(char const *s) {
  static CSymbol *sym;
  u64 i = 0;
  __builtin_memcpy(&i, s, Min(strlen(s), 8ul));
  if (!sym)
    sym = map_get(&symtab, "throw");
  fficall(sym->val, i);
  Unreachable();
}

typedef struct {
  char const *name;
  void *fp;
  u16 arity;
} HolyFFI;

static i64 genthunk(u8 *to, HolyFFI *cur) {
  i64 off = 0;
  Addcode(to, off, x86pushreg, RBP);
  Addcode(to, off, x86movregreg, RBP, RSP);
  /* SysV and NT require stack alignment */
  Addcode(to, off, x86andimm, RSP, ~0xF);
  /* System V saved registers (a) := {rbx, r12 ~ r15}
   * Win64 saved registers    (a) := {rbx, rdi, rsi, r12 ~ r15}
   * TempleOS saved registers (b) := {rdi, rsi, r10 ~ r15}
   * regs to save := b - a
   */
  Addcode(to, off, x86pushreg, R10);
  Addcode(to, off, x86pushreg, R11);
  if (iswindows()) {
    // register home space[1](something like red zone?)
    // volatile so just sub
    Addcode(to, off, x86subimm, RSP, 0x20);
  } else {
    Addcode(to, off, x86pushreg, RSI);
    Addcode(to, off, x86pushreg, RDI);
  }
  Addcode(to, off, x86lea, iswindows() ? RCX : RDI, -1, -1, RBP, SF_ARG1);
  Addcode(to, off, x86movimm, RAX, (i64)cur->fp);
  Addcode(to, off, x86callreg, RAX);
  if (iswindows()) {
    // restore stack
    Addcode(to, off, x86addimm, RSP, 0x20);
  } else {
    Addcode(to, off, x86popreg, RDI);
    Addcode(to, off, x86popreg, RSI);
  }
  Addcode(to, off, x86popreg, R11);
  Addcode(to, off, x86popreg, R10);
  // restore RSP, we cut down at the top
  // so just popping rbp will mess up the stack
  Addcode(to, off, x86leave, 0);
  Addcode(to, off, x86ret, cur->arity * 8);
  // x86 processors like aligned instructions
  off = ALIGNNUM(off, 16);
  return off;
}

static void genthunks(HolyFFI *list, i64 cnt) {
  i64 sz = genthunk(NULL, &(HolyFFI){
                              .fp = (void *)INT64_MAX,
                              .arity = INT16_MAX,
                          });
  u8 *blob = NewVirtualChunk(sz * cnt, true), *prev;
  if (veryunlikely(!blob)) {
    flushprint(stderr, "Can't allocate space for FFI function pointers\n");
    terminate(1);
  }
  for (HolyFFI *cur = list; cur != list + cnt; cur++) {
    blob += genthunk(prev = blob, cur);
    map_set(&symtab, cur->name, (CSymbol){.type = HTT_FUN, .val = prev});
  }
}

/* C -> HolyC FFI */
static void STK_DyadInit(argign void *args) {
  static bool init;
  if (init)
    return;
  init = true;
  dyad_init();
  dyad_setUpdateTimeout(0.);
}

static i64 STK_DyadListen(i64 *stk) {
  return dyad_listenEx((dyad_Stream *)stk[0], (char *)stk[2], stk[1], 511);
}

static i64 STK_DyadConnect(i64 *stk) {
  return dyad_connect((dyad_Stream *)stk[0], (char *)stk[1], stk[2]);
}

static void STK_DyadWrite(i64 *stk) {
  dyad_write((dyad_Stream *)stk[0], (void *)stk[1], (int)stk[2]);
}

static void STK_DyadEnd(dyad_Stream **stk) {
  dyad_end(stk[0]);
}

static void STK_DyadClose(dyad_Stream **stk) {
  dyad_close(stk[0]);
}

static char *STK_DyadGetAddress(dyad_Stream **stk) {
  return HolyStrDup(dyad_getAddress(stk[0]));
}

static i64 STK__DyadGetCallbackMode(char **stk) {
  char *s = stk[0];
#define C(a) else if (!strcmp(s, #a)) return a
  if (false)
    ;
  C(DYAD_EVENT_LINE);
  C(DYAD_EVENT_DATA);
  C(DYAD_EVENT_CLOSE);
  C(DYAD_EVENT_CONNECT);
  C(DYAD_EVENT_DESTROY);
  C(DYAD_EVENT_ERROR);
  C(DYAD_EVENT_READY);
  C(DYAD_EVENT_TICK);
  C(DYAD_EVENT_TIMEOUT);
  C(DYAD_EVENT_ACCEPT);
  HolyThrow("Invalid");
#undef C
}

static void readcallback(dyad_Event *e) {
  fficall(e->udata, e->stream, e->data, e->size, e->udata2);
}

static void closecallback(dyad_Event *e) {
  fficall(e->udata, e->stream, e->udata2);
}

static void listencallback(dyad_Event *e) {
  fficall(e->udata, e->remote, e->udata2);
}

static void STK_DyadSetReadCallback(void **stk) {
  dyad_addListener((dyad_Stream *)stk[0], (i64)stk[1], readcallback, stk[2],
                   stk[3]);
}

static void STK_DyadSetCloseCallback(void **stk) {
  dyad_addListener((dyad_Stream *)stk[0], (i64)stk[1], closecallback, stk[2],
                   stk[3]);
}

static void STK_DyadSetListenCallback(void **stk) {
  dyad_addListener((dyad_Stream *)stk[0], (i64)stk[1], listencallback, stk[2],
                   stk[3]);
}

// read callbacks -> DYAD_EVENT_{LINE,DATA}
// close callbacks -> DYAD_EVENT_{DESTROY,ERROR,CLOSE}
// listen callbacks -> DYAD_EVENT_{TIMEOUT,CONNECT,READY,TICK,ACCEPT}

static void STK_DyadSetTimeout(u64 *stk) {
  union {
    u64 i;
    f64 f;
  } u = {.i = stk[1]};
  dyad_setTimeout((dyad_Stream *)stk[0], u.f);
}

static void STK_DyadSetNoDelay(i64 *stk) {
  dyad_setNoDelay((dyad_Stream *)stk[0], stk[1]);
}

static void STK_UnblockSignals(argign void *args) {
  unblocksigs();
}

static void STK__GrPaletteColorSet(u64 *stk) {
  GrPaletteColorSet(stk[0], stk[1]);
}

static u64 STK___IsValidPtr(void **stk) {
  return isvalidptr(stk[0]);
}

static void STK_InterruptCore(u64 *stk) {
  InterruptCore(stk[0]);
}

static void STK___BootstrapForeachSymbol(void **stk) {
  map_iter_t it = map_iter(&symtab);
  char *k;
  CSymbol *v;
  while ((k = map_next(&symtab, &it))) {
    v = map_iter_val(&symtab, &it);
    fficall(stk[0], k, v->val,
            v->type == HTT_EXPORT_SYS_SYM ? HTT_FUN : v->type);
  }
}

/* HolyC ABI is stdcall (callee cleans up its own stack)
 * so we need RET1 to pop args(ret imm16)
 * variadics are cdecl
 * all args are 8 bytes
 * no returning structs (no secret parameters)
 * Calling a variadic function:
 *
 * U0 f() {
 *   U8 noreg *s="%d\n";
 *   MOV RBX,&s[RBP]
 *   PUSH 2
 *   PUSH 1 // num of varargs
 *   PUSH RBX
 *   CALL &Print // Print pops it for you
 * }
 * f;
 *
 * THUS WE NEED STK+2 TO GET THE VARARGS
 */
static void STK_TOSPrint(i64 *stk) {
  TOSPrint((char *)stk[0], /*stk[1]*/ 0, // WE DO NOT CHECK FOR ARG NUMS
           stk + 2);
}

static void STK_DrawWindowUpdate(u8 **stk) {
  DrawWindowUpdate(stk[0]);
}

static void STK_SetKBCallback(void **stk) {
  SetKBCallback(stk[0]);
}

static void STK_SetMSCallback(void **stk) {
  SetMSCallback(stk[0]);
}

static void STK___AwakeCore(u64 *stk) {
  WakeCoreUp(stk[0]);
}

// μs nap
static void STK___SleepHP(u64 *stk) {
  SleepUs(stk[0]);
}

static void STK___Sleep(u64 *stk) {
  SleepUs(stk[0] * 1000);
}

static void STK_SndFreq(u64 *stk) {
  SndFreq(stk[0]);
}

static void STK_SetClipboardText(char **stk) {
  SetClipboard(stk[0]);
}

static char *STK___GetStr(char **stk) {
  static char *boot_text;
  static bool init;
  if (!init) {
    boot_text = CmdLineBootText();
    init = true;
  }
  if (IsCmdLine() && boot_text) {
    char *orig = boot_text;
    boot_text = strchr(boot_text, '\n');
    if (boot_text)
      *boot_text++ = 0;
    return HolyStrDup(orig);
  }
  char cleanup(_dtor) *s = ic_readline(stk[0]);
  return HolyStrDup(s ?: "");
}

static u64 STK_FUnixTime(char **stk) {
  return VFsFUnixTime(stk[0]);
}

static u64 STK_UnixNow(argign void *stk) {
  return time(NULL);
}

static void STK___SpawnCore(void **stk) {
  vec_void_t vec;
  vec_init(&vec);
  vec_push(&vec, stk[0]);
  CreateCore(vec);
}

static void *STK_NewVirtualChunk(u64 *stk) {
  return NewVirtualChunk(stk[0], stk[1]);
}

static void STK_FreeVirtualChunk(u64 *stk) {
  FreeVirtualChunk((void *)stk[0], stk[1]);
}

static void STK_VFsSetPwd(char **stk) {
  VFsSetPwd(stk[0]);
}

static u64 STK_VFsFExists(char **stk) {
  return VFsFExists(stk[0]);
}

static u64 STK_VFsIsDir(char **stk) {
  return VFsIsDir(stk[0]);
}

static i64 STK_VFsFSize(char **stk) {
  return VFsFSize(stk[0]);
}

static void STK_VFsFTrunc(u64 *stk) {
  VFsFTrunc((char *)stk[0], stk[1]);
}

static u8 *STK_VFsFRead(u64 *stk) {
  return VFsFRead((char *)stk[0], (u64 *)stk[1]);
}

static u64 STK_VFsFWrite(char **stk) {
  return VFsFWrite(stk[0], (u8 const *)stk[1], (u64)stk[2]);
}

static u64 STK_VFsDirMk(char **stk) {
  return VFsDirMk(stk[0]);
}

static char **STK_VFsDir(argign void *stk) {
  return VFsDir();
}

static u64 STK_VFsDel(char **stk) {
  return VFsDel(stk[0]);
}

static i64 STK_VFsFOpenW(char **stk) {
  return VFsFOpen(stk[0], true /* rw */);
}

static i64 STK_VFsFOpenR(char **stk) {
  return VFsFOpen(stk[0], false /* readonly */);
}

static void STK_VFsFClose(int *stk) {
  closefd(stk[0]);
}

static u64 STK_VFsFBlkRead(i64 *stk) {
  i64 toread = stk[1] * stk[2];
  return toread == readfd(stk[3], (void *)stk[0], toread);
}

static u64 STK_VFsFBlkWrite(i64 *stk) {
  i64 towrite = stk[1] * stk[2];
  return towrite == writefd(stk[3], (void *)stk[0], towrite);
}

static u64 STK_VFsFSeek(i64 *stk) {
  return seekfd(stk[1], stk[0]);
}

static void STK_VFsSetDrv(u8 *stk) {
  VFsSetDrv(stk[0]);
}

static void STK_SetVolume(f64 *stk) {
  SetVolume(stk[0]);
}

static u64 STK_GetVolume(argign u64 *stk) {
  union {
    f64 f;
    u64 i;
  } u = {.f = GetVolume()};
  return u.i;
}

static i64 STK_HPET(argign u64 *stk) {
  return getticksus() * 14; // 14MHz
}

static void STK_Exit(int *stk) {
  terminate(stk[0]);
}

static u8 *STK_MemCpy(i64 *stk) {
  return memcpy((void *)stk[0], (void *)stk[1], stk[2]);
}

static u8 *STK_MemSet(i64 *stk) {
  return memset((void *)stk[0], stk[1] & 0xFF, stk[2]);
}

static i64 STK_MemCmp(i64 *stk) {
  return memcmp((void *)stk[0], (void *)stk[1], stk[2]);
}

static i64 *STK_MemSetI64(i64 *restrict stk) {
  i64 i, *to = (i64 *)stk[0];
  for (i = 0; i < stk[2]; i++)
    to[i] = stk[1];
  return to;
}

static u32 *STK_MemSetU32(i64 *restrict stk) {
  u32 *to = (u32 *)stk[0];
  for (i64 i = 0; i < stk[2]; i++)
    to[i] = stk[1] & 0xFFFFffffu;
  return to;
}

static u16 *STK_MemSetU16(i64 *restrict stk) {
  u16 *to = (u16 *)stk[0];
  for (i64 i = 0; i < stk[2]; i++)
    to[i] = stk[1] & 0xFFFFu;
  return to;
}

static i64 STK_StrCmp(char **stk) {
  return strcmp(stk[0], stk[1]);
}

static void STK_StrCpy(char **stk) {
  strcpy(stk[0], stk[1]);
}

static u64 STK_StrLen(char **stk) {
  return strlen(stk[0]);
}

#define MATHRT(nam, fun)           \
  static u64 STK_##nam(f64 *stk) { \
    union {                        \
      f64 f;                       \
      u64 i;                       \
    } u = {.f = fun(stk[0])};      \
    return u.i;                    \
  }

#define MATHRT2(nam, fun)             \
  static u64 STK_##nam(f64 *stk) {    \
    union {                           \
      f64 f;                          \
      u64 i;                          \
    } u = {.f = fun(stk[0], stk[1])}; \
    return u.i;                       \
  }

forceinline static f64 dbl(f64 f) {
  return f * f;
}

// pow10 removed in glibc 2.27
forceinline static f64 mypow10(f64 f) {
  return pow(f, 10);
}

MATHRT(Sqrt, sqrt);
MATHRT(Abs, fabs);
MATHRT(Cos, cos);
MATHRT(Sin, sin);
MATHRT(ATan, atan);
MATHRT(Sqr, dbl);
MATHRT(Tan, tan);
MATHRT(Ceil, ceil);
MATHRT(Ln, log);
MATHRT(Log10, log10);
MATHRT(Log2, log2);
MATHRT(Pow10, mypow10);
MATHRT(Round, round);
MATHRT(Trunc, trunc);
MATHRT(Floor, floor);
MATHRT(Exp, exp);
MATHRT2(Pow, pow);
MATHRT2(Arg, atan2);

static void STK_MPSetProfilerInt(i64 *stk) {
  MPSetProfilerInt((void *)stk[0], stk[1], stk[2]);
}

void BootstrapLoader(void) {
#define R(h, c, a) {.name = h, .fp = c, .arity = a}
#define S(h, a) \
  { .name = #h, .fp = STK_##h, .arity = a }
  HolyFFI ffis[] = {
      R("__CmdLineBootText", CmdLineBootText, 0),
      R("__CoreNum", CoreNum, 0),
      S(MPSetProfilerInt, 3),
      R("mp_cnt", mp_cnt, 0),
      R("MPIntsInit", InitIRQ0, 0),
      R("__IsCmdLine", IsCmdLine, 0),
      S(__IsValidPtr, 1),
      S(__SpawnCore, 1),
      S(UnixNow, 0),
      S(InterruptCore, 1),
      S(NewVirtualChunk, 2),
      S(FreeVirtualChunk, 2),
      R("Shutdown", STK_Exit, 1),
      S(__GetStr, 1),
      S(FUnixTime, 1),
      R("GetClipboardText", ClipboardText, 0),
      S(SetClipboardText, 1),
      S(SndFreq, 1),
      S(__Sleep, 1),
      S(__SleepHP, 1),
      S(__AwakeCore, 1),
      S(SetKBCallback, 1),
      S(SetMSCallback, 1),
      S(__BootstrapForeachSymbol, 1),
      S(DrawWindowUpdate, 1),
      R("DrawWindowNew", DrawWindowNew, 0),
      R("PCSpkInit", PCSpkInit, 0),
      S(UnblockSignals, 0),
      /*
       * in TempleOS variadics, functions follow __cdecl, whereas normal ones
       * follow __stdcall which is why the arity argument is needed(ret imm16)
       * thus we don't have to clean up the stack in variadics
       */
      S(TOSPrint, 0),
      //
      S(DyadInit, 0),
      R("DyadUpdate", dyad_update, 0),
      R("DyadShutdown", dyad_shutdown, 0),
      R("DyadNewStream", dyad_newStream, 0),
      S(DyadListen, 3),
      S(DyadConnect, 3),
      S(DyadWrite, 3),
      S(DyadEnd, 1),
      S(DyadClose, 1),
      S(DyadGetAddress, 1),
      S(_DyadGetCallbackMode, 1),
      S(DyadSetReadCallback, 4),
      S(DyadSetCloseCallback, 4),
      S(DyadSetListenCallback, 4),
      S(DyadSetTimeout, 2),
      S(DyadSetNoDelay, 2),
      S(MemCmp, 3),
      S(MemCpy, 3),
      S(MemSet, 3),
      S(MemSetI64, 3),
      S(MemSetU32, 3),
      S(MemSetU16, 3),
      R("MemSetU8", STK_MemSet, 3),
      S(StrCpy, 2),
      S(StrCmp, 2),
      S(StrLen, 1),
      S(Sqrt, 1),
      S(Sqr, 1),
      S(Sin, 1),
      S(Cos, 1),
      S(Abs, 1),
      S(ATan, 1),
      S(Tan, 1),
      S(Ceil, 1),
      S(Ln, 1),
      S(Log10, 1),
      S(Log2, 1),
      S(Arg, 2),
      S(Pow, 2),
      S(Pow10, 1),
      S(Round, 1),
      S(Trunc, 1),
      S(Exp, 1),
      S(Floor, 1),
      S(VFsFTrunc, 2),
      S(VFsSetPwd, 1),
      S(VFsFExists, 1),
      S(VFsIsDir, 1),
      S(VFsFSize, 1),
      S(VFsFRead, 2),
      S(VFsFWrite, 3),
      S(VFsDel, 1),
      S(VFsDir, 0),
      S(VFsDirMk, 1),
      S(VFsFBlkRead, 4),
      S(VFsFBlkWrite, 4),
      S(VFsFOpenW, 1),
      S(VFsFOpenR, 1),
      S(VFsFClose, 1),
      S(VFsFSeek, 2),
      S(VFsSetDrv, 1),
      S(HPET, 0),
      R("VFsGetDrv", VFsGetDrv, 0),
      S(SetVolume, 1),
      S(GetVolume, 0),
      S(_GrPaletteColorSet, 2),
  };
  genthunks(ffis, Arrlen(ffis));
}

/* CITATIONS:
 * [1]
 * https://learn.microsoft.com/en-us/cpp/build/stack-usage?view=msvc-170#stack-allocation
 *     (https://archive.md/4HDA0#selection-2085.429-2085.1196)
 */
