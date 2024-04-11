#pragma once

#include <exodus/types.h>

void InitSound(void);
// sets frequency. Called from HolyC
void SndFreq(u64);
f64 GetVolume(void);
void SetVolume(f64);
