// Quaternion code based on raymath.h under zlib/libpng license

#ifndef QUATERNION_HC
#define QUATERNION_HC

public class Quaternion {
  F64 x;
  F64 y;
  F64 z;
  F64 w;
};

// Adds q2 to q1
public U0 QuaternionAdd(Quaternion *q1, Quaternion *q2) {
  q1->x += q2->x;
  q1->y += q2->y;
  q1->z += q2->z;
  q1->w += q2->w;
}

public U0 QuaternionMultiply(Quaternion *q1, Quaternion *q2, Quaternion *res) {
  F64 qax = q1->x, qay = q1->y, qaz = q1->z, qaw = q1->w;
  F64 qbx = q2->x, qby = q2->y, qbz = q2->z, qbw = q2->w;

  res->x = qax*qbw + qaw*qbx + qay*qbz - qaz*qby;
  res->y = qay*qbw + qaw*qby + qaz*qbx - qax*qbz;
  res->z = qaz*qbw + qaw*qbz + qax*qby - qay*qbx;
  res->w = qaw*qbw - qax*qbx - qay*qby - qaz*qbz;
}

public U0 QuaternionScale(Quaternion *q, F64 mul) {
  F64 qax = q->x, qay = q->y, qaz = q->z, qaw = q->w;

  q->x = qax * mul + qaw * mul + qay * mul - qaz * mul;
  q->y = qay * mul + qaw * mul + qaz * mul - qax * mul;
  q->z = qaz * mul + qaw * mul + qax * mul - qay * mul;
  q->w = qaw * mul - qax * mul - qay * mul - qaz * mul;
}


public U0 QuaternionLerp(Quaternion *q1, Quaternion *q2, F64 amount, Quaternion *res) {
  res->x = q1->x + amount*(q2->x - q1->x);
  res->y = q1->y + amount*(q2->y - q1->y);
  res->z = q1->z + amount*(q2->z - q1->z);
  res->w = q1->w + amount*(q2->w - q1->w);
}

public F64 QuaternionLength(Quaternion *q) {
  return Sqrt(q->x*q->x + q->y*q->y + q->z*q->z + q->w*q->w);
}

public U0 QuaternionNormalize(Quaternion *q) {
  F64 length, ilength;
  length = QuaternionLength(q);
  if (length == 0.0)
    length = 1.0;
  ilength = 1.0/length;

  q->x *= ilength;
  q->y *= ilength;
  q->z *= ilength;
  q->w *= ilength;
}

public U0 QuaternionFromEuler(Quaternion *q, F64 roll, F64 pitch, F64 yaw) {
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

public U0 QuaternionFromCD3ToCD3(Quaternion *q, CD3 *from, CD3 *to) {
  F64 cos2Theta = D3Dot(from, to);
  CD3 cross;
  D3Cross(&cross, from, to);

  q->x = cross.x;
  q->y = cross.y;
  q->z = cross.z;
  q->w = 1.0 + cos2Theta;

  // Normalize to essentially nlerp the original and identity to 0.5
  QuaternionNormalize(q);

  // Above lines are equivalent to:
  //Quaternion result = QuaternionNlerp(q, QuaternionIdentity(), 0.5f);
}

/*
public U0 QuaternionToMatrix(Quaternion *q, I64 *m) {
  F64 a = q->w;
  F64 b = q->x;
  F64 c = q->y;
  F64 d = q->z;
  F64 a2 = a*a;
  F64 b2 = b*b;
  F64 c2 = c*c;
  F64 d2 = d*d;

  m[0] = (a2 + b2 - c2 - d2)*GR_SCALE;
  m[1] = 2.0*(b*c + a*d)*GR_SCALE;
  m[2] = 2.0*(b*d - a*c)*GR_SCALE;
  m[3] = 0.0;

  m[4] = 2.0*(b*c - a*d)*GR_SCALE;
  m[5] = (a2 - b2 + c2 - d2)*GR_SCALE;
  m[6] = 2.0*(c*d + a*b)*GR_SCALE;
  m[7] = 0.0;

  m[8] = 2.0*(b*d + a*c)*GR_SCALE;
  m[9] = 2.0*(c*d - a*b)*GR_SCALE;
  m[10] = (a2 - b2 - c2 + d2)*GR_SCALE;
  m[11] = 0.0;

  m[12] = m[13] = m[14] = 0.0;
  m[15] = GR_SCALE;
}
*/

public U0 QuaternionToMatrix(Quaternion *q, I64 *m) {
  F64 x = q->x, y = q->y, z = q->z, w = q->w;

  F64 x2 = x + x;
  F64 y2 = y + y;
  F64 z2 = z + z;

  F64 length = QuaternionLength(q);
  F64 lengthSquared = length*length;

  I64 xx = x*x2/lengthSquared*GR_SCALE;
  I64 xy = x*y2/lengthSquared*GR_SCALE;
  I64 xz = x*z2/lengthSquared*GR_SCALE;

  I64 yy = y*y2/lengthSquared*GR_SCALE;
  I64 yz = y*z2/lengthSquared*GR_SCALE;
  I64 zz = z*z2/lengthSquared*GR_SCALE;

  I64 wx = w*x2/lengthSquared*GR_SCALE;
  I64 wy = w*y2/lengthSquared*GR_SCALE;
  I64 wz = w*z2/lengthSquared*GR_SCALE;

  m[0] = GR_SCALE - (yy + zz);
  m[1] = xy - wz;
  m[2] = xz + wy;
  m[3] = 0;
  m[4] = xy + wz;
  m[5] = GR_SCALE - (xx + zz);
  m[6] = yz - wx;
  m[7] = 0;
  m[8] = xz - wy;
  m[9] = (yz + wx);
  m[10] = GR_SCALE - (xx + yy);
  m[11] = 0;
  m[12] = 0;
  m[13] = 0;
  m[14] = 0;
  m[15] = GR_SCALE;
}

#endif
