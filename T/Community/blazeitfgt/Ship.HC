#ifndef SHIP_HC
#define SHIP_HC

#include "World";
#include "Obj/ShipObj";

#define SHIP_VEL_MIN -512
#define SHIP_VEL_MAX 512

#define LASER_RANGE_1 256
#define BULLET_COOLDOWN 0.2
#define BULLET_SPEED 512

public U0 GenMatShip(Ship* ship, F64 jitter, Cam *cam, I64 *m, CD3I32 *tris, F64 *tf, I64 mx, I64 my) {
  F64 deg = Arg(mx-SCX, my-SCY);
  F64 vel = Abs(ship->vel.x) + Abs(ship->vel.y);
  vel /= 500.0;
  F64 rva = deg - Arg(ship->vel.x, ship->vel.y);

  F64 rvx = vel*Sin(rva);
  if (rvx > pi/4)
    rvx = pi/4;
  else if (rvx < -pi/4)
    rvx = -pi/4;

  F64 rvy = vel*Cos(rva);
  if (rvy > pi/6)
    rvy = pi/6;
  else if (rvy < -pi/6)
    rvy = -pi/6;

  F64 rx = Cos(deg);
  F64 ry = Sin(deg);
  *tf = (ship->accel.x*rx + ship->accel.y*ry) * 80;

  QuaternionFromEuler(&ship->q, rvx, rvy, deg);
  QuaternionToMatrix(&ship->q, m);
  F64 tx = ship->pos.x - cam->pos.x;
  F64 ty = ship->pos.y - cam->pos.y;
  if (jitter > 0.0) {
    tx += (ToI64(tf)%2-1) * jitter;
    ty += (ToI64(tf)%2-1) * jitter;
  }
  Mat4x4TranslationAdd(m, tx, ty,  256);
  Mat4x4Scale(m, cam->zoom);

  // Gen Thruster Matrix
  F64 rrad = Arg(SCX-mx, SCY-my); // flip the axis for fun
  rx = Cos(rrad);
  ry = Sin(rrad);
  F64 rmod = 1+(RandI64%100)/1000.0;
  F64 rr = (ship->accel.x*rx + ship->accel.y*ry) * 80 * rmod;
  MemCpy(tris, Thruster, sizeof(CD3I32)*Thruster_tris*3);
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

  tris[6*3+1].x += rr;
  tris[6*3+1].y *= rmod;
  tris[6*3+1].z *= rmod;
  tris[7*3+1].x += rr;
  tris[7*3+1].y *= rmod;
  tris[7*3+1].z *= rmod;
  tris[8*3+1].x += rr;
  tris[8*3+1].y *= rmod;
  tris[8*3+1].z *= rmod;
  tris[9*3+1].x += rr;
  tris[9*3+1].y *= rmod;
  tris[9*3+1].z *= rmod;
  tris[10*3+1].x += rr;
  tris[10*3+1].y *= rmod;
  tris[10*3+1].z *= rmod;
  tris[11*3+1].x += rr;
  tris[11*3+1].y *= rmod;
  tris[11*3+1].z *= rmod;
  

  // Buffer Thruster Mesh
  I64 i,px,py,pz;
  CD3I32 *p=tris;
  for (i=0; i<Thruster_tris*3; i++,p++) {
    px=p->x; py=p->y; pz=p->z;
    Mat4x4MulXYZ(m,&px,&py,&pz);
    p->x = px + SCX;
    p->y = py + SCY;
    p->z = pz + 256;
  }
}

public U0 DrawShip(CDC *dc, F64 t_now, I64 *m, F64 tf, CD3I32 *tris) {
  I64 i;
  dc->r = m;
  dc->r_norm = Sqrt(Mat4x4NormSqr65536(m))*65536;

  // Draw Ship
  dc->color = GREEN;
  for (i=0; i<ShipObj_cnt; i+=2)
    GrLine3F(dc, ShipObj[i].x, ShipObj[i].y, ShipObj[i].z, ShipObj[i+1].x, ShipObj[i+1].y, ShipObj[i+1].z);

  // Draw Dot Thruster
  dc->color = 0;
  for (i=0; i<Abs(tf*10); i++) {
    dc->color++;
    if (dc->color > 15)
      dc->color = 1;
    F64 modx = -19 + Sin(i+t_now*8) - i*tf/1000;
    F64 mody = Cos(i+t_now*8) * (8+i/32);
    F64 modz = Sin((i+4)/pi) * Cos((i+4)/pi) * 32;
    GrPlot3(dc, modx, 60 + mody, modz);
    GrPlot3(dc, modx, -60 + mody, modz);
  }

  // Draw Mesh Thruster
  CColorROPU32 old_color=dc->color;
  dc->color = BLUE;
  for (i=0; i<Thruster_tris; i++) {
    (*dc->lighting)(dc, &tris[i*3], &tris[i*3+1], &tris[i*3+2], old_color);
    GrFillTri0(dc, &tris[i*3], &tris[i*3+1], &tris[i*3+2]);
  }
}

public U0 DrawShipExplosion(CDC *dc, I64 x, I64 y, Quaternion *q, Cam *cam, F64 ttl) {
  I64 i, mat[4][4], mat2[4][4];
  Quaternion rotQ, qi;

  rotQ.x = 0.653;
  rotQ.y = 0.271;
  rotQ.z = -0.271;
  rotQ.w = 0.653;
  rotQ.x = 0.0;
  rotQ.y = 0.0;
  rotQ.z = 0.383;
  rotQ.w = 0.924;
  QuaternionToMatrix(q, mat);

  F64 tx = x - cam->pos.x;
  F64 ty = y - cam->pos.y;
  for (i=0; i<16; i++) {
    qi.x = q->x;
    qi.y = q->y;
    qi.z = q->z;
    qi.w = q->w;
    rotQ.y = 0.096;
    rotQ.z = 0.0;
    rotQ.w = 0.995;
    QuaternionMultiply(&qi, &rotQ, &rotQ);
    QuaternionNormalize(&rotQ);
    QuaternionToMatrix(&rotQ, mat2);

    Mat4x4IdentEqu(mat2);
    Mat4x4RotX(mat2, pi/64*i*(1+ttl));
    Mat4x4RotZ(mat2, pi/128*i*(1+ttl)+pi);

    Mat4x4TranslationAdd(mat2, tx, ty, 256);
    Mat4x4Scale(mat2, cam->zoom);
    dc->r = mat2;
    dc->r_norm = Sqrt(Mat4x4NormSqr65536(mat2))*65536;

    if (ttl < 4)
      GrCircle3(dc, 0, 0, 0, ttl*100);
  }
}

public Bool UpdateLaserUpgrade(Ship *ship, I64 xp) {
  I64 level = xp/20;
  I64 range = level * (LASER_RANGE_1/(level/2+1)) + LASER_RANGE_1;
  if (ship->laserRange != range) {
    ship->laserRange = range;
    ship->bulletCooldown = BULLET_COOLDOWN / (level/(2.0+level) + 1);
    ship->bulletDmg = BULLET_DMG*8.0 * (level/(2.0+level)+1);
    ship->bulletSpeed = BULLET_SPEED + 128.0*(level/(2.0+level));
    return TRUE;
  }
  return FALSE;
}

#endif