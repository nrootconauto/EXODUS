#ifndef MOB_HC
#define MOB_HC

#include "Collision"
#include "Draw"
#include "Vector"
#include "World"
#include "Globals"
#include "Pickup"
#include "Debris"

#define MOB_HIT_TTL 1
#define MOB_HIT_COLOR_TTL 0.95
#define BOSS_DEAD_TTL 4
#define BOSS_INTRO_TTL 5

#define MOBFLAG_INVULN 1

public U0 DmgMob(Mob* mob, F64 dmg) {
  if (mob->flags&MOBFLAG_INVULN == 0) {
    mob->hit_ttl = MOB_HIT_TTL;
    mob->health -= dmg;
  }
}

public U0 GenMatMobs(Mob *mobs, I64 cnt, Vector *grMobs) {
  VectorSetLen(grMobs, cnt);
  VectorSetLen(&gW.grGuns, cnt); // make sure cap is high enough
  gW.grGuns.len = 0; // reset len
  GrBuff *grBuf = grMobs->d;
  GrBuff *grGuns = gW.grGuns.d;
  I64 i;
  for (i=0; i<cnt; i++, mobs++, grBuf++) {
    F64 vel = Abs(mobs->vel.x) + Abs(mobs->vel.y);
    F64 rva = Arg(mobs->vel.x, mobs->vel.y);

    F64 rvx = vel*Cos(rva);
    if (mobs->hit_ttl > 0) {
      F64 hit_ratio = mobs->hit_ttl/MOB_HIT_TTL;
      rvx += hit_ratio*(Cos(hit_ratio*pi*4)/2);
    }

    if (rvx > pi/4)
      rvx = pi/4;
    else if (rvx < -pi/4)
      rvx = -pi/4;

    F64 rvy = vel*Sin(rva);
    if (rvy > pi/4)
      rvy = pi/4;
    else if (rvy < -pi/4)
      rvy = -pi/4;

    Quat q;
    QuatFromEuler(&q, rvx, rvy, mobs->rot);
    QuatToMatrix(&q, grBuf->mat);
    Mat4x4TranslationAdd(grBuf->mat, mobs->pos.x, mobs->pos.y, 256);

    I64 x = mobs->offX;
    I64 y = mobs->offY;
    I64 *m = grBuf->mat;
    mobs->gunX = (m[0*4+0]*x+m[0*4+1]*y+m[0*4+3])>>32;
    mobs->gunY = (m[1*4+0]*x+m[1*4+1]*y+m[1*4+3])>>32;

    if (mobs->obj->gun.cnt > 0) {
      F64 rad = Arg(gW.player.pos.x-mobs->gunX, gW.player.pos.y-mobs->gunY);
      QuatFromEuler(&q, 0, 0, rad-mobs->rot);
      QuatToMatrix(&q, grGuns->mat);
      grGuns++;
      gW.grGuns.len++;
    }
  }
}

public U0 GenCMobs(Mob *mobs, I64 cnt, Vector *polys, Vector *polyIdx, GrBuff *mats) {
  polys->len = 0;
  polyIdx->len = 0;
  U32 cLineIdx = 0;
  I32 i, ii;
  for (i=0; i<cnt; i++, mobs++, mats++) {
    MobObj *obj = mobs->obj;
    I64 *m = mats->mat;
    for (ii=0; ii<obj->cCnt; ii++) {
      U32 lineCnt = obj->collider[ii]->cnt;
      CD3I32 *mLines = obj->collider[ii]->lines;
      cPolyMeta meta;
      meta.idx = cLineIdx;
      meta.cnt = lineCnt;
      meta.mIdx = i;
      meta.cIdx = ii;
      VectorAdd(polyIdx, &meta);
      VectorInc(polys, lineCnt);
      CD2I32 *cLines = polys->d;
      cLines += cLineIdx;
      cLineIdx += lineCnt;
      I64 cx=0, cy=0;
      I32 lx, ly;
      U32 li;
      for (li=0; li<lineCnt; li++, mLines++, cLines++) {
        I64 xx = mLines->x+mobs->offX;
        I64 yy = mLines->y+mobs->offY;
        I64 zz = mLines->z;
        lx = (m[0*4+0]*xx+m[0*4+1]*yy+m[0*4+2]*zz+m[0*4+3])>>32;
        ly = (m[1*4+0]*xx+m[1*4+1]*yy+m[1*4+2]*zz+m[1*4+3])>>32;
        cLines->x = lx;
        cLines->y = ly;
        cx += lx;
        cy += ly;
      }
      cx -= lx;
      cy -= ly;
      mobs->centroid[ii].x = cx / (lineCnt-1);
      mobs->centroid[ii].y = cy / (lineCnt-1);
    }
  }
}

public U0 DrawMobs(CDC *dc, Mob *mobs, I64 cnt, GrBuff *buf, I32 *db) {
  I64 i, ii, ic;
  I64 x1, y1, z1, x2, y2, z2;
  I64 xx, yy, zz, *r;
  GrBuff *mg = gW.grGuns.d;
  for (i=0; i<cnt; i++, mobs++) {
    dc->r = buf[i].mat;
    MobObj *obj = mobs->obj;
    I64 lineCnt = obj->model.cnt;
    U8 *colors = obj->model.colors;
    CD3I32 *lines = obj->model.lines;
    if (mobs->hit_ttl-MOB_HIT_COLOR_TTL > 0) {
      dc->color = WHITE;
      for (ii=0; ii<lineCnt; ii+=2)
        GrLine3F(dc, lines[ii].x+mobs->offX, lines[ii].y+mobs->offY, lines[ii].z,
                 lines[ii+1].x+mobs->offX, lines[ii+1].y+mobs->offY, lines[ii+1].z, db);

      lineCnt = obj->gun.cnt;
      if (lineCnt > 0) {
        r = mg->mat;
        mg++;
        lines = obj->gun.lines;
        for (ii=0, ic=0; ii<lineCnt; ii+=2, ic++) {
          xx = lines[ii].x;
          yy = lines[ii].y;
          zz = lines[ii].z;
          x1=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
          y1=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
          z1=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

          xx = lines[ii+1].x;
          yy = lines[ii+1].y;
          zz = lines[ii+1].z;
          x2=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
          y2=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
          z2=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

          GrLine3F(dc,x1+mobs->offX,y1+mobs->offY,z1,x2+mobs->offX,y2+mobs->offY,z2,db);
        }
      }
      if (obj->mesh.triCnt > 0) {
        dc->color=ROPF_PROBABILITY_DITHER+6<<16+WHITE;
        dc->dither_probability_u16=I16_MAX/2;
        DrawTriFillVM(dc, obj->mesh.tris, obj->mesh.triCnt, buf[i].mat, gDepthBuf);
      }
    } else {
      for (ii=0, ic=0; ii<lineCnt; ii+=2, ic++) {
        dc->color = colors[ic];
        GrLine3F(dc, lines[ii].x+mobs->offX, lines[ii].y+mobs->offY, lines[ii].z,
                 lines[ii+1].x+mobs->offX, lines[ii+1].y+mobs->offY, lines[ii+1].z, db);
      }
      lineCnt = obj->gun.cnt;
      if (lineCnt > 0) {
        r = mg->mat;
        mg++;
        colors = obj->gun.colors;
        lines = obj->gun.lines;
        for (ii=0, ic=0; ii<lineCnt; ii+=2, ic++) {
          dc->color = colors[ic];

          xx = lines[ii].x;
          yy = lines[ii].y;
          zz = lines[ii].z;
          x1=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
          y1=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
          z1=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

          xx = lines[ii+1].x;
          yy = lines[ii+1].y;
          zz = lines[ii+1].z;
          x2=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
          y2=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
          z2=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

          GrLine3F(dc,x1+mobs->offX,y1+mobs->offY,z1,x2+mobs->offX,y2+mobs->offY,z2,db);
        }
      }
      if (obj->mesh.triCnt > 0) {
        dc->color=ROPF_PROBABILITY_DITHER+12<<16+11;
        dc->dither_probability_u16=I16_MAX/2;
        DrawTriFillVM(dc, obj->mesh.tris, obj->mesh.triCnt, buf[i].mat, gDepthBuf);
      }
    }
  }
}

U0 Boss0Destroyed(Mob *mob) {
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r, mob->rot);
  I64 xx = -7;
  I64 yy = -54;
  I64 zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000, 4,0,0, 0,0,mob->rot, 1,pi/4,0, &gAssets.boss0DLeft, &gAssets.boss0DMeshLeft);

  xx = -7;
  yy = 54;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000, -4,0,0, 0,0,mob->rot, -1,pi/6,pi/8, &gAssets.boss0DRight, &gAssets.boss0DMeshRight);

  CD2 vel;
  vel.x = 0;
  vel.y = 0;
  ObjTris *objTris = mob->obj->debris;
  AddDebris(&gW, &mob->pos, &vel, &objTris->tris, objTris->cnt);
}

U0 Boss1Destroyed(Mob *mob) {
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r, mob->rot);

  I64 xx = 0;
  I64 yy = -75.5;
  I64 zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, 1,pi/4,0,
                &gAssets.boss1DLeft, &gAssets.boss1DMeshLeft);

  xx = 0;
  yy = 75.5;
  zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -1,pi/6,pi/8,
                &gAssets.boss1DRight, &gAssets.boss1DMeshRight);

  xx = 102;
  yy = 0;
  zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -1,pi/6,pi/8,
                &gAssets.boss1DFront, &gAssets.boss1DMeshFront);

  xx = -102;
  yy = 0;
  zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -1,pi/6,pi/8,
                &gAssets.boss1DRear, &gAssets.boss1DMeshRear);

  CD2 vel;
  vel.x = 0;
  vel.y = 0;
  ObjTris *objTris = mob->obj->debris;
  AddDebris(&gW, &mob->pos, &vel, &objTris->tris, objTris->cnt);
}

U0 Boss2Destroyed(Mob *mob) {
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r, mob->rot);

  I64 xx = -4;
  I64 yy = -40;
  I64 zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, 1,pi/4,0,
                &gAssets.boss2DLeft, &gAssets.boss2DMeshLeft);

  xx = -4;
  yy = 40;
  zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -1,pi/6,pi/8,
                &gAssets.boss2DRight, &gAssets.boss2DMeshRight);

  CD2 vel;
  vel.x = 0;
  vel.y = 0;
  ObjTris *objTris = mob->obj->debris;
  AddDebris(&gW, &mob->pos, &vel, &objTris->tris, objTris->cnt);
}

U0 Boss3Destroyed(Mob *mob) {
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r, mob->rot);

  I64 xx = 64;
  I64 yy = -62;
  I64 zz = 17;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -3,pi/4,0,
                &gAssets.boss3DLF, &gAssets.boss3DMeshLF);

  xx = 64;
  yy = 62;
  zz = 17;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -3,pi/6,pi/8,
                &gAssets.boss3DRF, &gAssets.boss3DMeshRF);

  CD2 vel;
  vel.x = 0;
  vel.y = 0;
  ObjTris *objTris = mob->obj->debris;
  AddDebris(&gW, &mob->pos, &vel, &objTris->tris, objTris->cnt);
}

U0 Boss4Destroyed(Mob *mob) {
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r, mob->rot);
  I64 xx = -7;
  I64 yy = -54;
  I64 zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000, 4,0,0, 0,0,mob->rot, 1,pi/4,0, &gAssets.boss4DLeft, &gAssets.boss0DMeshLeft);

  xx = -7;
  yy = 54;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000, -4,0,0, 0,0,mob->rot, -1,pi/6,pi/8, &gAssets.boss4DRight, &gAssets.boss0DMeshRight);

  CD2 vel;
  vel.x = 0;
  vel.y = 0;
  ObjTris *objTris = mob->obj->debris;
  AddDebris(&gW, &mob->pos, &vel, &objTris->tris, objTris->cnt);
}

U0 Boss5Destroyed(Mob *mob) {
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r, mob->rot);

  I64 xx = 0;
  I64 yy = -75.5;
  I64 zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, 1,pi/4,0,
                &gAssets.boss5DLeft, &gAssets.boss1DMeshLeft);

  xx = 0;
  yy = 75.5;
  zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -1,pi/6,pi/8,
                &gAssets.boss5DRight, &gAssets.boss1DMeshRight);

  xx = 102;
  yy = 0;
  zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -1,pi/6,pi/8,
                &gAssets.boss5DFront, &gAssets.boss1DMeshFront);

  xx = -102;
  yy = 0;
  zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -1,pi/6,pi/8,
                &gAssets.boss5DRear, &gAssets.boss1DMeshRear);

  CD2 vel;
  vel.x = 0;
  vel.y = 0;
  ObjTris *objTris = mob->obj->debris;
  AddDebris(&gW, &mob->pos, &vel, &objTris->tris, objTris->cnt);
}

U0 Boss6Destroyed(Mob *mob) {
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r, mob->rot);

  I64 xx = -4;
  I64 yy = -40;
  I64 zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, 1,pi/4,0,
                &gAssets.boss6DLeft, &gAssets.boss2DMeshLeft);

  xx = -4;
  yy = 40;
  zz = 0;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -1,pi/6,pi/8,
                &gAssets.boss6DRight, &gAssets.boss2DMeshRight);

  CD2 vel;
  vel.x = 0;
  vel.y = 0;
  ObjTris *objTris = mob->obj->debris;
  AddDebris(&gW, &mob->pos, &vel, &objTris->tris, objTris->cnt);
}

U0 Boss7Destroyed(Mob *mob) {
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r, mob->rot);

  I64 xx = 64;
  I64 yy = -62;
  I64 zz = 17;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -3,pi/4,0,
                &gAssets.boss7DLF, &gAssets.boss3DMeshLF);

  xx = 64;
  yy = 62;
  zz = 17;
  Mat4x4MulXYZ(r, &xx, &yy, &zz);
  AddDebrisMesh(mob->pos.x+xx,mob->pos.y+yy,1000,
                xx/8,yy/8,0, 0,0,mob->rot, -3,pi/6,pi/8,
                &gAssets.boss7DRF, &gAssets.boss3DMeshRF);

  CD2 vel;
  vel.x = 0;
  vel.y = 0;
  ObjTris *objTris = mob->obj->debris;
  AddDebris(&gW, &mob->pos, &vel, &objTris->tris, objTris->cnt);
}

U0 (*BossDebrisFuncs)(Mob*)[LEVEL_TOTAL] = {
  &Boss0Destroyed,
  &Boss1Destroyed,
  &Boss2Destroyed,
  &Boss3Destroyed,
  &Boss4Destroyed,
  &Boss5Destroyed,
  &Boss6Destroyed,
  &Boss7Destroyed,
};

public U0 ExpireMobs() {
  I64 i=0, ii;
  CD2 vel, pos;
  while (i<gW.mobs.len && gW.mobs.len>0) {
    Mob *mob = &gW.mobs.d(Mob*)[i];
    if (mob->health <= 0) {
      gW.lvlMobsKilled++;
      if (mob->id == 1) {
        gW.bossDead = 1;
        gW.bossDeadTTL = BOSS_DEAD_TTL;
        Mob *submob = gW.mobs.d;
        for (ii=0; ii<gW.mobs.len; ii++, submob++) {
          if (submob->id == 2)
            DmgMob(submob, 10000);
        }
        for (ii=0; ii<128; ii++) {
          pos.x = mob->pos.x + Rand()*320-160;
          pos.y = mob->pos.y + Rand()*300;
          AddGodWord(&gW.godWords, &pos, &gW.gtext);
        }
        BossDebrisFuncs[gW.levelNum](mob);
      } else {
        vel.x = 0;
        vel.y = 0;
        AddGodWord(&gW.godWords, &mob->pos, &gW.gtext);
        // Add Drop
        if (mob->drop >= 0)
          AddPickup(mob->pos.x, mob->pos.y, mob->drop);
        // Add Debris
        ObjTris *objTris = mob->obj->debris;
        pos.x = mob->gunX; // gunX might not be perfect and debris isn't rotated
        pos.y = mob->gunY;
        AddDebris(&gW, &pos, &vel, &objTris->tris, objTris->cnt);
      }
      gW.score += mob->scoreValue;
      gW.lvlScore += mob->scoreValue;
      VectorDel(&gW.mobs, i);
      goto next_mob;
    } else if (mob->pos.x < -256 || mob->pos.x > 256+SCR_W || mob->pos.y < -256 || mob->pos.y > 256+FB_H) {
      VectorDel(&gW.mobs, i);
      goto next_mob;
    }
    i++;
next_mob:
  }
}

#endif
