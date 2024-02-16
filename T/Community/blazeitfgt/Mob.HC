#ifndef MOB_HC
#define MOB_HC

#include "Collision";
#include "Draw";
#include "Vector";
#include "Obj/MobObjL";

public class Mob {
  CD3 pos;
  CD2I32 size;
  CD2 vel;
  F64 health;
  F64 shoot_ttl;
  F64 lastHitRot;
};

public U0 AddMob(Vector *mobs, Vector *cMobs, I64 x, I64 y) {
  Mob mob;
  mob.pos.x = x;
  mob.pos.y = y;
  mob.size.x = 32;
  mob.size.y = 32;
  mob.vel.x = 0.0;
  mob.vel.y = 0.0;
  mob.health = 10;
  mob.shoot_ttl = 2.0;
  VectorAdd(mobs, &mob);
  VectorSetLen(cMobs, mobs->len);
}

public U0 DmgMob(Mob* mob, F64 dmg, F64 ox, F64 oy) {
  mob->health -= dmg;
  mob->lastHitRot = Arg(mob->pos.x-ox, mob->pos.y-oy);
}

public U0 DmgMobRot(Mob* mob, F64 dmg, F64 rot) {
  mob->health -= dmg;
  mob->lastHitRot = rot;
}

public U0 GenMatMobs(Mob *mobs, I64 cnt, Vector *grMobs, Cam *cam) {
  VectorSetLen(grMobs, cnt);
  GrBuff buf;
  I64 mi=0, i, x, y, zx, zy;
  for (i=0; i<cnt; i++) {
    x = mobs[i].pos.x - cam->pos.x;
    zx = AbsI64(x*cam->zoom);
    if (zx <= 320) {
      y = mobs[i].pos.y - cam->pos.y;
      zy = AbsI64(y*cam->zoom);
      if (zy <= 240) {
        Mat4x4IdentEqu(buf.mat);
        Mat4x4RotZ(buf.mat,Arg(mobs[i].vel.x, mobs[i].vel.y));
        Mat4x4TranslationAdd(buf.mat, mobs[i].pos.x - cam->pos.x,
                         mobs[i].pos.y - cam->pos.y, mobs[i].pos.z - cam->pos.z);
        Mat4x4Scale(buf. mat, cam->zoom);
        MemCpy(&grMobs->d(GrBuff*)[mi++], &buf, sizeof(GrBuff));
      }
    }
  }
  grMobs->len = mi;
}

public U0 GenCMobs(Mob *mobs, I64 cnt, Vec4 *cMobs) {
  I64 i;
  for (i=0; i<cnt; i++)
    GetAABBFromSize(&mobs[i].pos, &mobs[i].size, &cMobs[i]);
}

public U0 DrawMobs(CDC *dc, I64 cnt, GrBuff *buf) {
  I64 i, ii;
  dc->color=LTRED;
  for (i=0; i<cnt; i++) {
    dc->r = buf[i].mat;
    dc->r_norm = Sqrt(Mat4x4NormSqr65536(buf[i].mat))*65536;
    for (ii=0; ii<MobObjL_cnt; ii+=2)
      GrLine3F(dc, MobObjL[ii].x, MobObjL[ii].y, MobObjL[ii].z, MobObjL[ii+1].x, MobObjL[ii+1].y, MobObjL[ii+1].z);
  }
}

#endif
