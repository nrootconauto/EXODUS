#pragma once

#include <stdbool.h>

#include <exodus/types.h>

/* AUTOEXEC.BAT */
char *CmdLineBootText(void);

u64 IsCmdLine(void);
bool SdlGrab(void);
int GetFPS(void);
