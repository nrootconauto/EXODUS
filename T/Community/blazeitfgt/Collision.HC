#ifndef COLLISION_HC
#define COLLISION_HC

#define NO_COLLIDE 10000

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
    F64 w;
    F64 x2;
  }
  union {
    F64 h;
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

public U0 GetPosOnCurve2(CD2 *p0, CD2 *p1, CD2 *p2, CD2 *p3, F64 t, CD2 *res) {
  CD2 a,b,c,d,e;
  Lerp2(p0, p1, t, &a);
  Lerp2(p1, p2, t, &b);
  Lerp2(p2, p3, t, &c);
  Lerp2(&a, &b, t, &d);
  Lerp2(&b, &c, t, &e);
  Lerp2(&d, &e, t, res);
}

public Bool CheckCollisionAABB(Vec4 *aabb1, Vec4 *aabb2) {
  Bool d0 = aabb2->x2 < aabb1->x1;
  Bool d1 = aabb1->x2 < aabb2->x1;
  Bool d2 = aabb2->y2 < aabb1->y1;
  Bool d3 = aabb1->y2 < aabb2->y1;
  return !(d0 | d1 | d2 | d3);
}

public Bool CheckCollisionPoint(Vec4 *aabb, CD2 *p) {
  Bool d0 = p->x < aabb->x1;
  Bool d1 = p->y < aabb->y1;
  Bool d2 = p->x > aabb->x2;
  Bool d3 = p->y > aabb->y2;
  return !(d0 | d1 | d2 | d3);
}

public Bool CheckICollisionPoint(I64 x1, I64 y1, I64 x2, I64 y2, I64 px, I64 py) {
  Bool d0 = px < x1;
  Bool d1 = py < y1;
  Bool d2 = px > x2;
  Bool d3 = py > y2;
  return !(d0 | d1 | d2 | d3);
}

public U0 CheckCollisionLines(Vec4 *l1, Vec4 *l2, CD2 *res) {
  res->x = NO_COLLIDE;
  res->y = NO_COLLIDE;
  F64 collide = (l2->x2-l2->x1)*(l1->y2-l1->y1) - (l1->x2-l1->x1)*(l2->y2-l2->y1);
  if (collide > 0.01) {
    F64 lambda = ((l2->y1-l1->y1)*(l1->x2-l1->x1) - (l2->x1-l1->x1)*(l1->y2-l1->y1)) / collide;
    F64 gamma = ((l2->y1-l1->y1)*(l2->x2-l2->x1) - (l2->x1-l1->x1)*(l2->y2-l2->y1)) / collide;
    if (0.0 < lambda && lambda < 1.0 && 0.0 < gamma && gamma < 1.0) {
      res->x = l2->x1 + lambda*(l2->x2 - l2->x1);
      res->y = l2->y1 + lambda*(l2->y2 - l2->y1);
    }
  }
}

// res is array, eg. CD2 res[4]
public U0 CheckCollisionLineRec(Vec4 *l, Vec4* aabb, CD2* res) {
  Vec4 l2;
  // top-left - top-right
  l2.x1 = aabb->x;
  l2.y1 = aabb->y;
  l2.x2 = aabb->x2;
  l2.y2 = aabb->y;
  CheckCollisionLines(l, &l2, &res[0]);
  // top-left - bottom-left
  l2.x1 = aabb->x;
  l2.y1 = aabb->y2;
  l2.x2 = aabb->x;
  l2.y2 = aabb->y;
  CheckCollisionLines(l, &l2, &res[1]);
  // bottom-right - top-right
  l2.x1 = aabb->x2;
  l2.y1 = aabb->y;
  l2.x2 = aabb->x2;
  l2.y2 = aabb->y2;
  CheckCollisionLines(l, &l2, &res[2]);
  // bottom-right - bottom-left
  l2.x1 = aabb->x2;
  l2.y1 = aabb->y2;
  l2.x2 = aabb->x;
  l2.y2 = aabb->y2;
  CheckCollisionLines(l, &l2, &res[3]);
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

#endif