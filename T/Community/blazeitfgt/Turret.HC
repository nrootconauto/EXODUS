#ifndef TURRET_HC
#define TURRET_HC

#include "Collision";
#include "Draw";
#include "Vector";
#include "Obj/TurretL";

#define TUR_TARGET_DIST 2048
#define TUR_SHOOT_TTL 0.5

class Turret {
  CD3 pos;
  CD2I32 size;
  F64 rot;
  F64 health;
  F64 shoot_ttl;
  F64 lastHitRot;
};

public U0 AddTurret(Vector *vec, I64 x, I64 y, Vector *grBuf) {
  Turret t;
  t.pos.x = x;
  t.pos.y = y;
  t.pos.z = 0;
  t.size.x = 32;
  t.size.y = 32;
  t.rot = 0;
  t.health = 100;
  t.shoot_ttl = 0;
  VectorAdd(vec, &t);
  VectorSetLen(grBuf, vec->len);
}

public U0 DmgTur(Turret *t, F64 dmg, F64 rot) {
  t->health -= dmg;
  t->lastHitRot = rot;
}

public U0 GenMatTur(Turret *t, I64 cnt, Vector *vBuf, Cam *cam) {
  VectorSetLen(vBuf, cnt);
  GrBuff buf;
  I64 mi=0, i, x, y, zx, zy;
  for (i=0; i<cnt; i++) {
    x = t[i].pos.x - cam->pos.x;
    zx = AbsI64(x*cam->zoom);
    if (zx <= 320+32) {
      y = t[i].pos.y - cam->pos.y;
      zy = AbsI64(y*cam->zoom);
      if (zy <= 240+32) {
        Mat4x4IdentEqu(buf.mat);
        Mat4x4RotZ(buf.mat,t[i].rot);
        Mat4x4TranslationAdd(buf.mat, t[i].pos.x - cam->pos.x,
                         t[i].pos.y - cam->pos.y, t[i].pos.z - cam->pos.z);
        Mat4x4Scale(buf. mat, cam->zoom);
        MemCpy(&vBuf->d(GrBuff*)[mi++], &buf, sizeof(GrBuff));
      }
    }
  }
  vBuf->len = mi;
}

public U0 DrawTurrets(CDC *dc, I64 cnt, GrBuff *buf) {
  I64 i, ii;
  dc->color=YELLOW;
  for (i=0; i<cnt; i++) {
    dc->r = buf[i].mat;
    dc->r_norm = Sqrt(Mat4x4NormSqr65536(buf[i].mat))*65536;
    for (ii=0; ii<TurretL_cnt; ii+=2)
      GrLine3F(dc, TurretL[ii].x, TurretL[ii].y, TurretL[ii].z, TurretL[ii+1].x, TurretL[ii+1].y, TurretL[ii+1].z);
  }
}

public U0 GenCTur(Turret *t, I64 cnt, Vec4 *cT) {
  I64 i;
  for (i=0; i<cnt; i++)
    GetAABBFromSize(&t[i].pos, &t[i].size, &cT[i]);
}

#endif