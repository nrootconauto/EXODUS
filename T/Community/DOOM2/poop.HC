//https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
F64 DistFromLine(CD2 *p,CD2 *l1,CD2 *l2) {
  return Abs((l2->x-l1->x)*(l1->y-p->y)-(l2->y-l1->y)*(l1->x-p->x))/ApproxDist(l1->x-l2->x,l1->y-l2->y);
}

F64 IntesectDist(CD2 *a,CD2 *b,CD2 *a2,CD2 *b2) {
  F64 dist=DistFromLine(a,a2,b2);
  if(dist==0.) return 0.;
  F64 normal=FArg(b2->x-a2->x,b2->y-a2->y),angle;
  //Find which normal
  if((b2->x-a2->x)*(a->y-a2->y)-(b2->y-a2->y)*(a->x-a2->x)>0.)
    normal+=pi/2.;
  else
    normal-=pi/2.;
  angle=FArg(b->x-a->x,b->y-a->y)-normal;
  return FSin(angle)*dist;
}

F64 SectorEndDist(CD2 *at,F64 angle,CDoomSector *sector) {
  I64 w=sector->shape_dc->width*2,h=sector->shape_dc->height*2;
  I64 i;
  CD2 point,fin,point2;
  F64 min_dist=I16_MAX,d;
  fin.x=at->x+I16_MAX*Cos(angle);
  fin.y=at->y+I16_MAX*Sin(angle);
  for(i=0;i!=4;i++) {
    switch(i) {
      case 0:
        point.x=sector->shape_start_x;
        point.y=sector->shape_start_y;

        point2.x=sector->shape_start_x+w;
        point2.y=sector->shape_start_y;
        break;
      case 1:
        point.x=sector->shape_start_x+w;
        point.y=sector->shape_start_y;

        point2.x=sector->shape_start_x;
        point2.y=sector->shape_start_y+h;
        break;
      case 2:
        point.x=sector->shape_start_x;
        point.y=sector->shape_start_y+h;

        point2.x=sector->shape_start_x+w;
        point2.y=sector->shape_start_y+h;
        break;
      case 3:
        point.x=sector->shape_start_x+w;
        point.y=sector->shape_start_y+h;

        point2.x=sector->shape_start_x;
        point2.y=sector->shape_start_y;
        break;
    }
    d=IntesectDist(at,&fin,&point,&point2);
    if(0.<d<min_dist)
     min_dist=d;
  }
  return min_dist;
}
Uf("LookForLine");