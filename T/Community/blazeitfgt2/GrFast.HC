#ifndef GRFAST_HC
#define GRFAST_HC

#include "Matrix"

#define SCX 320
#define SCY 244
#define SCR_W 640
#define SCR_H 480
#define FB_H 472
#define PIX_TOP 8
#define TRI_MIN_W 0   // PIX_LEFT
#define TRI_MAX_W 639 // PIX_RIGHT
#define TRI_MIN_H -8  // -PIX_TOP
#define TRI_MAX_H 471 // PIX_BOTTOM - PIX_TOP

public class TriData {
  CD3I32 tri[3];
  CColorROPU32 color;
  U16 dProbability;
};

#define LIN_CONGRUE_A 6364136223846793005
#define LIN_CONGRUE_C 1442695040888963407
I64 RandF(I64 seed) {
  return LIN_CONGRUE_A*seed^(seed&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
}

U32 XorShift(U32 state) {
  state ^= state << 13;
  state ^= state >> 17;
  state ^= state << 5;
  return state;
}

U16 RandU16F() {
  I64 res=Fs->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  Fs->rand_seed=res;
  return res.u16[0];
}

public U0 LineH(CDC *dc,I64 x1,I64 x2,I64 y,I64 z1=0,I64 z2=0,I32 *depthBuf) {
  I64 dx,dz,z,i,j;

  if (0>y || y>=FB_H)
    return;
  y += PIX_TOP;
  if (x2<x1) {
    SwapI64(&x1,&x2);
    SwapI64(&z1,&z2);
  }
  if (x2<0 || x1 >= SCR_W)
    return;
  if (x1<0) {
    i=-x1;
    x1=0;
  } else
    i=0;
  j=0;
  if (x2 >= SCR_W) {
    j = x2 - (SCR_W-1);
    x2 = SCR_W-1;
  }
  dx=x2+j-(x1-i);

  if (dx)
    dz=(z2-z1)<<32/dx;
  else
    dz=0;
  z=z1<<32;

  if (i)
    z+=i*dz;
  if (x2>=SCR_W)
    x2=SCR_W-1;

  I64 d = SCR_W*y+x1;
  CColorROPU32 color = dc->color;
  U16 probability = dc->dither_probability_u16;
  U8 *dst = dc->body + d;
  I32 *db = depthBuf + d;
  I64 seed = Fs->rand_seed;
  while (x1<=x2) {
    if (z.i32[1]<=*db) {
      *db=z.i32[1];
      seed = RandF(seed);
      if (seed.u16[0] < probability) {
        *dst = color.c1.color;
      } else {
        *dst = color.c0.color;
      }
    }
    dst++;
    x1++;
    db++;
    z+=dz;
  }
  Fs->rand_seed = seed;
}

public U0 LineV(CDC *dc,I64 x,I64 y1,I64 y2,I64 z1=0,I64 z2=0,I32 *depthBuf) {
  I64 dy,dz,z,i,j;

  if (0>x || x>=SCR_W)
    return;
  if (y2<y1) {
    SwapI64(&y1,&y2);
    SwapI64(&z1,&z2);
  }
  if (y2<0)
    return;
  if (y1<0) {
    i=-y1;
    y1=0;
  } else
    i=0;

  if (y1 >= FB_H)
    return;
  y1 += PIX_TOP;

  j=0;
  y2 += PIX_TOP;
  if (y2 > SCR_H-1) {
    j = y2 - (SCR_H-1);
    y2 = SCR_H-1;
  }
  dy=y2+j-(y1-i);

  if (dy)
    dz=(z2-z1)<<32/dy;
  else
    dz=0;
  z=z1<<32;

  if (i)
    z+=i*dz;
  if (y2>=SCR_H)
    y2=SCR_H-1;

  I64 d = SCR_W*y1+x;
  CColorROPU32 color = dc->color;
  U16 probability = dc->dither_probability_u16;
  U8 *dst = dc->body + d;
  I32 *db = depthBuf + d;
  I64 seed = Fs->rand_seed;
  while (y1<=y2) {
    if (0<=z.i32[1]<=*db) {
      *db=z.i32[1];
      seed = RandF(seed);
      if (seed.u16[0] < probability) {
        *dst = color.c1.color;
      } else {
        *dst = color.c0.color;
      }
    }
    dst += SCR_W;
    y1++;
    db += SCR_W;
    z+=dz;
  }
  Fs->rand_seed = seed;
}

public U0 FillTri(CDC *dc,CD3I32 *p1,CD3I32 *p2,CD3I32 *p4,I32 *db) {
  I64 x1,x2,y1,y2,z1,z2,dx1,dy1,dz1,dx2,dy2,dz2,i;

  if (AbsI64(p1->y-p2->y)+AbsI64(p1->y-p4->y)<=
	AbsI64(p1->x-p2->x)+AbsI64(p1->x-p4->x)) {
//p1 is min x
    if (p4->x<p2->x)
      SwapI64(&p4,&p2);
    if (p2->x<p1->x)
      SwapI64(&p2,&p1);

    if (p4->y<p2->y)
      SwapI64(&p4,&p2);

    if ((dy2=p4->y-p1->y)<0) {
      dy1=p2->y-p1->y;
      dx1=(p1->x-p2->x)<<32/dy1;
      dz1=(p1->z-p2->z)<<32/dy1;

      dx2=(p1->x-p4->x)<<32/dy2;
      dz2=(p1->z-p4->z)<<32/dy2;
      x1=x2=p1->x<<32; y1=p1->y; z1=z2=p1->z<<32;
      if (y1+dy2 < TRI_MIN_H) {
	i = TRI_MIN_H - (y1+dy2);
	if (i>-dy2) return;
	dy2+=i;
      }
      if (y1>=TRI_MAX_H) {
	i = y1 - TRI_MAX_H + 1;
	if (i>-dy2)
	  i=-dy2;
	dy2+=i;
	y1-=i;
	x1+=dx1*i;
	x2+=dx2*i;
	z1+=dz1*i;
	z2+=dz2*i;
      }
      while (dy2++) {
	LineH(dc,x1.i32[1],x2.i32[1],y1,z1.i32[1],z2.i32[1],db);
	y1--;
	x1+=dx1;
	x2+=dx2;
	z1+=dz1;
	z2+=dz2;
      }
      if (dy2=p2->y-p4->y) {
	dx2=(p4->x-p2->x)<<32/dy2;
	dz2=(p4->z-p2->z)<<32/dy2;
	if (y1+dy2 < TRI_MIN_H) {
	  i = TRI_MIN_H - (y1+dy2);
	  if (i>-dy2) return;
	  dy2+=i;
	}
	if (y1>=TRI_MAX_H) {
	  i=y1-TRI_MAX_H+1;
	  if (i>-dy2) return;
	  dy2+=i;
	  y1-=i;
	  x1+=dx1*i;
	  x2+=dx2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
      }
      while (dy2++<=0) {
	LineH(dc,x1.i32[1],x2.i32[1],y1,z1.i32[1],z2.i32[1],db);
	y1--;
	x1+=dx1;
	x2+=dx2;
	z1+=dz1;
	z2+=dz2;
      }
    } else if ((dy2=p2->y-p1->y)>0) {
      dy1=p4->y-p1->y;
      dx1=(p4->x-p1->x)<<32/dy1;
      dz1=(p4->z-p1->z)<<32/dy1;

      dx2=(p2->x-p1->x)<<32/dy2;
      dz2=(p2->z-p1->z)<<32/dy2;
      x1=x2=p1->x<<32; y1=p1->y; z1=z2=p1->z<<32;
      if (y1+dy2>=TRI_MAX_H) {
	i=y1+dy2-TRI_MAX_H+1;
	if (i>dy2) return;
	dy2-=i;
      }
      if (y1<TRI_MIN_H) {
	i=TRI_MIN_H-y1;
	if (i>dy2)
	  i=dy2;
	dy2-=i;
	y1+=i;
	x1+=dx1*i;
	x2+=dx2*i;
	z1+=dz1*i;
	z2+=dz2*i;
      }
      while (dy2--) {
	LineH(dc,x1.i32[1],x2.i32[1],y1,z1.i32[1],z2.i32[1],db);
	y1++;
	x1+=dx1;
	x2+=dx2;
	z1+=dz1;
	z2+=dz2;
      }
      if (dy2=p4->y-p2->y) {
	dx2=(p4->x-p2->x)<<32/dy2;
	dz2=(p4->z-p2->z)<<32/dy2;
	if (y1+dy2>=TRI_MAX_H) {
	  i=y1+dy2-TRI_MAX_H+1;
	  if (i>dy2) return;
	  dy2-=i;
	}
	if (y1<TRI_MIN_H) {
	  i=TRI_MIN_H-y1;
	  if (i>dy2) return;
	  dy2-=i;
	  y1+=i;
	  x1+=dx1*i;
	  x2+=dx2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
      }
      while (dy2-->=0) {
	LineH(dc,x1.i32[1],x2.i32[1],y1,z1.i32[1],z2.i32[1],db);
	y1++;
	x1+=dx1;
	x2+=dx2;
	z1+=dz1;
	z2+=dz2;
      }
    } else {
      if (dy1=p2->y-p1->y) {
	dx1=(p2->x-p1->x)<<32/dy1;
	dz1=(p2->z-p1->z)<<32/dy1;
	if (dy2=p2->y-p4->y) {
	  dx2=(p2->x-p4->x)<<32/dy2;
	  dz2=(p2->z-p4->z)<<32/dy2;
	} else {
	  dx2=0;
	  dz2=0;
	}
	x1=x2=p2->x<<32; y1=p2->y; z1=z2=p2->z<<32;
	if (y1<TRI_MIN_H) {
	  i=TRI_MIN_H-y1;
	  if (i>-dy1)
	    i=-dy1;
	  dy1+=i;
	  y1+=i;
	  x1+=dx1*i;
	  x2+=dx2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
	while (dy1++<=0) {
	  if (y1<TRI_MAX_H)
	    LineH(dc,x1.i32[1],x2.i32[1],y1,z1.i32[1],z2.i32[1],db);
	  y1++;
	  x1+=dx1;
	  x2+=dx2;
	  z1+=dz1;
	  z2+=dz2;
	}
      }
      if (dy1=p4->y-p1->y) {
	dx1=(p1->x-p4->x)<<32/dy1;
	dz1=(p1->z-p4->z)<<32/dy1;
	if (dy2=p4->y-p2->y) {
	  dx2=(p2->x-p4->x)<<32/dy2;
	  dz2=(p2->z-p4->z)<<32/dy2;
	} else {
	  dx2=0;
	  dz2=0;
	}
	x1=x2=p4->x<<32; y1=p4->y; z1=z2=p4->z<<32;
	if (y1-dy1<TRI_MIN_H) {
	  i=TRI_MIN_H-(y1-dy1);
	  if (i>dy1) return;
	  dy1-=i;
	}
	if (y1>=TRI_MAX_H) {
	  i=y1-TRI_MAX_H+1;
	  if (i>dy1) return;
	  dy1-=i;
	  y1-=i;
	  x1+=dx1*i;
	  x2+=dx2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
	while (dy1-->=0) {
	  LineH(dc,x1.i32[1],x2.i32[1],y1,z1.i32[1],z2.i32[1],db);
	  y1--;
	  x1+=dx1;
	  x2+=dx2;
	  z1+=dz1;
	  z2+=dz2;
	}
      }
    }
  } else {
//p1 is min y
    if (p4->y<p2->y)
      SwapI64(&p4,&p2);
    if (p2->y<p1->y)
      SwapI64(&p2,&p1);

      //p2x<=p4x
    if (p4->x<p2->x)
      SwapI64(&p4,&p2);

    if ((dx2=p4->x-p1->x)<0) {
      dx1=p2->x-p1->x;
      dy1=(p1->y-p2->y)<<32/dx1;
      dz1=(p1->z-p2->z)<<32/dx1;

      dy2=(p1->y-p4->y)<<32/dx2;
      dz2=(p1->z-p4->z)<<32/dx2;
      y1=y2=p1->y<<32; x1=p1->x; z1=z2=p1->z<<32;
      if (x1+dx2<TRI_MIN_W) {
	i=TRI_MIN_W-(x1+dx2);
	if (i>-dx2) return;
	dx2+=i;
      }
      if (x1>=TRI_MAX_W) {
	i=x1-TRI_MAX_W+1;
	if (i>-dx2)
	  i=-dx2;
	dx2+=i;
	x1-=i;
	y1+=dy1*i;
	y2+=dy2*i;
	z1+=dz1*i;
	z2+=dz2*i;
      }
      while (dx2++) {
	LineV(dc,x1,y1.i32[1],y2.i32[1],z1.i32[1],z2.i32[1],db);
	x1--;
	y1+=dy1;
	y2+=dy2;
	z1+=dz1;
	z2+=dz2;
      }
      if (dx2=p2->x-p4->x) {
	dy2=(p4->y-p2->y)<<32/dx2;
	dz2=(p4->z-p2->z)<<32/dx2;
	if (x1+dx2<TRI_MIN_W) {
	  i=TRI_MIN_W-(x1+dx2);
	  if (i>-dx2) return;
	  dx2+=i;
	}
	if (x1>=TRI_MAX_W) {
	  i=x1-TRI_MAX_W+1;
	  if (i>-dx2) return;
	  dx2+=i;
	  x1-=i;
	  y1+=dy1*i;
	  y2+=dy2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
      }
      while (dx2++<=0) {
	LineV(dc,x1,y1.i32[1],y2.i32[1],z1.i32[1],z2.i32[1],db);
	x1--;
	y1+=dy1;
	y2+=dy2;
	z1+=dz1;
	z2+=dz2;
      }
    } else if ((dx2=p2->x-p1->x)>0) {
      dx1=p4->x-p1->x;
      dy1=(p4->y-p1->y)<<32/dx1;
      dz1=(p4->z-p1->z)<<32/dx1;

      dy2=(p2->y-p1->y)<<32/dx2;
      dz2=(p2->z-p1->z)<<32/dx2;
      y1=y2=p1->y<<32; x1=p1->x; z1=z2=p1->z<<32;
      if (x1+dx2>=TRI_MAX_W) {
	i=x1+dx2-TRI_MAX_W+1;
	if (i>dx2) return;
	dx2-=i;
      }
      if (x1<TRI_MIN_W) {
	i=TRI_MIN_W-x1;
	if (i>dx2)
	  i=dx2;
	dx2-=i;
	x1+=i;
	y1+=dy1*i;
	y2+=dy2*i;
	z1+=dz1*i;
	z2+=dz2*i;
      }
      while (dx2--) {
	LineV(dc,x1,y1.i32[1],y2.i32[1],z1.i32[1],z2.i32[1],db);
	x1++;
	y1+=dy1;
	y2+=dy2;
	z1+=dz1;
	z2+=dz2;
      }
      if (dx2=p4->x-p2->x) {
	dy2=(p4->y-p2->y)<<32/dx2;
	dz2=(p4->z-p2->z)<<32/dx2;
	if (x1+dx2>=TRI_MAX_W) {
	  i=x1+dx2-TRI_MAX_W+1;
	  if (i>dx2) return;
	  dx2-=i;
	}
	if (x1<TRI_MIN_W) {
	  i=TRI_MIN_W-x1;
	  if (i>dx2) return;
	  dx2-=i;
	  x1+=i;
	  y1+=dy1*i;
	  y2+=dy2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
      }
      while (dx2-->=0) {
	LineV(dc,x1,y1.i32[1],y2.i32[1],z1.i32[1],z2.i32[1],db);
	x1++;
	y1+=dy1;
	y2+=dy2;
	z1+=dz1;
	z2+=dz2;
      }
    } else {
      if (dx1=p2->x-p1->x) {
	dy1=(p2->y-p1->y)<<32/dx1;
	dz1=(p2->z-p1->z)<<32/dx1;
	if (dx2=p2->x-p4->x) {
	  dy2=(p2->y-p4->y)<<32/dx2;
	  dz2=(p2->z-p4->z)<<32/dx2;
	} else {
	  dy2=0;
	  dz2=0;
	}
	y1=y2=p2->y<<32; x1=p2->x; z1=z2=p2->z<<32;
	if (x1<TRI_MIN_W) {
	  i=TRI_MIN_W-x1;
	  if (i>-dx1)
	    i=-dx1;
	  dx1+=i;
	  x1+=i;
	  y1+=dy1*i;
	  y2+=dy2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
	while (dx1++<=0) {
	  if (x1<TRI_MAX_W)
	    LineV(dc,x1,y1.i32[1],y2.i32[1],z1.i32[1],z2.i32[1],db);
	  x1++;
	  y1+=dy1;
	  y2+=dy2;
	  z1+=dz1;
	  z2+=dz2;
	}
      }
      if (dx1=p4->x-p1->x) {
	dy1=(p1->y-p4->y)<<32/dx1;
	dz1=(p1->z-p4->z)<<32/dx1;
	if (dx2=p4->x-p2->x) {
	  dy2=(p2->y-p4->y)<<32/dx2;
	  dz2=(p2->z-p4->z)<<32/dx2;
	} else {
	  dy2=0;
	  dz2=0;
	}
	y1=y2=p4->y<<32; x1=p4->x; z1=z2=p4->z<<32;
	if (x1-dx1<TRI_MIN_W) {
	  i=TRI_MIN_W-(x1-dx1);
	  if (i>dx1) return;
	  dx1-=i;
	}
	if (x1>=TRI_MAX_W) {
	  i=x1-TRI_MAX_W+1;
	  if (i>dx1) return;
	  dx1-=i;
	  x1-=i;
	  y1+=dy1*i;
	  y2+=dy2*i;
	  z1+=dz1*i;
	  z2+=dz2*i;
	}
	while (dx1-->=0) {
	  LineV(dc,x1,y1.i32[1],y2.i32[1],z1.i32[1],z2.i32[1],db);
	  x1--;
	  y1+=dy1;
	  y2+=dy2;
	  z1+=dz1;
	  z2+=dz2;
	}
      }
    }
  }
}

public U0 DrawMesh(CDC *dc, TriData *data, I64 cnt, I32 *depthBuf) {
  I64 i;
  TriData *ptr = data;
  for (i=0; i<cnt; i++, ptr++) {
    // TODO turn to args
    dc->color = ptr->color;
    dc->dither_probability_u16 = ptr->dProbability;
    FillTri(dc, &ptr->tri[0], &ptr->tri[1], &ptr->tri[2], depthBuf);
  }
}

public U0 DrawTriFill(CDC *dc, CD3I32 *tri, I64 cnt, CD3I32 *buf) {
  I64 i,px,py,pz;
  CColorROPU32 color=dc->color;
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
    (*dc->lighting)(dc, &p[i*3], &p[i*3+1], &p[i*3+2], color);
    GrFillTri0(dc, &p[i*3], &p[i*3+1], &p[i*3+2]);
  }
}

public U0 DrawTriFillV(CDC *dc, CD3I32 *tri, I64 cnt, CD3I32 *buf, I32 *db) {
  CD3I32 *p=tri, *dst=buf;
  I64 i, vertex_cnt=cnt*3;
  for (i=0; i<vertex_cnt; i++,p++,dst++) {
    dst->x = p->x + dc->x;
    //dst->y = p->y / (Abs(p->x/6)/((Sin(tS)+1.0)*32+10)) + dc->y;
    dst->y = p->y + dc->y;
    dst->z = p->z;
  }
  p=buf;

  for (i=0, dst=buf; i<cnt; i++, dst += 3) {
    //(*dc->lighting)(dc, &p[i*3], &p[i*3+1], &p[i*3+2], old_color);
    FillTri(dc, &dst[0], &dst[1], &dst[2], db);
  }
}

public U0 DrawTriFillVM(CDC *dc, CD3I32 *tris, I64 cnt, I64 *r, I32 *db) {
  I64 i, xx, yy, zz;
  CD3I32 tri[3];
  CD3I32 *ptr = tris;
  for (i=0; i<cnt; i++,ptr++) {
    xx=ptr->x; yy=ptr->y; zz=ptr->z;
    tri[0].x=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
    tri[0].y=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
    tri[0].z=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

    ptr++; xx=ptr->x; yy=ptr->y; zz=ptr->z;
    tri[1].x=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
    tri[1].y=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
    tri[1].z=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

    ptr++; xx=ptr->x; yy=ptr->y; zz=ptr->z;
    tri[2].x=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
    tri[2].y=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
    tri[2].z=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

    FillTri(dc, &tri[0], &tri[1], &tri[2], db);
  }
}

public U0 DrawTriFillVMC(CDC *dc, CD3I32 *tris, I64 cnt, I64 *r, I32 *db, U8 *c) {
  I64 i, xx, yy, zz;
  CD3I32 tri[3];
  CD3I32 *ptr = tris;
  for (i=0; i<cnt; i++,ptr++, c++) {
    xx=ptr->x; yy=ptr->y; zz=ptr->z;
    tri[0].x=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
    tri[0].y=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
    tri[0].z=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

    ptr++; xx=ptr->x; yy=ptr->y; zz=ptr->z;
    tri[1].x=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
    tri[1].y=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
    tri[1].z=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

    ptr++; xx=ptr->x; yy=ptr->y; zz=ptr->z;
    tri[2].x=(r[0*4+0]*xx+r[0*4+1]*yy+r[0*4+2]*zz+r[0*4+3])>>32;
    tri[2].y=(r[1*4+0]*xx+r[1*4+1]*yy+r[1*4+2]*zz+r[1*4+3])>>32;
    tri[2].z=(r[2*4+0]*xx+r[2*4+1]*yy+r[2*4+2]*zz+r[2*4+3])>>32;

    dc->color = ROPF_PROBABILITY_DITHER+BLACK<<16+*c;
    FillTri(dc, &tri[0], &tri[1], &tri[2], db);
  }
}

public U0 LineF(U8 *aux_data,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2,
	U0 (*fp_plot)(U8 *aux,I64 x,I64 y,I64 z,I32 *depthBuf), I32 *db) {
  I64 i,d,dx=x2-x1,dy=y2-y1,dz=z2-z1,_x,_y,_z,
	adx=AbsI64(dx),ady=AbsI64(dy),adz=AbsI64(dz);
  if (adx>=ady) {
    if (adx>=adz) {
      if (d=adx) {
	if (dx>=0)
	  dx=0x100000000;
	else
	  dx=-0x100000000;
	dy=dy<<32/d;
	dz=dz<<32/d;
      }
    } else {
      if (d=adz) {
	dx=dx<<32/d;
	dy=dy<<32/d;
	if (dz>=0)
	  dz=0x100000000;
	else
	  dz=-0x100000000;
      }
    }
  } else {
    if (ady>=adz) {
      if (d=ady) {
	dx=dx<<32/d;
	if (dy>=0)
	  dy=0x100000000;
	else
	  dy=-0x100000000;
	dz=dz<<32/d;
      }
    } else {
      if (d=adz) {
	dx=dx<<32/d;
	dy=dy<<32/d;
	if (dz>=0)
	  dz=0x100000000;
	else
	  dz=-0x100000000;
      }
    }
  }
  x1<<=32; y1<<=32; z1<<=32;
  for (i=0;i<=d;i++) {
    (*fp_plot)(aux_data,x1.i32[1],y1.i32[1],z1.i32[1],db);
    _x=x1.i32[1]; _y=y1.i32[1]; _z=z1.i32[1];
    x1+=dx; y1+=dy; z1+=dz;
  }
}

public U0 Plot0F(CDC *dc, I64 x, I64 y) {
  dc->body[SCR_W*y+x] = dc->color;
}

public U0 Plot1F(CDC *dc, I64 x, I64 y) {
  if (0<=x<SCR_W && 0<=y<SCR_H)
    dc->body[SCR_W*y+x] = dc->color;
}

public U0 Plot3F(CDC *dc, I64 x, I64 y, I64 z, I32 *db) {
  y += PIX_TOP;
  db += SCR_W*y+x;
  if (0<=x<SCR_W && 8<=y<SCR_H && 0<=z<=*db) {
    *db = z;
    dc->body[SCR_W*y+x] = dc->color;
  }
}

// F64 Matrix, always transform, never brush, never thick
public U0 Line3F(CDC *dc,F64 *m,F64 x1,F64 y1,F64 z1,F64 x2,F64 y2,F64 z2,I32 *db) {
  F64 pw1, pw2;
  MatMulXYZ(m, &x1, &y1, &z1, &pw1);
  if (pw1 >= 0)
    return;
  MatMulXYZ(m, &x2, &y2, &z2, &pw2);
  if (pw2 >= 0)
    return;
  if (pw2 >= -0.1) {
//    return;
    F64 n = (pw1 - 0.1) / (pw2 - pw1$BK,0$);
    //F64 xc = x2;
    //F64 yc = y2;
    //F64 zc = z2;
    x2 = x2 + (x1 - x2) * n;
    y2 = y2 + (y1 - y2) * n;
    z2 = z2 + (z1 - z2) * n;
    //x2 = (n * x1) + ((1.0-n) * xc);
    //y2 = (n * y1) + ((1.0-n) * yc);
    //z2 = (n * z1) + ((1.0-n) * zc);
    pw2 = -0.1;
  } else {
  }
  x1 /= pw1;
  x1 += SCX;
  y1 /= pw1;
  y1 += SCY;
  x2 /= pw2;
  x2 += SCX;
  y2 /= pw2;
  y2 += SCY;
  LineF(dc,x1,y1,z1,x2,y2,z2,&Plot3F,db);
}

public U0 PutSF(CDC *dc, I64 x, I64 y, U8 *_s, U8 *_e=NULL) {
  I64 x0,sx=0,sy=0,res;
  x0=x;
  res=0;
  while (*_s && _s != _e) {
    if (*_s=='\n') {
      x=x0;
      y+=FONT_HEIGHT;
    } else if (*_s=='\t') {
      x=x0+CeilU64(x-x0+FONT_WIDTH,8*FONT_WIDTH);
    } else if (*_s!=5) {
      res+=GrPutChar(dc,x+sx,y+sy,*_s);
      x+=FONT_WIDTH;
    }
    _s++;
  }
}

public U0 DrawRect(U8 *fb, I32 x, I32 y, I32 w, I32 h, U8 color) {
  U8 *b;
  I32 yy, xi, yi;
  y += PIX_TOP;
  for (yi=0, yy=y; yi<h; yi++, yy++) {
    for (xi=0, b=fb+yy*SCR_W+x; xi<w; xi++, b++)
      *b = color;
  }
}

#endif
