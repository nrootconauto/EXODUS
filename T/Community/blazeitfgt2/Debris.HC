#ifndef DEBRIS_HC
#define DEBRIS_HC

#define DEBRIS_EXPIRE 10

#include "World"
#include "Quaternion"
#include "Vector"
#include "Globals"

class Debris {
  CD3 pos;
  CD3 vel;
  Quat q;
  F64 ttl;
};

class DebrisMesh {
  CD3 pos;
  CD3 vel;
  Quat q;
  Quat spin;
  ObjLinesColor *lines;
  ModelTemplate *mesh; // TODO don't need full ModelTemplate
};

class GrDebris {
  I64 mat[4][4];
  CD3I32 tri[3];
};

U0 AddDebrisMesh(F64 x, F64 y, F64 z,
                  F64 vx, F64 vy, F64 vz,
                  F64 roll, F64 pitch, F64 yaw,
                  F64 sroll, F64 spitch, F64 syaw,
                  ObjLinesColor *lines, ModelTemplate *mesh) {
  VectorInc(&gW.debrisMesh, 1);
  DebrisMesh *d = gW.debrisMesh.d(DebrisMesh*) + gW.debrisMesh.len-1;
  d->pos.x=x; d->pos.y=y; d->pos.z=z;
  d->vel.x=vx; d->vel.y=vy; d->vel.z=vz;
  QuatFromEuler(&d->q, roll, pitch, yaw);
  QuatFromEuler(&d->spin, sroll, spitch, syaw);
  d->lines = lines;
  d->mesh = mesh;
}

U0 ProcessDebrisMesh(F64 delta) {
  I64 i; Quat q;
  DebrisMesh *d = gW.debrisMesh.d;
  for (i=0; i<gW.debrisMesh.len; i++, d++) {
    d->pos.x += d->vel.x * delta;
    d->pos.y += d->vel.y * delta;
    d->pos.z += d->vel.z * delta;
    QuatMul(&d->q, &d->spin, &q);
    QuatLerp(&d->q, &q, delta, &d->q);
    QuatNormalize(&d->q);
  }
}

U0 DrawDebrisMesh(CDC *dc) {
  I64 i, ii, ic, r[16];
  DebrisMesh *d = gW.debrisMesh.d;
  for (i=0; i<gW.debrisMesh.len; i++, d++) {
    // Generate Matrix
    QuatToMatrix(&d->q, r);
    Mat4x4TranslationAdd(r, d->pos.x, d->pos.y, d->pos.z);
    dc->r = r;

    // Draw Color Lines
    ObjLinesColor *objL = d->lines;
    I64 lineCnt = objL->cnt;
    U8 *colors = objL->colors;
    CD3I32 *lines = objL->lines;
    for (ii=0, ic=0; ii<lineCnt; ii+=2, ic++) {
      dc->color = colors[ic];
      GrLine3F(dc, lines[ii].x, lines[ii].y, lines[ii].z,
               lines[ii+1].x, lines[ii+1].y, lines[ii+1].z, gDepthBuf);
    }

    // Draw Mesh
    dc->color=ROPF_PROBABILITY_DITHER+12<<16+11;
    dc->dither_probability_u16=I16_MAX/2;
    DrawTriFillVM(dc, d->mesh->tris, d->mesh->triCnt, r, gDepthBuf);
  }
}

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

U0 DrawDebris(CDC *dc, I64 cnt, GrDebris* debris, I32 *db) {
  I64 i;
  dc->color = 5;
  for (i=0; i<cnt; i++) {
    dc->r = debris[i].mat;
    GrLine3F(dc, debris[i].tri[0].x, debris[i].tri[0].y, debris[i].tri[0].z, debris[i].tri[1].x, debris[i].tri[1].y, debris[i].tri[1].z, db);
    GrLine3F(dc, debris[i].tri[1].x, debris[i].tri[1].y, debris[i].tri[1].z, debris[i].tri[2].x, debris[i].tri[2].y, debris[i].tri[2].z, db);
    GrLine3F(dc, debris[i].tri[2].x, debris[i].tri[2].y, debris[i].tri[2].z, debris[i].tri[0].x, debris[i].tri[0].y, debris[i].tri[0].z, db);
  }
}

public U0 AddDebris(World *w, CD2 *pos, CD2 *vel, CD3I32 *tri, I64 cnt) {
  I64 i;
  Debris debris;
  GrDebris grd;
  for (i=0; i<cnt; i++) {
    debris.pos.x = pos->x;
    debris.pos.y = pos->y;
    debris.pos.z = 1000;
    debris.vel.x = vel->x + Sin(i)*64;
    debris.vel.y = vel->y + Cos(i)*64;
    debris.vel.z = 0;
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

public U0 DebrisMat(I64 cnt, Debris* d, GrDebris *grd, F64 delta) {
  I64 i;
  for (i=0; i<cnt; i++) {
    d[i].pos.x += d[i].vel.x * delta;
    d[i].pos.y += d[i].vel.y * delta;
    d[i].pos.z += d[i].vel.z * delta;
    Quat q;
    q.x = 0.627;
    q.y = 0.327;
    q.z = 0.327;
    q.w = 0.627;
    QuatMul(&d[i].q, &q, &q);
    QuatLerp(&d[i].q, &q, delta, &d[i].q);
    QuatNormalize(&d[i].q);
    QuatToMatrix(&d[i].q, grd[i].mat);
    Mat4x4TranslationAdd(grd[i].mat, d[i].pos.x, d[i].pos.y, d[i].pos.z);
  }
}

#endif
