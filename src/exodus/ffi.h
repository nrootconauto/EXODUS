#pragma once

#include <exodus/misc.h>
#include <exodus/types.h>

void BootstrapLoader(void);

/* HolyC routines */
void *HolyMAlloc(u64 sz);
char *HolyStrDup(char const *s);
void HolyFree(void *p);
noret void HolyThrow(char const *s);
