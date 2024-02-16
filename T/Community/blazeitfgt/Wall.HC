#ifndef WALL_HC
#define WALL_HC

#include "Collision";
#include "Draw";
#include "Vector";

class WallPost {
  CD3 pos;
};

class Wall {
  Vec4 l;
  F64 health;
  F64 lastHitRot;
};

public U0 DmgWall(Wall* wall, F64 dmg, F64 rot) {
  wall->health -= dmg;
  wall->lastHitRot = rot;
}

public U0 DrawWall(CDC* dc, Wall* w, I64 cnt, Cam *cam, F64 t_now) {
  I64 i, mat[4][4];
  Mat4x4IdentEqu(mat);
  Mat4x4TranslationAdd(mat, -cam->pos.x, -cam->pos.y, 0);
  Mat4x4Scale(mat, cam->zoom);
  dc->r = mat;
  dc->r_norm = Sqrt(Mat4x4NormSqr65536(mat))*65536;
  for (i=0; i<cnt; i++) {
    dc->color = YELLOW;
    GrLine3F(dc, w[i].l.x1, w[i].l.y1, 0, w[i].l.x2, w[i].l.y2, 0);

    dc->color = BLUE;
    F64 rot = Arg(w[i].l.x2 - w[i].l.x1, w[i].l.y2 - w[i].l.y1);
    I64 modx = Sin(t_now)*8*Sin(rot);
    I64 x1 = w[i].l.x1+modx;
    I64 mody = Cos(t_now)*8*Cos(rot);
    I64 y1 = w[i].l.y1+mody;
    I64 x2 = w[i].l.x2+modx;
    I64 y2 = w[i].l.y2+mody;
    GrLine3F(dc, x1, y1, 0, x2, y2, 0);


    modx = Sin(t_now+pi)*8*Sin(rot);
    x1 = w[i].l.x1+modx;
    mody = Cos(t_now+pi)*8*Cos(rot);
    y1 = w[i].l.y1+mody;
    x2 = w[i].l.x2+modx;
    y2 = w[i].l.y2+mody;
    GrLine3F(dc, x1, y1, 0, x2, y2, 0);
  }
}

public U0 GenWalls(WallPost *posts, I64 cnt, Vector *vWalls) {
  I64 i, ii;
  vWalls->len = 0;
  for (i=0; i<cnt; i++) {
    for (ii=i; ii<cnt; ii++) {
      if (i != ii) {
        F64 dist = Abs(posts[ii].pos.x - posts[i].pos.x) + AbsI64(posts[ii].pos.y - posts[i].pos.y);
        if (dist <= 256) {
          Wall nwall;
          nwall.l.x1 = posts[i].pos.x;
          nwall.l.y1 = posts[i].pos.y;
          nwall.l.x2 = posts[ii].pos.x;
          nwall.l.y2 = posts[ii].pos.y;
          nwall.health = 200;
          VectorAdd(vWalls, &nwall);
        }
      }
    }
  }
}

#endif
