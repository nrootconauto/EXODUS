#pragma once

#include <exodus/types.h>

void *NewVirtualChunk(u64 sz, bool exec);
void FreeVirtualChunk(void *ptr, u64 sz);
