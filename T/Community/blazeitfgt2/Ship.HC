#ifndef SHIP_HC
#define SHIP_HC

#include "Globals"
#include "World"

#define SHIP_VEL_MIN -512
#define SHIP_VEL_MAX 512

#define LASER_RANGE_1 256

public U0 GenMatShip(Ship* ship, I64 *m) {
  F64 vel = Abs(ship->vel.x) + Abs(ship->vel.y);
  vel /= 500.0;
  F64 rva = Arg(ship->vel.x, ship->vel.y);

  F64 rvx = vel*Cos(rva);
  if (rvx > pi/4)
    rvx = pi/4;
  else if (rvx < -pi/4)
    rvx = -pi/4;

  F64 rvy = vel*Sin(rva);
  if (rvy > pi/6)
    rvy = pi/6;
  else if (rvy < -pi/6)
    rvy = -pi/6;

  QuatFromEuler(&ship->q, rvx, rvy, -pi/2);
  QuatToMatrix(&ship->q, m);
  F64 tx = ship->pos.x;
  F64 ty = ship->pos.y;
  Mat4x4Scale(m, ship->scale);
  Mat4x4TranslationAdd(m, tx, ty,  256);

  // Gen Thruster Matrix
  F64 rmod = 1+RandI64%100/1000.0;
  F64 rr = ship->accel.y * 80 * rmod;
  CD3I32 *tris = ship->thruster;
  MemCpy(tris, gAssets.shipThruster->tris, sizeof(CD3I32)*gAssets.shipThruster->cnt*3);
  tris[0+1].x += rr;
  tris[0+1].y *= rmod;
  tris[0+1].z *= rmod;
  tris[1*3+1].x += rr;
  tris[1*3+1].y *= rmod;
  tris[1*3+1].z *= rmod;
  tris[2*3+1].x += rr;
  tris[2*3+1].y *= rmod;
  tris[2*3+1].z *= rmod;
  tris[3*3+1].x += rr;
  tris[3*3+1].y *= rmod;
  tris[3*3+1].z *= rmod;
  tris[4*3+1].x += rr;
  tris[4*3+1].y *= rmod;
  tris[4*3+1].z *= rmod;
  tris[5*3+1].x += rr;
  tris[5*3+1].y *= rmod;
  tris[5*3+1].z *= rmod;

  tris[6*3+2].x += rr;
  tris[6*3+2].y *= rmod;
  tris[6*3+2].z *= rmod;
  tris[7*3+2].x += rr;
  tris[7*3+2].y *= rmod;
  tris[7*3+2].z *= rmod;
  tris[8*3+2].x += rr;
  tris[8*3+2].y *= rmod;
  tris[8*3+2].z *= rmod;
  tris[9*3+2].x += rr;
  tris[9*3+2].y *= rmod;
  tris[9*3+2].z *= rmod;
  tris[10*3+2].x += rr;
  tris[10*3+2].y *= rmod;
  tris[10*3+2].z *= rmod;
  tris[11*3+2].x += rr;
  tris[11*3+2].y *= rmod;
  tris[11*3+2].z *= rmod;

  // Buffer Thruster Mesh
  I64 i,px,py,pz;
  CD3I32 *p=tris;
  I64 triCnt = gAssets.shipThruster->cnt*3;
  for (i=0; i<triCnt; i++,p++) {
    px=p->x; py=p->y; pz=p->z;
    Mat4x4MulXYZ(m,&px,&py,&pz);
    p->x = px;
    p->y = py;
    p->z = pz + 256;
  }
}

public U0 DrawShip(CDC *dc, I64 *m, CD3I32 *tris, I32 *db) {
  I64 i;
  dc->r = m;

  // Draw Ship
  dc->color = GREEN;
  CD3I32 *lines = gAssets.ship->lines;
  I64 cnt = gAssets.ship->cnt;
  for (i=0; i<cnt; i+=2)
    GrLine3F(dc, lines[i].x, lines[i].y, lines[i].z, lines[i+1].x, lines[i+1].y, lines[i+1].z, db);

  // Draw Mesh Thruster
  I64 triCnt = gAssets.shipThruster->cnt;
  for (i=0; i<triCnt; i++) {
    (*dc->lighting)(dc, &tris[i*3], &tris[i*3+1], &tris[i*3+2], YELLOW);
    FillTri(dc, &tris[i*3], &tris[i*3+1], &tris[i*3+2], db);
  }
}

public U0 DrawShipExplosion(CDC *dc, I64 x, I64 y, Quat *q, F64 ttl) {
  I64 i, mat[4][4], mat2[4][4];
  Quat rotQ, qi;

  rotQ.x = 0.653;
  rotQ.y = 0.271;
  rotQ.z = -0.271;
  rotQ.w = 0.653;
  rotQ.x = 0.0;
  rotQ.y = 0.0;
  rotQ.z = 0.383;
  rotQ.w = 0.924;
  QuatToMatrix(q, mat);

  F64 tx = x;
  F64 ty = y;
  for (i=0; i<16; i++) {
    qi.x = q->x;
    qi.y = q->y;
    qi.z = q->z;
    qi.w = q->w;
    rotQ.y = 0.096;
    rotQ.z = 0.0;
    rotQ.w = 0.995;
    QuatMul(&qi, &rotQ, &rotQ);
    QuatNormalize(&rotQ);
    QuatToMatrix(&rotQ, mat2);

    Mat4x4IdentEqu(mat2);
    Mat4x4RotX(mat2, pi/64*i*(1+ttl));
    Mat4x4RotZ(mat2, pi/128*i*(1+ttl)+pi);

    Mat4x4TranslationAdd(mat2, tx, ty, 256);
    dc->r = mat2;

    if (ttl < 4)
      GrCircle3(dc, 0, 0, 0, ttl*100);
  }
}

#endif
