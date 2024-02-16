#ifndef TITLEDRAW_HC
#define TITLEDRAW_HC

#include "Globals"
#include "TitleGlobals"
#include "Assets"
#include "Draw"
#include "Text"

// Draw Title
U0 DrawTitle(CTask* f, CDC *dc) {
  I64 r[4][4], *old_r=dc->r;

  // Setup DC
  dc->flags |= DCF_TRANSFORMATION;

  // Draw Text Scroll
  U8 *startPtr = titleData.srcText;
  U8 *endPtr = titleData.srcText + ToI64(titleData.time*128)%StrLen(titleData.srcText);
  U8 *scanPtr = endPtr;
  I64 returnCnt = 0;
  while (scanPtr >= titleData.srcText) {
    if (scanPtr != endPtr && *scanPtr == '\n') {
      if (returnCnt == 9) {
        returnCnt = 0;
        startPtr = scanPtr+1;
        break;
      }
      returnCnt++;
    }
    scanPtr--;
  }
  dc->color = 9;
  PutSF(dc, 8, SCR_H-FONT_HEIGHT*14, startPtr, endPtr);

  // Draw Starfield
  I64 x2 = gAssets.pxScum->width;
  I64 x = SCX - x2/2;
  I64 y = 16;
  I64 y2 = gAssets.pxScum->height;
  dc->color = WHITE;
  U32 rand = 65434;
  U32 rand2 = 443243;
  I64 i;
  for (i=0; i<128; i++) {
    rand = XorShift(rand);
    rand2 = XorShift(rand2);
    Plot0F(dc, x+ToI64(t_now*32+rand)%x2, y+8+ToI64(t_now*8+rand2)%y2);
  }

  // Draw Scum
  PxBlot(dc->body, gAssets.pxScum, x, y);

  // Draw CrunkLord420
  x = SCX - gAssets.pxCrunkLord->width/2;
  PxBlot(dc->body, gAssets.pxCrunkLord, x, 300);

  MemSetU32(gDepthBuf, I32_MAX, SCR_W*SCR_H);
  Mat4x4IdentEqu(r);
  Mat4x4RotX(r, t_now);
  Mat4x4RotZ(r, -pi/4);
  Mat4x4Scale(r, 4);
  Mat4x4TranslationEqu(r, SCX, SCY, 256);
  dc->r = r;

  // Draw Ship
  dc->color = BLUE;
  CD3I32 *lines = gAssets.ship->lines;
  I64 cnt = gAssets.ship->cnt;
  for (i=0; i<cnt; i+=2)
    GrLine3F(dc, lines[i].x, lines[i].y, lines[i].z, lines[i+1].x, lines[i+1].y, lines[i+1].z, gDepthBuf);

  // Draw BlazeItFgt Logo
  U64 mask, probability;
  mask.u8[0] = 13;
  mask.u8[1] = BLACK;
  probability.u16[0] = Min(titleData.time*U16_MAX, U16_MAX);
  PxBlotDither(dc->body, gAssets.pxBIF, 32, 220, mask, probability);

  if (titleData.time>=0.6) {
    probability.u16[0] = Clamp((titleData.time-0.9)/2*U16_MAX, 0, U16_MAX/2);
    mask.u8[0] = 5;
    mask.u8[1] = BLACK;
    I32 offX = Clamp((titleData.time-1.0)*64, 0, 6);
    PxBlotDither(dc->body, gAssets.pxBIF2A, 490+offX, 164+offX, mask, probability);
    probability.u16[0] = Clamp((titleData.time-0.6)*U16_MAX, 0, U16_MAX);
    mask.u8[0] = 1;
    mask.u8[1] = BLACK;
    PxBlotDither(dc->body, gAssets.pxBIF2, 490, 164, mask, probability);
  }

  // Draw Strings
  DrawText(dc->body,&gAssets.fontKapel2x,"HTTPS://SCUMGAMES.NEOCITIES.ORG/",2,FB_H-gAssets.fontKapel2x.y-1);
  DrawText(dc->body,&gAssets.fontKapel,"VER. 0.420 MIT+NIGGER",SCR_W-164, FB_H-12);

  // Restore DC
  dc->r = old_r;
  // Update Palette
  GrPaletteSet(titleData.palette);
}

#endif
