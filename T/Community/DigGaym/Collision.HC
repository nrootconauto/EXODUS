#ifndef COLLISION_HC
#define COLLISION_HC

#include "Vec"
#include "Map"

#define NO_COLLIDE 10000

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

public Bool CheckPointAABB(I32 x, I32 y, I32 x1, I32 x2, I32 y1, I32 y2) {
  if (x >= x1 && x <= x2 && y >= y1 && y <= y2)
    return TRUE;
  return FALSE;
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

public U0 ApplyVelCollideTile(Map *lvl, F64 delta, CD2 *pos, CD2 *vel, I32 w, I32 h) {
  I32 tmpY, tmpX, i, tw, th;

  // Collide X Axis
  pos->x += vel->x * delta;
  I32 x = Round(pos->x);
  I32 y = Round(pos->y);
  if (vel->x > 0.0) {
    tmpX = (x+w)/16;
    if (tmpX >= 0 && tmpX < lvl->width) {
      tmpY = y/16;
      th = Ceil((pos->y+h)/16)-tmpY;
      for (i=0; i<th; i++) {
        if (tmpY+i >= 0 && tmpY+i < lvl->height &&
            lvl->flags[(tmpY+i)*lvl->width+tmpX] & TFLAG_BLOCK) {
          pos->x = tmpX*16-w;
          vel->x = 0;
          break;
        }
      }
    }
  } else if (vel->x < 0.0) {
    tmpX = pos->x/16;
    if (tmpX >= 0 && tmpX < lvl->width) {
      tmpY = y/16;
      th = Ceil((pos->y+h)/16)-tmpY;
      for (i=0; i<th; i++) {
        if (tmpY+i >= 0 && tmpY+i < lvl->height &&
            lvl->flags[(tmpY+i)*lvl->width+tmpX] & TFLAG_BLOCK) {
          pos->x = tmpX*16+16;
          vel->x = 0;
          break;
        }
      }
    }
  }

  // Collide Y Axis
  pos->y += vel->y * delta;
  x = Round(pos->x);
  y = Round(pos->y);
  if (vel->y > 0.0) {
    tmpY = (y+h)/16;
    if (tmpY >= 0 && tmpY < lvl->height) {
      tmpX = x/16;
      tw = Ceil((pos->x+w)/16)-tmpX;
      for (i=0; i<tw; i++) {
        if (tmpX+i >= 0 && tmpX+i < lvl->width &&
            lvl->flags[tmpY*lvl->width+tmpX+i] & TFLAG_BLOCK) {
          pos->y = tmpY*16-h;
          vel->y = 0;
          break;
        }
      }
    }
  } else if (vel->y < 0) {
    tmpY = pos->y/16;
    if (tmpY >= 0 && tmpY < lvl->height) {
      tmpX = x/16;
      tw = Ceil((pos->x+w)/16)-tmpX;
      for (i=0; i<tw; i++) {
        if (tmpX+i >= 0 && tmpX+i < lvl->width &&
            lvl->flags[tmpY*lvl->width+tmpX+i] & TFLAG_BLOCK) {
          pos->y = tmpY*16+16;
          vel->y = 0;
          break;
        }
      }
    }
  }
}


public U0 ApplyVelCollideTileBounce(Map *lvl, F64 delta, CD2 *pos, CD2 *vel, I32 w, I32 h) {
  I64 tmpY, tmpX, i, tw, th;

  // Collide X Axis
  pos->x += vel->x * delta;
  if (vel->x > 0.0) {
    tmpX = (ToI64(pos->x) + w)/16;
    if (tmpX >= 0 && tmpX < lvl->width) {
      tmpY = pos->y/16;
      th = Ceil((pos->y+h)/16)-tmpY;
      for (i=0; i<th; i++) {
        if (tmpY+i >= 0 && tmpY+i < lvl->height &&
            lvl->flags[(tmpY+i)*lvl->width+tmpX] & TFLAG_BLOCK) {
          pos->x = tmpX*16-w;
          vel->x = -(vel->x/2);
          break;
        }
      }
    }
  } else if (vel->x < 0.0) {
    tmpX = ToI64(pos->x)/16;
    if (tmpX >= 0 && tmpX < lvl->width) {
      tmpY = pos->y/16;
      th = Ceil((pos->y+h)/16)-tmpY;
      for (i=0; i<th; i++) {
        if (tmpY+i >= 0 && tmpY+i < lvl->height &&
            lvl->flags[(tmpY+i)*lvl->width+tmpX] & TFLAG_BLOCK) {
          pos->x = tmpX*16+16;
          vel->x = -(vel->x/2);
          break;
        }
      }
    }
  }

  // Collide Y Axis
  pos->y += vel->y * delta;
  if (vel->y > 0.0) {
    tmpY = (ToI64(pos->y)+h)/16;
    if (tmpY >= 0 && tmpY < lvl->height) {
      tmpX = ToI64(pos->x)/16;
      tw = Ceil((pos->x+w)/16)-tmpX;
      for (i=0; i<tw; i++) {
        if (tmpX+i >= 0 && tmpX+i < lvl->width &&
            lvl->flags[tmpY*lvl->width+tmpX+i] & TFLAG_BLOCK) {
          pos->y = tmpY*16-h;
          vel->y = -(vel->y/2);
          break;
        }
      }
    }
  } else if (vel->y < 0) {
    tmpY = ToI64(pos->y)/16;
    if (tmpY >= 0 && tmpY < lvl->height) {
      tmpX = ToI64(pos->x)/16;
      tw = Ceil((pos->x+w)/16)-tmpX;
      for (i=0; i<tw; i++) {
        if (tmpX+i >= 0 && tmpX+i < lvl->width &&
            lvl->flags[tmpY*lvl->width+tmpX+i] & TFLAG_BLOCK) {
          pos->y = tmpY*16+16;
          vel->y = -(vel->y/2);
          break;
        }
      }
    }
  }
}

public U0 ApplyVelCollidePointTileBounce(Map *lvl, F64 delta, CD2 *pos, CD2 *vel) {
  I64 tmpY, tmpX;

  // Collide X Axis
  pos->x += vel->x * delta;
  if (vel->x > 0.0) {
    tmpX = ToI64(pos->x+1)/16;
    if (tmpX >= 0 && tmpX < lvl->width) {
      tmpY = pos->y/16;
      if (tmpY >= 0 && tmpY < lvl->height &&
          lvl->flags[tmpY*lvl->width+tmpX] & TFLAG_BLOCK) {
        pos->x = tmpX*16-1;
        vel->x = -(vel->x/2);
      }
    }
  } else if (vel->x < 0.0) {
    tmpX = ToI64(pos->x-1)/16;
    if (tmpX >= 0 && tmpX < lvl->width) {
      tmpY = pos->y/16;
      if (tmpY >= 0 && tmpY < lvl->height &&
          lvl->flags[tmpY*lvl->width+tmpX] & TFLAG_BLOCK) {
        pos->x = tmpX*16+16;
        vel->x = -(vel->x/2);
      }
    }
  }

  // Collide Y Axis
  pos->y += vel->y * delta;
  if (vel->y > 0.0) {
    tmpY = ToI64(pos->y+1)/16;
    if (tmpY >= 0 && tmpY < lvl->height) {
      tmpX = ToI64(pos->x)/16;
      if (tmpX >= 0 && tmpX < lvl->width &&
          lvl->flags[tmpY*lvl->width+tmpX] & TFLAG_BLOCK) {
        pos->y = tmpY*16-1;
        vel->y = -(vel->y/2);
      }
    }
  } else if (vel->y < 0) {
    tmpY = ToI64(pos->y-1)/16;
    if (tmpY >= 0 && tmpY < lvl->height) {
      tmpX = ToI64(pos->x)/16;
      if (tmpX >= 0 && tmpX < lvl->width &&
          lvl->flags[tmpY*lvl->width+tmpX] & TFLAG_BLOCK) {
        pos->y = tmpY*16+16;
        vel->y = -(vel->y/2);
      }
    }
  }
}

public U0 ApplyDrag(F64 *vel, F64 amount, F64 delta) {
  if (*vel > 0) {
    *vel -= amount * delta;
    if (*vel < 0) {
      *vel = 0;
    }
  } else if (*vel < 0) {
    *vel += amount * delta;
    if (*vel > 0) {
      *vel = 0;
    }
  }
/*
  if (vel->y > 0) {
    vel->y -= amount * delta;
    if (vel->y < 0) {
      vel->y = 0;
    }
  } else if (vel->y < 0) {
    vel->y += amount * delta;
    if (vel->y > 0) {
      vel->y = 0;
    }
  }
*/
}

#endif