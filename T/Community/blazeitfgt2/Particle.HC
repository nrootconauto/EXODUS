#ifndef PARTICLE_HC
#define PARTICLE_HC

#include "World"

public U0 AddParticle(Vector *vec, F64 x, F64 y) {
  Particle p;
  p.pos.x = x;
  p.pos.y = y;
  p.ttl = 0;
  VectorAdd(vec, &p);
}

public U0 DrawExplosions(CDC *dc, Particle *exp, I64 cnt, I32 *db) {
  I64 mat[4][4], i, ii;
  for (i=0; i<cnt; i++) {
    Mat4x4IdentEqu(mat);
    Mat4x4TranslationAdd(mat, exp[i].pos.x, exp[i].pos.y, 0);
    dc->r = mat;
    dc->color = 1;
    for (ii=0; ii<10; ii++) {
      GrEllipse3F(dc, 0, Cos(ii)*32*exp[i].ttl, 0, Sin(ii)*64*exp[i].ttl, Sin(ii)*32*exp[i].ttl, db);
      if (++dc->color > 15)
        dc->color = 1;
    }
  }
}

public U0 DrawSpawnFX(CDC *dc, Particle *p, I64 cnt, I32 *db) {
  I64 mat[4][4], i, ii;
  for (i=0; i<cnt; i++) {
    Mat4x4IdentEqu(mat);
    Mat4x4TranslationAdd(mat, p[i].pos.x, p[i].pos.y, 0);
    dc->r = mat;
    F64 val = Sin(p[i].ttl*3);
    F64 val2 = Cos(p[i].ttl*3+pi);
    for (ii=0; ii<16; ii++)
      GrEllipse3F(dc, 0, 0, 0, ii*ii*val - val2*32, ii*ii*val/3 + val2*32, db);
  }
}

#endif
