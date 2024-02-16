#ifndef SCENEEND_HC
#define SCENEEND_HC

#include "Globals"
#include "Assets"
#include "Draw"
#include "Ship"
#include "Text"
#include "Sound"

#define SCENE_END_END_T 1

class SceneEndData {
  F64 time;
  F64 end_t;
  CBGR48 palette[COLORS_NUM];
  CBGR48 randColor;
  TextData endText;
  Bool transition;
} endData;

U0 DrawEnd(CTask*, CDC *dc) {
  I64 i, *old_r = dc->r;
  U8 *old_db = dc->depth_buf;
  dc->depth_buf = gDepthBuf;
  MemSetU32(gDepthBuf, I32_MAX, SCR_W*SCR_H);

  // Draw Background
  U32 rand=65434, rand2=443243;
  dc->color = BLUE;
  for (i=0; i<128; i++) {
    rand = XorShift(rand);
    rand2 = XorShift(rand2);
    Plot0F(dc,ToI64(rand)%SCR_W,ToI64(endData.time*5 + rand2)%FB_H + 8);
  }
  dc->color = WHITE;
  for (i=0; i<128; i++) {
    rand = XorShift(rand);
    rand2 = XorShift(rand2);
    Plot0F(dc,ToI64(rand)%SCR_W,ToI64(endData.time*10 + rand2)%FB_H + 8);
  }

  // Draw Ship
  gW.player.pos.x = 480;
  gW.player.pos.y = 150;
  gW.player.scale = 3.5;
  gW.player.vel.y = -1000;
  gW.player.vel.x = Cos(t_now) * 128;
  gW.player.accel.y = (Sin(t_now*2)-1.0)*0.1;
  GenMatShip(&gW.player, gW.pMat);
  DrawShip(dc, gW.pMat, gW.player.thruster, gDepthBuf);

  // Draw Borders
  I64 borderTopX = MinI64(-640 + 640*endData.time, 0);
  I64 borderBottomX = MaxI64(640 - 640*endData.time, -21);
  PxBlot(dc->body, gAssets.BossBorderTop, borderTopX, 0);
  PxBlot(dc->body, gAssets.BossBorderBottom, borderBottomX, 459);
  I64 sliderX;
  for (i=0; i<17; i++) {
    sliderX = (i*40 + endData.time*200 - 672)%680 - 40;
    PxBlot(dc->body, gAssets.BossBorderSlider, sliderX, 1);
  }
  for (i=0; i<17; i++) {
    sliderX = 640 - (i*40 + endData.time*200 - 640)%680;
    PxBlot(dc->body, gAssets.BossBorderSlider, sliderX, 460);
  }

  // Draw Text
  DrawTextBounce(dc->body, &gAssets.fontKapel2x, &endData.endText, 35, 64);

  // Clean Up
  dc->r = old_r;
  dc->depth_buf = old_db;;
  GrPaletteSet(endData.palette);
}

U0 EndInitEnd() {
  if (!endData.transition && endData.time > 8.0) {
    SetSnd(SND_TITLE_END);
    endData.transition = TRUE;
  }
}

U0 EndInput() {
  I64 msg, ch, sc;
  while (TRUE) {
    msg = ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN|1<<MSG_MS_L_DOWN, Fs);
    switch (msg) {
      case MSG_KEY_DOWN:
        if (ch) {
          switch (ch) {
            case '\n':
            case CH_SPACE:
              EndInitEnd;
              break;
            case CH_SHIFT_ESC:
              QuitGame;
              return;
            default:
              break;
          }
        }
        break;
      case MSG_MS_L_DOWN:
        EndInitEnd;
        break;
      default:
        return;
    }
  }
}

U0 UpdateEnd(F64 delta) {
  I64 i;
  endData.time += delta;

  endData.palette[01] = endData.randColor;
  endData.palette[02] = 0x30000333D999;
  endData.palette[03] = 0xFFFFFFFFEBBB;
  endData.palette[04] = 0x277727772777;
  endData.palette[05] = 0x5DDD5DDD5DDD;
  endData.palette[06] = 0xEAAA32223CCC;
  endData.palette[07] = 0x89991EEE2BBB;
  endData.palette[08] = 0xEDDD7BBB3888;
  endData.palette[09] = 0x5AAAC5554FFF;
  endData.palette[10] = 0xBCCC3FFF3444;
  endData.palette[11] = 0xFFFFF4444000;
  endData.palette[12] = 0x7AAA0999FAAA;
  endData.palette[13].r = Sin(endData.time*2) * 32767 + 32768;
  endData.palette[13].g = Sin(endData.time*2+2) * 32767 + 32768;
  endData.palette[13].b = Sin(endData.time*2+4) * 32767 + 32768;
  endData.palette[14] = 0xFEEEB7774999;
  endData.palette[15] = 0xFFFFFFFFFFFF;

  F64 colorMul = endData.time;
  if (colorMul > 1) colorMul = 1;
  for (i=1; i<15; i++) {
    endData.palette[i].r *= colorMul;
    endData.palette[i].g *= colorMul;
    endData.palette[i].b *= colorMul;
  }

  endData.endText.timer += delta;

  if (endData.transition) {
    if (endData.end_t > SCENE_END_END_T)
      switchScene = SCENE_TITLE;
    F64 diff = SCENE_END_END_T - endData.end_t;
    if (diff < 0) diff = 0;
    for (i=0; i<16; i++) {
      endData.palette[i].r *= diff;
      endData.palette[i].g *= diff;
      endData.palette[i].b *= diff;
    }
    endData.end_t += delta;
  }
}

public U0 InitEnd() {
  endData.time = 0;
  endData.end_t = 0;
  endData.palette[00] = 0x000000000000;
  F64 colorSeed = Rand()*pi*2;
  endData.randColor.r = Sin(colorSeed) * 32767 + 32768;
  endData.randColor.g = Sin(colorSeed+2) * 32767 + 32768;
  endData.randColor.b = Sin(colorSeed+4) * 32767 + 32768;
  endData.transition = FALSE;

  endData.endText.str = "You have stopped the JANNY incursion
and returned the GOD WORDS to
THE TEMPLE ORACLE.


Few people will ever play this game.
Even fewer will complete it.
You are an ELITE TEMPLEOS GAMER


\"MAKE GAMES, DON'T PLAY THEM\" --Terry <3";
  endData.endText.timer = 0;
  endData.endText.speed = 30;

  ActiveInput = &EndInput;
  ActiveUpdate = &UpdateEnd;
  Fs->draw_it = &DrawEnd;
}

#endif
