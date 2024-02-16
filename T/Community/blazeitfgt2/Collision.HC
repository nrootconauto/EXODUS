#ifndef COLLISION_HC
#define COLLISION_HC

#include "Assets"
#include "Vec"

public Bool CheckCollideAABB(Vec4 *aabb1, Vec4 *aabb2) {
  Bool d0 = aabb2->x2 < aabb1->x1;
  Bool d1 = aabb1->x2 < aabb2->x1;
  Bool d2 = aabb2->y2 < aabb1->y1;
  Bool d3 = aabb1->y2 < aabb2->y1;
  return !(d0 | d1 | d2 | d3);
}

public Bool CheckCollidePoint(Vec4 *aabb, CD2 *p) {
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

public Bool CheckCollideCircle(F64 x1,F64 y1,F64 r1,F64 x2,F64 y2,F64 r2) {
  F64 dx = x1 - x2;
  F64 dy = y1 - y2;
  if (Sqrt(dx*dx + dy*dy) <= r1+r2)
    return TRUE;
  return FALSE;
}

public Bool CheckCollideCirclePoint(F64 cx,F64 cy,F64 cr, CD2I32 p) {
  F64 dx = cx - p.x;
  F64 dy = cy - p.y;
  if (Sqrt(dx*dx + dy*dy) <= cr)
    return TRUE;
  return FALSE;
}

public Bool CheckCollideCircleRec(F64 cx,F64 cy,F64 cr,F64 x1, F64 x2,F64 y1,F64 y2) {
  F64 dx = cx - Max(x1,Min(cx,x2));
  F64 dy = cy - Max(y1,Min(cy,y2));
  if (dx*dx + dy*dy < cr*cr)
    return TRUE;
  return FALSE;
}

public U0 CheckCollideLines(Vec4 *l1, Vec4 *l2, CD2 *res) {
  res->x = inf;
  res->y = inf;
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
public U0 CheckCollideLineRec(Vec4 *l, Vec4* aabb, CD2* res) {
  Vec4 l2;
  // top-left - top-right
  l2.x1 = aabb->x;
  l2.y1 = aabb->y;
  l2.x2 = aabb->x2;
  l2.y2 = aabb->y;
  CheckCollideLines(l, &l2, &res[0]);
  // top-left - bottom-left
  l2.x1 = aabb->x;
  l2.y1 = aabb->y2;
  l2.x2 = aabb->x;
  l2.y2 = aabb->y;
  CheckCollideLines(l, &l2, &res[1]);
  // bottom-right - top-right
  l2.x1 = aabb->x2;
  l2.y1 = aabb->y;
  l2.x2 = aabb->x2;
  l2.y2 = aabb->y2;
  CheckCollideLines(l, &l2, &res[2]);
  // bottom-right - bottom-left
  l2.x1 = aabb->x2;
  l2.y1 = aabb->y2;
  l2.x2 = aabb->x;
  l2.y2 = aabb->y2;
  CheckCollideLines(l, &l2, &res[3]);
}

public U0 GetAABBFromSize(CD2 *pos, CD2I32 *size, Vec4* res) {
  CD2I32 hs;
  hs.x = size->x/2;
  hs.y = size->y/2;
  res->x1 = pos->x - hs.x;
  res->x2 = pos->x + hs.x;
  res->y1 = pos->y - hs.y;
  res->y2 = pos->y + hs.y;
}

public Bool CheckCollidePolyCircle(CD2I32 *poly, I64 cnt, F64 x, F64 y, F64 r) {
  U32 i;
  for (i=0; i<cnt-1; i++) {
    CD2 a, b, e;
    a.x = poly[i].x;
    a.y = poly[i].y;
    b.x = poly[i+1].x;
    b.y = poly[i+1].y;
    e.x = -(b.y - a.y);
    e.y = b.x - a.x;
    F64 d = Sqrt(e.x * e.x + e.y * e.y);
    e.x /= d;
    e.y /= d;
    F64 min1 = inf;
    F64 max1 = -inf;
    U32 ii;
    for (ii=0; ii<cnt; ii++) {
      F64 q = ToF64(poly[ii].x)*e.x + ToF64(poly[ii].y)*e.y;
      if (min1 > q)
        min1 = q;
      if (max1 < q)
        max1 = q;
    }
    CD2 circleDir, p1, p2;
    circleDir.x = e.x * r;
    circleDir.y = e.y * r;
    p1.x = x + circleDir.x;
    p1.y = y + circleDir.y;
    p2.x = x - circleDir.x;
    p2.y = y - circleDir.y;
    F64 min2 = p1.x * e.x + p1.y * e.y;
    F64 max2 = p2.x * e.x + p2.y * e.y;
    if (min2 > max2) {
      F64 t = min2;
      min2 = max2;
      max2 = t;
    }
    if (min1 >= max2 || min2 >= max1)
      return FALSE;
  }
  return TRUE;
}

public U0 CheckCollidePolyLine(CD2I32 *poly, I64 cnt, Vec4 *line, CD2 *res) {
  U32 i;
  Vec4 pLine;
  res->x = inf;
  for (i=0; i<cnt-1; i++) {
    pLine.x1 = poly[i].x;
    pLine.y1 = poly[i].y;
    pLine.x2 = poly[i+1].x;
    pLine.y2 = poly[i+1].y;
    CheckCollideLines(line, &pLine, res);
    if (res->x != inf)
      return;
  }
}

public Bool CheckCollidePolyPoint(CD2I32 *poly, I64 cnt, CD2I32 p) {
  U32 i;
  for (i=0; i<cnt-1; i++) {
    CD2 a, b, e;
    a.x = poly[i].x;
    a.y = poly[i].y;
    b.x = poly[i+1].x;
    b.y = poly[i+1].y;
    e.x = -(b.y - a.y);
    e.y = b.x - a.x;
    F64 d = Sqrt(e.x * e.x + e.y * e.y);
    e.x /= d;
    e.y /= d;
    F64 min1 = inf;
    F64 max1 = -inf;
    U32 ii;
    for (ii=0; ii<cnt; ii++) {
      F64 q = ToF64(poly[ii].x)*e.x + ToF64(poly[ii].y)*e.y;
      if (min1 > q)
        min1 = q;
      if (max1 < q)
        max1 = q;
    }
    F64 min2 = p.x * e.x + p.y * e.y;
    if (min1 >= min2 || min2 >= max1)
      return FALSE;
  }
  return TRUE;
}

public Bool CollidePolyBezier(CD2I32 *ctrl, CD2I32 *poly, I64 cnt, CD2I32 *res) {
  I64 dx,dy,d_max;
  F64 x0=ctrl[0].x,y0=ctrl[0].y,
      x1=ctrl[1].x-x0,y1=ctrl[1].y-y0,
      x2=ctrl[2].x-x0,y2=ctrl[2].y-y0,t;
  F64 d=Sqrt(SqrI64(ctrl[0].x-ctrl[1].x)+SqrI64(ctrl[0].y-ctrl[1].y))+
        Sqrt(SqrI64(ctrl[1].x-ctrl[2].x)+SqrI64(ctrl[1].y-ctrl[2].y))+
        Sqrt(SqrI64(ctrl[2].x-ctrl[0].x)+SqrI64(ctrl[2].y-ctrl[0].y));
  F64 s=0.5/d,t1,t2;
  CD2I32 p, pp;
  pp.x = x0;
  pp.y = y0;

  if (CheckCollidePolyPoint(poly, cnt, pp)) {
    res->x = pp.x;
    res->y = pp.y;
    return TRUE;
  }

  for (t=0.0;t<=1.0;t+=s) {
    t1=t*(1.0-t);
    t2=t*t;
    p.x=x0+x1*t1+x2*t2;
    p.y=y0+y1*t1+y2*t2;
    dx=AbsI64(p.x-pp.x);
    dy=AbsI64(p.y-pp.y);
    if (dx>dy)
      d_max=dx;
    else
      d_max=dy;
    if (!d_max)
      s*=1.1;
    else {
      s*=0.9;
      if (CheckCollidePolyPoint(poly, cnt, p)) {
        res->x = p.x;
        res->y = p.y;
        return TRUE;
      }
      pp.x=p.x;
      pp.y=p.y;
    }
  }
  p.x=ctrl[2].x; p.y=ctrl[2].y;
  if ((pp.x!=p.x || pp.y!=p.y) && CheckCollidePolyPoint(poly, cnt, p)) {
    res->x = p.x;
    res->y = p.y;
    return TRUE;
  }
  return FALSE;
}

public Bool CollideCircleBezier(CD2I32 *ctrl, F64 cx, F64 cy, F64 cr, CD2I32 *res) {
  I64 dx,dy,d_max;
  F64 x0=ctrl[0].x,y0=ctrl[0].y,
      x1=ctrl[1].x-x0,y1=ctrl[1].y-y0,
      x2=ctrl[2].x-x0,y2=ctrl[2].y-y0,t;
  F64 d=Sqrt(SqrI64(ctrl[0].x-ctrl[1].x)+SqrI64(ctrl[0].y-ctrl[1].y))+
        Sqrt(SqrI64(ctrl[1].x-ctrl[2].x)+SqrI64(ctrl[1].y-ctrl[2].y))+
        Sqrt(SqrI64(ctrl[2].x-ctrl[0].x)+SqrI64(ctrl[2].y-ctrl[0].y));
  F64 s=0.5/d,t1,t2;
  CD2I32 p, pp;
  pp.x = x0;
  pp.y = y0;

  if (CheckCollideCirclePoint(cx, cy, cr, pp)) {
    res->x = pp.x;
    res->y = pp.y;
    return TRUE;
  }

  for (t=0.0;t<=1.0;t+=s) {
    t1=t*(1.0-t);
    t2=t*t;
    p.x=x0+x1*t1+x2*t2;
    p.y=y0+y1*t1+y2*t2;
    dx=AbsI64(p.x-pp.x);
    dy=AbsI64(p.y-pp.y);
    if (dx>dy)
      d_max=dx;
    else
      d_max=dy;
    if (!d_max)
      s*=1.1;
    else {
      s*=0.9;
      if (CheckCollideCirclePoint(cx, cy, cr, p)) {
        res->x = p.x;
        res->y = p.y;
        return TRUE;
      }
      pp.x=p.x;
      pp.y=p.y;
    }
  }
  p.x=ctrl[2].x; p.y=ctrl[2].y;
  if ((pp.x!=p.x || pp.y!=p.y) && CheckCollideCirclePoint(cx, cy, cr, p)) {
    res->x = p.x;
    res->y = p.y;
    return TRUE;
  }
  return FALSE;
}

#endif
