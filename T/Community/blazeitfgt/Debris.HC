#ifndef DEBRIS_HC
#define DEBRIS_HC

#define DEBRIS_EXPIRE 10

#include "World";
#include "Quaternion";
#include "Vector";

class Debris {
  CD3 pos;
  CD3 vel;
  Quaternion q;
  F64 ttl;
};

class GrDebris {
  Bool draw;
  I64 mat[4][4];
  CD3I32 tri[3];
};

U0 ExpireDebris(World* w, F64 delta) {
  I64 i;
  Debris* dptr;
  for (i=0; i<w->debris.len; i++) {
    dptr = &w->debris.d(Debris*)[i];
    dptr->ttl += delta;
    if (dptr->ttl >= DEBRIS_EXPIRE) {
      VectorDel(&w->debris, i);
      VectorDel(&w->grDebris, i);
      i--;
    }
  }
}

U0 DrawDebris(CDC *dc, I64 cnt, GrDebris* debris) {
  I64 i;
  dc->color = WHITE;
  for (i=0; i<cnt; i++) {
    if (debris[i].draw) {
      dc->r = debris[i].mat;
      dc->r_norm = Sqrt(Mat4x4NormSqr65536(debris[i].mat))*65536;
      GrLine3F(dc, debris[i].tri[0].x, debris[i].tri[0].y, debris[i].tri[0].z, debris[i].tri[1].x, debris[i].tri[1].y, debris[i].tri[1].z);
      GrLine3F(dc, debris[i].tri[1].x, debris[i].tri[1].y, debris[i].tri[1].z, debris[i].tri[2].x, debris[i].tri[2].y, debris[i].tri[2].z);
      GrLine3F(dc, debris[i].tri[2].x, debris[i].tri[2].y, debris[i].tri[2].z, debris[i].tri[0].x, debris[i].tri[0].y, debris[i].tri[0].z);
    }
  }
}

public U0 AddDebris(World *w, CD3 *pos, CD3 *vel, CD3I32 *tri, I64 cnt) {
  I64 i;
  Debris debris;
  GrDebris grd;
  for (i=0; i<cnt; i++) {
    debris.pos.x = pos->x;
    debris.pos.y = pos->y;
    debris.pos.z = pos->z;
    debris.vel.x = vel->x + Sin(i)*64;
    debris.vel.y = vel->y + Cos(i)*64;
    debris.vel.z = vel->z;
    debris.q.x = 0.627;
    debris.q.y = 0.327;
    debris.q.z = 0.327;
    debris.q.w = 0.627;
    debris.ttl = 0.0;
    VectorAdd(&w->debris, &debris);
    MemCpy(grd.tri, &tri[i*3], sizeof(CD3I32)*3);
    VectorAdd(&w->grDebris, &grd);
  }
}

public U0 DebrisMat(I64 cnt, Debris* d, GrDebris *grd, Cam *cam, F64 delta) {
  I64 i,x,y,zx,zy;
  Quaternion q;
  for (i=0; i<cnt; i++) {
    d[i].pos.x += d[i].vel.x * delta;
    d[i].pos.y += d[i].vel.y * delta;
    d[i].pos.z += d[i].vel.z * delta;
    q.x = 0.627;
    q.y = 0.327;
    q.z = 0.327;
    q.w = 0.627;
    QuaternionMultiply(&d[i].q, &q, &q);
    QuaternionLerp(&d[i].q, &q, delta, &d[i].q);
    QuaternionNormalize(&d[i].q);
    grd[i].draw = FALSE;
    x = d[i].pos.x - cam->pos.x;
    zx = AbsI64(x*cam->zoom);
    if (zx <= 350) {
      y = d[i].pos.y - cam->pos.y;
      zy = AbsI64(y*cam->zoom);
      if (zy <= 270) {
        grd[i].draw = TRUE;
        QuaternionToMatrix(&d[i].q, grd[i].mat);
        Mat4x4TranslationAdd(grd[i].mat, x, y, 0);
        Mat4x4Scale(grd[i].mat, cam->zoom);
      }
    }
  }
}

#endif