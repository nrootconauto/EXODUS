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
    I32 x;
    I32 x1;
  }
  union {
    I32 y;
    I32 y1;
  }
  union {
    I32 w;
    I32 x2;
  }
  union {
    I32 h;
    I32 y2;
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
  hs.x = size->x>>1;
  hs.y = size->y>>1;
  res->x1 = pos->x - hs.x;
  res->x2 = pos->x + hs.x;
  res->y1 = pos->y - hs.y;
  res->y2 = pos->y + hs.y;
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

public F64 CD2Magnitude(CD2 *v) {
  return Sqrt(v->x * v->x + v->y * v->y);
}

public U0 CD2Normalize(CD2 *v) {
  F64 length = CD2Magnitude(v);
  if (length == 0)
    return;
  v->x /= length;
  v->y /= length;
}

public F64 CD2Dot(CD2 *lhs, CD2 *rhs) {
  return lhs->x * rhs->x + lhs->y * rhs->y;
}

public U0 CD2DotDirection(CD2 *lhs, CD2 *rhs) {
  CD2Normalize(rhs);
  F64 dot = CD2Dot(lhs, rhs);
  rhs->x *= dot;
  rhs->y *= dot;
}

public U0 CD2Perpendicular(CD2 *origin, CD2 *target, CD2 *dst) {
  CD2 diff;
  diff.x = target->x-origin->x; // +8 is for player offset
  diff.y = target->y-origin->y; // +16 is for player offset
  CD2Normalize(&diff);
  dst->x = diff.y;
  dst->y = -diff.x;
}

#endif