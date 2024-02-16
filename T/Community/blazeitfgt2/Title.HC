#ifndef TITLE_HC
#define TITLE_HC

#include "TitleDraw"
#include "TitleInput"
#include "Intro"

public U0 UpdateTitle(F64 delta) {

  // Update Timers
  titleData.time += delta;
  titleData.palette[1].r = Sin(t_now) * 32767 + 32768;
  titleData.palette[1].g = Sin(t_now+2) * 32767 + 32768;
  titleData.palette[1].b = Sin(t_now+4) * 32767 + 32768;
  titleData.palette[13].r = Sin(t_now+pi/2) * 32767 + 32768;
  titleData.palette[13].g = Sin(t_now+pi/2+2) * 32767 + 32768;
  titleData.palette[13].b = Sin(t_now+pi/2+4) * 32767 + 32768;

  if (titleData.transition) {
    if (titleData.end_t > TITLE_END_T)
      switchScene = SCENE_INTRO;

    I64 i;
    F64 diff = TITLE_END_T - titleData.end_t;
    if (diff < 0) diff = 0;
    for (i=0; i<16; i++) {
      titleData.palette[i].r *= diff;
      titleData.palette[i].g *= diff;
      titleData.palette[i].b *= diff;
    }
    titleData.end_t += delta;
  }
}

public U0 InitTitle() {
  titleData.time = 0;
  titleData.end_t = 0;
  titleData.palette[00] = 0x000000000000;
  titleData.palette[01] = 0x00000000AAAA;
  titleData.palette[02] = 0x244424442444;
  titleData.palette[03] = 0x29992CCC5AAA;
  titleData.palette[04] = 0x62226DDD9444;
  titleData.palette[05] = 0xA444AEEEBDDD;
  titleData.palette[06] = 0xDEEEAEEEE666;
  titleData.palette[07] = 0x0CCC2EEE4444;
  titleData.palette[08] = 0x92223CCCD555;
  titleData.palette[09] = 0x9CCC38883999;
  titleData.palette[10] = 0xCDDD75558BBB;
  titleData.palette[11] = 0xE666BEEEBDDD;
  titleData.palette[12] = 0xE6E6BEBEBDBD;
  titleData.palette[13] = 0xEEEE3CCC7333;
  titleData.palette[14] = 0xFFFFC8882555;
  titleData.palette[15] = 0xFFFFFFFFFFFF;
  titleData.transition = FALSE;

  ActiveInput = &TitleInput;
  ActiveUpdate = &UpdateTitle;
  Fs->draw_it = &DrawTitle;
}

#endif
