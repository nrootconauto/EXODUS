// Quaternion code based on raymath.h under zlib/libpng license

#ifndef QUATERNION_HC
#define QUATERNION_HC

#include "Vec"

public class Quat {
  F64 x;
  F64 y;
  F64 z;
  F64 w;
};

// Adds q2 to q1
public U0 QuatAdd(Quat *q1, Quat *q2) {
  q1->x += q2->x;
  q1->y += q2->y;
  q1->z += q2->z;
  q1->w += q2->w;
}

public U0 QuatMul(Quat *q1, Quat *q2, Quat *res) {
  F64 qax = q1->x, qay = q1->y, qaz = q1->z, qaw = q1->w;
  F64 qbx = q2->x, qby = q2->y, qbz = q2->z, qbw = q2->w;

  res->x = qax*qbw + qaw*qbx + qay*qbz - qaz*qby;
  res->y = qay*qbw + qaw*qby + qaz*qbx - qax*qbz;
  res->z = qaz*qbw + qaw*qbz + qax*qby - qay*qbx;
  res->w = qaw*qbw - qax*qbx - qay*qby - qaz*qbz;
}

public U0 QuatScale(Quat *q, F64 mul) {
  F64 qax = q->x, qay = q->y, qaz = q->z, qaw = q->w;

  q->x = qax * mul + qaw * mul + qay * mul - qaz * mul;
  q->y = qay * mul + qaw * mul + qaz * mul - qax * mul;
  q->z = qaz * mul + qaw * mul + qax * mul - qay * mul;
  q->w = qaw * mul - qax * mul - qay * mul - qaz * mul;
}


public U0 QuatLerp(Quat *q1, Quat *q2, F64 amount, Quat *res) {
  res->x = q1->x + amount*(q2->x - q1->x);
  res->y = q1->y + amount*(q2->y - q1->y);
  res->z = q1->z + amount*(q2->z - q1->z);
  res->w = q1->w + amount*(q2->w - q1->w);
}

public F64 QuatLength(Quat *q) {
  return Sqrt(q->x*q->x + q->y*q->y + q->z*q->z + q->w*q->w);
}

public U0 QuatNormalize(Quat *q) {
  F64 length, ilength;
  length = QuatLength(q);
  if (length == 0.0)
    length = 1.0;
  ilength = 1.0/length;

  q->x *= ilength;
  q->y *= ilength;
  q->z *= ilength;
  q->w *= ilength;
}

public U0 QuatFromEuler(Quat *q, F64 roll, F64 pitch, F64 yaw) {
  F64 x0 = Cos(roll*0.5);
  F64 x1 = Sin(roll*0.5);
  F64 y0 = Cos(pitch*0.5);
  F64 y1 = Sin(pitch*0.5);
  F64 z0 = Cos(yaw*0.5);
  F64 z1 = Sin(yaw*0.5);

  q->x = x1*y0*z0 - x0*y1*z1;
  q->y = x0*y1*z0 + x1*y0*z1;
  q->z = x0*y0*z1 - x1*y1*z0;
  q->w = x0*y0*z0 + x1*y1*z1;
}

public U0 QuatFromCD3ToCD3(Quat *q, CD3 *from, CD3 *to) {
  F64 cos2Theta = D3Dot(from, to);
  CD3 cross;
  D3Cross(&cross, from, to);

  q->x = cross.x;
  q->y = cross.y;
  q->z = cross.z;
  q->w = 1.0 + cos2Theta;

  // Normalize to essentially nlerp the original and identity to 0.5
  QuatNormalize(q);

  // Above lines are equivalent to:
  //Quat result = QuatNlerp(q, QuatIdentity(), 0.5f);
}

public U0 QuatToMatrix(Quat *q, I64 *m) {
  I64 a2=2*q->x*q->x*GR_SCALE, b2=2*q->y*q->y*GR_SCALE;
  I64 c2=2*q->z*q->z*GR_SCALE;

  I64 ab=2*q->x*q->y*GR_SCALE, _ac=2*q->x*q->z*GR_SCALE, bc=2*q->y*q->z*GR_SCALE;
  I64 ad=2*q->x*q->w*GR_SCALE, bd=2*q->y*q->w*GR_SCALE, cd=2*q->z*q->w*GR_SCALE;

  m[0]  = GR_SCALE - b2 - c2;
  m[1]  = ab - cd;
  m[2]  = _ac + bd;
  m[3] = 0;

  m[4]  = ab + cd;
  m[5]  = GR_SCALE - a2 - c2;
  m[6]  = bc - ad;
  m[7] = 0;

  m[8]  = _ac - bd;
  m[9]  = bc + ad;
  m[10] = GR_SCALE - a2 - b2;
  m[11] = 0;
  m[12] = 0;
  m[13] = 0;
  m[14] = 0;
  m[15] = GR_SCALE;
}

public U0 Quat2Mat(F64 x, F64 y, F64 z, F64 w, F64 *m) {
  F64 s;
  F64 norm = Vec4Norm(x, y, z, w);
  if (norm > 0.0) {
    s = 2.0 / norm;
  } else {
    s = 0.0;
  }
  F64 xx=s*x*x, xy=s*x*y, wx=s*w*x;
  F64 yy=s*y*y, yz=s*y*z, wy=s*w*y;
  F64 zz=s*z*z, xz=s*x*z, wz=s*w*z;

  m[0]  = 1.0 - yy - zz;
  m[1]  = xy + wz;
  m[2]  = xz - wy;
  m[3]  = 0;

  m[4]  = xy - wz;
  m[5]  = 1.0 - xx - zz;
  m[6]  = yz + wx;
  m[7]  = 0;

  m[8]  = xz + wy;
  m[9]  = yz - wx;
  m[10] = 1.0 - xx - yy;
  m[11] = 0;

  m[12] = 0;
  m[13] = 0;
  m[14] = 0;
  m[15] = 1.0;
}

#endif
