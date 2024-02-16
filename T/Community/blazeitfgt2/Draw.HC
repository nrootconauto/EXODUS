// Matrix math based on raymath.h under zlib/libpng license

#ifndef DRAW_HC
#define DRAW_HC

#include "GrFast"
#include "Quaternion"

public class GrBuff {
  I64 mat[4][4];
};

public class Cam {
  CD3 pos;
  CD3 target;
  F64 zoom;
  CD3 up;
  I64 mat[4][4];
};

// No symmetry, mirror, etc
public U0 GrFillPoly3F(CDC *dc, I64 n, CD3I32 *poly) {
  CD3I32 tri[3];
  I64 i,j,x,y,z;
  for (i=1;i<n-1;i++) {
    j=i-1;
    if (i==1) {
      x=poly[j].x; y=poly[j].y; z=poly[j].z;
      if (dc->flags&DCF_TRANSFORMATION)
	(*dc->transform)(dc,&x,&y,&z);
      tri[0].x=x; tri[0].y=y; tri[0].z=z;
    }

    j++;
    if (i==1) {
      x=poly[j].x; y=poly[j].y; z=poly[j].z;
      if (dc->flags&DCF_TRANSFORMATION)
	(*dc->transform)(dc,&x,&y,&z);
    }
    tri[1].x=x; tri[1].y=y; tri[1].z=z;

    j++;
    x=poly[j].x; y=poly[j].y; z=poly[j].z;
    if (dc->flags&DCF_TRANSFORMATION)
      (*dc->transform)(dc,&x,&y,&z);
    tri[2].x=x; tri[2].y=y; tri[2].z=z;

    GrFillTri0(dc,&tri[0],&tri[1],&tri[2]);
  }
}

// assumes lighting + transform
public U0 GrFillPoly3L(CDC *dc, I64 n, CD3I32 *poly, CColorROPU32 color) {
  CD3I32 tri[3];
  I64 i,j,x,y,z;
  for (i=1;i<n-1;i++) {
    j=i-1;
    if (i==1) {
      x=poly[j].x; y=poly[j].y; z=poly[j].z;
      (*dc->transform)(dc,&x,&y,&z);
      tri[0].x=x; tri[0].y=y; tri[0].z=z;
    }

    j++;
    if (i==1) {
      x=poly[j].x; y=poly[j].y; z=poly[j].z;
      (*dc->transform)(dc,&x,&y,&z);
    }
    tri[1].x=x; tri[1].y=y; tri[1].z=z;

    j++;
    x=poly[j].x; y=poly[j].y; z=poly[j].z;
    (*dc->transform)(dc,&x,&y,&z);
    tri[2].x=x; tri[2].y=y; tri[2].z=z;

    (*dc->lighting)(dc, &tri[0], &tri[1], &tri[2], color);

    GrFillTri0(dc,&tri[0],&tri[1],&tri[2]);
  }
}

// uses GrFillPoly3F for performance
public U0 GrRect3F(CDC *dc, I64 x, I64 y, I64 z, I64 w, I64 h) {
  CD3I32 poly[4];
  poly[0].x=x;
  poly[0].y=y;
  poly[0].z=z;
  poly[1].x=x+w;
  poly[1].y=y;
  poly[1].z=z;
  poly[2].x=x+w;
  poly[2].y=y+h;
  poly[2].z=z;
  poly[3].x=x;
  poly[3].y=y+h;
  poly[3].z=z;
  GrFillPoly3F(dc,4,poly);
}

// assumes lighting and transform
public U0 GrRect3L(CDC *dc, I64 x, I64 y, I64 z, I64 w, I64 h, CColorROPU32 color) {
  CD3I32 poly[4];
  poly[0].x=x;
  poly[0].y=y;
  poly[0].z=z;
  poly[1].x=x+w;
  poly[1].y=y;
  poly[1].z=z;
  poly[2].x=x+w;
  poly[2].y=y+h;
  poly[2].z=z;
  poly[3].x=x;
  poly[3].y=y+h;
  poly[3].z=z;
  GrFillPoly3L(dc,4,poly,color);
}

// Always transform, never brush, never thick
public U0 GrLine3F(CDC *dc,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2,I32 *db) {
  (*dc->transform)(dc,&x1,&y1,&z1);
  (*dc->transform)(dc,&x2,&y2,&z2);
  LineF(dc,x1,y1,z1,x2,y2,z2,&Plot3F,db);
}

public U0 EllipseF(U8 *aux_data,I64 cx,I64 cy,I64 cz,
	I64 x_radius,I64 y_radius,U0 (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z,I32 *db),
	I32 *db, F64 rot_angle=0,F64 start_radians=0,F64 len_radians=2*ã) {
  I64 i,len,
	x,y,_x,_y,x1,y1,x2,y2, s1,s2,c, s12,s22,c2;
  F64 t;
  if (x_radius<=0 || y_radius<=0)
    return;
  if (x_radius>=y_radius) {
    t=1.0/x_radius;
    len=Ceil(len_radians*x_radius);
  } else {
    t=1.0/y_radius;
    len=Ceil(len_radians*y_radius);
  }

  c=1<<GR_SCALE1_BITS*Cos(t);
  s1=1<<GR_SCALE1_BITS*Sin(t);
  s2=-s1;

  c2=1<<GR_SCALE1_BITS*Cos(rot_angle);
  s12=1<<GR_SCALE1_BITS*Sin(rot_angle);
  s22=-s12;

  if (start_radians) {
    x=x_radius*Cos(start_radians);
    y=-x_radius*Sin(start_radians);
  } else {
    x=x_radius;
    y=0;
  }
  x<<=GR_SCALE2_BITS;
  y<<=GR_SCALE2_BITS;
  x2=x;
  y2=y;

  y1=y2*y_radius/x_radius;
  x=(c2*x2+s12*y1)>>GR_SCALE1_BITS;
  y=(s22*x2+c2*y1)>>GR_SCALE1_BITS;

  for (i=0;i<=len;i++) {
    (*fp_plot)(aux_data,cx+x>>GR_SCALE2_BITS,cy+y>>GR_SCALE2_BITS,cz,db);
    _x=x>>GR_SCALE2_BITS; _y=y>>GR_SCALE2_BITS;
    x1=(c*x2+s1*y2)>>GR_SCALE1_BITS;
    y1=(s2*x2+c*y2)>>GR_SCALE1_BITS;
    x2=x1;
    y2=y1;
    y1=y1*y_radius/x_radius;
    x=(c2*x1+s12*y1)>>GR_SCALE1_BITS;
    y=(s22*x1+c2*y1)>>GR_SCALE1_BITS;
  }
}

public U0 GrEllipse3F(CDC *dc,
		I64 cx,I64 cy,I64 cz,
		I64 x_radius,I64 y_radius,I32 *db,
		F64 rot_angle=0,
		F64 start_radians=0,
		F64 len_radians=2*ã)
{
  I64 x,y,z,xx,yy,zz;
  F64 m1,arg1,m2,arg2,s,c;
  (*dc->transform)(dc,&cx,&cy,&cz);

  c=Cos(rot_angle);
  s=Sin(rot_angle);

  x_radius<<=16;
  y_radius<<=16;

  xx=0;
  yy=0;
  zz=0;
  (*dc->transform)(dc,&xx,&yy,&zz);

  x=x_radius*c;
  y=x_radius*s;
  z=0;
  (*dc->transform)(dc,&x,&y,&z);
  x-=xx;
  y-=yy;
  z-=zz;
  R2P(&m1,&arg1,x,y);

  x=-y_radius*s;
  y=y_radius*c;
  z=0;
  (*dc->transform)(dc,&x,&y,&z);
  x-=xx;
  y-=yy;
  z-=zz;
  R2P(&m2,&arg2,x,y);
  m2*=Abs(Sin(arg2-arg1));

  EllipseF(dc,cx,cy,cz,
          m1/0x10000,m2/0x10000,&Plot3F,db,-arg1,start_radians,len_radians);
}

public U0 Bezier2F(U8 *aux_data,CD2I32 *ctrl,U0 (*fp_plot)(U8 *aux,I64 x,I64 y)){
  I64 x,y,xx,yy,dx,dy,d_max;
  F64 x0=ctrl[0].x,y0=ctrl[0].y,
	x1=ctrl[1].x-x0,y1=ctrl[1].y-y0,
	x2=ctrl[2].x-x0,y2=ctrl[2].y-y0,
	t;
  F64 d=Sqrt(SqrI64(ctrl[0].x-ctrl[1].x)+SqrI64(ctrl[0].y-ctrl[1].y))+
        Sqrt(SqrI64(ctrl[1].x-ctrl[2].x)+SqrI64(ctrl[1].y-ctrl[2].y))+
        Sqrt(SqrI64(ctrl[2].x-ctrl[0].x)+SqrI64(ctrl[2].y-ctrl[0].y));
  F64 s=0.5/d,t1,t2;
  xx=x0; yy=y0;

  (*fp_plot)(aux_data,xx,yy);

  for (t=0.0;t<=1.0;t+=s) {
    t1=t*(1.0-t);
    t2=t*t;
    x=x0+x1*t1+x2*t2;
    y=y0+y1*t1+y2*t2;
    dx=AbsI64(x-xx);
    dy=AbsI64(y-yy);
    if (dx>dy)
      d_max=dx;
    else
      d_max=dy;
    if (!d_max)
      s*=1.1;
    else {
      s*=0.9;
      (*fp_plot)(aux_data,x,y);
      xx=x;
      yy=y;
    }
  }
  x=ctrl[2].x; y=ctrl[2].y;
  if (xx!=x || yy!=y)
    (*fp_plot)(aux_data,x,y);
}

public U0 Bezier2FN(CDC *dc, CD2I32 *ctrl, I32 width) {
  I64 x,y,xx,yy,dx,dy,d_max;
  F64 x0=ctrl[0].x,    y0=ctrl[0].y+PIX_TOP,
      x1=ctrl[1].x-x0, y1=ctrl[1].y-ctrl[0].y,
      x2=ctrl[2].x-x0, y2=ctrl[2].y-ctrl[0].y,
      t,t1,t2;
  F64 d=Sqrt(SqrI64(ctrl[0].x-ctrl[1].x)+SqrI64(ctrl[0].y-ctrl[1].y))+
        Sqrt(SqrI64(ctrl[1].x-ctrl[2].x)+SqrI64(ctrl[1].y-ctrl[2].y))+
        Sqrt(SqrI64(ctrl[2].x-ctrl[0].x)+SqrI64(ctrl[2].y-ctrl[0].y));
  F64 s=0.5/d;
  xx=x0; yy=y0;

  //(*fp_plot)(aux_data,xx,yy);

  for (t=0.0;t<=1.0;t+=s) {
    t1=t*(1.0-t);
    t2=t*t;
    x=x0+x1*t1+x2*t2;
    y=y0+y1*t1+y2*t2;
    dx=AbsI64(x-xx);
    dy=AbsI64(y-yy);
    if (dx>dy)
      d_max=dx;
    else
      d_max=dy;
    if (!d_max)
      s*=1.1;
    else {
      s*=0.9;
      dx = x-xx;
      dy = y-yy;
      F64 mag = Sqrt(dx*dx+dy*dy);
      dx /= mag;
      dy /= mag;
      F64 sx = x - dy*(width/2);
      F64 sy = y - dx*(width/2);
      I32 i;
      U8 color = dc->color;
      for (i=0; i<width; i++) {
        sx += dy;
        sy += dx;
        xx = sx;
        yy = sy;
        if (0<=xx<SCR_W && PIX_TOP<=yy<SCR_H)
          dc->body[SCR_W*yy+xx] = color;
      }
      color = (dc->color+1)%16;
      sx = x - dy*(width/4);
      sy = y - dx*(width/4);
      for (i=0; i<width/2; i++) {
        sx += dy;
        sy += dx;
        xx = sx;
        yy = sy;
        if (0<=xx<SCR_W && PIX_TOP<=yy<SCR_H)
          dc->body[SCR_W*yy+xx] = color;
      }
      xx=x;
      yy=y;
    }
  }
//  x=ctrl[2].x; y=ctrl[2].y;
//  if (xx!=x || yy!=y)
//    (*fp_plot)(aux_data,x,y);
}

public U0 Gr2BezierF(CDC *dc, CD2I32 *ctrl) {
  Bezier2F(dc,ctrl,&Plot1F);
}

public U0 DCMat4x4SetFast(CDC *dc, I64 *r) {
  dc->r = r;
  dc->r_norm = Sqrt(Mat4x4NormSqr65536(r))*65536;
}

public U0 DrawRecBorder(CDC* dc, I64 x, I64 y, I64 w, I64 h) {
  // Draw Map Background
  DrawRect(dc->body, x+1, y+1, w-1, h-1, BLACK);
  // Draw Map Borders
  dc->color = WHITE;
  y += dc->win_task->pix_top+dc->win_task->scroll_y;
  Line(dc,x,y,0,x+w,y,0,&GrLinePlot0,1,0);
  Line(dc,x,y+h,0,x+w,y+h,0,&GrLinePlot0,1,0);
  Line(dc,x,y,0,x,y+h,0,&GrLinePlot0,1,0);
  Line(dc,x+w,y,0,x+w,y+h,0,&GrLinePlot0,1,0);
}

public U0 DrawLines(CDC *dc, I64 cnt, CD3I32 *lines, I32 *db) {
  I64 i;
  for (i=0; i<cnt; i+=2)
    GrLine3F(dc, lines[i].x, lines[i].y, lines[i].z, lines[i+1].x, lines[i+1].y, lines[i+1].z, db);
}

public U0 DrawLinesC(CDC *dc, I64 cnt, CD2I32 *lines) {
  I64 i;
  for (i=0; i<cnt-1; i++)
    GrLine(dc, lines[i].x, lines[i].y, lines[i+1].x, lines[i+1].y);
}

U0 DrawTri(CDC *dc, CD3 *pos, F64 rot, CD3I32 *tri, I64 cnt, F64 scale, Cam *cam, I32 *db) {
  I64 i, mat[4][4];
  Mat4x4IdentEqu(mat);
  Mat4x4RotZ(mat,rot);
  Mat4x4Scale(mat, scale);
  Mat4x4TranslationAdd(mat, pos->x-cam->pos.x, pos->y-cam->pos.y, 0);
  Mat4x4Scale(mat, cam->zoom);
  dc->r = mat;
  dc->r_norm = Sqrt(Mat4x4NormSqr65536(mat))*65536;
  for (i=0; i<cnt; i++) {
    GrLine3F(dc, tri[i*3].x, tri[i*3].y, tri[i*3].z, tri[i*3+1].x, tri[i*3+1].y, tri[i*3+1].z, db);
    GrLine3F(dc, tri[i*3+1].x, tri[i*3+1].y, tri[i*3+1].z, tri[i*3+2].x, tri[i*3+2].y, tri[i*3+2].z, db);
    GrLine3F(dc, tri[i*3+2].x, tri[i*3+2].y, tri[i*3+2].z, tri[i*3].x, tri[i*3].y, tri[i*3].z, db);
  }
}

/*
public U0 DrawObj(CDC *dc, I64 cnt, CD3I32 *lines, I64 x, I64 y, I64 z, F64 rx, F64 ry, F64 rz, F64 scale, Cam* cam) {
  I64 mat[4][4];
  Mat4x4IdentEqu(mat);
  if (rx != 0.0)
    Mat4x4RotX(mat,rx);
  if (ry != 0.0)
    Mat4x4RotY(mat,ry);
  if (rz != 0.0)
    Mat4x4RotZ(mat,rz);
  Mat4x4Scale(mat, scale);
  Mat4x4TranslationAdd(mat, x-cam->pos.x, y-cam->pos.y, z-cam->pos.z);
  Mat4x4Scale(mat, cam->zoom);
  dc->r = mat;
  I64 i;
  for (i=0; i<cnt; i+=2)
    GrLine3F(dc, lines[i].x, lines[i].y, lines[i].z, lines[i+1].x, lines[i+1].y, lines[i+1].z, db);
}
*/

// D3Sub returns difference
U0 CD3Sub(CD3 *res, CD3 *v1, CD3 *v2) {
  res->x = v1->x - v2->x;
  res->y = v1->y - v2->y;
  res->z = v1->z - v2->z;
}

F64 CD3Len(CD3 *v) {
  return Sqrt(v->x*v->x + v->y*v->y + v->z*v->z);
}

// D3Norm returns a single float???
U0 CD3Norm(CD3 *v) {
  F64 length, ilength;
  length = CD3Len(v);
  if (length == 0.0)
    length = 1.0;
  ilength = 1.0/length;

  v->x *= ilength;
  v->y *= ilength;
  v->z *= ilength;
}

public U0 MatrixInvert(F64 *fmat, I64 *res) {
  F64 a00 = fmat[0], a01 = fmat[1], a02 = fmat[2], a03 = fmat[3];
  F64 a10 = fmat[4], a11 = fmat[5], a12 = fmat[6], a13 = fmat[7];
  F64 a20 = fmat[8], a21 = fmat[9], a22 = fmat[10], a23 = fmat[11];
  F64 a30 = fmat[12], a31 = fmat[13], a32 = fmat[14], a33 = fmat[15];

  F64 b00 = a00*a11 - a01*a10;
  F64 b01 = a00*a12 - a02*a10;
  F64 b02 = a00*a13 - a03*a10;
  F64 b03 = a01*a12 - a02*a11;
  F64 b04 = a01*a13 - a03*a11;
  F64 b05 = a02*a13 - a03*a12;
  F64 b06 = a20*a31 - a21*a30;
  F64 b07 = a20*a32 - a22*a30;
  F64 b08 = a20*a33 - a23*a30;
  F64 b09 = a21*a32 - a22*a31;
  F64 b10 = a21*a33 - a23*a31;
  F64 b11 = a22*a33 - a23*a32;

  F64 invDet = GR_SCALE/(b00*b11 - b01*b10 + b02*b09 + b03*b08 - b04*b07 + b05*b06);

  res[0] = (a11*b11 - a12*b10 + a13*b09)*invDet;
  res[1] = (-a01*b11 + a02*b10 - a03*b09)*invDet;
  res[2] = (a31*b05 - a32*b04 + a33*b03)*invDet;
  res[3] = (-a21*b05 + a22*b04 - a23*b03)*invDet;
  res[4] = (-a10*b11 + a12*b08 - a13*b07)*invDet;
  res[5] = (a00*b11 - a02*b08 + a03*b07)*invDet;
  res[6] = (-a30*b05 + a32*b02 - a33*b01)*invDet;
  res[7] = (a20*b05 - a22*b02 + a23*b01)*invDet;
  res[8] = (a10*b10 - a11*b08 + a13*b06)*invDet;
  res[9] = (-a00*b10 + a01*b08 - a03*b06)*invDet;
  res[10] = (a30*b04 - a31*b02 + a33*b00)*invDet;
  res[11] = (-a20*b04 + a21*b02 - a23*b00)*invDet;
  res[12] = (-a10*b09 + a11*b07 - a12*b06)*invDet;
  res[13] = (a00*b09 - a01*b07 + a02*b06)*invDet;
  res[14] = (-a30*b03 + a31*b01 - a32*b00)*invDet;
  res[15] = (a20*b03 - a21*b01 + a22*b00)*invDet;
  /*F64 invDet = 1.0/(b00*b11 - b01*b10 + b02*b09 + b03*b08 - b04*b07 + b05*b06);

  res[0] = (a11*b11 - a12*b10 + a13*b09)*invDet*GR_SCALE;
  res[1] = (-a01*b11 + a02*b10 - a03*b09)*invDet*GR_SCALE;
  res[2] = (a31*b05 - a32*b04 + a33*b03)*invDet*GR_SCALE;
  res[3] = (-a21*b05 + a22*b04 - a23*b03)*invDet*GR_SCALE;
  res[4] = (-a10*b11 + a12*b08 - a13*b07)*invDet*GR_SCALE;
  res[5] = (a00*b11 - a02*b08 + a03*b07)*invDet*GR_SCALE;
  res[6] = (-a30*b05 + a32*b02 - a33*b01)*invDet*GR_SCALE;
  res[7] = (a20*b05 - a22*b02 + a23*b01)*invDet*GR_SCALE;
  res[8] = (a10*b10 - a11*b08 + a13*b06)*invDet*GR_SCALE;
  res[9] = (-a00*b10 + a01*b08 - a03*b06)*invDet*GR_SCALE;
  res[10] = (a30*b04 - a31*b02 + a33*b00)*invDet*GR_SCALE;
  res[11] = (-a20*b04 + a21*b02 - a23*b00)*invDet*GR_SCALE;
  res[12] = (-a10*b09 + a11*b07 - a12*b06)*invDet*GR_SCALE;
  res[13] = (a00*b09 - a01*b07 + a02*b06)*invDet*GR_SCALE;
  res[14] = (-a30*b03 + a31*b01 - a32*b00)*invDet*GR_SCALE;
  res[15] = (a20*b03 - a21*b01 + a22*b00)*invDet*GR_SCALE;*/
}

// using F64 matrix internally because im too stupid to convert
// someone else's math to Terry's integer scaling system
U0 MatrixLookAtI64(I64 *mat, CD3 *eye, CD3 *target, CD3 *up) {
  CD3 x, y, z;
  F64 fmat[4*4];
  CD3Sub(&z, eye, target);
  CD3Norm(&z);
  D3Cross(&x, up, &z);
  CD3Norm(&x);
  D3Cross(&y, &z, &x);
  CD3Norm(&y);

  fmat[0] = x.x;
  fmat[1] = x.y;
  fmat[2] = x.z;
  fmat[3] = 0.0;
  fmat[4] = y.x;
  fmat[5] = y.y;
  fmat[6] = y.z;
  fmat[7] = 0.0;
  fmat[8] = z.x;
  fmat[9] = z.y;
  fmat[10] = z.z;
  fmat[11] = 0.0;
  fmat[12] = eye->x;
  fmat[13] = eye->y;
  fmat[14] = eye->z;
  fmat[15] = 1.0;

  MatrixInvert(fmat, mat);
}

public Bool CamMVP(Cam *cam, CD3 *pos, I64* r, I64 *mat) {
  F64 dist = D3Dist(pos, &cam->pos);
  if (dist == 0.0)
    return FALSE;
  F64 zoom = 1.0 / (dist/256);
  Mat4x4MulMat4x4Equ(mat, cam->mat, r);
  Mat4x4TranslationAdd(mat, pos->x - cam->pos.x, pos->y - cam->pos.y, pos->z - cam->pos.z);
  Mat4x4Scale(mat, zoom);
  return TRUE;
}

public U0 CamUpdate(Cam *cam) {
  MatrixLookAtI64(cam->mat, &cam->pos, &cam->target, &cam->up);
}

#endif
