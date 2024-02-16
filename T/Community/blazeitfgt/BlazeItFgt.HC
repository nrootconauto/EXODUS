#ifndef BLAZEITFGT_HC
#define BLAZEITFGT_HC

#exe {
#ifdef DEBUG
  Option(OPTf_WARN_UNUSED_VAR, ON);
  Option(OPTf_WARN_PAREN, ON);
#endif
}
#include "Bullet";
#include "Title";
#include "God";
#include "Mob";
#include "Particle";
#include "PlayfieldInput";
#include "SBase";
#include "Ship";
#include "Sound";
#include "Turret";
#include "Wall";
#include "World";
#include "Obj/MobObjT";
#include "Obj/TurretT";

// Defines
#define POPUP_TTL 4
#define MAP_W 196
#define MAP_H 96
#define HEALTH_X 240
#define HEALTH_Y 0
#define HEALTH_W 128
#define HEALTH_H 16
#define BULLET_EXPIRE 5
#define EXP_EXPIRE 1
#define LEVEL_TRANSITION_TTL 0.33
#define POPUP_CNT 6

// Global Variables
World gW;
U8 scoreStr[32], popupStr[POPUP_CNT][64];
F64 popup_ttl;
I64 lastWheel,score,test_flag=0;
Bool quitGame, firing;
F64 death_ttl;
F64 jitter_ttl,blur_ttl;
F64 firing_ttl;
F64 t_last, t_now, t_delta;
CD2 cVel;
CJob *sndJob;
U0 (*ActiveInput)();
U0 (*ActiveUpdate)(F64 delta);
Cam gCam;

// Functions
U0 InitPopup() {
  I64 i;
  for (i=0; i<POPUP_CNT; i++) {
    popupStr[i][0] = '\0';
  }
  popup_ttl = POPUP_TTL;
}

U0 InitLevel() {
  firing = FALSE;
  firing_ttl = 0.1;
  cVel.x = 0.0;
  cVel.y = 0.0;
  gW.spawnWave = 0;
  gW.spawnedMobsLeft = 0;
  gW.dead = FALSE;
  gW.escapePhase = FALSE;
  gW.cam.pos.x = 0;
  gW.cam.pos.y = 0;
  gW.cam.pos.z = -128;
  gW.cam.zoom = 0.5;
  gW.cam.up.x = 0;
  gW.cam.up.y = 1;
  gW.cam.up.z = 0;

  gW.player.pos.x = 0.0;
  gW.player.pos.y = 0.0;
  gW.player.size.x = 64;
  gW.player.size.y = 64;
  gW.player.vel.x = 0.0;
  gW.player.vel.y = 0.0;
  gW.player.q.x = 0.0;
  gW.player.q.y = 0.0;
  gW.player.q.z = 0.0;
  gW.player.q.w = 1.0;
  gW.player.health = 100.0;
  gW.player.accel.x = 0.0;
  gW.player.accel.y = 0.0;

  // Reset Arrays
  gW.base.len = 0;
  gW.spawner.len = 0;
  gW.bullets.len = 0;
  gW.mobs.len = 0;
  gW.bulletM.len = 0;
  gW.lasers.len = 0;
  gW.mapPings.len = 0;
  gW.turrets.len = 0;
  gW.walls.len = 0;
  gW.wallPosts.len = 0;

  // Reset Collision Buffers
  gW.collide.len = 0;
  gW.collideMeta.len = 0;
  gW.cBase.len = 0;
  gW.cMobs.len = 0;
  gW.cSpawner.len = 0;
  gW.cTur.len = 0;

  // Reset Graphics Buffers
  gW.grBullets.len = 0;
  gW.grBulletsM.len = 0;
  gW.grDebris.len = 0;
  gW.grMobs.len = 0;
  gW.grSpawner.len = 0;
  gW.grTur.len = 0;

  // Reset Particle Buffers
  gW.debris.len = 0;
  gW.explosion.len = 0;
  gW.spawnFX.len = 0;

  // Generate Space Bases
  I64 i;
  for (i=0; i<1; i++)
    NewSBase(&gW);

  // Generate Walls
  GenWalls(gW.wallPosts.d, gW.wallPosts.len, &gW.walls);
}

U0 InitNextLevel() {
  gW.level++;
  gW.levelTransition = TRUE;
  gW.levelTransitionTTL = 0.0;
  blur_ttl = LEVEL_TRANSITION_TTL;
}

U0 MobAI(Mob *mob, I64 mi) {
  I64 ndist, lowi = -1;
  I64 cx = mob->pos.x;
  I64 cy = mob->pos.y;
  I64 dist = I64_MAX;
  I64 type = TYPE_NONE;

  // Check Player Distance
  ndist = Abs(gW.player.pos.x-cx) + Abs(gW.player.pos.y-cy);
  if (ndist < dist) {
    dist = ndist;
    type = TYPE_PLAYER;
  }

  // Check Base Distance
/*  for (i=0; i<gW.base.len; i++) {
    ndist = Abs(gW.base.d(SBase*)[i].pos.x-cx) + Abs(gW.base.d(SBase*)[i].pos.y-cy);
    if (ndist < dist) {
      dist = ndist;
      lowi = i;
      type = TYPE_BASE;
    }
  }*/

  if (type != TYPE_NONE) {
    F64 tx, ty;
    if (type == TYPE_PLAYER) {
      tx = gW.player.pos.x;
      ty = gW.player.pos.y;
    } else {
      tx = gW.base.d(SBase*)[lowi].pos.x;
      ty = gW.base.d(SBase*)[lowi].pos.y;
    }
    F64 tmx = tx + Sin(t_now+mi)*128-cx;
    F64 tmy = ty + Cos(t_now+mi)*128-cy;
    F64 mag = Arg(tmx, tmy);
    mob->vel.x = Cos(mag) * 128;
    mob->vel.y = Sin(mag) * 128;

    // Mob Shoot
    mob->shoot_ttl -= t_delta;
    if (mob->shoot_ttl <= 0.0 && dist < 512) {
      mob->shoot_ttl = 2.0;
      tmx = tx-cx;
      tmy = ty-cy;
      AddBullet(cx, cy, tmx, tmy, &gW.bulletM, BULLET_SPEED);
    }
  }
}

U0 TurAI(Turret *t, I64 cnt, F64 delta) {
  I64 i;
  F64 dist, a, ad;
  for (i=0; i<cnt; i++) {
    t[i].shoot_ttl -= delta;
    // Check Player Distance
    dist = Abs(gW.player.pos.x-t[i].pos.x) + Abs(gW.player.pos.y-t[i].pos.y);
    if (dist <= TUR_TARGET_DIST) {
      a = Arg(gW.player.pos.x-t[i].pos.x, gW.player.pos.y-t[i].pos.y);
      ad = Arg(Sin(t[i].rot-a+pi/2), Cos(t[i].rot-a+pi/2));
      ad = Clamp(ad, -pi/6, pi/6);
      t[i].rot += ad * delta;
      if (t[i].shoot_ttl <= 0 && Abs(ad) <= pi/18) {
        t[i].shoot_ttl = TUR_SHOOT_TTL;
        // Fire Turret
        Bullet b;
        b.pos.x = t[i].pos.x;
        b.pos.y = t[i].pos.y;
        b.size.x = 16;
        b.size.y = 16;
        b.vel.x = Cos(t[i].rot)*512;
        b.vel.y = Sin(t[i].rot)*512;
        b.ry = t[i].rot;
        b.ttl = 0.0;
        VectorAdd(&gW.bulletM, &b);
      }
    }
  }
}

U0 SpawnGroup(I64 x, I64 y, I64 cnt) {
  I64 i;
  for (i=0; i<cnt; i++)
    AddMob(&gW.mobs, &gW.cMobs, x+Sin(i)*32, y+Sin(i)*32);
  AddMapPing(&gW.mapPings, x, y, BLUE);
  AddParticle(&gW.spawnFX, x, y);
}

U0 SpawnWave() {
  I64 i;
  gW.spawnWave++;
  for (i=0; i<gW.spawnWave; i++) {
    SpawnGroup(Sin(t_now)*2000, Cos(t_now)*1000, 8);
  }
  gW.spawnedMobsLeft = gW.spawnWave*8;
}

U0 DmgPlayer(F64 dmg) {
  if (!gW.levelTransition) {
    blur_ttl = 0.07;
    playSnd = SND_PLAYER_DMG;
    gW.player.health -= dmg;
    if (gW.player.health < 0.0)
      gW.player.health = 0.0;
  }
}

// Draw
U0 DrawPlayfield(CTask *task, CDC *dc) {
  dc = DCAlias(gr.dc, task);
  DCDepthBufAlloc(dc);
  if (blur_ttl <= 0.0 && test_flag == 0)
    DCFill;

  I64 i, ii, *old_r;

  // Draw Background
  dc->x = SCX;
  dc->y = SCY;
  dc->z = 256;
  dc->color = WHITE;
  if (gW.levelTransition) {
    for (i=0; i<48; i++) {
      for (ii=0; ii<16; ii++) {
        GrPlot0F(dc,
         (ToI64(-gW.cam.pos.x*(1.0+gW.levelTransitionTTL*10.0) + Sin(i*ii)*10240) + 4611686018427387903) % 640,
         (ToI64(-gW.cam.pos.y*(1.0+gW.levelTransitionTTL*10.0) + Cos(i*ii)*10240) + 4611686018427387903) % task->pix_height + task->pix_top);
      }
    }
  } else {
    for (i=0; i<48; i++) {
      for (ii=0; ii<16; ii++) {
        GrPlot0F(dc,
         (ToI64(-gW.cam.pos.x + Sin(i*ii)*10240) + 4611686018427387903) % 640,
         (ToI64(-gW.cam.pos.y + Cos(i*ii)*10240) + 4611686018427387903) % task->pix_height + task->pix_top);
      }
    }
  }

  // Begin 3D
  old_r = dc->r;
  dc->flags |= DCF_TRANSFORMATION;

  // Draw Player
  if (!gW.dead) {
    DrawShip(dc, t_now, gW.pMat, gW.pTf, gW.pTris);
  } else {
    DrawShipExplosion(dc, gW.player.pos.x, gW.player.pos.y, &gW.player.q, &gW.cam, death_ttl);
  }

  // Draw Walls
  DrawWall(dc, gW.walls.d, gW.walls.len, &gW.cam, t_now);

  // Draw Turrets
  DrawTurrets(dc, gW.grTur.len, gW.grTur.d);

  // Draw Bullets
  dc->color = WHITE;
  DrawBullets(dc, gW.grBullets.len, gW.grBullets.d);

  // Draw Mob Bullets
  dc->color = RED;
  DrawBullets(dc, gW.grBulletsM.len, gW.grBulletsM.d);

  // Draw SpawnFX
  DrawSpawnFX(dc, gW.spawnFX.d, gW.spawnFX.len, &gW.cam);

  // Draw Explosions
  DrawExplosions(dc, gW.explosion.d, gW.explosion.len, &gW.cam);

  // Draw Debris
  DrawDebris(dc, gW.grDebris.len, gW.grDebris.d);

  // Draw Bases
  DrawBase(dc, gW.base.d, gW.base.len, &gW.cam, t_now);

  // Draw Spawner
  DrawSpawners(dc, gW.grSpawner.len, gW.grSpawner.d);

  // Mobs
  DrawMobs(dc, gW.grMobs.len, gW.grMobs.d);

  // Restore DC
  dc->r=old_r;

  // Draw Lasers
  CD3I32 bc[3];
  dc->color = 1;
  Laser *laser = gW.lasers.d;
  for (i=0; i<gW.lasers.len; i++) {
    bc[0].x = SCX;
    bc[0].y = SCY;
    bc[0].z = 0;
    bc[2].x = (laser[i].cx-gW.cam.pos.x)*gW.cam.zoom+SCX;
    bc[2].y = (laser[i].cy-gW.cam.pos.y)*gW.cam.zoom+SCY;
    bc[2].z = 0;
    bc[1].x = bc[0].x + (bc[2].x - bc[0].x) + Sin(t_now+i/pi)*16;
    bc[1].y = bc[0].y + (bc[2].y - bc[0].y) + Cos(t_now+i/pi)*16;
    bc[1].z = 0;
    Gr2BezierF(dc, bc);
    dc->color++;
    if (dc->color >= 16)
      dc->color = 1;
  }

  // Draw Escape Zone
  if (gW.escapePhase) {
    dc->r = gW.escapeMat;
    dc->r_norm = gW.escapeNorm;
    CColorROPU32 color = GREEN;
    color.c0.rop |= ROPBF_TWO_SIDED;
    GrRect3L(dc, -128, -128, 0, 256, 256, color);
  }

  // Draw God Words
  dc->color = WHITE;
  CD2 bp1, bp2, bp3;
  bp1.x = gW.cam.pos.x-64;
  bp1.y = gW.cam.pos.y+240/gW.cam.zoom;
  bp2.x = gW.cam.pos.x-64;
  bp2.y = gW.cam.pos.y+240/gW.cam.zoom;
  bp3.x = gW.cam.pos.x;
  bp3.y = gW.cam.pos.y-240/gW.cam.zoom;
  for (i=0; i<gW.godWords.len; i++) {
    GWord* gword = &gW.godWords.d(GWord*)[i];
    CD2 dpos,p1,p2,p3;
    CD3I64 fpos;
    p1.x = bp1.x;
    p1.y = bp1.y;
    p2.x = bp2.x;
    p2.y = bp2.y;
    p3.x = bp3.x;
    p3.y = bp3.y;
    GetPosOnCurve2(&gword->pos, &p1, &p2, &p3, gword->ttl/4, &dpos);
    fpos.x = (dpos.x - gW.cam.pos.x)*gW.cam.zoom;
    fpos.y = (dpos.y - gW.cam.pos.y)*gW.cam.zoom;
    fpos.z = 0;
    (*dc->transform)(dc,&fpos.x,&fpos.y,&fpos.z);
    GrPutS(dc, fpos.x, fpos.y, gword->str);
  }

  // End 3D
  dc->x = 0;
  dc->y = 0;
  dc->flags &= ~DCF_TRANSFORMATION;

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
  gy += FONT_HEIGHT;
  GrPutS(dc, gx, gy, gW.gtext.walletStr);

  // Draw Health Bar
  dc->color = WHITE;
  DrawRecBorder(dc, HEALTH_X, 0, HEALTH_W, HEALTH_H);
  F64 hpPer = gW.player.health / 100.0;
  I64 wPer = (HEALTH_W-1) * hpPer;
  dc->color = RED;
  GrRect(dc, HEALTH_X+1, 1, wPer, HEALTH_H-1);
  dc->color = BLACK;
  I64 hx = HEALTH_X+1 + wPer;
  I64 hw = HEALTH_W-1 - wPer;
  GrRect(dc, hx, 1, hw, HEALTH_H-1);

  // Draw Map Background
  DrawRecBorder(dc, 0, 0, MAP_W, MAP_H);

  I64 cx = gW.player.pos.x;
  I64 cy = gW.player.pos.y;
  I64 mx, my, mx2, my2;
  // Draw Map Escape Zone
  if (gW.escapePhase) {
    mx = (0-cx)/64+MAP_W/2+2; // offset by 2, we need to correct others
    my = (0-cy)/64+MAP_H/2-6;
    if (CheckICollisionPoint(0, 0, MAP_W, MAP_H, mx, my)) {
      GrRect3(dc, mx-4, my-4, 0, 4, 4);
    }
  }

  // Draw Map Player
  dc->color = GREEN;
  GrPlot0F(dc, MAP_W/2, MAP_H/2);
  GrPlot0F(dc, MAP_W/2+1, MAP_H/2);
  GrPlot0F(dc, MAP_W/2-1, MAP_H/2);
  GrPlot0F(dc, MAP_W/2, MAP_H/2+1);
  GrPlot0F(dc, MAP_W/2, MAP_H/2-1);

  // Draw Map Pings
  MapPing *ping = gW.mapPings.d;
  for (i=0; i<gW.mapPings.len; i++) {
    mx = (ping[i].pos.x-cx)/64+MAP_W/2;
    if (mx > 0 && mx < MAP_W) {
      my = (ping[i].pos.y-cy)/64+MAP_H/2;
      if (my > task->pix_top && my < MAP_H + task->pix_top) {
       dc->color = ping[i].color;
       for (ii=0; ii<8; ii++) {
         GrCircle(dc, mx, my, (2.0+ii)*ping[i].ttl);
       }
       //GrCircle(dc, mx, my, 16, 1, ping[i].ttl/PING_EXPIRE*pi, pi*2*0.9);
      }
    }
  }

  // Draw Map Walls
  Vec4 mapBounds;
  CD2 mapPoint1, mapPoint2;
  mapBounds.x1 = 0;
  mapBounds.y1 = 0;
  mapBounds.x2 = MAP_W;
  mapBounds.y2 = MAP_H;
  dc->color = YELLOW;
  Wall *gwall = gW.walls.d;
  for (i=0; i<gW.walls.len; i++) {
    mx = (gwall[i].l.x1-cx)/64+MAP_W/2;
    mx2 = (gwall[i].l.x2-cx)/64+MAP_W/2;
    my = (gwall[i].l.y1-cy)/64+MAP_H/2-8;
    my2 = (gwall[i].l.y2-cy)/64+MAP_H/2-8;
    mapPoint1.x = mx;
    mapPoint1.y = my;
    mapPoint2.x = mx2;
    mapPoint2.y = my2;
    if (CheckCollisionPoint(&mapBounds, &mapPoint1) ||
        CheckCollisionPoint(&mapBounds, &mapPoint2))
      GrLine3(dc, mx, my, 0, mx2, my2, 0);
  }
  // Draw Map Mobs
  dc->color = LTRED;
  for (i=0; i<gW.mobs.len; i++) {
    mx = (gW.mobs.d(Mob*)[i].pos.x-cx)/64+MAP_W/2;
    if (mx > 0 && mx < MAP_W) {
      my = (gW.mobs.d(Mob*)[i].pos.y-cy)/64+MAP_H/2;
      if (my > task->pix_top && my < MAP_H + task->pix_top)
        GrPlot0F(dc, mx, my);
    }
  }
  // Draw Map Turrets
  dc->color = RED;
  for (i=0; i<gW.turrets.len; i++) {
    mx = (gW.turrets.d(Turret*)[i].pos.x-cx)/64+MAP_W/2;
    if (mx > 0 && mx < MAP_W) {
      my = (gW.turrets.d(Turret*)[i].pos.y-cy)/64+MAP_H/2;
      if (my > task->pix_top && my < MAP_H + task->pix_top) {
        GrPlot0F(dc, mx, my);
        GrPlot0F(dc, mx-1, my);
        GrPlot0F(dc, mx+1, my);
        GrPlot0F(dc, mx, my-1);
        GrPlot0F(dc, mx, my+1);
      }
    }
  }
  // Draw Map Spawners
  dc->color = PURPLE;
  for (i=0; i<gW.spawner.len; i++) {
    mx = (gW.spawner.d(SBase*)[i].pos.x-cx)/64+MAP_W/2;
    if (mx > 0 && mx < MAP_W) {
      my = (gW.spawner.d(SBase*)[i].pos.y-cy)/64+MAP_H/2;
      if (my > task->pix_top && my < MAP_H + task->pix_top) {
        GrPlot0F(dc, mx, my);
        GrPlot0F(dc, mx-1, my);
        GrPlot0F(dc, mx+1, my);
        GrPlot0F(dc, mx, my-1);
        GrPlot0F(dc, mx, my+1);
      }
    }
  }
  // Draw Map Bases
  dc->color = WHITE;
  for (i=0; i<gW.base.len; i++) {
    mx = (gW.base.d(SBase*)[i].pos.x-cx)/64+MAP_W/2;
    if (mx > 0 && mx < MAP_W) {
      my = (gW.base.d(SBase*)[i].pos.y-cy)/64+MAP_H/2;
      if (my > task->pix_top && my < MAP_H + task->pix_top) {
        GrPlot0F(dc, mx, my);
        GrPlot0F(dc, mx-1, my);
        GrPlot0F(dc, mx+1, my);
        GrPlot0F(dc, mx, my-1);
        GrPlot0F(dc, mx, my+1);
      }
    }
  }

#ifdef DEBUG
  // Draw Debug Data
  dc->color = WHITE;
  GrPrint(dc, 2, 100,
   "Score: %d\nWave: %d\nMobsLeft: %d\nX: %f Y: %f\nVX: %f VY: %f\nCam: %fx%f\nMouse: %dx%d\nDC: %dx%d",
   score, gW.spawnWave, gW.spawnedMobsLeft, gW.player.pos.x, gW.player.pos.y,
   gW.player.vel.x, gW.player.vel.y, gW.cam.pos.x, gW.cam.pos.y,
   ms.pos.x - task->pix_width/2 - task->pix_left,
   ms.pos.y - task->pix_height/2 - task->pix_top,
   task->pix_left + task->pix_width/2, task->pix_top + task->pix_height/2);
#endif

  // Enter 3D Again
  dc->x = SCX;
  dc->y = SCY;
  dc->flags |= DCF_TRANSFORMATION;

  // Draw Waypoint
  dc->color = YELLOW;
  dc->r = gW.waypointMat;
  dc->r_norm = Sqrt(Mat4x4NormSqr65536(gW.waypointMat))*65536;
  for (i=0; i<ArrowL_cnt; i+=2)
    GrLine3F(dc, ArrowL[i].x, ArrowL[i].y, ArrowL[i].z, ArrowL[i+1].x, ArrowL[i+1].y, ArrowL[i+1].z);

  // Restore DC
  dc->x = 0;
  dc->y = 0;
  dc->r=old_r;
  dc->flags &= ~DCF_TRANSFORMATION;

  // Draw Cursor
  if (firing)
    dc->color = LTRED; // we're already set to white
  I64 x=ms.pos.x;
  bc[0].x = x - 16;
  I64 y=ms.pos.y;
  bc[0].y = y;
  bc[0].z = 0;
  if (jitter_ttl > 0) {
    bc[1].x = x+(RandI64%16)*jitter_ttl;
    bc[1].y = y+(RandI64%16)*jitter_ttl;
  } else {
    bc[1].x = x;
    bc[1].y = y;
  }
  bc[1].z = 0;
  bc[2].x = x + 16;
  bc[2].y = y;
  bc[2].z = 0;
  Gr2BezierF(dc, bc);
  bc[0].x = x;
  bc[0].y = y - 16;
  if (jitter_ttl > 0) {
    bc[1].x = x+(RandI64%16)*jitter_ttl;
    bc[1].y = y+(RandI64%16)*jitter_ttl;
  } else {
    bc[1].x = x;
    bc[1].y = y;
  }
  bc[2].x = x;
  bc[2].y = y + 16;
  Gr2BezierF(dc, bc);

  // Draw Popup Message
  if (popup_ttl > 0.0) {
    dc->dither_probability_u16=13000;

    for (i=0; i<POPUP_CNT; i++) {
      if (popupStr[i][0] == '\0')
        break;

      I64 popupW = FONT_WIDTH*StrLen(popupStr[i]);
      I64 popupX = SCX-popupW/2;
      I64 popupY = FONT_HEIGHT*10 + FONT_HEIGHT*i*2;
      dc->color=ROPF_PROBABILITY_DITHER+LTGRAY<<16+BLACK;
      GrRect(dc, popupX-2, popupY-2, popupW+4, FONT_HEIGHT+4);
      dc->color = WHITE;
      GrPutS(dc, popupX, popupY, popupStr[i]);
    }
    popup_ttl -= t_delta;
  }

  if (gW.dead) {
    GrPutS(dc,320-FONT_WIDTH*4, 240-FONT_HEIGHT,"Game Over");
    GrPutS(dc,320-FONT_WIDTH*11, 240+FONT_HEIGHT,"Press Enter to Restart");
  }
  DCDel(dc);
}

U0 Task1(JobData *d) {
  World *w = d->w;
  // Process God Words
  ProcessGodWords(&w->godWords, d->delta);

  // Process Debris
  DebrisMat(w->debris.len, w->debris.d, w->grDebris.d, &w->cam, d->delta);

  GenMatShip(&d->w->player, jitter_ttl, &gW.cam, gW.pMat, gW.pTris, &gW.pTf, d->mx, d->my);
}

U0 Task2(JobData *d) {
  World *w = d->w;
  GenMatBullets(w->bullets.len, w->bullets.d, &w->grBullets, &w->cam, t_now);
  GenMatMobs(w->mobs.d, w->mobs.len, &d->w->grMobs, &w->cam);
}

U0 Task3(JobData *d) {
  World *w = d->w;
  GenMatBullets(w->bulletM.len, w->bulletM.d, &w->grBulletsM, &w->cam, t_now);
}

public U0 ProcessKill(CD3 *pos) {
  AddGodWord(&gW.godWords, pos, &gW.gtext);
  if (UpdateLaserUpgrade(&gW.player, gW.gtext.godWallet)) {
    SetSnd(SND_UPGRADE);
    InitPopup;
    StrPrint(popupStr[0], "Laser Range Upgrade! %d", gW.player.laserRange);
    StrPrint(popupStr[1], "Bullet Damage Upgrade! %d", gW.player.bulletDmg);
    StrPrint(popupStr[2], "Bullet Cooldown Upgrade! %.2f", gW.player.bulletCooldown);
    StrPrint(popupStr[3], "Bullet Speed Upgrade! %f", gW.player.bulletSpeed);
    if (gW.activeWeapon == WEAPON_SHOT) {
      gW.activeWeaponTTL = gW.player.bulletCooldown;
    }
  }
}

U0 UpdateGame(F64 delta) {
  I64 i, ii, len;
  CD3 vel;
  CJob *jobs[3];

  if (test_flag) {
    gW.player.health = 0;
  }

  if (gW.spawnedMobsLeft <= 0) {
    SpawnWave();
  }

  // Expiration
  ExpireDebris(&gW, delta);

  // Mob Death
  for (i=0; i<gW.mobs.len && gW.mobs.len>0; i++) {
    if (gW.mobs.d(Mob*)[i].health <= 0) {
      vel.x = Cos(gW.mobs.d(Mob*)[i].lastHitRot)*400;
      vel.y = Sin(gW.mobs.d(Mob*)[i].lastHitRot)*400;
      vel.z = 0;
      ProcessKill(&gW.mobs.d(Mob*)[i].pos);
      // Add Debris
      AddDebris(&gW, &gW.mobs.d(Mob*)[i].pos, &vel, &MobObjT, MobObjT_tris);
      // Cleanups
      VectorDel(&gW.mobs, i);
      VectorSetLen(&gW.cMobs, gW.mobs.len);
      i--;
      score++;
      gW.spawnedMobsLeft--;
    }
  }

  // Wall Death
  Wall* wall = gW.walls.d;
  for (i=0; i<gW.walls.len && gW.walls.len>0; i++) {
    if (wall[i].health <= 0) {
      vel.x = Cos(wall[i].lastHitRot)*400;
      vel.y = Sin(wall[i].lastHitRot)*400;
      vel.z = 0;
      // Add Debris
      //AddDebris(&gW, &gW.mobs.d(Mob*)[i].pos, &vel, &MobObjT, MobObjT_tris);
      // Cleanups
      VectorDel(&gW.walls, i);
      i--;
      score++;
    }
  }

  // Base Death
  ExpireBases(&gW);
  if (gW.base.len <= 0 && !gW.escapePhase) {
    playSnd = SND_BASE_DESTROYED;
    gW.escapePhase = TRUE;
    InitPopup;
    StrCpy(popupStr[0], "Get to the Escape Zone");
  }

  // Turret Death
  Turret *turret = gW.turrets.d;
  for (i=0; i<gW.turrets.len && gW.turrets.len>0; i++) {
    if (turret[i].health <= 0) {
      vel.x = Cos(turret[i].lastHitRot)*400;
      vel.y = Sin(turret[i].lastHitRot)*400;
      vel.z = 0;
      // Add Debris
      AddDebris(&gW, &turret[i].pos, &vel, &TurretT, TurretT_tris);
      // Cleanups
      VectorDel(&gW.turrets, i);
      i--;
      score++;
      // Regenerate Turret Colliders
      VectorSetLen(&gW.cTur, gW.turrets.len);
      GenCTur(gW.turrets.d, gW.turrets.len, gW.cTur.d);
    }
  }

  // Spawner Death
  ExpireSpawner(&gW);

  // Process Spawners
  SBase *spawn = gW.spawner.d;
  for (i=0; i<gW.spawner.len; i++) {
    spawn[i].spawn_ttl -= delta;
    if (spawn[i].spawn_ttl <= 0) {
      spawn[i].spawn_ttl = BASE_SPAWN_TTL;
      AddMob(&gW.mobs, &gW.cMobs, spawn[i].pos.x, spawn[i].pos.y);
      AddParticle(&gW.spawnFX, spawn[i].pos.x, spawn[i].pos.y);
    }
  }

  // Process Base Spawns
  SBase *base = gW.base.d;
  for (i=0; i<gW.base.len; i++) {
    base[i].spawn_ttl -= delta;
    if (base[i].spawn_ttl <= 0) {
      base[i].spawn_ttl = BASE_SPAWN_TTL;
      AddMob(&gW.mobs, &gW.cMobs, base[i].pos.x, base[i].pos.y);
    }
  }

  // Process Player
  if (!gW.dead) {
    if (gW.player.health <= 0) {
      gW.dead = TRUE;
      death_ttl = 0.0;
      // Add Debris
      vel.x = 0;
      vel.y = 0;
      vel.z = 0;
      AddDebris(&gW, &gW.player.pos, &vel, &MobObjT, MobObjT_tris);
    } else {
      // Process Player Movement
      if (cVel.x != 0.0) {
        gW.player.accel.x += cVel.x * 20 * delta;
        gW.player.accel.x = Clamp(gW.player.accel.x, -1, 1);
        gW.player.vel.x += cVel.x * SHIP_VEL_MAX * delta;
        gW.player.vel.x = Clamp(gW.player.vel.x, SHIP_VEL_MIN, SHIP_VEL_MAX);
      } else { // X Friction
        gW.player.accel.x *= 1.0 - 1.0 * (20*delta);
        gW.player.vel.x *= 1.0 - 1.0 * delta;
      }
      if (cVel.y != 0.0) {
        gW.player.accel.y += cVel.y * 20 * delta;
        gW.player.accel.y = Clamp(gW.player.accel.y, -1, 1);
        gW.player.vel.y += cVel.y * SHIP_VEL_MAX * delta;
        gW.player.vel.y = Clamp(gW.player.vel.y, SHIP_VEL_MIN, SHIP_VEL_MAX);
      } else { // Y Friction
        gW.player.accel.y *= 1.0 - 1.0 * (20*delta);
        gW.player.vel.y *= 1.0 - 1.0 * delta;
      }
      gW.player.pos.x += gW.player.vel.x * delta;
      gW.player.pos.y += gW.player.vel.y * delta;

      // Check Escape Zone
      Vec4 escapeAABB;
      escapeAABB.x1 = -128;
      escapeAABB.y1 = -128;
      escapeAABB.x2 = 128;
      escapeAABB.y2 = 128;
      if (gW.escapePhase && !gW.levelTransition && CheckCollisionPoint(&escapeAABB, &gW.player.pos)) {
        InitNextLevel;
      }
    }
  } else {
    death_ttl += delta;
  }

  gW.cam.pos.x = gW.player.pos.x;
  gW.cam.pos.y = gW.player.pos.y;

  // Start Task1
  JobData jobD;
  jobD.w = &gW;
  jobD.delta = delta;
  F64 mx=ms.pos.x-SCX;
  jobD.mx = ms.pos.x;
  F64 my=ms.pos.y-SCY;
  jobD.my = ms.pos.y;
#if mp_cnt > 1
  jobs[0]=JobQue(&Task1,&jobD,1,1);
#else
  Task1(&jobD);
#endif

  // Process Mob AI
  for (i=0; i<gW.mobs.len; i++)
    MobAI(&gW.mobs.d(Mob*)[i], i);

  // Process Turret AI
  TurAI(gW.turrets.d, gW.turrets.len, delta);

  // Process Walls
  Vec4 aabb1, aabbP;
  GetAABBFromSize(&gW.player.pos, &gW.player.size, &aabbP);
  CD2 intersection[4];
  wall = gW.walls.d;
  for (i=0; i<gW.walls.len; i++) {
    CheckCollisionLineRec(&wall[i].l, &aabbP, intersection);
    for (ii=0; ii<4; ii++) {
      if (intersection[ii].x != NO_COLLIDE || intersection[ii].y != NO_COLLIDE) {
        DmgPlayer(20*delta);

        // Deflect Velocity
        F64 wNorm;
        // Get the normal of the wall
        if (wall[i].l.x1 < wall[i].l.x2) {
          wNorm = (pi/2);
        } else {
          wNorm = -(pi/2);
        }

        // Get Center of Wall
        F64 wAvgX = wall[i].l.x2 - wall[i].l.x1;
        F64 wAvgY = wall[i].l.y2 - wall[i].l.y1;

        // Imply the origin of collision from player velocity
        F64 wAng = Arg(wAvgX, wAvgY);
        F64 pAng = Arg(-gW.player.vel.x, -gW.player.vel.y);

        // How much has the player crossed the line?
        F64 xC = (Abs(gW.player.pos.x - intersection[ii].x) + 1)*64*(Abs(gW.player.vel.x)/SHIP_VEL_MAX);
        F64 yC = (Abs(gW.player.pos.y - intersection[ii].y) + 1)*64*(Abs(gW.player.vel.y)/SHIP_VEL_MAX);

        // Check if we need to flip axis
        if (pAng >= 0) {
          gW.player.vel.x = Cos(wAng+wNorm)*xC;
          gW.player.vel.y = Sin(wAng+wNorm)*yC;
        } else {
          gW.player.vel.x = Clamp(Cos(wAng+wNorm+pi)*xC, SHIP_VEL_MIN, SHIP_VEL_MAX);
          gW.player.vel.y = Clamp(Sin(wAng+wNorm+pi)*yC, SHIP_VEL_MIN, SHIP_VEL_MAX);
        }
      }
    }
  }

#ifdef DEBUG
  // TMP Spawn Mob
  if (ms.rb)
    AddMob(&gW.mobs, &gW.cMobs, RandI64() % 500.0, RandI64() % 340.0);
#endif

  // Update Timers
  blur_ttl -= delta;
  jitter_ttl -= delta;
  firing_ttl -= delta;

  // Fire
  F64 dist;
  if (firing && firing_ttl <= 0.0 && !gW.dead) {
    SetSnd(SND_LASER);
    jitter_ttl = 1.0;
    firing_ttl = gW.activeWeaponTTL;

    switch (gW.activeWeapon) {
      case WEAPON_SHOT:
        AddBullet(gW.player.pos.x, gW.player.pos.y, mx, my, &gW.bullets, gW.player.bulletSpeed);
        break;
      case WEAPON_LASER:
        Laser laser;
        laser.x1 = gW.player.pos.x;
        laser.y1 = gW.player.pos.y;
        F64 dx = mx/gW.cam.zoom;
        laser.x2 = gW.player.pos.x + dx;
        F64 dy = my/gW.cam.zoom;
        laser.y2 = gW.player.pos.y + dy;
        F64 laserAng = Arg(dx, dy);
        F64 clampx = Cos(laserAng)*gW.player.laserRange;
        if (Abs(dx) > Abs(clampx))
          laser.x2 = clampx + gW.player.pos.x;
        F64 clampy = Sin(laserAng)*gW.player.laserRange;
        if (Abs(dy) > Abs(clampy))
          laser.y2 = clampy + gW.player.pos.y;
        laser.ttl = 0.5;
        VectorAdd(&gW.lasers, &laser);
    }
  }

  GenCMobs(gW.mobs.d, gW.mobs.len, gW.cMobs.d);

  // Process Lasers
  for (i=0; i<gW.lasers.len; i++) {
    I64 ci = 0;
    CD2I32 cmeta;
    Vec4 line;
    gW.collide.len = 0;
    gW.collideMeta.len = 0;
    line.x1 = gW.lasers.d(Laser*)[i].x1;
    line.y1 = gW.lasers.d(Laser*)[i].y1;
    line.x2 = gW.lasers.d(Laser*)[i].x2;
    line.y2 = gW.lasers.d(Laser*)[i].y2;
    // Check Mobs
    for (ii=0; ii<gW.mobs.len; ii++) {
      VectorInc(&gW.collide, 4);
      CheckCollisionLineRec(&line, &gW.cMobs.d(Vec4*)[ii], &gW.collide.d(CD2*)[ci]);
      VectorInc(&gW.collideMeta, 4);
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_MOB;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_MOB;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_MOB;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_MOB;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
    }
    // Check Walls
    for (ii=0; ii<gW.walls.len; ii++) {
      // check twice for two-way collision on walls
      VectorInc(&gW.collide, 2);
      CheckCollisionLines(&line, &gW.walls.d(Wall*)[ii].l, &gW.collide.d(CD2*)[ci++]);
      CheckCollisionLines(&gW.walls.d(Wall*)[ii].l, &line, &gW.collide.d(CD2*)[ci++]);
      cmeta.x = TYPE_WALL;
      cmeta.y = ii;
      VectorAdd(&gW.collideMeta, &cmeta);
      VectorAdd(&gW.collideMeta, &cmeta);
    }
    // Check Turrets
    for (ii=0; ii<gW.cTur.len; ii++) {
      VectorInc(&gW.collide, 4);
      CheckCollisionLineRec(&line, &gW.cTur.d(Vec4*)[ii], &gW.collide.d(CD2*)[ci]);
      VectorInc(&gW.collideMeta, 4);
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_TUR;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_TUR;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_TUR;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_TUR;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
    }
    // Check Spawners
    for (ii=0; ii<gW.cSpawner.len; ii++) {
      VectorInc(&gW.collide, 4);
      CheckCollisionLineRec(&line, &gW.cSpawner.d(Vec4*)[ii], &gW.collide.d(CD2*)[ci]);
      VectorInc(&gW.collideMeta, 4);
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_SPAWNER;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_SPAWNER;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_SPAWNER;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_SPAWNER;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
    }
    // Check Bases
    for (ii=0; ii<gW.base.len; ii++) {
      VectorInc(&gW.collide, 4);
      CheckCollisionLineRec(&line, &gW.cBase.d(Vec4*)[ii], &gW.collide.d(CD2*)[ci]);
      VectorInc(&gW.collideMeta, 4);
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_BASE;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_BASE;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_BASE;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
      gW.collideMeta.d(CD2I32*)[ci].x = TYPE_BASE;
      gW.collideMeta.d(CD2I32*)[ci++].y = ii;
    }
    // Find Closest Collision
    ci = -1;
    F64 cdist = NO_COLLIDE;
    for (ii=0; ii<gW.collide.len; ii++) {
      if (gW.collide.d(CD2*)[ii].x != NO_COLLIDE) {
        dist = Abs(gW.collide.d(CD2*)[ii].x - gW.lasers.d(Laser*)[i].x1
          + (gW.collide.d(CD2*)[ii].y - gW.lasers.d(Laser*)[i].y1));
        if (dist < cdist) {
          cdist = dist;
          ci = ii;
        }
      }
    }
    if (ci >= 0) {
      SetSnd(SND_HIT);
      I32 id = gW.collideMeta.d(CD2I32*)[ci].y;
      switch (gW.collideMeta.d(CD2I32*)[ci].x) {
        case TYPE_MOB:
          DmgMob(&gW.mobs.d(Mob*)[id], LASER_DMG*delta, line.x1, line.y1);
          break;
        case TYPE_WALL:
          DmgWall(&gW.walls.d(Wall*)[id], LASER_DMG*delta,
          Arg(gW.collide.d(CD2*)[ci].x-line.x1, gW.collide.d(CD2*)[ci].y-line.y1));
          break;
        case TYPE_TUR:
          DmgTur(&gW.turrets.d(Turret*)[id], LASER_DMG*delta,
          Arg(gW.collide.d(CD2*)[ci].x-line.x1, gW.collide.d(CD2*)[ci].y-line.y1));
          break;
        case TYPE_SPAWNER:
          DmgBase(&gW.spawner.d(SBase*)[id], LASER_DMG*delta);
          break;
        case TYPE_BASE:
          DmgBase(&gW.base.d(SBase*)[id], LASER_DMG*delta);
          break;
        default:
          Beep;
      }
      AddParticle(&gW.explosion, gW.collide.d(CD2*)[ci].x, gW.collide.d(CD2*)[ci].y);
      gW.lasers.d(Laser*)[i].cx = gW.collide.d(CD2*)[ci].x;
      gW.lasers.d(Laser*)[i].cy = gW.collide.d(CD2*)[ci].y;
    } else {
      gW.lasers.d(Laser*)[i].cx = gW.lasers.d(Laser*)[i].x2;
      gW.lasers.d(Laser*)[i].cy = gW.lasers.d(Laser*)[i].y2;
    }
  }

  // Process Mob Movement
  for (i=0; i<gW.mobs.len; i++) {
    gW.mobs.d(Mob*)[i].pos.x += gW.mobs.d(Mob*)[i].vel.x * delta;
    gW.mobs.d(Mob*)[i].pos.y += gW.mobs.d(Mob*)[i].vel.y * delta;
  }

  // Process Bullets
  len = gW.bullets.len;
  Bullet *pb = gW.bullets.d;
  for (i=0; i<len && len>0; i++) {
    pb[i].ttl += delta;
    if (pb[i].ttl >= BULLET_EXPIRE) {
      VectorDel(&gW.bullets, i);
      VectorSetLen(&gW.grBullets, gW.bullets.len);
      i--;
      len--;
    } else {
      pb[i].pos.x += pb[i].vel.x * delta;
      pb[i].pos.y += pb[i].vel.y * delta;
      GetAABBFromSize(&pb[i].pos, &pb[i].size, &aabb1);
      // Check Mobs
      for (ii=0; ii<gW.cMobs.len; ii++) {
        if (CheckCollisionAABB(&aabb1, &gW.cMobs.d(Vec4*)[ii])) {
          SetSnd(SND_HIT);
          F64 dmgrot = Arg(pb[i].vel.x, pb[i].vel.y);
          DmgMobRot(&gW.mobs.d(Mob*)[ii], gW.player.bulletDmg, dmgrot);
          AddParticle(&gW.explosion, gW.mobs.d(Mob*)[ii].pos.x, gW.mobs.d(Mob*)[ii].pos.y);
          VectorDel(&gW.bullets, i);
          VectorSetLen(&gW.grBullets, gW.bullets.len);
          i--;
          len--;
          goto found_collision;
        }
      }
      // Check Turrets
      for (ii=0; ii<gW.cTur.len; ii++) {
        if (CheckCollisionAABB(&aabb1, &gW.cTur.d(Vec4*)[ii])) {
          SetSnd(SND_HIT);
          DmgTur(&gW.turrets.d(Turret*)[ii], gW.player.bulletDmg, Arg(pb[i].vel.x, pb[i].vel.y));
          AddParticle(&gW.explosion, gW.turrets.d(Turret*)[ii].pos.x, gW.turrets.d(Turret*)[ii].pos.y);
          VectorDel(&gW.bullets, i);
          VectorSetLen(&gW.grBullets, gW.bullets.len);
          i--;
          len--;
          goto found_collision;
        }
      }
      // Check Spawners
      for (ii=0; ii<gW.cSpawner.len; ii++) {
        if (CheckCollisionAABB(&aabb1, &gW.cSpawner.d(Vec4*)[ii])) {
          SetSnd(SND_HIT);
          DmgBase(&gW.spawner.d(SBase*)[ii], gW.player.bulletDmg);
          AddParticle(&gW.explosion, gW.spawner.d(SBase*)[ii].pos.x, gW.spawner.d(Turret*)[ii].pos.y);
          VectorDel(&gW.bullets, i);
          VectorSetLen(&gW.grBullets, gW.bullets.len);
          i--;
          len--;
          goto found_collision;
        }
      }
      // Check Bases
      for (ii=0; ii<gW.cBase.len; ii++) {
        if (CheckCollisionAABB(&aabb1, &gW.cBase.d(Vec4*)[ii])) {
          SetSnd(SND_HIT);
          DmgBase(&gW.base.d(SBase*)[ii], gW.player.bulletDmg);
          AddParticle(&gW.explosion, gW.base.d(SBase*)[ii].pos.x, gW.base.d(SBase*)[ii].pos.y);
          VectorDel(&gW.bullets, i);
          VectorSetLen(&gW.grBullets, gW.bullets.len);
          i--;
          len--;
          goto found_collision;
        }
      }
      // Check Walls
      // turn the projectile into a line for collision
      Vec4 bLine;
      F64 bdelta = 2.0*(1.0+delta);
      F64 bx = Cos(pb[i].ry) * pb[i].size.x * bdelta;
      bLine.x1 = pb[i].pos.x + -bx;
      bLine.x2 = pb[i].pos.x + bx;
      F64 by = Sin(pb[i].ry) * pb[i].size.y * bdelta;
      bLine.y1 = pb[i].pos.y + -by;
      bLine.y2 = pb[i].pos.y + by;
      for (ii=0; ii<gW.walls.len; ii++) {
        // check twice for two-way collision on walls
        CD2 collision;
        CheckCollisionLines(&bLine, &gW.walls.d(Wall*)[ii].l, &collision);
        if (collision.x != NO_COLLIDE) {
          SetSnd(SND_HIT);
          DmgWall(&gW.walls.d(Wall*)[ii], gW.player.bulletDmg, Arg(collision.x-line.x1, collision.y-line.y1));
          AddParticle(&gW.explosion, collision.x, collision.y);
          VectorDel(&gW.bullets, i);
          VectorSetLen(&gW.grBullets, gW.bullets.len);
          i--;
          len--;
          goto found_collision;
        }
        CheckCollisionLines(&gW.walls.d(Wall*)[ii].l, &bLine, &collision);
        if (collision.x != NO_COLLIDE) {
          SetSnd(SND_HIT);
          DmgWall(&gW.walls.d(Wall*)[ii], gW.player.bulletDmg, Arg(collision.x-line.x1, collision.y-line.y1));
          AddParticle(&gW.explosion, collision.x, collision.y);
          VectorDel(&gW.bullets, i);
          VectorSetLen(&gW.grBullets, gW.bullets.len);
          i--;
          len--;
          goto found_collision;
        }
      }
found_collision:
    }
  }

// Start Task2
#if mp_cnt == 1
  Task2(&jobD);
#else
  #if mp_cnt == 2
    jobs[1]=JobQue(&Task2,&jobD,1,0);
  #else
    jobs[1]=JobQue(&Task2,&jobD,2,0);
  #endif
#endif

  // Process Mob Bullets
  pb = gW.bulletM.d;
  len = gW.bulletM.len;
  for (i=0; i<len && len>0; i++) {
    if (pb[i].ttl >= BULLET_EXPIRE) {
      VectorDel(&gW.bulletM, i);
      VectorSetLen(&gW.grBulletsM, gW.bulletM.len);
      i--;
      len--;
    } else {
      pb[i].pos.x += pb[i].vel.x * delta;
      pb[i].pos.y += pb[i].vel.y * delta;
      GetAABBFromSize(&pb[i].pos, &pb[i].size, &aabb1);
      // Check Player Collision
      if (CheckCollisionAABB(&aabb1, &aabbP)) {
        AddParticle(&gW.explosion, gW.player.pos.x, gW.player.pos.y);
        DmgPlayer(BULLET_DMG);
        VectorDel(&gW.bulletM, i);
        VectorSetLen(&gW.grBulletsM, gW.bulletM.len);
        i--;
        len--;
      } else {
        // Check Base Collision
        /*base = gW.base.d;
        for (ii=0; ii<gW.base.len; ii++) {
          if (CheckCollisionAABB(&aabb1, &gW.cBase.d(Vec4*)[ii])) {
            AddParticle(&gW.explosion, base[ii].pos.x, base[ii].pos.y);
            gW.base.d(SBase*)[ii].health -= BULLET_DMG;
            VectorDel(&gW.bulletM, i);
            VectorSetLen(&gW.grBulletsM, gW.bulletM.len);
            i--;
            len--;
            break;
          }
        }*/
      }
    }
  }

// Start Task3
#if mp_cnt > 1
  jobs[2]=JobQue(&Task3,&jobD,1,0);
#else
  Task3(&jobD);
#endif

  // Generate Spawner Matrix
  GenMatSpawner(gW.spawner.d, gW.spawner.len, &gW.grSpawner, &gW.cam, t_now);

  // Process Level Transition
  if (gW.levelTransition) {
    gW.levelTransitionTTL += delta;
    if (gW.levelTransitionTTL >= LEVEL_TRANSITION_TTL) {
      gW.levelTransition = FALSE;
      InitLevel;
    }
  }

  // Process Waypoints
  Mat4x4IdentEqu(gW.waypointMat);
  ii = -1;
  dist = I64_MAX;
  if (gW.base.len > 0) { // Waypoint Enemy Base
    base = gW.base.d;
    for (i=0; i<gW.base.len; i++) {
      cdist = Abs(base[i].pos.x-gW.player.pos.x) + Abs(base[i].pos.y-gW.player.pos.y);
      if (cdist < dist) {
        dist = cdist;
        ii = i;
      }
    }
    if (ii >= 0) {
      dx = base[ii].pos.x-gW.player.pos.x;
      dy = base[ii].pos.y-gW.player.pos.y;
    }
  } else { // Waypoint Escape Zone
    dx = -gW.player.pos.x;
    dy = -gW.player.pos.y;
  }
  F64 waypointA = Arg(dx, dy);
  F64 wpx = Clamp(dx*gW.cam.zoom, -SCX+19, SCX-19);
  F64 wpy = Clamp(dy*gW.cam.zoom, -SCY+19, SCY-35); // why -35? just werx
  Mat4x4RotX(gW.waypointMat, t_now*8);
  Mat4x4RotZ(gW.waypointMat, waypointA);
  Mat4x4TranslationAdd(gW.waypointMat, wpx, wpy, 0);

  // Generate Turret Matrix
  GenMatTur(gW.turrets.d, gW.turrets.len, &gW.grTur, &gW.cam);

  // Animate Lasers
  for (i=0; i<gW.lasers.len && gW.lasers.len>0; i++) {
    gW.lasers.d(Laser*)[i].ttl -= delta;
    if (gW.lasers.d(Laser*)[i].ttl <= 0.0) {
      VectorDel(&gW.lasers, i);
      i--;
    }
  }

  // Expire Explosions
  Particle *exp = gW.explosion.d;
  for (i=0; i<gW.explosion.len && gW.explosion.len>0; i++) {
    exp[i].ttl += delta;
    if (exp[i].ttl >= EXP_EXPIRE)
      VectorDel(&gW.explosion, i--);
  }

  // Expire SpawnFX
  exp = gW.spawnFX.d;
  for (i=0; i<gW.spawnFX.len && gW.spawnFX.len>0; i++) {
    exp[i].ttl += delta;
    if (exp[i].ttl >= EXP_EXPIRE)
      VectorDel(&gW.spawnFX, i--);
  }

  // Process Map Pings
  MapPing *ping = gW.mapPings.d;
  for (i=0; i<gW.mapPings.len && gW.mapPings.len>0; i++) {
    ping[i].ttl += delta;
    if (ping[i].ttl >= PING_EXPIRE) {
      VectorDel(&gW.mapPings, i--);
    }
  }

  // Process Escape Zone
  if (gW.escapePhase) {
    Mat4x4IdentEqu(gW.escapeMat);
    Mat4x4RotX(gW.escapeMat, Sin(t_now)/2);
    Mat4x4RotY(gW.escapeMat, Cos(t_now)/2);
    Mat4x4TranslationAdd(gW.escapeMat, -gW.cam.pos.x, -gW.cam.pos.y, 512);
    Mat4x4Scale(gW.escapeMat, gW.cam.zoom);
    gW.escapeNorm = Sqrt(Mat4x4NormSqr65536(gW.escapeMat))*65536;
  }

#if mp_cnt > 1
  #ifdef DEBUG
    DocGoToLine(DocPut, 0); // put it where we can see it
    //EdLineDel(DocPut);
    F64 td;
    F64 pnow = tS;
  #endif
  while(!JobResScan(jobs[0])) {} // JobResGet yields, we don't want that
  #ifdef DEBUG
    td = (tS - pnow)*1000;
    if (td > 0.5)
      "Time1: %.1f\n", td;
    pnow = tS;
  #endif
  while(!JobResScan(jobs[1])) {}
  #ifdef DEBUG
    td = (tS - pnow)*1000;
    if (td > 0.5)
     "Time2: %.1f\n", td;
    pnow = tS;
  #endif
  while(!JobResScan(jobs[2])) {}
  #ifdef DEBUG
    td = (tS - pnow)*1000;
    if (td > 0.5)
      "Time3: %.1f\n", td;
  #endif
#endif
}

U0 Init() {
  Seed;
  InitSnd;
  quitGame = FALSE;
  gr.fp_draw_ms = NULL; // disable TempleOS cursor
  VectorInit(&gW.base, sizeof(SBase));
  VectorInit(&gW.spawner, sizeof(SBase));
  VectorInit(&gW.bullets, sizeof(Bullet));
  VectorInit(&gW.bulletM, sizeof(Bullet));
  VectorInit(&gW.mobs, sizeof(Mob));
  VectorInit(&gW.lasers, sizeof(Laser));
  VectorInit(&gW.godWords, sizeof(GWord));
  VectorInit(&gW.mapPings, sizeof(MapPing));
  VectorInit(&gW.turrets, sizeof(Turret));
  VectorInit(&gW.walls, sizeof(Wall));
  VectorInit(&gW.wallPosts, sizeof(WallPost));

  // Init Particle Buffers
  VectorInit(&gW.debris, sizeof(Debris));
  VectorInit(&gW.explosion, sizeof(Particle));
  VectorInit(&gW.spawnFX, sizeof(Particle));

  // Init Collision Buffers
  VectorInit(&gW.collide, sizeof(CD2));
  VectorInit(&gW.collideMeta, sizeof(CD2I32));
  VectorInit(&gW.cBase, sizeof(Vec4));
  VectorInit(&gW.cMobs, sizeof(Vec4));
  VectorInit(&gW.cSpawner, sizeof(Vec4));
  VectorInit(&gW.cTur, sizeof(Vec4));

  // Init Draw Buffers
  VectorInit(&gW.grBullets, sizeof(GrBuff));
  VectorInit(&gW.grBulletsM, sizeof(GrBuff));
  VectorInit(&gW.grDebris, sizeof(GrDebris));
  VectorInit(&gW.grMobs, sizeof(GrBuff));
  VectorInit(&gW.grSpawner, sizeof(GrBuff));
  VectorInit(&gW.grTur, sizeof(GrBuff));

  //StrPrint(scoreStr, "Score: %d", score);

  t_last = tS;
  gW.task = Fs;
}


U0 InitPlayfield() {
  lastWheel = ms.pos.z;
  score = 0;

  blur_ttl = 0;
  jitter_ttl = 0;
  t_delta = 0;
  InitPopup;
  popup_ttl = 0;

  // "Empty" arrays
  gW.godWords.len = 0;

  InitGText(&gW.gtext);
  Mat4x4IdentEqu(gW.waypointMat);

  gW.level = 1;
  gW.levelTransition = FALSE;

  InitLevel;
  UpdateLaserUpgrade(&gW.player, 0);
  gW.activeWeapon = WEAPON_SHOT;
  gW.activeWeaponTTL = gW.player.bulletCooldown;

  InitPopup;
  popup_ttl = 8;
  StrCpy(popupStr[0], "Destroy the Enemy Base");
  StrCpy(popupStr[1], "Move: WASD | Shoot: Left Mouse");
  StrCpy(popupStr[2], "Cannon: 1 | Laser: 2");
  StrCpy(popupStr[3], "Zoom: Mouse Wheel");
  StrCpy(popupStr[4], "KillSnd: M");

  gW.task->draw_it = &DrawPlayfield;
  ActiveInput = &PlayfieldInput;
  ActiveUpdate = &UpdateGame;
}

U0 QuitGame() {
  quitGame = TRUE;
}

U0 BlazeItFgt() {
  SettingsPush;
  Fs->text_attr=BLACK<<4+WHITE;
  MenuPush(
        "File {"
        "  Abort(,CH_SHIFT_ESC);"
        "  Exit(,CH_ESC);"
        "}"
        "Play {"
        "  Up(,'w');"
        "  Down(,'s');"
        "  Left(,'a');"
        "  Right(,'d');"
        "  Weapon1(,'1');"
        "  Weapon2(,'2');"
        "  KillSnd(,'m');"
        "}"
        );
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;
  GrPaletteSet(gr_palette_std);
  Fs->win_inhibit=WIG_TASK_DFT-WIF_SELF_FOCUS-WIF_SELF_BORDER-WIF_FOCUS_TASK_MENU;

  Init;
  InitTitle;

  sndJob = *Spawn(&SndTask,NULL,"Sound",mp_cnt-1,Fs);

  while (!quitGame) {
    t_now = tS;
    t_delta = t_now - t_last;
    t_last = t_now;
    (ActiveInput)();
    (ActiveUpdate)(t_delta);
    Refresh;
  }
  SetSnd(SND_QUIT);
  Sleep(33); // fix for sometimes DCFill not working? (called too early?)
  MenuPop;
  DocClear;
  SettingsPop;
  gr.fp_draw_ms=&DrawStdMs;
  DCFill;
}

#endif