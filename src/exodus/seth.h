#pragma once

#include <vec/vec.h>

#include <exodus/types.h>

u64 CoreNum(void);
/* CTRL+ALT+C */
void InterruptCore(u64 core);

void CreateCore(vec_void_t ptrs);

void WakeCoreUp(u64 n);
void SleepMillis(u64 ms);

void InitIRQ0(void);
void MPSetProfilerInt(void *fp, i64 idx, i64 freq);
