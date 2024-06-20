#ifndef COLLISION_H
#define COLLISION_H "Yunno wut I mean"
//Returns TRUE on collision
#define STEP_HEIGHT 32
Bool MoveInLevel(CDoomLevel *l,CD2 *result,CD2 *at,F64 angle,F64 dist,F64 radius=64.,F64 cur_height=0.) {
  I64 blockx=(at->x-l->block_map_x_off)/128;
  I64 blocky=(at->y-l->block_map_y_off)/128;
  CD2 move1,move2;
  F64 dist2=0,sin=Sin(angle),cos=Cos(angle),cap;
  CDoomLinedef **lds;
  move1.x=at->x,move1.y=at->y;
  move2.x=at->x+dist*cos,move2.y=at->y+dist*sin;
  while(dist2<=dist) {
    for(lds=l->block_map_data+l->block_map_offsets[
	  blockx+blocky*l->block_map_cols
	  ];*lds;lds++) {
//TODO ceiling
      if(lds[0]->floor_height>cur_height+STEP_HEIGHT)
        if(PlaneIntersect(result,&move1,&move2,lds[0]->start,lds[0]->end)) {
	  dist=Sqrt(Sqr(result->x-move1.x)+Sqr(result->y-move1.y));
	  dist-=radius;
	  result->x=move1.x+cos*dist;
	  result->y=move1.y+cos*dist;
	  return TRUE;
        }
    }
    if(sin>cos) {
      dist2+=128/sin;
    } else {
      dist2+=128/cos;
    }
    blockx=(dist2*cos+at->x-l->block_map_x_off)/128;
    blocky=(dist2*sin+at->y-l->block_map_y_off)/128;
  }
  result->x=at->x;
  result->y=at->y;
  return FALSE;
}
#endif