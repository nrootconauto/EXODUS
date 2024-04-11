#pragma once

#include <exodus/misc.h>
#include <exodus/types.h>

void SetClipboard(char const *text);
char *ClipboardText(argign void *stk);
void DrawWindowNew(void);
void DrawWindowUpdate(u8 *px);
void EventLoop(void);
void PCSpkInit(void);
void GrPaletteColorSet(u64 i, u64 _u);
void SetKBCallback(void *fp);
void SetMSCallback(void *fp);
