#ifndef VEC_HC
#define VEC_HC

public class Vec4 {
  union {
    F64 x;
    F64 x1;
  }
  union {
    F64 y;
    F64 y1;
  }
  union {
    F64 z;
    F64 w;  // width
    F64 x2;
  }
  union {
    F64 qw; // quaternion w
    F64 h;  // height
    F64 y2;
  }
};

public class IVec4 {
  union {
    I64 x;
    I64 x1;
  }
  union {
    I64 y;
    I64 y1;
  }
  union {
    I64 w;
    I64 x2;
  }
  union {
    I64 h;
    I64 y2;
  }
};

public F64 Lerp(F64 v1, F64 v2, F64 t) {
  //return v1 + t * (v2 - v1);
  return (1-t) * v1 + t * v2;
}

public U0 Lerp2(CD2 *v1, CD2 *v2, F64 t, CD2 *res) {
  res->x = Lerp(v1->x, v2->x, t);
  res->y = Lerp(v1->y, v2->y, t);
}

public U0 Lerp3(CD3 *v1, CD3 *v2, F64 t, CD3 *res) {
  res->x = Lerp(v1->x, v2->x, t);
  res->y = Lerp(v1->y, v2->y, t);
  res->z = Lerp(v1->z, v2->z, t);
}

public U0 GetAABBFromSize(CD3 *pos, CD2I32 *size, Vec4* res) {
  CD2I32 hs;
  hs.x = size->x/2;
  hs.y = size->y/2;
  res->x1 = pos->x - hs.x;
  res->x2 = pos->x + hs.x;
  res->y1 = pos->y - hs.y;
  res->y2 = pos->y + hs.y;
}

public U0 BezierQuadratic(CD2 *p0, CD2 *p1, CD2 *p2, F64 t, CD2 *res) {
  F64 tt = 1.0 - t;
  res->x = tt * tt * p0->x + 2 * tt * t * p1->x + t * t * p2->x;
  res->y = tt * tt * p0->y + 2 * tt * t * p1->y + t * t * p2->y;
}

public U0 GetPosOnCurve2(CD2 *p0, CD2 *p1, CD2 *p2, CD2 *p3, F64 t, CD2 *res) {
  CD2 a,b,c,d,e;
  Lerp2(p0, p1, t, &a);
  Lerp2(p1, p2, t, &b);
  Lerp2(p2, p3, t, &c);
  Lerp2(&a, &b, t, &d);
  Lerp2(&b, &c, t, &e);
  Lerp2(&d, &e, t, res);
}

public F64 CD3Len(CD3 *v) {
  return Sqrt(v->x*v->x + v->y*v->y + v->z*v->z);
}

public U0 CD3Normalize(CD3 *v) {
  //F64 norm = Sqrt(D3Dot(v, v));
  F64 norm = D3Norm(v);
  if (norm == 0.0) {
   v->x = 0;
   v->y = 0;
   v->z = 0;
   return;
  }
  norm = 1.0 / norm;
  v->x *= norm;
  v->y *= norm;
  v->z *= norm;
/*
  F64 length, ilength;
  length = CD3Len(v);
  if (length == 0.0)
    length = 1.0;
  ilength = 1.0/length;

  v->x *= ilength;
  v->y *= ilength;
  v->z *= ilength;
*/
}

public F64 Vec4Norm(F64 x, F64 y, F64 z, F64 w) {
  return Sqrt(x * x + y * y + z * z + w * w);
}

#endif
