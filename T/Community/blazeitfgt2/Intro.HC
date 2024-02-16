#ifndef INTRO_HC
#define INTRO_HC

#include "Globals"
#include "Assets"
#include "Draw"
#include "Ship"
#include "Sound"
#include "Text"

#define INTRO_END_T 1

class IntroData {
  F64 time;
  F64 end_t;
  CBGR48 palette[COLORS_NUM];
  CBGR48 randColor;
  TextData story_text;
  TextData controls_text;
  TextData controls_text0;
  TextData controls_text1;
  TextData controls_text2;
  TextData controls_text3;
  PxAnimSheet blackhole;
  Bool transition;
} introData;

U0 DrawIntro(CTask*, CDC *dc) {
  I64 *old_r = dc->r;
  U8 *old_db = dc->depth_buf;
  dc->depth_buf = gDepthBuf;
  MemSetU32(gDepthBuf, I32_MAX, SCR_W*SCR_H);

  I64 i;
  U32 rand=65434, rand2=443243;
  dc->color = BLUE;
  for (i=0; i<128; i++) {
    rand = XorShift(rand);
    rand2 = XorShift(rand2);
    Plot0F(dc,ToI64(rand)%SCR_W,ToI64(introData.time*10 + rand2)%FB_H + 8);
  }
  dc->color = WHITE;
  for (i=0; i<128; i++) {
    rand = XorShift(rand);
    rand2 = XorShift(rand2);
    Plot0F(dc,ToI64(rand)%SCR_W,ToI64(introData.time*20 + rand2)%FB_H + 8);
  }

  gW.player.pos.x = 480;
  gW.player.pos.y = 150;
  gW.player.scale = 3.5;
  gW.player.vel.y = -1000;
  gW.player.vel.x = Cos(t_now) * 128;
  gW.player.accel.y = (Sin(t_now*2)-1.0)*0.1;
  GenMatShip(&gW.player, gW.pMat);
  DrawShip(dc, gW.pMat, gW.player.thruster, gDepthBuf);

  DrawAnimSheet(dc->body, &introData.blackhole, 8, 303+Sin(t_now*1.5)*3);

  DrawTextBounce(dc->body, &gAssets.fontKapel2x, &introData.story_text, 16, 29);
  DrawTextBounce(dc->body, &gAssets.fontKapel2x, &introData.controls_text, 380, 324);
  DrawTextBounce(dc->body, &gAssets.fontKapel2x, &introData.controls_text0, 348, 324+24);
  DrawTextBounce(dc->body, &gAssets.fontKapel2x, &introData.controls_text1, 348, 324+24*2);
  DrawTextBounce(dc->body, &gAssets.fontKapel2x, &introData.controls_text2, 348, 324+24*3);
  DrawTextBounce(dc->body, &gAssets.fontKapel2x, &introData.controls_text3, 348, 324+24*4);

  I64 borderTopX = MinI64(-640 + 640*introData.time, 0);
  I64 borderBottomX = MaxI64(640 - 640*introData.time, -21);
  PxBlot(dc->body, gAssets.BossBorderTop, borderTopX, 0);
  PxBlot(dc->body, gAssets.BossBorderBottom, borderBottomX, 459);
  I64 sliderX;
  for (i=0; i<17; i++) {
    sliderX = (i*40 + introData.time*200 - 672)%680 - 40;
    PxBlot(dc->body, gAssets.BossBorderSlider, sliderX, 1);
  }
  for (i=0; i<17; i++) {
    sliderX = 640 - (i*40 + introData.time*200 - 640)%680;
    PxBlot(dc->body, gAssets.BossBorderSlider, sliderX, 460);
  }

  dc->r = old_r;
  dc->depth_buf = old_db;;
  GrPaletteSet(introData.palette);
}

U0 IntroInitEnd() {
  if (!introData.transition && introData.time > 0.1) {
    SetSnd(SND_TITLE_END);
    introData.transition = TRUE;
  }
}

U0 IntroInput() {
  I64 msg, ch, sc;
  while (TRUE) {
    msg = ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN|1<<MSG_MS_L_DOWN, Fs);
    switch (msg) {
      case MSG_KEY_DOWN:
        if (ch) {
          switch (ch) {
            case '\n':
            case CH_SPACE:
              IntroInitEnd;
              break;
//            case CH_ESC:
            case CH_SHIFT_ESC:
              QuitGame;
              return;
            default:
              break;
          }
        }
        break;
      case MSG_MS_L_DOWN:
        IntroInitEnd;
        break;
      default:
        return;
    }
  }
}

U0 UpdateIntro(F64 delta) {
  I64 i;
  introData.time += delta;

  introData.palette[01] = introData.randColor;
  introData.palette[02] = 0x30000333D999;
  introData.palette[03] = 0xFFFFFFFFEBBB;
  introData.palette[04] = 0x277727772777;
  introData.palette[05] = 0x5DDD5DDD5DDD;
  introData.palette[06] = 0xEAAA32223CCC;
  introData.palette[07] = 0x89991EEE2BBB;
  introData.palette[08] = 0xEDDD7BBB3888;
  introData.palette[09] = 0x5AAAC5554FFF;
  introData.palette[10] = 0xBCCC3FFF3444;
  introData.palette[11] = 0xFFFFF4444000;
  introData.palette[12] = 0x7AAA0999FAAA;
  introData.palette[13].r = Sin(introData.time*2) * 32767 + 32768;
  introData.palette[13].g = Sin(introData.time*2+2) * 32767 + 32768;
  introData.palette[13].b = Sin(introData.time*2+4) * 32767 + 32768;
  introData.palette[14] = 0xFEEEB7774999;
  introData.palette[15] = 0xFFFFFFFFFFFF;

  F64 colorMul = introData.time;
  if (colorMul > 1) colorMul = 1;
  for (i=1; i<15; i++) {
    introData.palette[i].r *= colorMul;
    introData.palette[i].g *= colorMul;
    introData.palette[i].b *= colorMul;
  }

  introData.story_text.timer += delta;
  introData.controls_text.timer += delta;
  introData.controls_text0.timer += delta;
  introData.controls_text1.timer += delta;
  introData.controls_text2.timer += delta;
  introData.controls_text3.timer += delta;
  introData.blackhole.time += delta;

  if (introData.transition) {
    if (introData.end_t > INTRO_END_T)
      switchScene = SCENE_GAME;
    F64 diff = INTRO_END_T - introData.end_t;
    if (diff < 0) diff = 0;
    for (i=0; i<16; i++) {
      introData.palette[i].r *= diff;
      introData.palette[i].g *= diff;
      introData.palette[i].b *= diff;
    }
    introData.end_t += delta;
  }
}

public U0 InitIntro() {
  introData.time = 0;
  introData.end_t = 0;
  introData.palette[00] = 0x000000000000;
  F64 colorSeed = Rand()*pi*2;
  introData.randColor.r = Sin(colorSeed) * 32767 + 32768;
  introData.randColor.g = Sin(colorSeed+2) * 32767 + 32768;
  introData.randColor.b = Sin(colorSeed+4) * 32767 + 32768;
  introData.transition = FALSE;

  TextBounceInit(&introData.story_text, "The GOD WORDS has been\nkidnapped by the JANNIES.\n\nAre you a bad enough dude\nto rescue the GOD WORDS?", 20);
  TextBounceInit(&introData.controls_text, "CONTROLS", 20);
  TextBounceInit(&introData.controls_text0, "MOVE = ARROWS|WASD", 20);
  TextBounceInit(&introData.controls_text1, "FIRE  = SPACE", 20);
  TextBounceInit(&introData.controls_text2, "BOMB = CTRL|X", 20);
  TextBounceInit(&introData.controls_text3, "MUTE = M", 20);

  InitAnimSheet(&introData.blackhole, gAssets.pxBlackHole, BLACKHOLE_LEN, 20);

  ActiveInput = &IntroInput;
  ActiveUpdate = &UpdateIntro;
  Fs->draw_it = &DrawIntro;
}

#endif
