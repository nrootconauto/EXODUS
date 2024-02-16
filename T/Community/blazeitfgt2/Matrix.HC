#ifndef MATRIX_HC
#define MATRIX_HC

#include "Vec"

public U0 MatPerspective(F64 fovy, F64 aspect, F64 nearVal,
                         F64 farVal, F64 *dest) {
  F64 f  = 1.0 / Tan(fovy * 0.5);
  F64 fn = 1.0 / (nearVal - farVal);
/*
  dest[0] = f / aspect;
  dest[1] = 0;
  dest[2] = 0;
  dest[3] = 0;

  dest[4] = 0;
  dest[5] = f;
  dest[6] = 0;
  dest[7] = 0;

  dest[8] = 0;
  dest[9] = 0;
  dest[10] = (nearVal + farVal) * fn;
  dest[11] = 2.0 * nearVal * farVal * fn;

  dest[12] = 0;
  dest[13] = 0;
  dest[14] = 0;
  dest[15] = -1;
*/
  dest[0] = f / aspect;
  dest[1] = 0;
  dest[2] = 0;
  dest[3] = 0;

  dest[4] = 0;
  dest[5] = f;
  dest[6] = 0;
  dest[7] = 0;

  dest[8] = 0;
  dest[9] = 0;
  dest[10] = (nearVal + farVal) * fn;
  dest[14] = -1;

  dest[12] = 0;
  dest[13] = 0;
  dest[11] = 2.0 * nearVal * farVal * fn;
  dest[15] = 0;
}

// MatMulXYZ uses 13/14/15 for translation, like OpenGL/DirectX
public U0 MatMulXYZ(F64 *r,F64 *_x,F64 *_y,F64 *_z,F64 *_w) {
  F64 x1,y1,z1,w1,xx=*_x,yy=*_y,zz=*_z;
/*
  x1=r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3];
  y1=r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3];
  z1=r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3];
  w1=r[3*4+0]*xx+r[3*4+1]*yy+r[3*4+2]*zz+r[3*4+3];
*/
  x1=r[0*4+0]*xx+r[1*4+0]*yy+r[2*4+0]*zz+r[3*4+0];
  y1=r[0*4+1]*xx+r[1*4+1]*yy+r[2*4+1]*zz+r[3*4+1];
  z1=r[0*4+2]*xx+r[1*4+2]*yy+r[2*4+2]*zz+r[3*4+2];
  w1=r[0*4+3]*xx+r[1*4+3]*yy+r[2*4+3]*zz+r[3*4+3];
  *_x=x1;*_y=y1;*_z=z1;*_w=w1;
}

// MatMulXYZ but no W (for pre-normalized)
public U0 MatMulXYZ2(F64 *r, F64 *_x, F64 *_y, F64 *_z) {
  F64 x1,y1,z1,xx=*_x,yy=*_y,zz=*_z;
  x1=r[0*4+0]*xx+r[1*4+0]*yy+r[2*4+0]*zz+r[3*4+0];
  y1=r[0*4+1]*xx+r[1*4+1]*yy+r[2*4+1]*zz+r[3*4+1];
  z1=r[0*4+2]*xx+r[1*4+2]*yy+r[2*4+2]*zz+r[3*4+2];
  *_x=x1;*_y=y1;*_z=z1;
}

public U0 MatIdent(F64 *m) {
  m[0] = 1.0;
  m[1] = 0.0;
  m[2] = 0.0;
  m[3] = 0.0;

  m[4] = 0.0;
  m[5] = 1.0;
  m[6] = 0.0;
  m[7] = 0.0;

  m[8] = 0.0;
  m[9] = 0.0;
  m[10] = 1.0;
  m[11] = 0.0;

  m[12] = 0.0;
  m[13] = 0.0;
  m[14] = 0.0;
  m[15] = 1.0;
}

public U0 MatNewPos(F64 *m, F64 x, F64 y, F64 z) {
  m[0] = 1.0;
  m[1] = 0.0;
  m[2] = 0.0;
  m[3] = 0.0;

  m[4] = 0.0;
  m[5] = 1.0;
  m[6] = 0.0;
  m[7] = 0.0;

  m[8] = 0.0;
  m[9] = 0.0;
  m[10] = 1.0;
  m[11] = 0.0;

  m[12] = x;
  m[13] = y;
  m[14] = z;
  m[15] = 1.0;
}


public U0 MatMul(F64 *m1, F64 *m2, F64 *dest) {
  F64 a00 = m1[0], a01 = m1[1], a02 = m1[2], a03 = m1[3],
      a10 = m1[4], a11 = m1[5], a12 = m1[6], a13 = m1[7],
      a20 = m1[8], a21 = m1[9], a22 = m1[10], a23 = m1[11],
      a30 = m1[12], a31 = m1[13], a32 = m1[14], a33 = m1[15],
      b00 = m2[0], b01 = m2[1], b02 = m2[2], b03 = m2[3],
      b10 = m2[4], b11 = m2[5], b12 = m2[6], b13 = m2[7],
      b20 = m2[8], b21 = m2[9], b22 = m2[10], b23 = m2[11],
      b30 = m2[12], b31 = m2[13], b32 = m2[14], b33 = m2[15];

  dest[0] = a00 * b00 + a10 * b01 + a20 * b02 + a30 * b03;
  dest[1] = a01 * b00 + a11 * b01 + a21 * b02 + a31 * b03;
  dest[2] = a02 * b00 + a12 * b01 + a22 * b02 + a32 * b03;
  dest[3] = a03 * b00 + a13 * b01 + a23 * b02 + a33 * b03;
  dest[4] = a00 * b10 + a10 * b11 + a20 * b12 + a30 * b13;
  dest[5] = a01 * b10 + a11 * b11 + a21 * b12 + a31 * b13;
  dest[6] = a02 * b10 + a12 * b11 + a22 * b12 + a32 * b13;
  dest[7] = a03 * b10 + a13 * b11 + a23 * b12 + a33 * b13;
  dest[8] = a00 * b20 + a10 * b21 + a20 * b22 + a30 * b23;
  dest[9] = a01 * b20 + a11 * b21 + a21 * b22 + a31 * b23;
  dest[10] = a02 * b20 + a12 * b21 + a22 * b22 + a32 * b23;
  dest[11] = a03 * b20 + a13 * b21 + a23 * b22 + a33 * b23;
  dest[12] = a00 * b30 + a10 * b31 + a20 * b32 + a30 * b33;
  dest[13] = a01 * b30 + a11 * b31 + a21 * b32 + a31 * b33;
  dest[14] = a02 * b30 + a12 * b31 + a22 * b32 + a32 * b33;
  dest[15] = a03 * b30 + a13 * b31 + a23 * b32 + a33 * b33;
}

public U0 MatRotX(F64 *m, F64 angle, F64 *dest) {
  F64 t[4][4];
  F64 c, s;

  c = Cos(angle);
  s = Sin(angle);

  MatIdent(t);
  t[1][1] =  c;
  t[1][2] =  s;
  t[2][1] = -s;
  t[2][2] =  c;

  //MatMulRot(m, t, dest);
  MatMul(m, t, dest);
}

public U0 MatRotY(F64 *m, F64 angle, F64 *dest) {
  F64 t[4][4];
  F64 c, s;

  c = Cos(angle);
  s = Sin(angle);

  MatIdent(t);
  t[0][0] =  c;
  t[0][2] = -s;
  t[2][0] =  s;
  t[2][2] =  c;

  //MatMulRot(m, t, dest);
  MatMul(m, t, dest);
}

public U0 MatRotZ(F64 *m, F64 angle, F64 *dest) {
  F64 t[4][4];
  F64 c, s;

  c = Cos(angle);
  s = Sin(angle);

  MatIdent(t);
  t[0][0] =  c;
  t[0][1] =  s;
  t[1][0] = -s;
  t[1][1] =  c;

  //MatMulRot(m, t, dest);
  MatMul(m, t, dest);
}

public U0 MatScale(F64 *m, F64 s) {
  m[0]  *= s;
  m[5]  *= s;
  m[10] *= s;
/*
  m[0]  *= s; m[1]  *= s; m[2]  *= s; m[3]  *= s;
  m[4]  *= s; m[5]  *= s; m[6]  *= s; m[7]  *= s;
  m[8]  *= s; m[9]  *= s; m[10] *= s; m[11] *= s;
  m[12] *= s; m[13] *= s; m[14] *= s; m[15] *= s;
*/
}

public U0 MatTranslate(F64 *m, F64 x, F64 y, F64 z) {
  m[12] += m[0] * x;
  m[13] += m[1] * x;
  m[14] += m[2] * x;
  m[15] += m[3] * x;

  m[12] += m[4] * y;
  m[13] += m[5] * y;
  m[14] += m[6] * y;
  m[15] += m[7] * y;

  m[12] += m[8] * z;
  m[13] += m[9] * z;
  m[14] += m[10] * z;
  m[15] += m[11] * z;

//  m[15] += x;
//  m[15] += y;
//  m[15] += z;
}

public U0 MatFloat2Fixed(F64 *m, I64 *dest) {
  dest[0] = ToI64(m[0]*GR_SCALE);
  dest[1] = ToI64(m[1]*GR_SCALE);
  dest[2] = ToI64(m[2]*GR_SCALE);
  dest[3] = ToI64(m[3]*GR_SCALE);
  dest[4] = ToI64(m[4]*GR_SCALE);
  dest[5] = ToI64(m[5]*GR_SCALE);
  dest[6] = ToI64(m[6]*GR_SCALE);
  dest[7] = ToI64(m[7]*GR_SCALE);
  dest[8] = ToI64(m[8]*GR_SCALE);
  dest[9] = ToI64(m[9]*GR_SCALE);
  dest[10] = ToI64(m[10]*GR_SCALE);
  dest[11] = ToI64(m[11]*GR_SCALE);
  dest[12] = ToI64(m[12]*GR_SCALE);
  dest[13] = ToI64(m[13]*GR_SCALE);
  dest[14] = ToI64(m[14]*GR_SCALE);
  dest[15] = ToI64(m[15]*GR_SCALE);
}

// using F64 matrix internally because im too stupid to convert
// someone else's math to Terry's integer scaling system
U0 MatrixLookAt(CD3 *eye, CD3 *target, CD3 *up, F64 *dest) {
  CD3 x, y, z;
  D3Sub(&z, target, eye);
  CD3Normalize(&z);
  D3Cross(&x, &z, up);
  CD3Normalize(&x);
  D3Cross(&y, &z, &x);

  dest[0] = x.x;
  dest[1] = y.x;
  dest[2] = -z.x;
  dest[3] = 0;

  dest[4] = x.y;
  dest[5] = y.y;
  dest[6] = -z.y;
  dest[7] = 0;

  dest[8] = x.z;
  dest[9] = y.z;
  dest[10] = -z.z;
  dest[11] = 0;

  dest[12] = -D3Dot(&x, eye);
  dest[13] = -D3Dot(&y, eye);
  dest[14] = D3Dot(&z, eye);
  dest[15] = 1;
}

#endif
