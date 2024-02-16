#ifndef BULLET_HC
#define BULLET_HC

#include "Draw"
#include "Vector"
#include "Globals"

#define BULLET_TYPE_SHOT0          0
#define BULLET_TYPE_SHOT1          1
#define BULLET_TYPE_SHOT2          2
#define BULLET_TYPE_SPREAD0        3
#define BULLET_TYPE_SPREAD1        4
#define BULLET_TYPE_SPREAD2        5
#define BULLET_TYPE_MOB_CIRCLE8    6
#define BULLET_TYPE_MOB_CIRCLE16   7
#define BULLET_TYPE_MOB_CIRCLE16_F 8
#define BULLET_TYPE_MOB_STAR16     9
#define BULLET_TYPE_TOTAL          10

class BulletType {
  PxData *px;
  U16 speed;
  I8 pxOffX;
  I8 pxOffY;
  U8 radius;
  U8 dmg;
};

BulletType BULLET_DATA[BULLET_TYPE_TOTAL] = {
  {gAssets.pxBulletShot0      , 1000, -4, -4, 4, 10},
  {gAssets.pxBulletShot1      , 1000, -4, -4, 4, 15},
  {gAssets.pxBulletShot2      , 1000, -4, -4, 4, 20},
  {gAssets.pxBulletSpread0    , 1000, -4, -4, 4, 8},
  {gAssets.pxBulletSpread1    , 1000, -5, -5, 5, 8},
  {gAssets.pxBulletSpread2    , 1000, -6, -6, 6, 8},
  {gAssets.pxBulletMobCircle8 , 200,  -4, -4, 4, 10},
  {gAssets.pxBulletMobCircle16, 256,  -8, -8, 8, 10},
  {gAssets.pxBulletMobCircle16, 400,  -8, -8, 8, 10},
  {gAssets.pxBulletMobStar16  , 256,  -8, -8, 8, 10},
};

class Bullet {
  CD2 pos;
  CD2 vel;
  PxData *px;
  I8 pxOffX;
  I8 pxOffY;
  U8 radius;
  U8 dmg;
};

public U0 AddBullet(F64 x, F64 y, F64 tx, F64 ty, Vector* vec, I32 type) {
  Bullet b;
  F64 mag = Sqrt(tx*tx+ty*ty);
  b.pos.x = x;
  b.pos.y = y;
  b.vel.x = tx / mag * BULLET_DATA[type].speed;
  b.vel.y = ty / mag * BULLET_DATA[type].speed;
  b.px = BULLET_DATA[type].px;
  b.pxOffX = BULLET_DATA[type].pxOffX;
  b.pxOffY = BULLET_DATA[type].pxOffY;
  b.radius = BULLET_DATA[type].radius;
  b.dmg = BULLET_DATA[type].dmg;
//  b.ry = Arg(x+tx-b.pos.x, y+ty-b.pos.y);
  VectorAdd(vec, &b);
}

public U0 AddBulletRad(F64 x, F64 y, F64 rad, Vector* vec, I32 type) {
  Bullet b;
  b.pos.x = x;
  b.pos.y = y;
  b.vel.x = Cos(rad) * BULLET_DATA[type].speed;
  b.vel.y = Sin(rad) * BULLET_DATA[type].speed;
  b.px = BULLET_DATA[type].px;
  b.pxOffX = BULLET_DATA[type].pxOffX;
  b.pxOffY = BULLET_DATA[type].pxOffY;
  b.radius = BULLET_DATA[type].radius;
  b.dmg = BULLET_DATA[type].dmg;
  VectorAdd(vec, &b);
}

public U0 DrawBullets(U8 *fb, Bullet *bullets, I64 cnt) {
  I64 i;
  for (i=0; i<cnt; i++, bullets++)
    PxBlot(fb, bullets->px, ToI64(bullets->pos.x)+bullets->pxOffX, ToI64(bullets->pos.y)+bullets->pxOffY);
}

#endif
