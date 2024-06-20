Bool InRange(F64 low,F64 x,F64 high) {
  if(low<high)
    return low-.01<=x<=high+.01;
  return high-.01<=x<=low+.01;
}

Bool PlaneIntersect(CD2 *dst,CD2 *a,CD2 *b,CD2 *a2,CD2 *b2,Bool check=TRUE) {  
/*
* Nroot here,Heres the deal,I make a system of 2 linear equations and solve for an intersect
* I solve for the intersect and check if they are in bounds of points

Check for intersection basically.

     /
----*------
   / 
  /
 /
*/
  F64 slope1,slope2,off1,off2,x,x2,y,y2;
  F64 tolerance=.01;
  CD2 dummy;
  if(!dst) dst=&dummy;
//If the line points straight up,we can check to see if the other
  //line goes through the y position,if so,it is a hit
  if((ToI64(b->x)==ToI64(a->x))||(ToI64(b2->x)==ToI64(a2->x))) {
    tolerance=1.;
    if(ToI64(a->x)==ToI64(b->x)&&ToI64(a2->x)==ToI64(b2->x)) {
      if(ToI64(a->x)==ToI64(a2->x)) {
        dst->x=a->x;
        dst->y=a->y;
	goto fin;
      } else
	return FALSE;
    }
    if(ToI64(a->x)==ToI64(b->x)) {
      dst->x=a->x;
      slope2=(b2->y-a2->y)/(b2->x-a2->x);
      dst->y=slope2*(dst->x-a2->x)+a2->y;
      goto fin;
    }
    if(ToI64(a2->x)==ToI64(b2->x)) {
      dst->x=a2->x;
      slope1=(b->y-a->y)/(b->x-a->x);
      dst->y=slope1*(dst->x-a->x)+a->y;
      goto fin;
    }
    goto fin;
  }
//https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
  slope2=(b2->y-a2->y)/(b2->x-a2->x);
  slope1=(b->y-a->y)/(b->x-a->x);
  off1=slope1*-a->x+a->y;
  off2=slope2*-a2->x+a2->y;
  if(slope1==slope2) return FALSE;
  dst->x=((off2-off1)/(slope1-slope2));
  dst->y=slope1*(dst->x)+off1;
fin:
  if(!check) return TRUE;
  if(a->x>b->x)
    x=b->x-tolerance,x2=a->x+tolerance;
  else
    x=a->x-tolerance,x2=b->x+tolerance;
  if(a->y>b->y)
    y=b->y-tolerance,y2=a->y+tolerance;
  else
    y=a->y-tolerance,y2=b->y+tolerance;

  if(!(x<=dst->x<=x2&&y<=dst->y<=y2))
    return FALSE;

  if(a2->x>b2->x)
    x=b2->x-tolerance,x2=a2->x+tolerance;
  else
    x=a2->x-tolerance,x2=b2->x+tolerance;
  if(a2->y>b2->y)
    y=b2->y-tolerance,y2=a2->y+tolerance;
  else
    y=a2->y-tolerance,y2=b2->y+tolerance;
  if(!(x<=dst->x<=x2&&y<=dst->y<=y2))
    return FALSE;

  return TRUE;
}
