# Introduction
EXODUS forbids the use of uintptr\_t, intptr\_t, size\_t, ptrdiff\_t and the like. Use u64 or i64 instead.
# Adding an FFI routine
In src/ffi.c:
```C
i64 STK_FunctionName(i64* stk) {
  /* function body */
}
```
in BootstrapLoader():
```C
  S(FunctionName, <function's argument count in HolyC>),
```
`STK_FunctionName` ***MUST*** return void OR a value that is 8 bytes big.

In T/KERNELA.HH:
```C
...after #ifdef IMPORT_BUILTINS
import <type> FunctionName(<arguments>);
...#else...
extern <type> FunctionName(<arguments>);
```
Build HCRT.BIN using `./exodus -c -t T BuildHCRT.HC`, copy HCRT.BIN to HCRT\_BOOTSTRAP.BIN
# Check if you forgot to add symbols
If you want to add a HolyC native function, add a file and include it in T/HCRT\_TOS.HC.

Sometimes you forget to add it to KERNELA.HH, so here's how to see if you missed anything:

In T/FULL\_PACKAGE.HC:
```C
#define GEN_HEADERS 1
```
Rebuild HCRT -> Run EXODUS -> copy functions from T/unfound.DD to T/KERNELA.HH
