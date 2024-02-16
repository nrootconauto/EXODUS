// Matrix math based on raymath.h under zlib/libpng license

#ifndef DRAW_HC
#define DRAW_HC

#include "Quaternion";
#include "Obj/ArrowL";

#define SCX 320
#define SCY 244

public class GrBuff {
  I64 mat[4][4];
};

public class Cam {
  CD3 pos;
  CD3 target;
  CD3 up;
  F64 zoom;
  I64 mat[4][4];
};

public Bool GrPlot0F(CDC *dc, I64 x, I64 y) {
  U8 *dst;
  I32 *db;
  I64 d;
  CColorROPU32 c,color=dc->color,bkcolor=dc->bkcolor;
  d=dc->width_internal*y+x;
  if (db=dc->depth_buf) {
    db+=d;
    if (0<=dc->db_z<=*db)
      *db=dc->db_z;
    else
      return TRUE;
  }
  if (color.c1.rop&(ROPBF_DITHER|ROPBF_PROBABILITY_DITHER)) {
    if (color.c1.rop&ROPBF_PROBABILITY_DITHER) {
      if (RandU16<dc->dither_probability_u16) {
	color.c1.rop=color.c0.rop;
	color.c0=color.c1;
      }
    } else {
      if ((x^y)&1) {
	color.c1.rop=color.c0.rop;
	color.c0=color.c1;
      }
    }
  }
  dst=dc->body+d;
  switch [color.c0.rop] {
    case ROPB_EQU:
    case ROPB_MONO:
      *dst=color.c0.color;
      break;
    case ROPB_COLLISION:
      c=*dst;
      if (c!=TRANSPARENT && c!=bkcolor.c0.color)
	dc->collision_cnt++;
      break;
    case ROPB_XOR:
      *dst^=color.c0.color;
      break;
  }
  return TRUE;
}

// Never transform, never brush, never thick
public Bool GrPlot3F(CDC *dc, I64 x, I64 y, I64 z) {
  dc->db_z = z;
  CTask *win_task = dc->win_task;
  y += 8;
  if (0<=x<640 && 8<=y<480 && (win_task->next_task==sys_winmgr_task ||
      dc->flags&DCF_ON_TOP || !IsPixCovered0(win_task,x,y)))
    GrPlot0F(dc,x,y);
  return TRUE;
}

public Bool GrPlot1F(CDC *dc, I64 x, I64 y, I64 z) {
  dc->db_z=z;
  if (0<=x<640 && 0<=y<480)
    GrPlot0F(dc,x,y);
  return TRUE;
}

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
public U0 GrLine3F(CDC *dc=gr.dc,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2,
I64 step=1,I64 start=0) {
  (*dc->transform)(dc,&x1,&y1,&z1);
  (*dc->transform)(dc,&x2,&y2,&z2);
  Line(dc,x1,y1,z1,x2,y2,z2,&GrPlot3F,step,start);
}

public U0 GrEllipse3F(CDC *dc=gr.dc,
		I64 cx,I64 cy,I64 cz,
		I64 x_radius,I64 y_radius,
		F64 rot_angle=0,
		I64 step=1,
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

  Ellipse(dc,cx,cy,cz,
          m1/0x10000,m2/0x10000,&GrPlot3F,-arg1,step,start_radians,len_radians);
}

public U0 Gr2BezierF(CDC *dc, CD3I32 *ctrl) {
  Bezier2(dc,ctrl,&GrPlot3F);
}

public U0 DCMat4x4SetFast(CDC *dc, I64 *r) {
  dc->r = r;
  dc->r_norm = Sqrt(Mat4x4NormSqr65536(r))*65536;
}

public U0 DrawRecBorder(CDC* dc, I64 x, I64 y, I64 w, I64 h) {
  // Draw Map Background
  dc->color = BLACK;
  GrRect(dc, x+1, y+1, w-1, h-1);
  // Draw Map Borders
  dc->color = WHITE;
  y += dc->win_task->pix_top+dc->win_task->scroll_y;
  Line(dc,x,y,0,x+w,y,0,&GrLinePlot0,1,0);
  Line(dc,x,y+h,0,x+w,y+h,0,&GrLinePlot0,1,0);
  Line(dc,x,y,0,x,y+h,0,&GrLinePlot0,1,0);
  Line(dc,x+w,y,0,x+w,y+h,0,&GrLinePlot0,1,0);
}

public U0 DrawLines(CDC *dc, I64 cnt, CD3I32 *lines) {
  I64 i;
  for (i=0; i<cnt; i+=2)
    GrLine3F(dc, lines[i].x, lines[i].y, lines[i].z, lines[i+1].x, lines[i+1].y, lines[i+1].z);
}


public U0 DrawArrow(CDC *dc, I64 x, I64 y, F64 rot, F64 t_now) {
  I64 i, mat[4][4];
  Mat4x4IdentEqu(mat);
  Mat4x4RotX(mat, t_now*8);
  Mat4x4RotZ(mat, rot);
  Mat4x4TranslationAdd(mat, x-SCX, y-SCY, 0);
  dc->color=YELLOW;
  dc->r = mat;
  dc->r_norm = Sqrt(Mat4x4NormSqr65536(mat))*65536;
  for (i=0; i<ArrowL_cnt; i+=2)
    GrLine3F(dc, ArrowL[i].x, ArrowL[i].y, ArrowL[i].z, ArrowL[i+1].x, ArrowL[i+1].y, ArrowL[i+1].z);
}

U0 DrawTri(CDC *dc, CD3 *pos, F64 rot, CD3I32 *tri, I64 cnt, F64 scale, Cam *cam) {
  I64 i, mat[4][4];
  Mat4x4IdentEqu(mat);
  Mat4x4RotZ(mat,rot);
  Mat4x4Scale(mat, scale);
  Mat4x4TranslationAdd(mat, pos->x-cam->pos.x, pos->y-cam->pos.y, 0);
  Mat4x4Scale(mat, cam->zoom);
  dc->r = mat;
  dc->r_norm = Sqrt(Mat4x4NormSqr65536(mat))*65536;
  for (i=0; i<cnt; i++) {
    GrLine3F(dc, tri[i*3].x, tri[i*3].y, tri[i*3].z, tri[i*3+1].x, tri[i*3+1].y, tri[i*3+1].z);
    GrLine3F(dc, tri[i*3+1].x, tri[i*3+1].y, tri[i*3+1].z, tri[i*3+2].x, tri[i*3+2].y, tri[i*3+2].z);
    GrLine3F(dc, tri[i*3+2].x, tri[i*3+2].y, tri[i*3+2].z, tri[i*3].x, tri[i*3].y, tri[i*3].z);
  }
}

public U0 DrawTriFill(CDC *dc, CD3I32 *tri, I64 cnt, CD3I32 *buf) {
  I64 i,px,py,pz;
  CColorROPU32 old_color=dc->color;
  CD3I32 *p=tri, *dst;
  I64 vertex_cnt = cnt*3;
  dst=buf;
  for (i=0;i<vertex_cnt;i++,p++,dst++) {
    px=p->x; py=p->y; pz=p->z;
    (*dc->transform)(dc,&px,&py,&pz);
    dst->x=px; dst->y=py; dst->z=pz;
  }
  p=buf;

  for (i=0; i<cnt; i++) {
    (*dc->lighting)(dc, &p[i*3], &p[i*3+1], &p[i*3+2], old_color);
    GrFillTri0(dc, &p[i*3], &p[i*3+1], &p[i*3+2]);
  }
  dc->color=old_color;
}

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
  dc->r_norm = Sqrt(Mat4x4NormSqr65536(mat))*65536;
  I64 i;
  for (i=0; i<cnt; i+=2)
    GrLine3F(dc, lines[i].x, lines[i].y, lines[i].z, lines[i+1].x, lines[i+1].y, lines[i+1].z);
}

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
U0 MatrixLookAt(I64 *mat, CD3 *eye, CD3 *target, CD3 *up) {
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
  MatrixLookAt(cam->mat, &cam->pos, &cam->target, &cam->up);
}

#endif