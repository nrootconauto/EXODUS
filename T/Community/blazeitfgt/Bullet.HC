#ifndef BULLET_HC
#define BULLET_HC

#include "Draw";
#include "Vector";
#include "Obj/BulletObj";

class Bullet {
  CD3 pos;
  CD2I32 size;
  CD2 vel;
  F64 ry;
  F64 ttl;
};

public U0 DrawBullets(CDC* dc, I64 cnt, GrBuff* m) {
  I64 i, ii;
  for (i=0; i<cnt; i++) {
    dc->r = m[i].mat;
    dc->r_norm = Sqrt(Mat4x4NormSqr65536(m[i].mat))*65536;
    for (ii=0; ii<BulletObj_cnt; ii+=2)
      GrLine3F(dc, BulletObj[ii].x, BulletObj[ii].y, BulletObj[ii].z, BulletObj[ii+1].x, BulletObj[ii+1].y, BulletObj[ii+1].z);
  }
}

public U0 AddBullet(F64 x, F64 y, F64 tx, F64 ty, Vector* vec, F64 vel) {
  Bullet b;
  F64 mag = Sqrt(tx*tx + ty*ty);
  b.pos.x = x;
  b.pos.y = y;
  b.size.x = 16;
  b.size.y = 16;
  b.vel.x = tx / mag * vel;
  b.vel.y = ty / mag * vel;
  b.ry = Arg(x+tx-b.pos.x, y+ty-b.pos.y);
  b.ttl = 0.0;
  VectorAdd(vec, &b);
}

public U0 GenMatBullets(I64 cnt, Bullet* b, Vector *vecGr, Cam *cam, F64 time) {
  I64 i, mi=0;
  GrBuff buf;
  Cam c;
  MemCpy(&c, cam, sizeof(Cam));
  VectorSetLen(vecGr, cnt);
  GrBuff *vb = vecGr->d;
  for (i=0; i<cnt; i++) {
    I64 x,y,zx,zy;
    x = b[i].pos.x - c.pos.x;
    zx = AbsI64(x*c.zoom);
    if (zx <= 320) {
      y = b[i].pos.y - c.pos.y;
      zy = AbsI64(y*c.zoom);
      if (zy <= 240) {
        Mat4x4IdentEqu(buf.mat);
        Mat4x4RotX(buf.mat, time*10);
        Mat4x4RotZ(buf.mat, b[i].ry);
        Mat4x4TranslationAdd(buf.mat, x, y, 0);
        Mat4x4Scale(buf.mat, c.zoom);
        MemCpy(&vb[mi++], &buf, sizeof(GrBuff));
        //VectorAdd(vecGr, &buf);
      }
    }
  }
  vecGr->len = mi;
}

#endif