#ifndef PLAYFIELDDRAW_HC
#define PLAYFIELDDRAW_HC

#include "Globals"
#include "Mob"
#include "Ship"

#include "Particle"
#include "Bullet"
#include "Text"
#include "PauseMenu"

// Defines
#define HEALTH_X 240
#define HEALTH_Y FB_H-HEALTH_H-1
#define HEALTH_W 128
#define HEALTH_H 16

// Classes
class BombData {
  F64 t_now;
  F64 bomb_ttl;
  CD2I32 bombPos;
  U8 *old_fb;
  U8 *backbuffer;
};

{
I64 _bsz;
U8 *BombBIN=FileRead("Asm/Bomb.BIN",&_bsz);
U0 (*BombVFX)(BombData *bd)=MAlloc32(_bsz);
MemCpy(BombVFX,BombBIN,_bsz);
Free(BombBIN);
}

#define SCORESCR_X 192
#define SCORESCR_Y 8
#define SCORESCR_STR_X SCORESCR_X+24
#define SCORESCR_STR_Y SCORESCR_Y+24
#define SCORESCR_STR_BONUS_X SCORESCR_STR_X+24

U0 DrawScoreScreen(CDC *dc) {
  I32 i;
  U8 endScoreStr[128];
  PxBlot(dc->body, gAssets.ScoreScreen, SCORESCR_X, SCORESCR_Y);

  F64 scoreTimer = gW.levelTransitionTTL-3.5;
  if (scoreTimer > 1) scoreTimer=1;
  else if (scoreTimer < 0) scoreTimer=0;
  StrPrint(endScoreStr, "Killed: %f%%", ToF64(gW.lvlMobsKilled)/gW.lvlMobsSpawned*100.0*scoreTimer);
  DrawText(dc->body, &gAssets.fontKapel2x, endScoreStr, SCORESCR_STR_X, SCORESCR_STR_Y+32);

  gW.appliedMobBonus = gW.lvlMobsBonus*scoreTimer;
  StrPrint(endScoreStr, "Bonus: %d", gW.appliedMobBonus);
  DrawText(dc->body, &gAssets.fontKapel2x, endScoreStr, SCORESCR_STR_BONUS_X, SCORESCR_STR_Y+32+24);

  scoreTimer = gW.levelTransitionTTL-5;
  if (scoreTimer > 1) scoreTimer=1;
  else if (scoreTimer < 0) scoreTimer=0;
  StrPrint(endScoreStr, "Bombs:");
  DrawText(dc->body, &gAssets.fontKapel2x, endScoreStr, SCORESCR_STR_X, SCORESCR_STR_Y+32*2+24);
  I32 bombMul = gW.bombs*scoreTimer;
  for (i=0; i<bombMul; i++) {
    PxBlot(dc->body, gAssets.pxBomb, SCORESCR_STR_X+94+i*(gAssets.pxBomb->width+2), SCORESCR_STR_Y+32*2+24+5);
  }
  gW.appliedBombBonus = BOMB_BONUS*bombMul;
  StrPrint(endScoreStr, "Bonus: %d", gW.appliedBombBonus);
  DrawText(dc->body, &gAssets.fontKapel2x, endScoreStr, SCORESCR_STR_BONUS_X, SCORESCR_STR_Y+32*2+24+24);

  scoreTimer = gW.levelTransitionTTL-2;
  if (scoreTimer > 1) scoreTimer = 1;
  else if (scoreTimer < 0) scoreTimer=0;
  StrPrint(endScoreStr, "Score: %d", ToI64(gW.lvlScore*scoreTimer)+gW.appliedMobBonus+gW.appliedBombBonus);
  DrawText(dc->body, &gAssets.fontKapel2x, endScoreStr, SCORESCR_STR_X, SCORESCR_STR_Y);
}

// Draw
U0 DrawPlayfield(CTask *task, CDC *dc) {
  I64 i, ii;
  I64 *old_r = dc->r;
  U8 *old_db = dc->depth_buf;
  U8 *old_fb = dc->body;
  dc->body = backbuffer;
  dc->depth_buf = gDepthBuf;

  if (blur_ttl <= 0.0)
    MemSet(dc->body+PIX_TOP*SCR_W,BLACK,SCR_W*FB_H);

  MemSetU32(gDepthBuf, I32_MAX, SCR_W*SCR_H);

  // Draw Background
  U32 rand=65434, rand2=443243;
  dc->color = BLUE;
  for (i=0; i<128; i++) {
    rand = XorShift(rand);
    rand2 = XorShift(rand2);
    Plot0F(dc,ToI64(rand)%SCR_W,ToI64(gW.scrollY*0.1 + rand2)%FB_H + 8);
  }
  dc->color = WHITE;
  for (i=0; i<128; i++) {
    rand = XorShift(rand);
    rand2 = XorShift(rand2);
    Plot0F(dc,ToI64(rand)%SCR_W,ToI64(gW.scrollY*0.2 + rand2)%FB_H + 8);
  }

  // Draw God Screen
  I64 gword_x = task->pix_width-(GWORD_W)-1;
  DrawRecBorder(dc, gword_x, GWORD_Y, GWORD_W, GWORD_H);
  I64 gx = gword_x + 3;
  I64 gy = GWORD_Y + 3;
  for (i=0; i<GTEXT_LINES; i++) {
    for (ii=0; ii<gW.gtext.ol[i]->len; ii++) {
      GrPutChar(dc, gx, gy, gW.gtext.ol[i]->c[ii]);
      gx += FONT_WIDTH;
    }
    gx = gword_x + 3;
    gy += FONT_HEIGHT;
  }

  // Begin 3D
  dc->flags |= DCF_TRANSFORMATION;

  // Draw Player
  if (!gW.dead)
    DrawShip(dc, gW.pMat, gW.player.thruster, gDepthBuf);
  else
    DrawShipExplosion(dc, gW.player.pos.x, gW.player.pos.y, &gW.player.q, death_ttl);

  // Draw SpawnFX
  DrawSpawnFX(dc, gW.spawnFX.d, gW.spawnFX.len, gDepthBuf);

  // Draw Explosions
  DrawExplosions(dc, gW.explosion.d, gW.explosion.len, gDepthBuf);

  // Draw Debris
  DrawDebris(dc, gW.grDebris.len, gW.grDebris.d, gDepthBuf);
  DrawDebrisMesh(dc);

  // Mobs
  DrawMobs(dc, gW.mobs.d, gW.mobs.len, gW.grMobs.d, gDepthBuf);

  // Draw Mob Bullets
  DrawBullets(dc->body, gW.bulletsM.d, gW.bulletsM.len);

  // Draw Bullets
  DrawBullets(dc->body, gW.bullets.d, gW.bullets.len);

  // Draw Pickups
  DrawPickups(dc->body, gW.pickups.d, gW.pickups.len);

  // TMP draw poly collision
/*
  CD2 testCircle;
  testCircle.x = gW.player.pos.x;
  testCircle.y = gW.player.pos.y;
  testCircle.x = ms.pos.x;
  testCircle.y = ms.pos.y;
  CD2 *tmpLines;
  tmpLines = MAlloc(gAssets.mobBasicC->cnt*sizeof(CD2));
  for (i=0; i<gAssets.mobBasicC->cnt; i++) {
    tmpLines[i].x = gAssets.mobBasicC->lines[i].x + 256;
    tmpLines[i].y = gAssets.mobBasicC->lines[i].y + 256;
  }
  //if (CheckCollidePolyCircle(tmpLines, gAssets.mobBasicC->cnt, testCircle.x, testCircle.y, 8)) {
  if (CheckCollideCircle(gW.player.pos.x, gW.player.pos.y, PLAYER_HIT_RADIUS, ms.pos.x, ms.pos.y, PLAYER_HIT_RADIUS)) {
    dc->color = GREEN;
  } else {
    dc->color = RED;
  }
  GrFillCircle(dc, testCircle.x, testCircle.y, 0, 16);
  DrawLinesC(dc, gAssets.mobBasicC->cnt, tmpLines);
  Free(tmpLines);
*/

  // Draw Lasers
  dc->color = 1;
  Laser *laser = gW.lasers.d;
  for (i=0; i<gW.lasers.len; i++) {
    Bezier2FN(dc, laser[i].curve, laser[i].width);
    dc->color++;
    if (dc->color >= 16)
      dc->color = 1;
  }

  // Draw God Words
  dc->color = WHITE;
  CD2 bp1, bp2, bp3;
  bp1.x = 0;
  bp1.y = 0;
  bp2.x = SCX;
  bp2.y = SCY;
  bp3.x = SCR_W-80;
  bp3.y = 0;
  GWord* gword = gW.godWords.d;
  for (i=0; i<gW.godWords.len; i++, gword++) {
    CD2 dpos;
    GetPosOnCurve2(&gword->pos, &bp1, &bp2, &bp3, gword->ttl/4, &dpos);
    PutSF(dc, dpos.x, dpos.y, gword->str);
  }

  dc->dither_probability_u16=I16_MAX/2;
  DrawTriFillVMC(dc, gAssets.shipCore.tris, gAssets.shipCore.triCnt, gW.pMat, gDepthBuf, gAssets.shipCore.colors);

  // End 3D
  dc->flags &= ~DCF_TRANSFORMATION;

  // Draw Health Bar
  dc->color = WHITE;
  DrawRecBorder(dc, HEALTH_X, HEALTH_Y, HEALTH_W, HEALTH_H);
  F64 hpPer = gW.player.health / 100.0;
  I32 wPer = (HEALTH_W-1) * hpPer;
  DrawRect(dc->body, HEALTH_X+1, HEALTH_Y+1, wPer, HEALTH_H-1, RED);
  I32 hx = HEALTH_X+1 + wPer;
  I32 hw = HEALTH_W-1 - wPer;
  DrawRect(dc->body, hx, HEALTH_Y+1, hw, HEALTH_H-1, BLACK);

  // Draw Score
  U8 scoreStr[24];
  StrPrint(scoreStr, "%d", gW.score+gW.appliedMobBonus+gW.appliedBombBonus);
  DrawText(dc->body, &gAssets.fontKapel2x, scoreStr, 4, 4);

#ifdef DEBUG
  // Draw Debug Data
  dc->color = WHITE;
  GrPrint(dc, 2, 100,
   "Level: %d\nPos: %fx%f\nVel: %fx%f\nscrollY: %f\nlastSpawnIdx: %d",
   gW.levelNum, gW.player.pos.x, gW.player.pos.y,
   gW.player.vel.x, gW.player.vel.y, gW.scrollY,
   gW.lastSpawnIdx);

  // TMP draw player hitbox
  //GrCircle(dc, ToI64(gW.player.pos.x), ToI64(gW.player.pos.y), 8);
#endif

  // Draw Bombs
  for (i=0; i<gW.bombs; i++)
    PxBlot(dc->body, gAssets.pxBomb, gAssets.pxBomb->width*i+2, FB_H-gAssets.pxBomb->height-2);

  // Draw End Level Score Screen
  if (gW.levelTransition && gW.levelTransitionTTL-2 >= 0)
    DrawScoreScreen(dc);

  // Draw Game Over
  if (gW.dead) {
    U8 *str = "Game Over";
    I64 text_len = GetTextWidth(&gAssets.fontKapel2x, str);
    DrawText(dc->body,&gAssets.fontKapel2x,str,SCX-text_len/2,SCY-gAssets.fontKapel2x.y);
    str = "Press Enter to Restart";
    text_len = GetTextWidth(&gAssets.fontKapel2x, str);
    DrawText(dc->body,&gAssets.fontKapel2x,str,SCX-text_len/2,SCY);
  }

  // Draw Bomb
  if (gW.bossIntroTTL > 0) {
    F64 ttlN = BOSS_INTRO_TTL-gW.bossIntroTTL;
    dc->color = 4;
    I64 rectH = MinI64(87*(-1 + ttlN*2), 87);
    GrRect(dc, 0, 113, 640, rectH);

    F64 pmul = ttlN;
    if (pmul > 1) pmul = 1;
    U64 probability;
    probability.u16[0] = U16_MAX*pmul;
    probability.u16[1] = U16_MAX/1.5*pmul;
    U64 mask;
    mask.u8[0] = 13;
    mask.u8[1] = 4;
    mask.u8[2] = 0;
    mask.u8[3] = 4;
    PxBlotDither(dc->body, gAssets.BreachDetected, 8, 130, mask, probability);

    I64 borderTopX = MinI64(-640 + 640*ttlN, 0);
    I64 borderBottomX = MaxI64(640 - 640*ttlN, -21);
    PxBlot(dc->body, gAssets.BossBorderTop, borderTopX, 100);
    PxBlot(dc->body, gAssets.BossBorderBottom, borderBottomX, 200);

    I64 sliderX;
    for (i=0; i<17; i++) {
      sliderX = (i*40 + ttlN*256 - 672)%680 - 40;
      PxBlot(dc->body, gAssets.BossBorderSlider, sliderX, 101);
    }
    for (i=0; i<17; i++) {
      sliderX = 640 - (i*40 + ttlN*256 - 640)%680;
      PxBlot(dc->body, gAssets.BossBorderSlider, sliderX, 201);
    }
  }

#ifdef DEBUG
  // DEBUG Draw Collision Boxes
  cPolyMeta *meta = gW.cPolyIdx.d;
  dc->color = WHITE;
  CD2I32 *poly = gW.cPolys.d;
  for (i=0; i<gW.cPolyIdx.len; i++, meta++)
    DrawLinesC(dc, meta->cnt, poly+meta->idx);

  // DEBUG Draw Centroid
  Mob *mobs = gW.mobs.d;
  dc->color = GREEN;
  for (i=0; i<gW.mobs.len; i++, mobs++) {
    for (ii=0; ii<mobs->centroidCnt; ii++)
      GrFillCircle(dc, mobs->centroid[ii].x, mobs->centroid[ii].y, 0, 5);
  }
#endif

  if (gW.pauseMenu)
    DrawPauseMenu(dc);

  // Draw Bomb Effect
  if (bomb_ttl > 0) {
    BombData bd;
    bd.t_now = t_now;
    bd.bomb_ttl = bomb_ttl;
    bd.bombPos.x = bombPos.x;
    bd.bombPos.y = bombPos.y;
    bd.old_fb = old_fb;
    bd.backbuffer = backbuffer;
    (*BombVFX)(&bd);
  } else {
    MemCpy(old_fb+PIX_TOP*SCR_W,backbuffer+PIX_TOP*SCR_W,SCR_W*FB_H);
  }

  dc->body = old_fb;
  dc->depth_buf = old_db;
  dc->r = old_r;

  // Update Palette
  if (gW.bossDeadTTL >= BOSS_DEAD_TTL-0.1) {
    if (game_palette[BLACK] != 0xFFFFFFFFFFFF) {
      game_palette[BLACK] = 0xFFFFFFFFFFFF;
      GrPaletteColorSet(BLACK,game_palette[BLACK]);
    }
  } else if (game_palette[BLACK] != 0x0) {
    game_palette[BLACK] = 0x0;
    GrPaletteColorSet(BLACK,game_palette[BLACK]);
  }
  game_palette[13].r = Sin(t_now*2) * 32767 + 32768;
  game_palette[13].g = Sin(t_now*2) * 32767/4 + 32768/4;
  game_palette[13].b = Sin(t_now*2) * 32767/4 + 32768/4;
  GrPaletteColorSet(13,game_palette[13]);
  //GrPaletteSet(game_palette);
}

#endif
