#ifndef SBase_HC
#define SBase_HC

#define BASE_HEALTH 500
#define SPAWNER_HEALTH 200
#define MIN_BASE_DIST 512
#define BASE_SPAWN_TTL 2

#include "Debris";
#include "Draw";
#include "Turret";
#include "Wall";
#include "Obj/BaseL";
#include "Obj/BaseT";
#include "Obj/SpawnerL";
#include "Obj/SpawnerT";

class SBase {
  CD3 pos;
  CD2I32 size;
  F64 health;
  F64 spawn_ttl;
};

public U0 DmgBase(SBase *base, F64 dmg) {
  base->health -= dmg;
}

public U0 GenCBase(SBase *base, I64 cnt, Vec4 *cBase) {
  I64 i;
  for (i=0; i<cnt; i++)
    GetAABBFromSize(&base[i].pos, &base[i].size, &cBase[i]);
}

public U0 GenMatSpawner(SBase *t, I64 cnt, Vector *vBuf, Cam *cam, F64 t_now) {
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
        Mat4x4RotX(buf.mat, t_now);
        Mat4x4RotZ(buf.mat, t_now);
        Mat4x4TranslationAdd(buf.mat, t[i].pos.x - cam->pos.x,
                         t[i].pos.y - cam->pos.y, t[i].pos.z - cam->pos.z);
        Mat4x4Scale(buf. mat, cam->zoom);
        MemCpy(&vBuf->d(GrBuff*)[mi++], &buf, sizeof(GrBuff));
      }
    }
  }
  vBuf->len = mi;
}

public U0 DrawSpawners(CDC *dc, I64 cnt, GrBuff *buf) {
  I64 i, ii;
  dc->color=YELLOW;
  for (i=0; i<cnt; i++) {
    dc->r = buf[i].mat;
    dc->r_norm = Sqrt(Mat4x4NormSqr65536(buf[i].mat))*65536;
    for (ii=0; ii<SpawnerL_cnt; ii+=2)
      GrLine3F(dc, SpawnerL[ii].x, SpawnerL[ii].y, SpawnerL[ii].z, SpawnerL[ii+1].x, SpawnerL[ii+1].y, SpawnerL[ii+1].z);
  }
}

public U0 AddSpawner(Vector *vec, I64 x, I64 y) {
  SBase ns;
  ns.pos.x = x;
  ns.pos.y = y;
  ns.pos.z = 0;
  ns.size.x = 64; // model is 64x64
  ns.size.y = 64;
  ns.health = SPAWNER_HEALTH;
  ns.spawn_ttl = BASE_SPAWN_TTL;
  VectorAdd(vec, &ns);
}

public U0 NewSBase(World *w) {
  I64 i, ii;
  SBase newb;
  newb.pos.z = 0;

continue:
  newb.pos.x = RandI64%3072;
  newb.pos.y = RandU64%1024 + 2048;
  for (i=0; i<w->base.len; i++) {
    SBase *b = &w->base.d(SBase*)[i];
    F64 dist = Abs(b->pos.x-newb.pos.x) + Abs(b->pos.y-newb.pos.y);
    if (dist < MIN_BASE_DIST)
      goto continue;
  }
  newb.size.x = 64;
  newb.size.y = 64;
  newb.health = BASE_HEALTH;
  newb.spawn_ttl = BASE_SPAWN_TTL;
  VectorAdd(&w->base, &newb);

  // Generate Walls
  I64 wallLayers = w->level;
  for (i=0; i<wallLayers; i++) {
    I64 ic = 4*(i*2+1);
    for (ii=0; ii<ic; ii++) {
      WallPost npost;
      npost.pos.x = newb.pos.x+Sin(ii*pi*2/ic)*256*i;
      npost.pos.y = newb.pos.y+Cos(ii*pi*2/ic)*256*i;
      npost.pos.z = 0;
      VectorAdd(&w->wallPosts, &npost);
    }
  }

  // Generate Turrets
  I64 turretCnt = w->level;
  for (i=0; i<turretCnt; i++) {
    AddTurret(&w->turrets, newb.pos.x+Sin(i*pi*2/turretCnt)*512,
              newb.pos.y+Cos(i*pi*2/turretCnt)*512, &w->cTur);
  }
  // Regenerate Turret Colliders
  VectorSetLen(&w->cTur, w->turrets.len);
  GenCTur(w->turrets.d, w->turrets.len, w->cTur.d);

  // Generate Spawners
  I64 spawnCnt = w->level;
  for (i=0; i<spawnCnt; i++) {
    AddSpawner(&w->spawner, newb.pos.x+Sin(i*pi*2/spawnCnt)*768,
              newb.pos.y+Cos(i*pi*2/spawnCnt)*768);
  }
  VectorSetLen(&w->cSpawner, w->spawner.len);
  GenCBase(w->spawner.d, w->spawner.len, w->cSpawner.d);

  VectorSetLen(&w->cBase, w->base.len);
  GenCBase(w->base.d, w->base.len, w->cBase.d);
}

public U0 ExpireBases(World *w) {
  I64 i;
  CD3 vel;
  Bool expired = FALSE;
  for (i=0; i<w->base.len; i++) {
    if (w->base.d(SBase*)[i].health <= 0) {
      vel.x = 0;
      vel.y = 0;
      vel.z = 0;
      AddDebris(w, &w->base.d(SBase*)[i].pos, &vel, &BaseT, BaseT_tris);
      VectorDel(&w->base, i);
      i--;
      VectorSetLen(&w->cBase, w->base.len);
      expired = TRUE;
    }
  }
  if (expired)
    GenCBase(w->base.d, w->base.len, w->cBase.d);
}

public U0 ExpireSpawner(World *w) {
  I64 i;
  CD3 vel;
  Bool expired = FALSE;
  for (i=0; i<w->spawner.len; i++) {
    if (w->spawner.d(SBase*)[i].health <= 0) {
      vel.x = 0;
      vel.y = 0;
      vel.z = 0;
      AddDebris(w, &w->spawner.d(SBase*)[i].pos, &vel, &SpawnerT, SpawnerT_tris);
      VectorDel(&w->spawner, i);
      i--;
      VectorSetLen(&w->cSpawner, w->spawner.len);
      expired = TRUE;
    }
  }
  if (expired)
    GenCBase(w->spawner.d, w->spawner.len, w->cSpawner.d);
}

public U0 DrawBase(CDC* dc, SBase *base, I64 cnt, Cam *cam, F64 t_now) {
  I64 mat[4][4], rmat[4][4], i, ii;
  Mat4x4IdentEqu(rmat);
  Mat4x4RotX(rmat,t_now);
  Mat4x4RotY(rmat,t_now);
  Mat4x4RotZ(rmat,t_now);
  for (i=0; i<cnt; i++) {
    MemCpy(mat, rmat, sizeof(I64)*16);
    Mat4x4TranslationAdd(mat, base[i].pos.x-cam->pos.x, base[i].pos.y-cam->pos.y, base[i].pos.z-cam->pos.z);
    Mat4x4Scale(mat, cam->zoom);
    dc->r = mat;
    dc->r_norm = Sqrt(Mat4x4NormSqr65536(mat))*65536;
    for (ii=0; ii<BaseL_cnt; ii+=2)
      GrLine3F(dc, BaseL[ii].x, BaseL[ii].y, BaseL[ii].z, BaseL[ii+1].x, BaseL[ii+1].y, BaseL[ii+1].z);
  }
}

#endif