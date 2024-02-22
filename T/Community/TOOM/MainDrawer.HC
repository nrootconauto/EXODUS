#ifndef DOOM_MAIN
#define DOOM_MAIN "Doom" 
#exe {Cd(__DIR__);};;
#ifndef PrintI 
U0 PrintI(U8*,I64) {}
U0 PrintF(U8*,F64) {}
U0 DbgPrint(U8*,...) {}
#endif
#ifndef MemSetI64
#define MemSetI64 MemSetU64
#endif
Bool in_level=FALSE,screen_melt=FALSE;
CDC *doom_scrn=DCNew(GR_WIDTH,GR_HEIGHT);
doom_scrn->flags|=DCF_NO_TRANSPARENTS;

#include "ScreenMelt.HC"
#include "Serialize.HC";
#include "FastTrig.HC";
#include "Wad.HC";
#include "Intermission.HC";
CTask *doom_task=Fs;
#include "Thinker.HC";
#include "Music.HC";
#define MUZZLE_FLASH_LIGHT 50
extern U0 ThingDel(CDoomLevel *l,CDoomThing *t);
extern U0 TeleportThingToPos(CDoomLevel *l,CDoomThing *t,F64,F64,F64);
extern U0 ST_Message(U8*,U8*); //Frist is CDoomPlayer
extern U0 DamageMob(CDoomLevel *l,CDoomThing *target,CDoomThing *opp,F64 damage);
extern CDoomThing **GetCrushedThingsInSector(CDoomLevel *l,CDoomSector *s);
U0 TallBlot(CDC *to,I64 x,I64 y,I64 h,CDC *from) {
  I64 i,w=from->width;
  if(x+from->width>to->width)
    w=to->width-x;
  U8 *src,*dst;
  for(i=0;i<h;i++) {
    dst=&to->body[x+(y+i)*to->width_internal];
    src=&from->body[ToI64(i/ToF64(h)*from->height)*from->width_internal];
    MemCpy(dst,src,w);
  }
}
F64 ray_cast_table_cos[GR_WIDTH/2];
F64 ray_cast_table_sin[GR_WIDTH/2];
Bool paused = FALSE,gameExit=FALSE;
F64 time_offset=0,base_tS=tS;
F64 paused_at=0;
F64 Server_tS() {
  if(paused) {
    return paused_at;
  }
  paused_at=tS-base_tS+time_offset;
  return paused_at;
}
U0 Unpause(F64 to=-1) {
  base_tS=tS;
  if(to<0)
    time_offset=paused_at;
  else
    time_offset=to;
  paused_at=time_offset;
  paused=FALSE;
}
#include "Lighting.HC";
class CJobRunnerData {
  U0 (*fptr)(U8*);
};
I64 doom_scrn_in_draw=0;
CDoomSector *GetSectorForCoord(CDoomLevel *level,I64 x,I64 y) {
  CDoomSubsector *ss;
  CDoomBSPNode *node=DoomWhichBSPNode(x,y,level,&ss);
  if(ss) {
    return ss->sector;
  }
  return NULL;
}

class AmmoType{
  U64 ammo;
  Bool splash;  
};

class GunAvail{
  Bool available;
  I16 baseDamage;
  AmmoType *load;
};
class CDoomPlayer:CDoomThing { 
//rad_suit_time is the time remaining(same for bezerk_time) in ticks
  F64 armor,rad_suit_time,bezerk_time,last_attack;
  F64 invisible_time;
//These are used for screen palete effects
  F64 hurt_amt,pickup_amt;
  F64 muzzle_flash_end_tS;
//When you die,the player stares at the thing that killed the player
  CDoomThing *stare_at;
  GunAvail arsenal[8];
  Bool running,made_a_sound,has_backpack,pad[5];
  U8 message[STR_LEN];
//Private
#define WEAPON_IDLE 0
#define WEAPON_FIRE 1
#define WEAPON_REFIRE 2
#define WEAPON_PAUSE 3
  I64 weapon_state;
  F64 weapon_cooldown,message_end_tS,light_goggles_time,invincible_time;
} *p=NULL;

//IMPORTANT
CacheAnimationFrames;

I64 cursor_x = ms.pos.x, cursor_tx = ms.pos.x, cursor_z = ms.pos.z, cursor_tz = ms.pos.z;

class CVisplane {
  I64 color;
  I64 fminx,fmaxx; //floor
  I64 cminx,cmaxx; //ceil
  I64 fminy,fmaxy; //floor
  I64 cminy,cmaxy; //ceil
  CDoomSector *sector;
//Farthest are per x
  I32 sector_limits[GR_WIDTH/2]; 
};

I64 class CWallCommand {
  I16 start,end;
  I32 dist;
  CDoomLinedef *ld;
};


class CDoomCamera {
  F64 x,y,h;
  F64 angle,fov;
//Private
//These are used for rejecting places to draw
  I64 wall_command_cnts[GR_WIDTH/2];
  CWallCommand wall_commands[GR_WIDTH/2][0x80];
  CDC *floor_dc; //This is black or white,this is used for reducing floor overdraw
  I64 visplane_cnt;
  CVisplane visplanes[256];
} cam;
cam.fov=pi/4;

I64 IsBlockedByWall(CDoomCamera *cam,I64 x,I64 y,I64 dist,CDoomSidedef *self=INVALID_PTR) {
  I64 i,cnt=cam->wall_command_cnts[x>>1];
  CWallCommand *cmd=cam->wall_commands[x>>1];
  for(i=0;i!=cnt;i++,cmd++) {
    if(cmd->dist<=dist&&cmd->ld!=self) {
      if(cmd->start<y<cmd->end) {
	return cmd->end-y;
      }
    }
  }
  return 0;
}

I64 IsBlockedByWallReverse(CDoomCamera *cam,I64 x,I64 y,I64 dist,CDoomSidedef *self=INVALID_PTR) {
  I64 i,cnt=cam->wall_command_cnts[x>>1];
  CWallCommand *cmd=cam->wall_commands[x>>1];
  for(i=0;i!=cnt;i++,cmd++) {
    if(cmd->dist<=dist&&cmd->ld!=self) {
      if(cmd->start<y<cmd->end) {
	return y-cmd->start;
      }
    }
  }
  return 0;
}


U0 InsertVisplane(CDoomCamera *cam,CDoomSector *s) {
  I64 cnt=cam->visplane_cnt;
  CVisplane *vp;
  if(cnt<255) {
    vp=&cam->visplanes[cnt];
    vp->fminx=GR_WIDTH;
    vp->fminy=GR_HEIGHT;
    vp->fmaxy=0;
    vp->fmaxx=0;
    vp->cminx=GR_WIDTH;
    vp->cminy=GR_HEIGHT;
    vp->cmaxy=0;
    vp->cmaxx=0;
    vp->sector=s;
    vp->color=cnt+1;
    s->visplane_idx=cnt;
    cam->visplane_cnt++;
    MemSetU32(vp->sector_limits,I32_MAX,GR_WIDTH/2);
  }
}
#define GRID_SZ  128
#define Y_SCALE 5
#define DIST_SCALE (GR_HEIGHT*1.4)

#define FLOOR_VPIXEL_WIDTH 2
#define WALL_VPIXEL_WIDTH 2
#define WALL_HPIXEL_HEIGHT 2
#define FLOOR_HPIXEL_HEIGHT 2

/*
* Listen up,here's the deal
* A view plane is FLAT,not a point,so when we look at an angle,we 
* need to "straigten" our line,otherwise we will have a curved lense effect 
*
* Ask Nroot about this
*/

I64 PointToLinedefSegment(CDoomCamera *cam,CDoomLinedef *def,CD2 *coord) {
  CD2 line_s,at;
  F64 dist;
  line_s.x=cam->x;
  line_s.y=cam->y;
  PlaneIntersect(&at,&line_s,coord,def->start,def->end);
  dist=Sqrt(Sqr(at.x-def->start->x)+Sqr(at.y-def->start->y));
  return ToI64(dist);
}

F64 Lerp(F64 per,F64 min,F64 max) {
  F64 tmp;
  if(min>max)
    return Clamp(per*(max-min)+min,max,min);
  return Clamp(per*(max-min)+min,min,max);

}

I64 YSort(CD2 *a,CD2 *b) {
  if(a->y>b->y)
    return 1;
  else if(a->y<b->y)
    return -1;
  return 0;
}


U0 TransformPointToCamera(CDoomCamera *cam,CD2 *p) {
  F64 x,y;
  F64 angle=FArg(x=p->x-cam->x,y=p->y-cam->y)-cam->angle;
  F64 dist=Sqrt(x*x+y*y);
  p->x=dist*FCos(angle);
  p->y=dist*FSin(angle);
}

Bool ClipLineToScrenCoords(CDoomCamera *cam,CD2 *p,CD2 *p2,F64 level=0.,Bool *out_of_view=NULL,Bool clamp=TRUE) {
  CD2 s,e,at,*ptr,debug;
  Bool dummy;
  I64 cnt,fail_cnt;
  F64 angle,angle2,slump,dist,slump_angle=cam->fov/2;
  TransformPointToCamera(cam,p);
  TransformPointToCamera(cam,p2);
  s.x=0,s.y=0;
  slump=1.75;
  e.y=I16_MAX*Sin(cam->fov/2),e.x=I16_MAX*Cos(cam->fov/2);
  slump=cam->fov/2.;
  angle=FArg(p->x,p->y);
  angle2=FArg(p2->x,p2->y);
  if(!out_of_view) out_of_view=&dummy;

  *out_of_view=FALSE;
  if(p->x*e.y<e.x*p->y)   
    if(p2->x*e.y<e.x*p2->y) 
      *out_of_view=TRUE;
  e.y=-e.y;
  if(p->x*e.y>e.x*p->y)   
    if(p2->x*e.y>e.x*p2->y)   
      *out_of_view=TRUE;
  if(p->x<0.)
    if(p2->x<0.)
      *out_of_view=TRUE;
  e.y=-e.y;

  if(clamp) {
//Use intersect if above the line
    PlaneIntersect(&at,&s,&e,p,p2,FALSE);
    if(p->x*e.y-e.x*p->y<-.1) {
      p->x=at.x;
      p->y=at.y;
    }
    if(p2->x*e.y-e.x*p2->y<-.1) {
      p2->x=at.x;
      p2->y=at.y;
    }

    //Use intersect if below the line
    e.y=-e.y;
    PlaneIntersect(&at,&s,&e,p,p2,FALSE);
    if(p->x*e.y-e.x*p->y>.1) {
      p->x=at.x;
      p->y=at.y;
    }
    if(p2->x*e.y-e.x*p2->y>.1) {
      p2->x=at.x;
      p2->y=at.y;
    }
  }

  for(cnt=0;cnt!=2;cnt++) {
    if(!cnt) ptr=p;
    else ptr=p2;
    angle=FArg(ptr->x,ptr->y);

    at.x=GR_WIDTH/2+angle/(cam->fov/2)*(GR_WIDTH/2);
    at.y=GR_HEIGHT/2+DIST_SCALE/(Sqrt(Sqr(ptr->x)+Sqr(ptr->y))*Cos(angle))*(cam->h-level);
    ptr->x=at.x;
    ptr->y=at.y;
  }
  return !*out_of_view;
}
I64 F64SortRev(F64 a,F64 b) {
  if(a<b) return 1;
  if(a>b) return -1;
  return 0;
}
I64 I64Sort(I64 a,I64 b) {
  return a-b;
}

F64 LightOffset() {
  if(!p) return 0;
  if(p->light_goggles_time>5) {
    return 255.;
  } else if(p->light_goggles_time) {
    if(Blink)
      return 255.;
  }
  if(Server_tS<p->muzzle_flash_end_tS)
    return MUZZLE_FLASH_LIGHT;
  return 0.;
}

Bool GodModeFilter() {
  if(!p) return FALSE;
  if(p->invincible_time>3.)
     return TRUE;
  else if(p->invincible_time>0.)
    return Blink;
  return FALSE;
}
 class CD4 {
  CD2 start;
  CD2 end;
};
I64 YSort(CD4 *a,CD4 *b) {
  if(a->start.y>b->start.y) return 1;
  if(a->start.y<b->start.y) return -1;
  return 0;
}
CD4 *GetFlatPoints(CDoomCamera *cam,CDoomSector *s,F64 level,I64 *cnt) {
  CD4 *ret=CAlloc(sizeof(CD4)*s->linedef_cnt);
  CDoomLinedef *ld;
  I64 idx,idx2=0;
  CD2 dummy;
  Bool out_of_view=0;
  for(idx=0;idx!=s->linedef_cnt;idx++) {
    ld=s->linedefs[idx];    
    ret[idx2].start.x=ld->start->x;
    ret[idx2].start.y=ld->start->y;
    ret[idx2].end.x=ld->end->x;
    ret[idx2].end.y=ld->end->y;
    ClipLineToScrenCoords(cam,&ret[idx2].start,&ret[idx2].end,level,&out_of_view);

    ret[idx2].start.x=ret[idx2].start.x;
    ret[idx2].end.x=ret[idx2].end.x;

    if(ret[idx2].start.x>ret[idx2].end.x) {
      SwapI64(&ret[idx2].start.x,&ret[idx2].end.x);
      SwapI64(&ret[idx2].start.y,&ret[idx2].end.y);
    }
    if(!out_of_view)
	idx2++;
  }
  if(cnt) *cnt=idx2;
  return ret;
}
I64 class CLine64 {
  I16 sx,sy,ex,ey;
};
I64 LineYSort(CLine64 a,CLine64 b) {
  return a.ey-b.ey;
}
U0 SectorPlot(CDC *dc,CDC *texture,I64 x,I64 y,F64 level,F64 cos2,F64 sin2,I64 light,Bool god_mode) {
  x=GR_WIDTH-x;
  if(x<0) return;
  if(x>GR_WIDTH-2) return;
  if(y<0) return;
  if(y>GR_HEIGHT-2) return;
  U16 *to=&dc->body[x+y*dc->width_internal];
  I32 *db_z=&dc->depth_buf[x+y*dc->width_internal];
  F64 dist=DIST_SCALE/((ToF64(y)-GR_HEIGHT/2)/(cam.h-level));
  F64 cos=ray_cast_table_cos[x>>1];
  dist/=cos;
  I32 idist=dist;
  I64 wx,wy,color;
  if(*db_z<idist) return;
//Heres the deal. The dither pixels are always aligned to 2 mofo.
    //So that means I can write an I64 as two I32s into the depth buffer mofo at once
  idist|=idist<<32;
  db_z[0](I64)=idist;
  db_z+=dc->width_internal;
  db_z[0](I64)=idist;
//End of legendary code
  wx=cam.x+dist*cos2;
  wy=cam.y+dist*sin2;
//wx<<1 multiples by 2,which means any number*2 is even
  wx=(wx<<1)&127;
  wy=(wy<<1)&127;
  color=LookupLighting(texture->body[wx+wy*128](U16),light,dist,god_mode);
  *to=color&0xffff;
  to(U8*)+=dc->width_internal;
  *to=color>>16;
}
U0 FillPoly(CDC *dc,CDoomCamera *cam,CDoomSector *s,CDC *texture,CD4 *points,I64 cnt,F64 level,Bool floor) {
  Bool god_mode=GodModeFilter;
  I64 idx,idx2,idx3;
  CI64Set *lines=I64SetNew();
  I64 minx,x,miny;
  I64 maxx,cap;
  CD3 dummya,dummyb;
  F64 slope,wxf,wyf,midx,y,slope2,angle,dist;
  I64 scrn_points[0x100],wall_skip;
  CLine64 ln,to_remove,ln2;
  static F64 last_angle=I16_MAX; //Not possible to start with this angle
  static F64 cos_table[GR_WIDTH];
  static F64 sin_table[GR_WIDTH];
  if(last_angle!=cam->angle) {
    for(x=0;x!=GR_WIDTH;x++) {
      angle=(ToF64(x)-GR_WIDTH/2)/GR_WIDTH*(cam->fov);
      sin_table[x]=Sin(cam->angle+angle);
      cos_table[x]=Cos(cam->angle+angle);
    }
    last_angle=cam->angle;
  }
  ln.sx=points[0].start.x;
  ln.ex=ln.sx;
  if(!floor)
    ln.sy=0,ln.ey=0;
  else 
    ln.sy=GR_HEIGHT,ln.ey=GR_HEIGHT;
  for(idx=0;idx!=cnt;idx++) {
    ln.sx=MinI64(points[idx].start.x,ln.sx);
    ln.ex=MaxI64(points[idx].end.x,ln.ex);
  }
  minx=ClampI64(ln.sx,0,GR_WIDTH-2);
  maxx=ClampI64(ln.ex,0,GR_WIDTH-2);

  I64SetAdd(lines,ln);

  for(idx=0;idx!=cnt;idx++) {
    ln.sx=points[idx].start.x;
    ln.sy=points[idx].start.y;
    ln.ex=points[idx].end.x;
    ln.ey=points[idx].end.y;
    I64SetAdd(lines,ln);
  }

  minx=minx&~1; //Avoids Templeos bug with &=~1;
  for(x=minx-2;x<maxx+2;x+=2) {
    idx3=0;
    if(maxx>GR_WIDTH-2)
      break;
    else if(maxx<0)
      maxx=0;
    for(idx2=0;idx2!=lines->cnt;idx2++) {
      ln=lines->body[idx2];
      if(!(ln.sx<=x<=ln.ex))
        goto skip;
      slope=ToF64(ln.ey-ln.sy)/ToF64(ln.ex-ln.sx);
      scrn_points[idx3++]=(x-ln.sx)*slope+ln.sy;
skip:;
    }
    if(idx3)
      QSortI64(&scrn_points,idx3,&I64Sort);
    for(idx2=0;idx2<idx3-1;idx2++) {
      dummya.x=x;
      dummyb.x=x;
      dummya.y=scrn_points[idx2];
      dummyb.y=scrn_points[idx2+1];
//In floors,the lower cordante is the nearest(idx2+1)
      if(floor) {
        dist=DIST_SCALE/((dummyb.y-GR_HEIGHT/2)/(cam->h-level));
        dist/=ray_cast_table_cos[ToI64(x)>>1];
	if(wall_skip=IsBlockedByWallReverse(cam,x,dummyb.y-2,dist,NULL)) {
	  if(2+wall_skip>=scrn_points[idx2+1]-scrn_points[idx2])
	    goto next;
	  dummyb.y-=2+wall_skip;
	}
      } else {
//In ceils,the upper cordante is the nearest(idx2+0)
        dist=DIST_SCALE/((dummya.y-GR_HEIGHT/2)/(cam->h-level));
        dist/=ray_cast_table_cos[ToI64(x)>>1];
	if(wall_skip=IsBlockedByWall(cam,x,dummya.y+2,dist,NULL)) {
	  if(2+wall_skip>=scrn_points[idx2+1]-scrn_points[idx2])
	    goto next;
	  dummya.y+=2+wall_skip;
	}  
      }
      dist=DIST_SCALE/(((dummya.y+dummyb.y)/2-GR_HEIGHT/2)/(cam->h-level));
      if(dist>0.) {
        dist/=ray_cast_table_cos[ToI64(x)>>1];
        wyf=cam->y+dist*sin_table[ToI64(x)];
        wxf=cam->x+dist*cos_table[ToI64(x)];
        if(GetSectorForCoord(l,wxf,wyf)==s) {
	  y=MinI64(dummya.y,dummyb.y);
	  cap=MaxI64(dummya.y,dummyb.y);
	  y=ClampI64(y-1,0,GR_HEIGHT-2);
	  cap=ClampI64(cap+2,0,GR_HEIGHT-2);
	  for(;y<cap;y+=2) {
	    SectorPlot(dc,texture,x,y,
		  level,
		  cos_table[x],
		  sin_table[x],
		  s->cur_light_level,
		  god_mode);
	  }
        }
      }
next:;
    }
  }
  I64SetDel(lines);
}
U0 DrawTexturedFlat(CDoomLevel *l,CDC *to_dc,CDoomCamera *cam,CDoomSector *sector,F64 at,CDC *texture,Bool floor=TRUE) {
  if(!texture) return;
  if(GetFlatDC("F_SKY1")==texture) return;
  I64 in_view;
  CD4 *poodle=GetFlatPoints(cam,sector,at,&in_view);
  FillPoly(to_dc,cam,sector,texture,poodle,in_view,at,floor);
  Free(poodle);
}


U0 PopulateTables() {
  I64 inc=0;
  F64 angle=-cam.fov/2;
  for(inc=0;inc!=GR_WIDTH/2;inc++) {
    ray_cast_table_cos[inc]=Cos(angle);
    ray_cast_table_sin[inc]=Sin(angle);
    angle+=cam.fov/GR_WIDTH*2;
  }
}
PopulateTables;
//floor is 0 for floor
//floor is 1 for middle
//floor is 2 for ceil
//floor is 3 if visplane only
U0 RayCastWall(CDC *to_dc,CDC *texture,CD2 *st,CD2 *en,CDoomCamera *cam,I64 level,I64 height,I64 flrh,I64 ceilh,U8 floor,CDoomLinedef *ld,CDoomSidedef *sd,Bool same_side) {
  I64 light=sd->sector->cur_light_level;
  if(ld->front==sd&&ld->back)
    light=MaxI64(light,ld->back->sector->cur_light_level);
  if(ld->back==sd&&ld->front)
    light=MaxI64(light,ld->front->sector->cur_light_level);
  light+=LightOffset;
  CD2 clone_st,clone_en,zero,clone_ld_st,clone_ld_en;
  CD2 scrn_st,scrn_en;
  scrn_st.x=st->x;
  scrn_st.y=st->y;
  scrn_en.x=en->x;
  scrn_en.y=en->y;
  clone_st.x=st->x,clone_st.y=st->y;
  clone_en.x=en->x,clone_en.y=en->y;
  clone_ld_st.x=ld->start->x;
  clone_ld_st.y=ld->start->y;
  clone_ld_en.x=ld->end->x;
  clone_ld_en.y=ld->end->y;
  zero.x=0.,zero.y=0.;
  TransformPointToCamera(cam,&clone_st);
  TransformPointToCamera(cam,&clone_en);
  TransformPointToCamera(cam,&clone_ld_st);
  TransformPointToCamera(cam,&clone_ld_en);
  st=&clone_st;
  en=&clone_en;
  F64 start_angle=FArg(st->x,st->y);
  F64 end_angle=FArg(en->x,en->y),tmp,tyf,sy,ey,slope;
  CD2 ray,hit,*sw;
  I64 ix,iy,ih=0,tx,ty,ih2,xoff=sd->xoff-texture->x,yoff=sd->yoff-texture->y,ex,dir,skip,sx;
  CVisplane *vp;
  I32 *db_z,idist;
  U32 dither_px;
  CWallCommand *wall_cmd;
  F64 dist,ratio;
  Bool repeat=FALSE,onesided=ld->front^^ld->back;
  Bool is_sky=FALSE,clipped=FALSE,recompute_ty,is_sky2=FALSE;
  Bool god_mode=GodModeFilter;
  I64 low_ih,high_ih;
  CDoomSidedef *opposite;
  U16 *color,*to;
  CDoomScroller1 *scroll1;
  if(ld->special_type&&ld->special_type->type=='Scroll1'&&sd==ld->front) {
    scroll1=ld->special_type;
    if(scroll1->x)
      xoff+=Server_tS*30*scroll1->x;
    else if(scroll1->offset_type) {
      yoff=yoff*Server_tS*30;
      xoff=xoff*Server_tS*30;
    }
  }
  if(ld->front==sd)
    opposite=ld->back;
  else
    opposite=ld->front;
  if(onesided)
    is_sky2=sd->sector->ceil_dc[0]==GetFlatDC("F_SKY1");
  else if(!sd->upper_texture[0]&&floor==1)
    is_sky2=sd->sector->ceil_dc[0]==GetFlatDC("F_SKY1");
  else if(floor==2)
    is_sky2=sd->sector->ceil_dc[0]==GetFlatDC("F_SKY1");
//Upper walls arent drawn between 2 sky sectors
    //is_sky will trigger no drawing wall 
  if(opposite&&floor==2&&opposite->sector->ceil_dc[0]==GetFlatDC("F_SKY1")) {
    return;
  }
  repeat=TRUE;

  ClipLineToScrenCoords(cam,&scrn_st,&scrn_en,level,&clipped);
  if(clipped) return;

  sy=scrn_st.y;
  ey=scrn_en.y;
  sx=scrn_st.x;
  ex=scrn_en.x;

  ix=sx;
//Avoids Templeos bug with &=~1;
  ix=ix&~1;
  ex=ex&~1;
  if(ix<ex) {
    dir=2;
  }else {
    dir=-2;
  }
  for(;ix!=ex;ix+=dir) {
    if(ix>GR_WIDTH) {
      break;
    } else if(ix<0) {
      break;
    }
    tyf=(ey-sy)/ToF64(ex-sx)*(ix-sx)+sy;
    dist=DIST_SCALE/((tyf-GR_HEIGHT/2)/(cam->h-level));
    dist/=ray_cast_table_cos[ix>>1];
    if(dist>0.) {
      hit.x=dist*ray_cast_table_cos[ix>>1];
      hit.y=dist*ray_cast_table_sin[ix>>1];
      idist=dist;
      if(dist<=0.) dist=1;
      tx=ToI64(Sqrt(Sqr(hit.x-clone_ld_st.x)+Sqr(hit.y-clone_ld_st.y)))*2+xoff*2;
      iy=DIST_SCALE/(dist*ray_cast_table_cos[ix/2])*(cam->h-(height+level))+GR_HEIGHT/2;
      ih=(DIST_SCALE/(dist*ray_cast_table_cos[ix/2])*(cam->h-level)+GR_HEIGHT/2)-iy;
      if(ih&1) ih++;
      if(iy&1) ih++,iy--;
//Avoids Templeos bug with &=~1;
      iy=iy&~1;
      ih=ih&~1;
      ih2=ih;
      ratio=height/ToF64(ih);
      if(floor==3) { //If a "visplane" draw
        if(0<=ix<=GR_WIDTH-2) {
	  vp=&cam->visplanes[sd->sector->visplane_idx];
	  if(vp->sector_limits[ix>>1]<idist||vp->sector_limits[ix>>1]==I32_MAX)
	    vp->sector_limits[ix>>1]=idist;
	  for(ty=0;ty!=2;ty++) {
	    if(!ty)
	      ih2=0;
	    else
	      ih2=ih;
	    xoff=ClampI64(ix,0,GR_WIDTH-2);
	    yoff=ClampI64(iy+ih2,1,GR_HEIGHT-2);
	    if(ty) { //Y grows down
//If our line is partialy behind the camera,we draw the floor from GR_HEIGHT
	      if(clipped)
	        vp->fmaxy=GR_HEIGHT;
	      if(xoff<vp->fminx)
	        vp->fminx=xoff;
	      if(xoff>vp->fmaxx)
	        vp->fmaxx=xoff;

	      if(yoff<vp->fminy)
	        vp->fminy=yoff;
	      if(yoff>vp->fmaxy)
	        vp->fmaxy=yoff;

	    } else {
//If our line is partialy behind the camera,we draw the ceil from 0
	      if(clipped)
	        vp->cminy=0;
	      if(xoff<vp->cminx)
	        vp->cminx=xoff;
	      if(xoff>vp->cmaxx)
	        vp->cmaxx=xoff;

	      if(yoff<vp->cminy)
	        vp->cminy=yoff;
	      if(yoff>vp->cmaxy)
	        vp->cmaxy=yoff;
	    }
	  }
        }
        goto next;
      }
      if(0<=ix<=GR_WIDTH-2) {
        if(is_sky2) {
	  ih2=ClampI64(ih2+iy,0,GR_HEIGHT-2);
	  while(ih2>=0) {
	    db_z=&to_dc->depth_buf[GR_WIDTH-2-ix+ih2*to_dc->width_internal];
	    to=&to_dc->body[GR_WIDTH-2-ix+ih2*to_dc->width_internal];
	    if(db_z[0]>idist+1) {
	      db_z[0]=idist+1;
	      db_z[1]=idist+1;
	      *to=TRANSPARENT|TRANSPARENT<<8;
	      db_z+=to_dc->width_internal;
	      to+=to_dc->width_internal;
	      db_z[0]=idist+1;
	      db_z[1]=idist+1;
	      *to=TRANSPARENT|TRANSPARENT<<8;
	    }
	    ih2-=2;
	  }
	  wall_cmd=&cam->wall_commands[ix>>1][cam->wall_command_cnts[ix>>1]++];
	  wall_cmd->start=0;
	  wall_cmd->end=ClampI64(ih2+iy,0,GR_HEIGHT);
	  wall_cmd->ld=ld;
	  wall_cmd->dist=idist+1;
        }

        if(texture->flags&DCF_NO_TRANSPARENTS) {
	  wall_cmd=&cam->wall_commands[ix>>1][cam->wall_command_cnts[ix>>1]++];
	  wall_cmd->ld=ld;
	  wall_cmd->end=ClampI64(iy+ih2,0,GR_HEIGHT);
	  wall_cmd->start=ClampI64(iy,0,GR_HEIGHT);;
	  wall_cmd->dist=idist;
	  if(floor==0)
	    wall_cmd->end=GR_HEIGHT; //All the way down(we dont need to drawn benith the floor)
	  else if(floor==1)
	    wall_cmd->start=0,wall_cmd->end=GR_HEIGHT;
	  else if(floor==2)
	    wall_cmd->start=0; //All the way up(We dont need to draw past the ceiling)
        }

	  {
	  tx%=texture->width;
	  if(tx<0)
	    tx+=texture->width;
	  tx=ClampI64(tx,0,texture->width-2);
//Avoids Templeos bug with &=~1;
	  tx=tx&~1;
	  low_ih=0;
	  ih2=low_ih;
//https://doomwiki.org/wiki/Texture_alignment
	  if(repeat) {
	    if(onesided) {
//Dont ask nroot how any of this works,he typed in random stuff
	      if(ld->flags&WAD_LINEDEFF_LOWER_UNPEGGED) {
	        tyf=(ih2*ratio+yoff+texture->height-1-ratio*ih)*2;
	      } else {
	        tyf=(ih2*ratio+yoff-sd->sector->door_height_offset)*2;
	      }
	    } else {
	      if(floor==0) {
	        if(ld->flags&WAD_LINEDEFF_LOWER_UNPEGGED) {
		  tyf=(ih2*ratio+yoff+texture->height-1-ratio*ih+ceilh-flrh)*2;
	        } else {
		  tyf=(ih2*ratio+yoff-sd->sector->door_height_offset)*2;
	        }
	      } else{
	        if(!(ld->flags&WAD_LINEDEFF_UPPER_UNPEGGED)) {
		  tyf=(ih2*ratio+yoff+texture->height-1-ratio*ih-sd->sector->door_height_offset)*2;
	        } else {
		  tyf=(ih2*ratio+yoff-sd->sector->door_height_offset)*2;
	        }
	      }
	    }
	  } else {
	    tyf=(ToF64(ih2)/ih)*(texture->height-2);
	  }
	  for(ih2=low_ih;TRUE;ih2+=2,tyf+=2*ratio*2) { //2 for dither pixel,2 for ih2+=2
	    if(ih2>=ih||ih2+iy>=GR_HEIGHT-2)
	      break;
	    if(iy+ih2<0) {
	      skip=-iy;
	      tyf+=2*ratio*(skip-2); // *2 for dither super pixel
	      ih2+=skip-2;
	      goto skip_p;
	    }
	    db_z=&to_dc->depth_buf[GR_WIDTH-2-ix+(iy+ih2)*to_dc->width_internal];
	    if(*db_z<idist) {
	      if((skip=IsBlockedByWall(cam,ix,iy+ih2,idist,ld))>2) {
	        tyf+=2*ratio*(skip-2); // *2 for dither super pixel
	        ih2+=skip-2;
	        goto skip_p;
	      }
            }
	    ty=tyf;
	    if(repeat)
	      ty=ty%texture->height;
	    if(ty<0) ty=-ty;
	    ty=ClampI64(ty,0,texture->height-2);
//Avoids Templeos bug with &=~1;
	    ty=ty&~1;
	    color=texture->body[tx+ty*texture->width_internal](U16);
	    dither_px=LookupLighting(color,light,dist,god_mode);
	    to=&to_dc->body[GR_WIDTH-2-ix+(iy+ih2)*to_dc->width_internal];
	    db_z=&to_dc->depth_buf[GR_WIDTH-2-ix+(iy+ih2)*to_dc->width_internal];
	    if(*db_z>idist) {
	      if(color&0xff!=TRANSPARENT) {
	        db_z[0]=idist;
	        db_z[1]=idist;
	        db_z+=to_dc->width_internal;
	        db_z[0]=idist;
	        db_z[1]=idist;
	        *to=dither_px&0xffff;
	        to(U8*)+=to_dc->width_internal;
	        *to=dither_px>>16;
	      }
	    }
skip_p:;
	  }
        }
      }
    }
next:;
  }
}
class CRayJobData:CJobRunnerData {
  CDC *to_dc,*texture;
  CD2 *st,*en;
  CDoomCamera *cam;
  I64 level,height,flrh,ceilh,floor;
  CDoomLinedef *ld;
  CDoomSidedef *sd;
  Bool same_side;
};
U0 RayCastJob(CRayJobData *data) {
  RayCastWall(
	data->to_dc,data->texture,data->st,data->en,data->cam,
	data->level,
	data->height,
	data->flrh,
	data->ceilh,
	data->floor,
	data->ld,
	data->sd,
	data->same_side
	);
  Free(data);
}
U0 QueRayCastJob(CDC *to_dc,CDC *texture,CD2 *st,CD2 *en,CDoomCamera *cam,I64 level,I64 height,I64 flrh,I64 ceilh,U8 floor,CDoomLinedef *ld,CDoomSidedef *sd,Bool same_side) {
  I64 core=0;
  CRayJobData *j=CAlloc(sizeof(CRayJobData),adam_task);
  j->fptr=&RayCastJob;
  j->to_dc=to_dc;
  j->texture=texture;
  j->st=st;
  j->en=en;
  j->cam=cam;
  j->height=height;
  j->level=level;
  j->flrh=flrh;
  j->ceilh=ceilh;
  j->floor=floor;
  j->ld=ld;
  j->sd=sd;
  j->fptr=&RayCastJob;
  j->same_side=same_side;
  RayCastJob(j);

}
U0 PlotSpriteIn3DSpace(CDC *to_dc,F64 height,CDC *sprite,CDoomCamera *cam,CD2 *_p,F64 level,Bool reflect=FALSE,Bool transparent=FALSE,I64 light=255) {
  if(!sprite) return;
  CD2 copy,copy2;
  F64 new_height,new_width,angle;
  I64 x,y,tox,fromx,toy,fromy,ix,iy,dist,best_color;
  U16 *from,*dst,black=BLACK|BLACK<<8,trans_pixel=TRANSPARENT|TRANSPARENT<<8;
  U32 dither_px;
  I32 *db_z;
  Bool god_mode=GodModeFilter;
  copy.x=_p->x,copy.y=_p->y;
  copy2.x=_p->x,copy2.y=_p->y;
  ClipLineToScrenCoords(cam,&copy,&copy2,level,,FALSE);
  angle=(ToF64(copy.x)-GR_WIDTH/2)/(GR_WIDTH/2)*(cam->fov/2);
  angle=Clamp(angle,-cam->fov/2,cam->fov/2);
  dist=Sqrt(1+Sqr(_p->x-cam->x)+Sqr(_p->y-cam->y));
  new_height=DIST_SCALE/(ToF64(1+dist)*FCos(angle))*sprite->height/2;
  new_width=new_height/sprite->height*sprite->width;
  fromx=copy.x-new_width/2;
  tox=ClampI64(copy.x+new_width/2,0,GR_WIDTH-2);;
  fromy=copy.y-new_height;
  toy=ClampI64(copy.y,0,GR_HEIGHT-2);
//&~1 aligns to 2 for dithering super pixels
//Avoids Templeos bug with &=~1;
  fromy=fromy&~1;
  toy=toy&~1;
  fromx=fromx&~1;
  tox=tox&~1;
  for(y=fromy;y<toy;y+=2) {
    if(y<0) y=0;
    if(y>toy) break;
    for(x=fromx;x<tox;x+=2) {
      if(x<0) x=0;
      if(x>tox) break;
      db_z=&to_dc->depth_buf[GR_WIDTH-2-x+y*to_dc->width_internal];
      if(*db_z>dist) {
        if(!reflect)
	  ix=Lerp((x-fromx)/new_width,0,sprite->width-2);
        else
	  ix=Lerp((x-fromx)/new_width,sprite->width-2,0);
        iy=Lerp((y-fromy)/new_height,0,sprite->height-2);
        from=&sprite->body[(ix&~1)+(iy&~1)*sprite->width_internal];
        if(transparent) {
	  if(RandU16<ToI64(0x10000*.75)) {
	    if(*from!=trans_pixel)
	      from=&black;
	    else
	      from=&trans_pixel;
	  } else
	    from=&trans_pixel;
        }
        dst=&to_dc->body[GR_WIDTH-2-x+y*to_dc->width_internal];
	dither_px=LookupLighting(*from,light,dist,god_mode);
        if(from->u8[0]!=TRANSPARENT)
	  *dst=dither_px&0xffff,*db_z=dist,db_z[1]=dist;
        dst(U8*)+=to_dc->width_internal;
        db_z+=to_dc->width_internal;
        if(from->u8[0]!=TRANSPARENT)
	  *dst=dither_px>>16,*db_z=dist,db_z[1]=dist;
      }
nextx:;
    }
  }
}


U0 DrawAThing(CDC *to_dc,CDoomThing *thing,CDoomCamera *cam) {
  if(!thing->template) return; //???
  if(thing->template==doom_thing_types[1]) return; //Dont render player
  if(!thing->animation) thing->animation=thing->template->_animation;
  if(!thing->animation) return; //???
  I64 anim_frame=(Server_tS-thing->anim_start_tS)*4,frame_cnt,face;
  if(anim_frame<0) anim_frame=0;
  F64 angle,gap,diff;
  CDoomSector *sec;
  CDC *sprite;
  CD2 p;
  Bool reflect;
  frame_cnt=0;
  while(thing->animation[frame_cnt].chr)
    frame_cnt++;
  if(!frame_cnt) return;
  if(thing->anim_no_repeat)
    anim_frame=MinI64(frame_cnt-1,anim_frame);
  else
    anim_frame%=frame_cnt;
  angle=thing->angle;
  angle-=cam->angle;
  angle+=pi;
  face=1;   
  for(gap=0.;gap<2*pi;gap+=2.*pi/8.) {
    diff=(angle-gap+3*pi)%(2*pi)-pi;
//https://stackoverflow.com/questions/12234574/calculating-if-an-angle-is-between-two-angles
    if(-2*pi/8./2<=diff<=2*pi/8./2)
      break;
    face++;
  }
  if(face>8)
    face=8;
  reflect=thing->animation[anim_frame].reflect[face-1];
  sprite=thing->animation[anim_frame].faces[face-1];
  sec=GetSectorForCoord(l,thing->x,thing->y);
  p.x=thing->x,p.y=thing->y;
  if(sec) {
    if(thing->template==doom_thing_types[58]) { //Spectre
      PlotSpriteIn3DSpace(to_dc,thing->template->height,sprite,cam,&p,thing->height,reflect,TRUE,sec->cur_light_level); //TRUEfor transparent
    } else if(sprite)
      PlotSpriteIn3DSpace(to_dc,thing->template->height,sprite,cam,&p,thing->height,reflect,,sec->cur_light_level+LightOffset);
  }
}
CDoomSector *OppositeSector(CDoomLinedef *l,CDoomSector *sector) {
  if(l->front^^l->back) return sector;
  if(l->front->sector==sector) return l->back->sector;
  return l->front->sector;
}
F64 FloorRaise(CDoomLinedef *l,CDoomSector *sector) {
  F64 ret=Max(sector->floor_height,OppositeSector(l,sector)->floor_height);
  return ret;
}

F64 CeilDepress(CDoomLinedef *l,CDoomSector *sector) {
  F64 ret=Min(sector->ceil_height,OppositeSector(l,sector)->ceil_height);
  return ret;
}

F64 HighestCeil(CDoomLinedef *l,CDoomSector *sector) {
  F64 ret=sector->ceil_height;
  return ret;
}

I64 FrameCnt(CDC **arr) {
  I64 i=0;
  while(i<4&&arr[i])
    i++;
  return i;
}

CDC *GetMiddleTexture(CDoomSidedef *s) {
  if(!s->middle_texture[0]) return NULL;
  I64 t=ToI64(Server_tS*4)%FrameCnt(s->middle_texture);
  return s->middle_texture[t];
}

CDC *GetUpperTexture(CDoomSidedef *s) {
  if(!s->upper_texture[0]) return NULL;
  I64 t=ToI64(Server_tS*4)%FrameCnt(s->upper_texture);
  return s->upper_texture[t];
}

CDC *GetLowerTexture(CDoomSidedef *s) {
  if(!s->lower_texture[0]) return NULL;
  I64 t=ToI64(Server_tS*4)%FrameCnt(s->lower_texture);
  return s->lower_texture[t];
}
U0 DrawSubsector(CDC *to_dc,CDoomCamera *cam,CDoomSubsector *ss) {
  CD2 start_floor,start_ceil;
  CD2 end_floor,end_ceil;
  I64 seg_idx,wall,fail_cnt;
  CDC *texture;
  F64 h,h2;
  Bool no_draw;
  CDoomBSPSeg *seg;
  CDoomSidedef *sidedef,*opposite;
  CDoomSector *sector,*sector2;
  Vector *wall_vect=CreateVector(2);
  CD2 cam_cord;
  I64 miss_cnt=0;
  I64 aframe=Server_tS*4;
  F64 floor,ceil,highest_ceil;
  for(seg_idx=0;seg_idx!=ss->cnt;seg_idx++) {
    seg=&ss->first[seg_idx];
//Use linedef as we want to see what side of the WALL we are on(not seg)
    cam_cord.x=cam->x-seg->linedef->start->x;
    cam_cord.y=cam->y-seg->linedef->start->y;
    SetVector(wall_vect,seg->linedef->end->x-seg->linedef->start->x,0);
    SetVector(wall_vect,seg->linedef->end->y-seg->linedef->start->y,1);
    opposite=NULL;
    if(IsFrontSideOfVector2D(wall_vect,&cam_cord)) 
      sidedef=seg->linedef->front,opposite=seg->linedef->back;
    else
      sidedef=seg->linedef->back,opposite=seg->linedef->front;
    no_draw=FALSE;
    if(!sidedef)
      goto skip;
    sector=sidedef->sector;
    highest_ceil=HighestCeil(seg->linedef,sector);
    for(wall=0;wall!=4;wall++) {
      if(wall==0) {
        floor=Min(sector->floor_height,FloorRaise(seg->linedef,sector));
        ceil=Max(sector->floor_height,FloorRaise(seg->linedef,sector));
//In orthodox doom,"missing" textures just render as if the floor/ceil was there
        if(texture=GetLowerTexture(sidedef)) {
        } else {
	  texture=sector->floor_dc[aframe%FrameCnt(sector->floor_dc)];
        }
draw_wall:
        if(floor!=ceil) {
	  start_floor.x=seg->start->x;
	  start_floor.y=seg->start->y;
	  end_floor.x=seg->end->x;
	  end_floor.y=seg->end->y;
	  start_ceil.x=seg->start->x;
	  start_ceil.y=seg->start->y;
	  end_ceil.x=seg->end->x;
	  end_ceil.y=seg->end->y;
	  fail_cnt=0;
	  if(!ClipLineToScrenCoords(cam,&start_floor,&end_floor,floor))
	    fail_cnt++;
	  if(!ClipLineToScrenCoords(cam,&start_ceil,&end_ceil,ceil))
	    fail_cnt++;
	  h=Abs(start_floor.y-start_ceil.y);
	  h2=Abs(end_ceil.y-end_floor.y);
	  if(ToI64(h)&&ToI64(h2)) {
	    if(fail_cnt!=2) {
	      if(!sector->drawn) {
	        sector->drawn=TRUE;
	        InsertVisplane(cam,sector);
	      }
	      if(opposite&&opposite->sector&&!opposite->sector->drawn) {
	        opposite->sector->drawn=TRUE;
	        InsertVisplane(cam,opposite->sector);
	      }
	      if(!no_draw) {
	        if(seg->back_side)
		  QueRayCastJob(to_dc,texture,seg->end,seg->start,cam,floor,ceil-floor,sector->floor_height,highest_ceil,wall,seg->linedef,sidedef,TRUE);
	        else
		  QueRayCastJob(to_dc,texture,seg->start,seg->end,cam,floor,ceil-floor,sector->floor_height,highest_ceil,wall,seg->linedef,sidedef,FALSE);
	        if(wall==3&&opposite&&opposite->sector) {
		  sector=opposite->sector;
		  sidedef=opposite;
		  floor=sector->floor_height;
		  ceil=sector->ceil_height;
		  QueRayCastJob(to_dc,texture,seg->start,seg->end,cam,floor,ceil-floor,sector->floor_height,highest_ceil,wall,seg->linedef,opposite,FALSE);
	        }
	      }
	    }
	  }
        }
      } else if(wall==2) {
        if(texture=GetUpperTexture(sidedef)) {
        } else {
	  texture=sector->ceil_dc[aframe%FrameCnt(sector->ceil_dc)];
        }
        floor=Min(sector->ceil_height,CeilDepress(seg->linedef,sector));
        ceil=Max(sector->ceil_height,CeilDepress(seg->linedef,sector));
        goto draw_wall;
      } else if(wall==1&&(texture=GetMiddleTexture(sidedef))) {
        floor=sector->floor_height;
        ceil=sector->ceil_height;
        goto draw_wall;
      } else if(wall==3) { //This is for generating visplanes
        texture=gr.dc; //Dummy texture
        floor=sector->floor_height;
        ceil=sector->ceil_height;
        goto draw_wall;
      }
    }
skip:;
  }
  DestroyVector(wall_vect);
}
Bool FrontSide(Vector *v,CD2 *p) {
  return v->data[0]*p->y-v->data[1]*p->x>=0.;
}


//box will either inteserect viewport,or point will be inside of it
Bool HitsBBox(CDoomCamera *cam,CBoundBoxF64 *bbox) {
  F64 x=cam->x,y=cam->y,angle,base;
  Vector *v,*v2;
  Bool ret=FALSE;
  CD2 a,b,c,d,zero,ra,rb;
  zero.x=0,zero.y=0;
  if(InRange(bbox->x,x,bbox->x2))
    if(InRange(bbox->y,y,bbox->y2)) {
      return TRUE;
    }
  ra.x=I16_MAX*Cos(cam->angle-cam->fov/2.);
  ra.y=I16_MAX*Sin(cam->angle-cam->fov/2.);
  rb.x=I16_MAX*Cos(cam->angle+cam->fov/2.);
  rb.y=I16_MAX*Sin(cam->angle+cam->fov/2.);
//Check if points are behind camera
  a.x=bbox->x-x;
  a.y=bbox->y-y;
  b.x=bbox->x2-x;
  b.y=bbox->y-y;
  c.x=bbox->x2-x;
  c.y=bbox->y2-y;
  d.x=bbox->x-x;
  d.y=bbox->y2-y;

  v=CreateVector(2);
  v2=CreateVector(2);
  v2->data[0]=rb.x;
  v2->data[1]=rb.y;
  v->data[0]=ra.x;
  v->data[1]=ra.y;
  if(!FrontSide(v2,&a)&&FrontSide(v,&a))  {
    ret=TRUE;
  } else if(!FrontSide(v2,&b)&&FrontSide(v,&b)) {
    ret=TRUE;
  } else if(!FrontSide(v2,&c)&&FrontSide(v,&c)) {
    ret=TRUE;
  } else if(!FrontSide(v2,&d)&&FrontSide(v,&d)) {
    ret=TRUE;
  } else if(PlaneIntersect(NULL,&a,&b,&zero,&ra)||
	PlaneIntersect(NULL,&b,&c,&zero,&ra)||
	PlaneIntersect(NULL,&c,&d,&zero,&ra)||
	PlaneIntersect(NULL,&d,&a,&zero,&ra)) {
    ret=TRUE;
  } else if(PlaneIntersect(NULL,&a,&b,&zero,&rb)||
	PlaneIntersect(NULL,&b,&c,&zero,&rb)||
	PlaneIntersect(NULL,&c,&d,&zero,&rb)||
	PlaneIntersect(NULL,&d,&a,&zero,&rb)) {
    ret=TRUE;
  }
  DestroyVector(v);
  DestroyVector(v2);
  return ret;
}

//https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
F64 DistFromLine(CD2 *p,CD2 *l1,CD2 *l2) {
  return Abs((l2->x-l1->x)*(l1->y-p->y)-(l2->y-l1->y)*(l1->x-p->x))/Sqrt(Sqr(l1->x-l2->x)+Sqr(l1->y-l2->y));
}

U0 WallCmdSort(CWallCommand *a,CWallCommand *b) {  
  if(a->start==b->start) {
    return a->end-b->end;
  }
  return a->start-b->start;
}
Bool WallCmdIsCovered(CWallCommand *others,CWallCommand *wall,I64 cnt) {
  I64 idx;
  Bool visible=FALSE;
  I64 y=ClampI64(wall->start,0,GR_HEIGHT/2),ey=ClampI64(wall->end,0,GR_HEIGHT/2);
  I64 a,b;
  CWallCommand *other;
  for(idx=0;idx!=cnt;idx++) {
    other=&others[idx];
    if(other!=wall&&other->dist<wall->dist&&other->ld!=wall->ld) {
      a=ClampI64(other->start,0,GR_HEIGHT/2);
      b=ClampI64(other->end,0,GR_HEIGHT/2);
      if(a<=y<=b&&a<=ey<=b)
       return TRUE;
    }
  }
  return FALSE;
}
U0 MergeWallCommands(CDoomCamera *cam) {
  I64 i=0,i2,cnt,new_cnt;
  CWallCommand *cmds;
  for(i=0;i!=GR_WIDTH/2;i++) {
    cmds=&cam->wall_commands[i];
    QSort(cmds,cnt=cam->wall_command_cnts[i],sizeof(CWallCommand),&WallCmdSort);
    new_cnt=0;
    for(i2=0;i2!=cnt;i2++) {
      if(WallCmdIsCovered(cmds,&cmds[i2],cnt)) {
        ; //Exclude from result
      } else {
        if(new_cnt!=i2)
	  MemCpy(&cmds[new_cnt],&cmds[i2],sizeof CWallCommand);
        new_cnt++;
      }
    }
    cam->wall_command_cnts[i]=new_cnt;
  }
}


U0 DrawBSP0(CDC *to_dc,CDoomCamera *cam,CDoomBSPNode *node) {
  if(node->signature!='NODE') {
    DrawSubsector(to_dc,cam,node);
    return;
  }
  if(node->visited) return;
  node->visited=TRUE;
  F64 left_dist,right_dist;
  CD2 other;
//Pick the closer node
  node->left_child->x;
  other.x=node->left_child->x+node->left_child->dx;
  other.y=node->left_child->y+node->left_child->dy;
  left_dist=DistFromLine(&cam->x,&node->left_child->x,&other);
  other.x=node->right_child->x+node->right_child->dx;
  other.y=node->right_child->y+node->right_child->dy;
  right_dist=DistFromLine(&cam->x,&node->right_child->x,&other);
  if(left_dist<right_dist) {
    if(HitsBBox(cam,&node->left))
      DrawBSP0(to_dc,cam,node->left_child);
    if(HitsBBox(cam,&node->right))
      DrawBSP0(to_dc,cam,node->right_child);
  } else {
    if(HitsBBox(cam,&node->right))
      DrawBSP0(to_dc,cam,node->right_child);
    if(HitsBBox(cam,&node->left))
      DrawBSP0(to_dc,cam,node->left_child);
  }
  if(node->parent) DrawBSP0(to_dc,cam,node->parent);
  node->visited=FALSE;
}

U0 DrawBSP(CDC *to_dc,CDoomCamera *cam,CDoomLevel *level) {
  DrawBSP0(to_dc,cam,DoomWhichBSPNode(cam->x,cam->y,level));
}

I64 FloorSort(CVisplane *va,CVisplane *vb)  {
  CDoomSector *a=va->sector,*b=vb->sector;
  if(a->floor_height>b->floor_height)
    return -1;
  if(a->floor_height<b->floor_height)
    return 1;
  return 0;
}

I64 CeilSort(CVisplane *va,CVisplane *vb)  {
  CDoomSector *a=va->sector,*b=vb->sector;
  if(a->ceil_height<b->ceil_height)
    return -1;
  if(a->ceil_height>b->ceil_height)
    return 1;
  return 0;
}


U0 DrawSky(CDC *to_dc,CDoomLevel *l,CDoomCamera *cam) {
  CDC *texture;
  switch(l->episode) {
   case 1:
     texture=GetGrLump("SKY1");
   break;
   case 2:
     texture=GetGrLump("SKY2");
   break;
   case 3:
     texture=GetGrLump("SKY3");
   break;
   case 4:
     texture=GetGrLump("SKY4");
   break;
  }
  I64 iy,ix,off=texture->width*cam->angle/pi,tx,ty;
  U16 *to,*from;
  for(iy=0;iy!=GR_HEIGHT;iy+=2) {
    ty=iy/ToF64(GR_HEIGHT)*texture->height;
    if(ty>texture->height-2)
      ty=texture->height-2;
    for(ix=0;ix!=GR_WIDTH;ix+=2) {
      to=&to_dc->body[GR_WIDTH-2-ix+iy*to_dc->width_internal];
      if(*to&TRANSPARENT!=TRANSPARENT)
        goto skip;
      tx=(ix+off)/ToF64(GR_WIDTH)*texture->width;
//Avoids Templeos bug with &=~1;
      tx=tx&~1;
      tx%=texture->width-2;
      tx=AbsI64(tx);
      from=&texture->body[tx+ty*texture->width_internal];
      *to=*from;
      from(U8*)+=texture->width_internal;
      to(U8*)+=to_dc->width_internal;
      *to=*from;
skip:;
    }
  }
}

U0 DrawDoomWorld(CDoomCamera *cam,CDoomLevel *level,CDC *to_dc) {
  CDoomSector *sector;  
  CDoomThing *thing;
  CVisplane *sorted[256];
  I64 idx=0,idx2,af,tf;
  LBts(&doom_scrn_in_draw,0);
  cam->visplane_cnt=0;
  if(!cam->floor_dc) {
    cam->floor_dc=DCNew(GR_WIDTH/2,GR_HEIGHT/2);
    DCDepthBufAlloc(cam->floor_dc);
  }
  DCDepthBufRst(cam->floor_dc);
  DCFill(doom_scrn);
  DCFill(cam->floor_dc,BLACK);
  for(sector=level->sectors.next;sector!=&level->sectors;sector=sector->next)
    sector->drawn=FALSE;
  MemSetI64(cam->wall_command_cnts,0,GR_WIDTH/2);
  if(!to_dc->depth_buf)
    DCDepthBufAlloc(to_dc);
  else
    DCDepthBufRst(to_dc);
  DrawBSP(to_dc,cam,level);

  MergeWallCommands(cam);

  af=Server_tS*4;
  for(idx2=0;idx2!=cam->visplane_cnt;idx2++) {
    sorted[idx2]=&cam->visplanes[idx2];
  }
  QSortI64(sorted,cam->visplane_cnt,&FloorSort);
  for(idx2=0;idx2!=cam->visplane_cnt;idx2++) {
    sector=sorted[idx2]->sector;
    if(sector->floor_dc)
      if(sector->floor_height<cam->h&&sector->ceil_height!=sector->floor_height)
        DrawTexturedFlat(l,to_dc,cam,sector,sector->floor_height,sector->floor_dc[af%FrameCnt(sector->floor_dc)],TRUE);
  }
  QSortI64(sorted,cam->visplane_cnt,&CeilSort);
  for(idx2=0;idx2!=cam->visplane_cnt;idx2++) {
    sector=sorted[idx2]->sector;
    if(sector->ceil_dc) {
      if(sector->ceil_height>cam->h&&sector->ceil_height!=sector->floor_height)
        DrawTexturedFlat(l,to_dc,cam,sector,sector->ceil_height,sector->ceil_dc[af%FrameCnt(sector->ceil_dc)],FALSE);
    }
  }
  for(thing=level->things.next;thing!=&level->things;thing=thing->next) {
    sector=GetSectorForCoord(level,thing->x,thing->y);
    if(sector->drawn)
      DrawAThing(to_dc,thing,cam);
  }
  DrawSky(to_dc,l,cam);
  for(idx=0;idx!=GR_WIDTH/2;idx++) {
    for(idx2=0;idx2!=cam->wall_command_cnts[idx];idx2++) {
//Earlier we trimmed out the hidden wall commands that are behind walls
	cam->wall_commands[idx][idx2].ld->seen=TRUE;
    }
  }
  LBtr(&doom_scrn_in_draw,0);
}

U0 SongTaskDOOM(I64 LEVEL)
{//Original Song by Robert Prince

  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  if(LEVEL==0||LEVEL>=3)
    {
    while (TRUE) {
      music.stacatto_factor = .75;
      music.tempo = 8;
      I64 i =3;
      while(i!=0)
        {
        Play("1AA2A1AA2G1AA2F1AA2D#1A2EF");
        Play("1AA2A1AA2G1AA2F1AA2D#D#D#D#");   
        i--;
      }
      Play("1AA2A1AA2G1AA2F1AA2D#1A2EF");
      Play("1AA2A1AA2G1AAtt3BA2F#3BDCB2F#3BCDEDCB2F#..");

      Play("1AA2A1AA2G1AA2F1AA2D#1A2EF");
      Play("1AA2A1AA2G1AA2F1AA2D#D#D#D#");   
      Play("1AA2A1AA2G1AA2F1AA2D#1A2EF");
      Play("1AA2A1AA2G1AAtt3ECACECEAECECEA..");

      Play("1DD2D1DD2C1DDA#1DDG#DDAA#");
      Play("1DD2D1DD2C1DDA#1DDG#G#G#G#");
      Play("1DD2D1DD2C1DDA#1DDG#DDAA#");
      Play("1DD2D1DD2C1DDtt4AGFAFDFADAFAFAFAFD.."); 

      Play("1AA2A1AA2G1AA2F1AA2D#1AA2EF");
      Play("1AA2A1AA2G1AA2F1AA2D#D#D#D#D#");    
      Play("1AA2A1AA2G1AA2F1AA2D#1AA2EF");
      Play("1AA2A1AA2G1AA2F1AA2D#D#D#D#D#");

      Play("1F#F#2F#1F#F#2E1F#F#2D1F#F#2C1F#F#2C#D");
      Play("1EE2E1EE2D1EE2C1D#D1A#A#A#A#");

      Play("1AA2A1AA2G1AA2F1AA2D#1AA2EF");
      Play("1AA2A1AA2G1AA2tt3AC2EC3A2E3CACA2EC3ACEA..");

      Play("1AA2A1AA2G1AA2F1AA2D#1AA2EF");
      Play("1AA2A1AA2G1AA2F1AA2D#D#D#D#D#");    
      Play("1AA2A1AA2G1AA2F1AA2D#1AA2EF");

      Play("1AA2A1AA2G1AAtt2G#FEB3B2G#ED3DB2G#E3EDB2G#..");
      Play("1AA2C1AA2B1AAG#AAGAAG2A");
      Play("1AA2C1AA2B1AAEAAF#F#F#F#");

      Play("1F#F#3C1F#F#3B1F#F#3A1F#F#2F#1F#F#2F#A");
      Play("1EE3B1EE3A1EE2G#1D#D2EEEE");

      Play("1AA2C1AA2B1AAG#AAGAAG2A");
      Play("1AA2C1AA2B1AAtt3DB2G#EDB1G#E3E3DB2G#EDB..");
      Play("1G#2A");
    }
  } else if(LEVEL==1) {

    while(TRUE){ //original song by Jamiroquai
      music.stacatto_factor = .9;
      music.tempo = 6;
      Play("q2A#D#3ttF#A#4hD#r..");
      Play("q2A#G#3ttF#4ChD#r..");
      Play("q2D#C#ttB4FhG#r..");
      Play("q2G#F#3ttA#4C#hFr..");
      Play("q3C#CttF#A#4hD#r..");
      Play("q2F#B3ttF#A#4hD#r..");
      Play("q2F#A#3ttG#4wDtq5F#G#A#hA#..");
      Play("q2D#A#5G#2ttC#F#..5F#");
      Play("5C#D#2G#5D#3ttD#F#4C..5hF#");
      Play("5qD#tt2C#..5G#tt2G#..5G#tt2B3F5F#..C#D#2F#5D#tt2C#5hD#q2FhA#q");
      Play("2C5C#D#tt2F#A#3D#..5hF#q");
      Play("2B5C#D#tt3F#A#3D#..5hF#q");
      Play("5F#2A#3F5F3G#4D5D#FF#2D#5D#");
      Play("2A#C#F#5D#D#hAq2D#5G#2ttA#3C#F#..5F#G#G#2hG#q5ttD#2D#F#3C..5hF#hG#q");
      Play("2C#ttG#B3F..5C#D#F#2F#5D#tt3C#FA#5hF#q..");
      Play("tt3C5C#D#tt3F#A#4D#..5hF#q");
      Play("2B5C#D#tt3F#A#D#..5hF#q");
      Play("5hF#q2A#5F3ttFG#D..5D#FF#2D#5hD#q");
      Play("ttt2D#A#3C#F#2hF#...5qC#tt2D#..5D#F#D#tt2A#3C#F#..5D#C#4A#A#hG#q2ttG#D#F#C#..");
      Play("5C#D#F#D#tt2C#G#B3F..5C#4A#A#hG#F#qA#tt2F#3C#FA#..");
      Play("5C#D#F#D#tt3CF#A#4D#..5C#4A#A#hG#qtt2B3F#A#4D#..A#5C#hD#q");
      Play("tt2A#3FG#B..5BhA#q2ttD#A#3C#F#..5G#F#G#F#hAqtt2D#G#A#3C#F#..5G#F#F#");
      Play("tt2C#G#B3F..5D#D#F#F#G#2ttF#3C#FA#..5D#F#D#F#D#tt3CF#A#D#..5F#D#F#D#3ttCF#A#3D#..5F#D#F#D#");
      Play("tt2B3F#A#4D#..5F#G#hG#qF#tt2A#3FG#D..5F#D#tt3FG#4D..");
      Play("tt2B4B5F#.B5hD#qtt3F#A#4D#3F#A#4D#2A#4A#5F4A#5hDqtt3FG#4D3FG#4D..");
      Play("tt2D#4A#5D#2A#3C#F#4A#5D#4A#5D#2A#3C#F#4A#5F4B5F#F2G#3D#F#B4B5D#2A#3FG#4DA#5Fr..");
      Play("tt2B4B5G#4B5hD#qtt3F#A#4D#3F#A#4D#A#..4A#5F4A#5hDqtt3FG#4D3FG#4D..");
      Play("tt2D#A#C#F#4A#5F#4A#5F4A#5D#4A#5F2A#C#F#4B5F#2G#3D#F#B4B5F4B5F2A#3FG#4DB5D#2B");
      Play("4B5F#4B5hD#qttt3F#A4#D3#F#A4#D#3A#4A#5F4hA#5hDqtt3FG#4D3FG#4D2D#A#3C#F#4A#5D#4A#5D#4A#5D#2A#3C#F#4A#5F4B5F#2G#3D#F#B4F#5D#4F#5D#2A#3FG#4D");
      Play("G#5C#2B4F#5D#4A#G#A#3F#A#4D#3F#A#4D#2A#3FG#4D5hC#4qA#t");
      Play("3FG#4DG#F#G#A#2D#A#3C#F#2A#3C#tF#5C#D#hF#.q");
      Play("tt2G#3D#F#B2A#3FG#4D5hD#qtD#AG#t2D#A#3C#F#..5hG#q");
      Play("5D#F#D#F#tt2C#G#B3F..5F#F#F#F#tt2F#C#FA#..5F#D#");
      Play("tt3CF#A#4D#..5C#D#F#rtt2B3F#A#4D#..5C#D#F#D#F#rtt2A#3FG4D..5D#D#Ftt2D#A#3C#F#..");
      Play("5D#hAqtt2G#3D#F#4C3D#F#4C..5#G#G#hF#hG#qtt2C#G#tB3F2B3F...5hF#qtt2G#B3F2F#..5hG#qttF#2F#3C#FA#..5D#F#D#tt3CF#A#4D#..");
      Play("tt2B3F#A#4D#..5C#D#F#tt2A#3FG#4D..5C#D#F#D#F#D#");
      Play("tt2D#A#C#F#F#..5C#rD#F#D#C#4A#tt2G#3D#F#4C3D#F#4C..4A#G#");
      Play("tt2C#G#B3F3G#B4F..5C#D#F#D#C#4A#tt2F#3C#FA#C#FA#..4A#G#");
      Play("tt3CD#F#A#D#F#A#..5C#D#F#D#C#4A#tt2B3F#A#4D#3F#A#D#..4A#G#tt2A#3FG#4D3FG#4D..4A#5C#D#"); 
      Play("tt2D#A#3C#F#..5wA#qtt2G#3D#F#4C..5G#G#F#tt2C#G#B3F..5D#F#F#D#D#F#F#D#tt2F#3C#FA#.."); 
      Play("tt3CF#A#4D#..5D#F#D#F#D#F#tt2B3F#A#4D#..5D#A#D#F#D#tt2A#3FG#4D3FG#4D2B....");
      Play("tt2B4B5F#.B5hD#qtt3F#A#4D#3F#A#4D#2A#4A#5F4A#5hDqtt3FG#4D3FG#4D..");
      Play("tt2D#4A#5D#2A#3C#F#4A#5D#4A#5D#2A#3C#F#4A#5F4B5F#F2G#3D#F#B4B5D#2A#3FG#4DA#5Fr..");
      Play("tt2B4B5G#4B5hD#qtt3F#A#4D#3F#A#4D#A#..4A#5F4A#5hDqtt3FG#4D3FG#4D..");
      Play("tt2D#A#C#F#4A#5F#4A#5F4A#5D#4A#5F2A#C#F#4B5F#2G#3D#F#B4B5F4B5F2A#3FG#4DB5D#2B");
      Play("4B5F#4B5hD#qttt3F#A4#D3#F#A4#D#3A#4A#5F4hA#5hDqtt3FG#4D3FG#4D2D#A#3C#F#4A#5D#4A#5D#4A#5D#2A#3C#F#4A#5F4B5F#2G#3D#F#B4F#5D#4F#5D#2A#3FG#4D");
      Play("G#5C#2B4F#5D#4A#G#A#3F#A#4D#3F#A#4D#2A#3FG#4D5hC#4qA#t");
      Play("3FG#4DG#F#G#A#2D#A#3C#F#2A#3C#tF#5C#D#hF#.q");
      Play(".q2A#D#3ttF#A#4hD#r..");
      Play("q2A#G#3ttF#4ChD#r..");
      Play("q2D#C#ttB4FhG#r..");
      Play("q2G#F#3ttA#4C#hFr..");
      Play("q3C#CttF#A#4hD#r..");
      Play("q2F#B3ttF#A#4hD#r..");
      Play("q2F#A#3ttG#4wDw4D#rr");
    }
  } else if(LEVEL==2) {
  //original by Mick Gordon
   while(TRUE)
   {

    //I64 i,j;
    SndRst;
    music.tempo = 1.2;
    music.staca$IV,0$tto_factor=.9;

    Play("e4C#3C#C#C#tttD...C#");
    Play("ttt4CD..C#.3C#C#D4D3tttF#G..4C#.");
    Play("3C#C#C#tttD...C#");
    Play("ttt4CD..C#.3C#ttC#G#4C#C2ErErEr");


    Play("");


    Play("tt4E3CG#CD..");
    Play("4C3CCCDC#");
    Play("4tttCD..C#.3C#C#D4D3F#G4C#3C#C#C#DC#");
    Play("4tttCD..C#.3C#C#G#4C#C3CC4C3C4C#3C#C#C#DC#");
    Play("4tttCD..C#.3C#C#D4D3F#G4C#3C#C#C#DC#");
    Play("4tttCD..C#.3C#C#G#4C#C3CC4C3CC#C#C#DC#");
  
    Play("4eC#etttttDFG#B5qCettttt4BA#qAqG#etttttAA#B5CqC#");
    Play("5qCettttt4BA#qAG#etttttGqF#w4F");

    Play("etttttD#DC#C3BA#AG#GF#FED#DC#C2BA#AG#GF#FD#DC#C");

    Play("4C#etttttDFG#B5qCettttt4BA#qAqG#etttttAA#B5CqC#Cettttt4BA#qA");
    Play("4etttttA#B5CC#q5DwC#");
    Play("etttttD#DC#C3BA#AG#GF#FED#DC#C2BA#AG#GF#FD#DC#C");
  
    //Play("4tttCD..C#.3C#C#G#4C#C3CC4C3CC#C#C#DC#"); 


   }


  }
}

CTask *music_task=NULL;


F64 GetTargetLiftHeight(CDoomSector *floor,I64 type,Bool going_up=TRUE) {
  F64 lowest=floor->floor_height,highest=floor->floor_height,diff;
  I64 idx,idx2;
  CDoomSidedef *sd;
  Bool up;
  switch(type) {
    case LIFT_STOP:
      return floor->floor_height;
    case LIFT_LOWEST_FLOOR:
      for(idx=0;idx!=floor->linedef_cnt;idx++) {
        sd=floor->linedefs[idx]->front;
        if(sd&&sd!=floor)
	  lowest=Min(lowest,sd->sector->floor_height);
        sd=floor->linedefs[idx]->back;
        if(sd&&sd!=floor)
	  lowest=Min(lowest,sd->sector->floor_height);
      }
      up=floor->floor_height==lowest;
      if(up) return floor->base_floor_height;
      return lowest;
    case LIFT_RAISE_32:
      up=floor->base_floor_height+32>floor->floor_height;
      if(up)
        return floor->base_floor_height+32;
      return floor->base_floor_height;
    case LIFT_RAISE_24:
      up=floor->base_floor_height+24>floor->floor_height;
      if(up)
        return floor->base_floor_height+24;
      return floor->base_floor_height;
    case LIFT_RAISE_NEXT_FLOOR:
      diff=I16_MAX;
      for(idx=0;idx!=floor->linedef_cnt;idx++) {
        for(idx2=0;idx2!=2;idx2++) {
	  if(idx2)
	    sd=floor->linedefs[idx]->front;
	  else
	    sd=floor->linedefs[idx]->back;
	  if(sd&&sd!=floor)
	    if(sd->sector->floor_height>floor->floor_height)
	      diff=Min(diff,sd->sector->floor_height-floor->floor_height);
        }
      }
      if(diff==ToF64(I16_MAX))
        return floor->base_floor_height;
      return diff+floor->floor_height;
    case LIFT_LOW_HIGH_REPEAT:
      if(going_up) {
        for(idx=0;idx!=floor->linedef_cnt;idx++) {
	  sd=floor->linedefs[idx]->front;
	  if(sd&&sd!=floor)
	    highest=Max(highest,sd->sector->base_floor_height);
	  sd=floor->linedefs[idx]->back;
	  if(sd&&sd!=floor)
	    highest=Max(highest,sd->sector->base_floor_height);
        }
        return highest;
      } else {
        for(idx=0;idx!=floor->linedef_cnt;idx++) {
	  sd=floor->linedefs[idx]->front;
	  if(sd&&sd!=floor)
	    lowest=Min(lowest,sd->sector->base_floor_height);
	  sd=floor->linedefs[idx]->back;
	  if(sd&&sd!=floor)
	    lowest=Min(lowest,sd->sector->base_floor_height);
        }
        return lowest;
      }
    case LIFT_CEIL_TOGGLE:
      if(floor->base_floor_height==floor->floor_height)
        return floor->base_ceil_height;
      return floor->base_floor_height;
  }
}


#define WACTIVATE_PUSH 1
#define WACTIVATE_SHOOT 2
#define WACTIVATE_SWITCH 4
#define WACTIVATE_MONSTER 8
#define WACTIVATE_WALK 0x10

#define TIME_SCALE (35.)

Bool OutsideOfRange(F64 p,F64 s,F64 e) {
  if(s<e&&s<=p<=e)
    return FALSE;
  else if(e<=p<=s)
    return FALSE;
  return TRUE;
}

F64 GetTargetCeilHeight(CDoomSector *s,I64 target) {
  I64 idx;
  CDoomSector *other;
  F64 to=s->ceil_height;
  switch(target) {
    case CEIL_DST_FLOOR:
      return s->floor_height;
    case CEIL_DST_HIGHEST_CEIL:
      for(idx=0;idx!=s->linedef_cnt;idx++) {
        if(s->linedefs[idx]->back&&s!=s->linedefs[idx]->back->sector) {
	  other=s->linedefs[idx]->back->sector;
        } else if(s->linedefs[idx]->front&&s!=s->linedefs[idx]->front->sector) {
	  other=s->linedefs[idx]->front->sector;
        }
        if(other)
	  to=Max(to,other->ceil_height);
      }
      return to;
    case CEIL_DST_FLOOR8:
      return s->floor_height+8;
    case CEIL_DST_LOWEST_CEIL:
      for(idx=0;idx!=s->linedef_cnt;idx++) {
        if(s->linedefs[idx]->back&&s!=s->linedefs[idx]->back->sector) {
	  other=s->linedefs[idx]->back->sector;
        } else if(s->linedefs[idx]->front&&s!=s->linedefs[idx]->front->sector) {
	  other=s->linedefs[idx]->front->sector;
        }
        if(other)
	  to=Min(to,other->ceil_height);
      }
      return to;
    case CEIL_DST_HIGHEST_FLOOR:
      to=s->floor_height;
      for(idx=0;idx!=s->linedef_cnt;idx++) {
        if(s->linedefs[idx]->back&&s!=s->linedefs[idx]->back->sector) {
	  other=s->linedefs[idx]->back->sector;
        } else if(s->linedefs[idx]->front&&s!=s->linedefs[idx]->front->sector) {
	  other=s->linedefs[idx]->front->sector;
        }
        if(other)
	  to=Min(to,other->floor_height);
      }
      return to;
  }
}

class CCeilThinker:CDoomThinkerBase {
  F64 target_start,target_end;
  F64 start_tS,speed,wait;
  CDoomSector*s;
  Bool going_up,going_down;
};
U0 CeilThinker(CDoomLevel *l,CCeilThinker *t) {
  CDoomSector *s=t->s;
  if(s->paused) return;
  if(!t->going_up&&!t->going_down) {
    if(t->target_end>s->ceil_height)
      t->going_up=TRUE,t->going_down=FALSE;
    else
      t->going_down=TRUE,t->going_up=FALSE;
  }
  F64 dir=Sign(t->target_end-t->target_start);
  s->ceil_height=dir*t->speed*TIME_SCALE*(Server_tS-t->start_tS)+t->target_start;
  if(t->going_up&&s->ceil_height>=t->target_end) {
    s->ceil_height=t->target_end;
    t->going_up=FALSE;
    s->cur_action_linedef=NULL;
    Spawn(&PlaySoundTask,"PSTOP","snd",0,Fs);
    QueRem(t);
    Free(t);
  } else if(t->going_down&&s->ceil_height<=t->target_end) {
    s->ceil_height=t->target_end;
    t->going_down=FALSE;
    s->cur_action_linedef=NULL;
    Spawn(&PlaySoundTask,"PSTOP","snd",0,Fs);
    QueRem(t);
    Free(t);
  }
}
U0 AddCeilThinker(CDoomLevel *l,CDoomSector *s,CDoomLinedef *ld,CDoomCeil *ceil) {
  if(s->cur_action_linedef) return;
  F64 dst=GetTargetCeilHeight(s,ceil->target);  
  CCeilThinker *t=AddThinker(l,&CeilThinker,"CCeilThinker");
  t->s=s;
  t->target_start=s->floor_height;
  t->target_end=dst;
  t->start_tS=Server_tS;
  t->speed=ceil->speed;
  s->cur_action_linedef=ld;
}
//This is used for floors too
class CLiftThinker:CDoomThinkerBase {
  F64 target_start,target_end;
  F64 start_tS,speed,wait_time;
  CDoomSector*s;
  CDoomLinedef *ld;
  CDoomLift *action;
  Bool going_up,going_down,reverting,waiting;
};

U0 LiftThinker(CDoomLevel *l,CLiftThinker *t) {
  CDoomSector *s=t->s;
  CDoomLift *action=t->action;
//Maybe we were stoped?
  if(!s->cur_action_linedef) {
    QueRem(t);
    Free(t);
    return;
  }
  CDoomLinedef *ld=t->ld;
  F64 dir;
  if(action->type=='Lift') {
    if(action->target==LIFT_LOW_HIGH_REPEAT) {
      dir=Sign(t->target_end-t->target_start);
      s->floor_height=dir*t->speed*TIME_SCALE*(Server_tS-t->start_tS)+t->target_start;
      if(dir>0.) {
        t->going_up=TRUE;
        if(s->floor_height>=t->target_end) {
	  s->floor_height=t->target_end;
lift_again:
	  t->target_start=s->floor_height;
	  Spawn(&PlaySoundTask,"PSTART","snd",0,Fs);
	  t->start_tS=Server_tS;
	  t->target_end=GetTargetLiftHeight(s,action->target,!t->going_up);
	  t->going_up=!t->going_up;
        }
      } else if(dir<0.) {
        t->going_up=FALSE;
        if(s->floor_height<=t->target_end) {
	  s->floor_height=t->target_end;
	  goto lift_again;
        }
      } else {
        t->going_up=!t->going_up;
        goto lift_again;
      }
    } else  {
      if(t->target_end>s->floor_height)
        t->going_up=TRUE,t->going_down=FALSE;
      else
        t->going_down=TRUE,t->going_up=FALSE;
      goto floor_defacto;
    }
  } else if(action->type=='Floor') {
floor_defacto:
    dir=Sign(t->target_end-t->target_start);
    if(!t->waiting) 
      s->floor_height=dir*t->speed*TIME_SCALE*(Server_tS-t->start_tS)+t->target_start;
    if(t->going_up) {
      if(s->floor_height>=t->target_end) {
        s->floor_height=t->target_end;
        t->going_up=FALSE;
floor_en:
        if(action->type=='Lift'&&!t->reverting) {
	  if(!t->waiting) {
	    t->waiting=TRUE;
	    Spawn(&PlaySoundTask,"PSTOP","snd",0,Fs);
	    t->start_tS=Server_tS;
	  }
	  if(t->wait_time+t->start_tS>Server_tS||t->wait_time<0.) {
	    return;
	  }
	  t->waiting=FALSE;
	  t->start_tS=Server_tS;
	  t->reverting=TRUE;
	  t->target_start=s->floor_height;
	  t->target_end=s->base_floor_height;
        } else {
	  t->reverting=FALSE;
	  s->cur_action_linedef=NULL;
	  QueRem(t);
	  Free(t);
	  t->going_up=FALSE,t->going_down=FALSE;
	  Spawn(&PlaySoundTask,"PSTOP","snd",0,Fs);
        }
      }
    } else if(t->going_down) {
      if(s->floor_height<=t->target_end) {
        s->floor_height=t->target_end;
        t->going_down=FALSE;
        goto floor_en;
      }
    }

  }
}

U0 AddLiftThinker(CDoomLevel *l,F64 st,F64 en,
	CDoomSector *s,CDoomLinedef *ld,
	CDoomLift *action,Bool up) {
  if(action->target==LIFT_STOP&&action->type=='Lift') {
    s->cur_action_linedef=NULL;
    return;
  }
  if(s->cur_action_linedef) {
    return;
  }
  s->cur_action_linedef=ld;
  CLiftThinker *t=AddThinker(l,&LiftThinker,"CLiftThinker");
  t->start_tS=Server_tS;
  t->target_start=st;
  t->target_end=en;
  t->wait_time=action->delay;
  t->speed=action->speed;
  t->s=s;
  t->ld=ld;
  t->action=action;
  if(up)
   t->going_up=TRUE;
  else
   t->going_down=TRUE;
}

class CDoorThinker:CDoomThinkerBase {
  F64 target_start,target_end;
  F64 start_tS,speed;
  F64 wait_time;
  CDoomSector*s;
  CDoomLinedef *ld;
  CDoomDoor *action;
  Bool opening,closing,waiting;
  Bool reverting;
};
//This doesnt do damage
U0 CrushThingsInSector(CDoomLevel *l,CDoomSector *s) {
//Crush them at 16 units
  if(s->ceil_height-s->floor_height>16.)
    return;
  CDoomThing *thing,**things=GetCrushedThingsInSector(l,s),*new;
  I64 idx;
  for(idx=0;thing=things[idx];idx++) {
    if(thing->template&&thing->health<=0.)
      switch(thing->template->type) {
        case 64:
        case 68:
        case 3003:
        case 3005:
        case 72:
        case 16:
        case 3002:
        case 65:
        case 69:
        case 3001:
        case 3006:
        case 67:
        case 71:
        case 66:
        case 9:
        case 58:
        case 7:
        case 84:
        case 3004:
          Spawn(&PlaySoundTask,"SLOP",,0,Fs);
	  thing->template=doom_thing_types[24];
	  thing->animation=NULL; //Will be set automatically(quit current animation)
      }
  }
  Free(things);
}
U0 DoorThinker(CDoomLevel *l,CDoorThinker *t) {
  CDoomSector *s=t->s;
  CDoomThing **things;
  F64 ceil=I16_MAX,dir;
  I64 idx;
//A door is fully open when its ceiling height is 4 less than the lowest neighbor ceiling adjacent to it
  for(idx=0;idx!=s->linedef_cnt;idx++) {
    if(s->linedefs[idx]->back&&s->linedefs[idx]->back->sector!=s)
      ceil=Min(s->linedefs[idx]->back->sector->base_ceil_height-4,ceil);
    else if(s->linedefs[idx]->front&&s->linedefs[idx]->front->sector!=s)
      ceil=Min(s->linedefs[idx]->front->sector->base_ceil_height-4,ceil);
  }
  if(t->opening) {
    t->target_end=ceil;
    s->bumped_into=FALSE;
    dir=Sign(t->target_end-t->target_start);
    if(!t->waiting) 
      s->ceil_height=dir*t->speed*TIME_SCALE*(Server_tS-t->start_tS)+t->target_start;
//if dir is 0,we are done
    if(dir==0||OutsideOfRange(s->ceil_height,t->target_start,t->target_end)||t->waiting) {
      s->ceil_height=ceil;
//-1 for never close/open again
      if(t->wait_time>=0.) {
//close again
        if(!t->waiting) {
	  t->waiting=TRUE;
	  t->start_tS=Server_tS;
        }
        if(t->wait_time+t->start_tS>Server_tS) return;
        t->waiting=FALSE;
        t->start_tS=Server_tS;
        t->opening=FALSE;
        t->closing=TRUE;
        Spawn(&PlaySoundTask,"DORCLS",,0,Fs);
        t->wait_time=-1.;
        t->target_start=s->ceil_height;
      } else {
        s->cur_action_linedef=NULL;
        QueRem(t);
        Free(t);
      }
    }
  } else if(t->closing) {
    t->target_end=s->floor_height;
    dir=Sign(t->target_end-t->target_start);
    s->ceil_height=dir*t->speed*TIME_SCALE*(Server_tS-t->start_tS)+t->target_start;
//if dir is 0,we are done
    if(dir==0.||OutsideOfRange(s->ceil_height,t->target_start,t->target_end)||t->waiting) {
      s->ceil_height=s->base_floor_height;
//-1 for never close/open again
      if(t->wait_time>=0.) {
        if(!t->waiting) {
	  t->waiting=TRUE;
	  t->start_tS=Server_tS;
        }
        if(t->wait_time+t->start_tS>Server_tS) return;
        t->wait_time=-1.;
        t->target_start=s->floor_height;
open_again:
        t->waiting=FALSE;
//open again
        t->start_tS=Server_tS;
        t->opening=TRUE;
        t->closing=FALSE;
        Spawn(&PlaySoundTask,"DOROPN","snd",0,Fs);
      } else {
        s->cur_action_linedef=NULL;
        QueRem(t);
        Free(t);
      }
    } else if(s->bumped_into) {
      s->bumped_into=FALSE;
      t->target_start=s->ceil_height;
      t->wait_time=t->action->wait;
      goto open_again;
    } else {
      CrushThingsInSector(l,s);
      things=GetCrushedThingsInSector(l,s); //NULL terminated
      for(idx=0;things[idx];idx++) {
        if(things[idx]->health>0.) {
	  Free(things);
	  t->target_start=s->ceil_height;
	  t->wait_time=t->action->wait;
	  goto open_again;
        }
      }
      Free(things);
    }
  } else {
        s->cur_action_linedef=NULL;
        QueRem(t);
        Free(t);
  }
  s->door_height_offset=s->ceil_height-s->base_floor_height;  
}
U0 AddDoorThinker(CDoomLevel *l,F64 st,F64 en,
	CDoomSector *s,CDoomLinedef *ld,
	CDoomDoor *action,Bool up,F64 wait_time=-1.) {
  if(s->cur_action_linedef) return;
  s->cur_action_linedef=ld;
  CDoorThinker *t=AddThinker(l,&DoorThinker,"CDoorThinker");
  t->start_tS=Server_tS;
  t->target_start=st;
  t->target_end=st;
  t->speed=action->speed;
  t->s=s;
  t->ld=ld;
  t->action=action;
  t->wait_time=wait_time;
  if(up)
   t->opening=TRUE;
  else
   t->closing=TRUE;
}

F64 GetTargetFloorHeight(CDoomSector *floor,I64 type,Bool up) {
  F64 dst;
  F64 diff;
  CDoomSidedef *sd;
  I64 idx;
  switch(type) {
      break; case FLOOR_DST_LOWEST:
      dst=I16_MAX;
      for(idx=0;idx!=floor->linedef_cnt;idx++) {
        if((sd=floor->linedefs[idx]->front)&&sd->sector!=floor) {
        } else
	  sd=floor->linedefs[idx]->back;
        if(sd&&sd->sector!=floor&&sd->sector->floor_height<dst)
	  dst=sd->sector->floor_height;
      }
      break; case FLOOR_ABS_24:
      dst=floor->base_floor_height;
      if(up)
        return dst+24;
      return dst-24;
      break; case FLOOR_ABS_512:
      dst=floor->base_floor_height;
      if(up)
        return dst+512;
      return dst-512;
    start:
      dst=I16_MIN;
      for(idx=0;idx!=floor->linedef_cnt;idx++) {
        if((sd=floor->linedefs[idx]->front)&&sd->sector!=floor) {
        } else
	  sd=floor->linedefs[idx]->back;
        if(sd&&sd->sector!=floor&&sd->sector->ceil_height>dst)
	  dst=sd->sector->ceil_height;
      }
      case FLOOR_DST_HIGHEST_CEIL:
        break;
      case FLOOR_DST_HIGHEST_CEIL_ADD_8:
        dst+=8.;
        break;
    end:
      break;
    start:
      dst=I16_MIN;
      for(idx=0;idx!=floor->linedef_cnt;idx++) {
        if((sd=floor->linedefs[idx]->front)&&sd->sector!=floor) {
        } else
	  sd=floor->linedefs[idx]->back;
        if(sd&&sd->sector!=floor&&sd->sector->floor_height>dst)
	  dst=sd->sector->floor_height;
      }
      case FLOOR_DST_HIGHEST_FLOOR:
        break;
      case FLOOR_DST_HIGHEST_FLOOR_ADD_8:
        dst+=8.;
        break;
    end:
      break;
    start:
      dst=I16_MAX;
      for(idx=0;idx!=floor->linedef_cnt;idx++) {
        if((sd=floor->linedefs[idx]->front)&&sd->sector!=floor) {
        } else
	  sd=floor->linedefs[idx]->back;
        if(sd&&sd->sector!=floor&&sd->sector->ceil_height<dst)
	  dst=sd->sector->ceil_height;
      }
      case FLOOR_DST_LOWEST_CEIL:
        break;
      case FLOOR_DST_LOWEST_CEIL_SUB_8:
        dst-=8.;
        break;
    end:
      break;
    start:
      dst=I16_MAX;
      for(idx=0;idx!=floor->linedef_cnt;idx++) {
        if((sd=floor->linedefs[idx]->front)&&sd->sector!=floor) {
        } else
	  sd=floor->linedefs[idx]->back;
        if(sd&&sd->sector!=floor&&sd->sector->floor_height<dst)
	  dst=sd->sector->floor_height;
      }
      case FLOOR_DST_LOWEST_FLOOR:
        break; case FLOOR_DST_LOWEST_FLOOR_SUB_8:
        dst-=8.;
        break;
    end:
      break; case FLOOR_DST_NEXT_FLOOR:
      if(up) {
        dst=floor->ceil_height;
        for(idx=0;idx!=floor->linedef_cnt;idx++) {
	  if((sd=floor->linedefs[idx]->front)&&sd->sector!=floor) {
	  } else
	    sd=floor->linedefs[idx]->back;
	  if(sd&&sd->sector!=floor) {
	    if(sd->sector->floor_height<dst) {
	      diff=sd->sector->floor_height-floor->floor_height;
	      if(.5<diff<dst-floor->floor_height)
	        dst=sd->sector->floor_height;
	    }
	  }
        }
      } else {
        dst=I16_MIN;
        for(idx=0;idx!=floor->linedef_cnt;idx++) {
	  if((sd=floor->linedefs[idx]->front)&&sd->sector!=floor) {
	  } else
	    sd=floor->linedefs[idx]->back;
	  if(sd&&sd->sector!=floor) {
	    if(sd->sector->floor_height>dst) {
	      diff=sd->sector->floor_height-dst;
	      if(diff<floor->floor_height-dst)
	        dst=sd->sector->floor_height;
	    }
	  }
        }
      }
      break; case FLOOR_DST_LOWEST_TEXTURE:
	dst=I16_MAX;
        for(idx=0;idx!=floor->linedef_cnt;idx++) {
	  if(sd=floor->linedefs[idx]->front) {
	    if(sd->lower_texture[0])
	      dst=Min(sd->lower_texture[0]->height/2,dst); // /2 for dither super pixels
	  }
	  if(sd=floor->linedefs[idx]->back) {
	    if(sd->lower_texture[0])
	      dst=Min(sd->lower_texture[0]->height/2,dst);
	  }
	}
        dst+=floor->base_floor_height;
  }
  return dst;
}

class CDonutThinker:CDoomThinkerBase {
  F64 start_tS;
  CDoomLinedef *ld;
};

U0 DonutThinker(CDoomLevel *l,CDonutThinker *t) {
  CDoomSector *s1,*s2,*s3;
  CDoomLinedef *ld;
  F64 time=Server_tS-t->start_tS;
  I64 i;
  for(s1=l->sectors.next;s1!=&l->sectors;s1=s1->next) {
    if(s1->tag_number==t->ld->sector_tag) {
//      if(s1->cur_action_linedef)
//	goto next;
      ld=s1->linedefs[0];
      if(ld->front^^ld->back) goto next;
      if(ld->front->sector==s1) {
	s2=ld->back->sector;
      } else
	s2=ld->front->sector;
      i=0;
      do {
	ld=s2->linedefs[i];
	if(!(ld->front&&ld->back)||ld->back->sector==s1)
	  goto next2;
	s3=ld->back->sector;
//Rising slime
	if(s2->floor_height<s3->floor_height) {
	  s2->cur_action_linedef=t->ld;
	  s2->floor_height+=1.5*(1/35.);
        } else {
	  s2->floor_height=s3->floor_height;
	  MemCpy(s2->floor_dc,s3->floor_dc,sizeof(CDC*)*4);
	  s2->cur_action_linedef=NULL;
	  s2->special_type=0;
	}
//Decending poo poo
	if(s1->floor_height>s3->floor_height) {
	  s1->cur_action_linedef=t->ld;
	  s1->floor_height-=1.5*(1/35.);
        } else {
	  s1->floor_height=s3->floor_height;
	  s1->cur_action_linedef=NULL;
	}
next2:;
      } while(++i<s2->linedef_cnt);
    }
next:;
  }
}
class CStairsThinker:CDoomThinkerBase {
  CDoomSector *s;
  F64 start_h,start_tS,target_h;
  F64 speed;
};
U0 StairThinker(CDoomLevel *l,CStairsThinker *t) {
  F64 tm=Server_tS-t->start_tS;
  t->s->floor_height=t->start_h+tm*t->speed*30;
  if(t->s->floor_height>t->target_h) {
    t->s->floor_height=t->target_h;
    QueRem(t);
    Free(t);
  }
}
U0 BuildStairs(CDoomLevel *l,CDoomLinedef *ld) {
  CDoomSector *s,*s2,*new;
  CStairsThinker *think;
  CDoomLinedef *ld2;
  CDoomStairs *st=ld->special_type;
  F64 step;
  I64 idx;
  for(s=l->sectors.next;s!=&l->sectors;s=s->next) {
    if(ld->sector_tag==s->tag_number) {
      if(s->cur_action_linedef) {
        goto nxt;
      }
      s->cur_action_linedef=ld;
      step=s->floor_height;
      s2=s;
loop:
      step+=st->step;
      think=AddThinker(l,&StairThinker,"CStairsThinker");
      think->start_h=s->floor_height;
      think->start_tS=Server_tS;
      think->target_h=step;
      think->speed=st->speed;
      think->s=s2;
      for(idx=0;idx!=s2->linedef_cnt;idx++) {
        ld2=s2->linedefs[idx];
        if(ld2->front&&ld2->back) {
	  if(ld2->front->sector==s2) {
	    new=ld2->back->sector;
	    if(!new->cur_action_linedef)
	      if(new->floor_dc[0]==s2->floor_dc[0]) {
	        new->cur_action_linedef=ld;
	        s2=new;
	        goto loop;
	      }
	  }
        }
      }
    }
nxt:;
  }
}

static CDoomThingTemplate *teleport_fog=NULL;
UH("telefog",teleport_fog=CAlloc(sizeof CDoomThingTemplate));
teleport_fog->spr_base_name[0](U32)='TFOG';
teleport_fog->radius=20;
teleport_fog->animation="ABABCDEFGHIJ";
UH("telefoganim",teleport_fog->_animation=GenerateCacheFrames(teleport_fog,teleport_fog->animation));

class CTeleportThinker:CDoomThinkerBase {
  CDoomThing *fog;
};
U0 TeleportFogThinker(CDoomLevel *l,CTeleportThinker *t) {
  CDoomThing *fog=t->fog;
  I64 frame;
  fog->anim_no_repeat=TRUE;
  frame=ToI64((Server_tS-fog->anim_start_tS)*4);
  if(frame>=StrLen(fog->template->animation)) {
    ThingDel(l,fog);
    QueRem(t);
    Free(t);
  }
}
U0 TeleportThing(CDoomLevel *l,CDoomTeleporter *tp,I64 sector_tag,CDoomThing *who) {
  CDoomThing *cur,*fog;
  CDoomSector *sec;
  for(cur=l->things.next;cur!=&l->things;cur=cur->next) {
//https://doomwiki.org/wiki/Teleporter
    if(cur->template->type==14) {
       sec=GetSectorForCoord(l,cur->x,cur->y);
       if(sec->tag_number==sector_tag) {
	 TeleportThingToPos(l,who,cur->x,cur->y,cur->height);
	 if(tp->orient==TP_ORIENT_SET)
	   who->angle=cur->angle;
	 if(!tp->silent) {
           Spawn(&PlaySoundTask,"TELEPT","snd",0,Fs);
	   fog=CAlloc(sizeof CDoomThing);
           InitPosDataForThing(l,fog);
	   QueIns(fog,l->things.last);
	   fog->template=teleport_fog;
	   fog->x=cur->x;
	   fog->y=cur->y;
	   fog->anim_start_tS=Server_tS;
	   fog->thinker=AddThinker(l,&TeleportFogThinker,"CTeleportThinker");
	   fog->thinker(CTeleportThinker*)->fog=fog;
	 }
	 return;
       }
    }
  }
}
U0 ChangeByModel(CDoomLinedef *ld,CDoomSector *s,I64 model,Bool texture_change,Bool type_change,Bool zero) {
  CDoomLinedef *ld2;
  I64 idx;
//Account for texture/type change
  if(texture_change||type_change) {
    if(texture_change) s->tx_changed=TRUE;
    if(zero) s->special_type=0;
    if(model==FLOOR_MODEL_NUMBERED) {
//See EV_DoFloor in doom3do source code
      for(idx=0;idx!=s->linedef_cnt;idx++) {
        ld2=s->linedefs[idx];
        if(ld2->front&&ld2->back) {
	  if(ld2->front->sector!=s) {
	    s->changed_from_sector=ld2->front->sector;
	    if(texture_change)
	      MemCpy(s->floor_dc,ld2->front->sector->floor_dc,8*4);
	    if(type_change)
	      s->special_type=ld2->front->sector->special_type;
	    break;
	  }
	  if(ld2->back->sector!=s) {
	    s->changed_from_sector=ld2->back->sector;
	    if(texture_change)
	      MemCpy(s->floor_dc,ld2->back->sector->floor_dc,8*4);
	    if(type_change)
	      s->special_type=ld2->back->sector->special_type;
	    break;
	  }
        }
      }
    } else if(model==FLOOR_MODEL_TRIGGER) {
      s->changed_from_sector=ld->front->sector;
      if(texture_change){
        MemCpy(s->floor_dc,ld->front->sector->floor_dc,8*4);
      }
      if(type_change)
        s->special_type=ld->front->sector->special_type;
    }
  }
}

class CCrushThinker:CDoomThinkerBase {
  CDoomSector *s;
  F64 base_speed;
  Bool going_up;
};
//NULL terminated
class CLightBlinkThinker:CDoomThinkerBase {
  CDoomSector *s;
  F64 begin_at_tS;
  F64 change_tS;
  Bool on;
};
U0 LightBlinkThinker(CDoomLevel *l,CLightBlinkThinker *t) {
  F64 ts=Server_tS;
  CDoomSector *s=t->s;
  if(ts<t->begin_at_tS) {
    return;
  }
  if(ts>t->change_tS) {
    t->on^=TRUE;
    if(t->on)
      t->change_tS=ts+1/7.*30;
    else
      t->change_tS=ts+1;
  }
  if(t->on) {
    s->cur_light_level=s->base_light_level;
  } else {
    s->cur_light_level=LowestSurrondingLight(s);
  }
}
extern U0 AddCrushThinker(CDoomLevel *l,CDoomSector *s,CDoomCrusher *c);
Bool _TriggerLinedef(CDoomLevel *l,CDoomSector *s,CDoomLinedef *ld,I64 flags,CDoomThing *who) {
  CDoomActionSector *type;
  CDoomFloor *fl;
  CDoomDoor *door;
  CDoomLift *lift;
  CDoomCeil *ceil;
  CDoomDonut *donut;
  CDoomExit *exit;
  CDoomTeleporter *tp;
  CDoomCrusher *crush;
  CDoomLight *light;
  I64 idx;
  CDoomLinedef *ld2;
  CDonutThinker *dt;
  CLightBlinkThinker *blink;
  Vector *cross;
  CD2 point;
  F64 dst;
  if(ld) {
    if((type=ld->special_type)) {
      if(type->type=='Light') {
        light=type;
        switch(light->trigger) {
	    break;case 'P1':
light_activate1:
	    if(ld->activated) return FALSE;
light_activate:
	    if(light->target==LIGHT_255) {
	      s->cur_light_level=255;
	    } else if(light->target==LIGHT_35) {
	      s->cur_light_level=35;
	    } else if(light->target==LIGHT_MIN_NIEGHBOR)
	      s->cur_light_level=LowestSurrondingLight(s);
	    else if(light->target==LIGHT_MAX_NIEGHBOR)
	      s->cur_light_level=HighestSurrondingLight(s);
	    else if(light->target==LIGHT_BLINK) {
	      if(ld->activated) return FALSE; //No need to add another thikner
	      blink=AddThinker(l,&LightBlinkThinker,"CLightBlinkThinker");
	      blink->on=FALSE;
	      blink->begin_at_tS=Server_tS+1/30.*9;
	    }
	    return TRUE;
	    break; case 'S1':    
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto light_activate1;
	    break; case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto light_activate1;
	    break; case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto light_activate1;
	    break; case 'PR':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
	    goto light_activate;
	    break; case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto light_activate;
	    break; case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto light_activate;
	    break; case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto light_activate;
        }
      } else if(type->type=='Crush') {
        crush=type;
        switch(crush->trigger) {
	    break;case 'P1':
crush_activate1:
	    if(ld->activated) return FALSE;
crush_activate:
	    if(crush->turn_on) {
	      AddCrushThinker(l,s,ld);
	    } else  //The thinker checks for this
	      s->cur_action_linedef=NULL;
	    return TRUE;
	    break; case 'S1':    
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto crush_activate1;
	    break; case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto crush_activate1;
	    break; case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto crush_activate1;
	    break; case 'PR':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
	    goto crush_activate;
	    break; case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto crush_activate;
	    break; case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto crush_activate;
	    break; case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto crush_activate;
        }
      } else if(type->type=='Stairs') {
        tp=type;
//ld->a
        switch(tp->trigger) {
	    break;case 'P1':
stairs_activate1:
	    if(ld->activated) return FALSE;
stairs_activate:
	    BuildStairs(l,ld);
	    return TRUE;
	    break; case 'S1':    
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto stairs_activate1;
	    break; case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto stairs_activate1;
	    break; case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto stairs_activate1;
	    break; case 'PR':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
	    goto stairs_activate;
	    break; case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto stairs_activate;
	    break; case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto stairs_activate;
	    break; case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto stairs_activate;
        }
      } else if(type->type=='Teleport') {
        tp=type;
        switch(tp->trigger) {
	    break;case 'P1':
teleport_activate1:
	    if(ld->activated) return FALSE;
teleport_activate:
	    if(tp->dest==TP_DEST_TP_THING) {
	      if(flags&WACTIVATE_MONSTER&&!tp->monster)
	        return FALSE;
	      if(!(flags&WACTIVATE_MONSTER)&&!tp->player)
	        return FALSE;
//You must be have passed the first sidedef to trigger a tele[P]orter(meaning you are on the backside)
	      cross=CreateVector(2);
	      cross->data[0]=ld->end->x-ld->start->x;
	      cross->data[1]=ld->end->y-ld->start->y;
	      point.x=who->x-ld->start->x;
	      point.y=who->y-ld->start->y;
	      if(flags&WACTIVATE_WALK&&IsFrontSideOfVector2D(cross,&point)) {
	        DestroyVector(cross);
	        return FALSE;
	      }
	      DestroyVector(cross);
	      TeleportThing(l,tp,ld->sector_tag,who);
	    } else
	      PrintI("UNIMP_DEST",tp->dest); 
	    return TRUE;
	    break; case 'S1':    
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto teleport_activate1;
	    break; case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto teleport_activate1;
	    break; case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto teleport_activate1;
	    break; case 'PR':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
	    goto teleport_activate;
	    break; case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto teleport_activate;
	    break; case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto teleport_activate;
	    break; case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto teleport_activate;
        }

      } else if(type->type=='Exit') {
        exit=type;
        switch(exit->trigger) {
	    break;case 'P1':
exit_activate1:
	    if(ld->activated) return FALSE;
exit_activate:
	    if(s->cur_action_linedef)
	      return FALSE;
	    s->cur_action_linedef=ld;
	    Spawn(&PlaySoundTask,"SWTCHX","snd",0,Fs);
	    l->ended_special=exit->secret;
	    l->ended=TRUE;
	    return TRUE;
	    break; case 'S1':    
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto exit_activate1;
	    break; case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto exit_activate1;
	    break; case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto exit_activate1;
	    break; case 'PR':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
	    goto exit_activate;
	    break; case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto exit_activate;
	    break; case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto exit_activate;
	    break; case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto exit_activate;
        }
      } else if(type->type=='Donut') {
        donut=type;
        switch(donut->trigger) {
	    break; case 'P1':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
donut_activate1:          
	    if(ld->activated) return FALSE;
donut_activate:
	    if(s->cur_action_linedef)
	      return FALSE;
	    s->cur_action_linedef=ld;
	    dt=AddThinker(l,&DonutThinker,"CDonutThinker");
	    dt->ld=ld;
	    dt->start_tS=Server_tS;
	    return TRUE;
	    break; case 'S1':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto donut_activate1;
	    break; case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto donut_activate1;
	    break; case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto donut_activate1;
	    break; case 'PR':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
	    goto donut_activate;
	    break; case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto donut_activate;
	    break; case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto donut_activate;
	    break; case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto donut_activate;
        }
      } else if(type->type=='Ceil') {
        ceil=type;
        switch(ceil->trigger) {
	    break; case 'P1':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
cactivate1:          
	    if(ld->activated) return FALSE;
cactivate:
	    if(s->cur_action_linedef)
	      return FALSE;
	    Spawn(&PlaySoundTask,"STNMOV","snd",0,Fs);
	    AddCeilThinker(l,s,ld,ceil);
	    return TRUE;
	    break; case 'S1':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto cactivate1;
	    break; case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto cactivate1;
	    break; case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto cactivate1;
	    break; case 'PR':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
	    goto cactivate;
	    break; case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto cactivate;
	    break; case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto cactivate;
	    break; case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto cactivate;
        }
      } else if(type->type=='Lift') {
        lift=type;
        switch(lift->trigger) {
	    break; case 'P1':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
lactivate1:
	    if(ld->activated) return FALSE;
lactivate:
	    if(!lift->monster&&(flags&WACTIVATE_MONSTER))
	      return FALSE;
//LIFT_STOP will remove the thinker in AddLiftThinker
	    dst=GetTargetLiftHeight(s,lift->target);
	    AddLiftThinker(l,s->floor_height,dst,s,ld,lift,dst>s->floor_height);
	    Spawn(&PlaySoundTask,"STNMOV","snd",0,Fs);
	    ChangeByModel(ld,s,lift->model,lift->texture_change,lift->type_change,lift->zero_type);
	    return TRUE;
	    break; case 'S1':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto lactivate1;
	    break; case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto lactivate1;
	    break; case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto lactivate1;
	    break; case 'PR':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
	    goto lactivate;
	    break; case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto lactivate;
	    break; case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto lactivate;
	    break; case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto lactivate;
        }
      } else if(type->type=='Floor') {
        fl=type;
        switch(fl->trigger) {
	    break; case 'P1':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
factivate1:
	    if(ld->activated) return FALSE;
factivate:
	    if(s->cur_action_linedef)
	      return FALSE;
	    dst=GetTargetFloorHeight(s,fl->target,fl->direction==FLOOR_DIR_UP);
	    AddLiftThinker(l,s->floor_height,dst,s,ld,fl,dst>s->floor_height);
	    Spawn(&PlaySoundTask,"STNMOV","snd",0,Fs);
	    ChangeByModel(ld,s,fl->model,fl->texture_change,fl->type_change,fl->zero_type);
	    return TRUE;
	    break; case 'S1':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto factivate1;
	    break; case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto factivate1;
	    break; case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto factivate1;
	    break; case 'PR':
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
	    goto factivate;
	    break; case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto factivate;
	    break; case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto factivate;
	    break; case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto factivate;
        }
      } else if(type->type=='Door') {
        door=type;
        switch(door->trigger) {
	  case 'P1':
	    if(!ld->back)
	      break;
	    s=ld->back->sector;
	    if(!(flags&WACTIVATE_PUSH)) return FALSE;
activate1:
	    if(ld->activated) return 0;
activate:
	    if(s->cur_action_linedef)
	      return FALSE;
	    if(!door->monster&&(flags&WACTIVATE_MONSTER))
	      return FALSE;
//Check for keys
	    if(!l->has_red_key&&(door->key&DOOR_LOCK_RED)) {
	      ST_Message(p,"You need a red key to open this door");
	      return 0;
	    }
	    if(!l->has_blue_key&&(door->key&DOOR_LOCK_BLUE)) {
	      ST_Message(p,"You need a blue key to open this door");
	      return 0;
	    }
	    if(!l->has_yellow_key&&(door->key&DOOR_LOCK_YELLOW)) {
	      ST_Message(p,"You need a yellow key to open this door");
	      return 0;
	    }
//Do the door action
	    switch(door->action) {
	      case DOOR_ACTION_OPEN_WAIT_CLOSE:
	        Spawn(&PlaySoundTask,"DOROPN","snd",0,Fs);
	        AddDoorThinker(l,s->ceil_height,0.,s,ld,door,TRUE,door->wait);
	        break;
	      case DOOR_ACTION_CLOSE_WAIT_OPEN:
	        Spawn(&PlaySoundTask,"DORCLS","snd",0,Fs);
	        AddDoorThinker(l,s->ceil_height,0.,s,ld,door,FALSE,door->wait);
	        break;
	      case DOOR_ACTION_CLOSE:
	        Spawn(&PlaySoundTask,"DORCLS","snd",0,Fs);
	        AddDoorThinker(l,s->ceil_height,0.,s,ld,door,FALSE,-1.);
	        break;
	      case DOOR_ACTION_OPEN:
	        Spawn(&PlaySoundTask,"DOROPN","snd",0,Fs);
	        AddDoorThinker(l,s->ceil_height,0.,s,ld,door,TRUE,-1.);
	        break;
	    }
	    return TRUE;
	    break;
	  case 'W1':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto activate1;
	    break;
	  case 'S1':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto activate1;
	    break;
	  case 'G1':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto activate1;
	    break;
	  case 'PR':
	    if(ld->back) {
	      s=ld->back->sector;
	      if(!(flags&WACTIVATE_PUSH)) return FALSE;
	      goto activate;
	    }
	    break;
	  case 'WR':
	    if(!(flags&WACTIVATE_WALK)) return FALSE;
	    goto activate;
	  case 'GR':
	    if(!(flags&WACTIVATE_SHOOT)) return FALSE;
	    goto activate;
	  case 'SR':
	    if(!(flags&WACTIVATE_SWITCH)) return FALSE;
	    goto activate;
        }
      }
    }
  }
  return FALSE;
}
CDC *AltSwitchTexture(U8 *txt,Bool on=FALSE,Bool *res_txtr_is_on=NULL) {
  static U8 *switch_textures[40]={
  "SW1BLUE",
        "SW1BRCOM", 
        "SW1BRI",
        "SW1BRN1",
        "SW1BRN2",
        "SW1BRNGN", 
        "SW1BROWN", 
        "SW1CMT", 
        "SW1COMM", 
        "SW1COMP", 
        "SW1DIRT", 
        "SW1EXIT", 
        "SW1GARG", 
        "SW1GRAY", 
        "SW1GRAY1", 
        "SW1GSTON", 
        "SW1HOT", 
        "SW1LION", 
        "SW1MARB", 
        "SW1MET2", 
        "SW1METAL", 
        "SW1MOD1", 
        "SW1PANEL", 
        "SW1PIPE", 
        "SW1ROCK", 
        "SW1SATYR", 
        "SW1SKIN", 
        "SW1SKULL", 
        "SW1SLAD", 
        "SW1STARG",
        "SW1STON1", 
        "SW1STON2", 
        "SW1STON6", 
        "SW1STONE", 
        "SW1STRTN", 
        "SW1TEK",
        "SW1VINE", 
        "SW1WDMET", 
        "SW1WOOD",
        "SW1ZIM"
        };
  U8 buf[STR_LEN];
  I64 idx=40;
  while(--idx>=0) {
    StrCpy(buf,switch_textures[idx]);
    if(!TextureName2DC(buf))
      goto skip;
    if(TextureName2DC(buf)==txt&&!on) {
      buf[2]='2';
      if(res_txtr_is_on) *res_txtr_is_on=TRUE;
      return TextureName2DC(buf);
    }
    if(on) {
      buf[2]='2';       
      if(TextureName2DC(buf)==txt) {
        buf[2]='1';
        if(res_txtr_is_on) *res_txtr_is_on=FALSE;
        return TextureName2DC(buf);
      }
    }
skip:;
  }
  return NULL;
}
class CButtonThinker:CDoomThinkerBase {
  CDoomSector *s;
  F64 switch_tS;
  I64 which_part;
  U8 active_state;
  U8 done_state;
  Bool repeat;
};

U0 ButtonThinker(CDoomLevel *l,CButtonThinker *t) {
  CDoomSidedef *sd=t->s;
  Bool repeat=t->repeat;
  F64 reset_time=t->switch_tS;
  I64 which_texture=t->which_part;
  U8 on_off_idx=t->active_state; 
  CDC *dc;
  if(!repeat) {
//active_state will be set as we never turn "off" again
    on_off_idx=t->active_state;
    Free(t);
    QueRem(t);
    goto set_and_ret;
  }
  if(reset_time>Server_tS) {
    on_off_idx=t->active_state;
set_and_ret:
    switch(which_texture) {
      case 2: 
        if(dc=AltSwitchTexture(sd->upper_texture[0],on_off_idx!='2'))
	  sd->upper_texture[0]=dc;
        break;
      case 1: 
        if(dc=AltSwitchTexture(sd->middle_texture[0],on_off_idx!='2'))
	  sd->middle_texture[0]=dc;
        break;
      case 0: 
        if(dc=AltSwitchTexture(sd->lower_texture[0],on_off_idx!='2')) {
	  sd->lower_texture[0]=dc;
        }
        break;
    }
    return;
  }
  on_off_idx=t->done_state;
  Free(t);
  QueRem(t);
  Spawn(&PlaySoundTask,"SWTCHX","snd",0,Fs);
  goto set_and_ret;
}
U0 AddButtonThinker(CDoomLevel *l,CDoomSidedef *s,I64 which_part,Bool repeat=TRUE,Bool on) {
  CButtonThinker *t=AddThinker(l,&ButtonThinker,"CButtonThinker");
  t->s=s;
  t->repeat=repeat;
  t->switch_tS=Server_tS+2.;
  t->which_part=which_part;
  if(on) {
    t->active_state='2';
    t->done_state='1';
  } else {
    t->active_state='1';
    t->done_state='2';
  }
}

Bool TriggerLinedef(CDoomLevel *l,CDoomLinedef *ld,I64 flags,CDoomThing *who) {
  CDoomSector *sector,*head=&l->sectors;
  I64 trig=FALSE;
  if(!ld->special_type) return;
//Push operators on the linedef that called it
  if(ld->back&&ld->special_type(CDoomDoor*)->trigger.u8[0]=='P') {

    ld->back->sector->bumped_into=TRUE;
    trig|=_TriggerLinedef(l,ld->back->sector,ld,flags,who);
  } else
    for(sector=head->next;sector!=head;sector=sector->next) {
      if(sector->tag_number==ld->sector_tag)
        trig|=_TriggerLinedef(l,sector,ld,flags,who);
    }
  if(!ld->activated)
    ld->activated=trig;
  return trig;
}



extern U0 LineAttack(CDoomLevel *l,CDoomThing *self,CDoomThing *target,F64 range,F64 angle,F64 damage);
#include "Collision.HC";
#include "ST.HC";
#include "Player.HC";
#include "Enemy.HC";
#include "Physics.HC";
U0 CheckPowerupPickup(CDoomLevel *l) {
  CDoomThing *t;
  AmmoType *load;
  GunAvail *avail;
  Bool change,new_gun=FALSE;
  CI64Set *things=ThingsInRadius(l,p->x,p->y,p->template->radius);
  I64 picked_up_gun=-1;
  I64 orig,idx;
  U8 *got_msg=NULL;
  for(idx=0;idx!=things->cnt;idx++) {
    t=things->body[idx];
    if(SqrI64(2*t->template->radius)>=SqrI64(p->x-t->x)+SqrI64(p->y-t->y)) {
      switch(t->template->type) {
	  case 2006: //BFG
	    new_gun=!p->arsenal[7].available;
	    p->arsenal[7].available=TRUE;
	    picked_up_gun=7;
	    got_msg="You got the BFG9000!  Oh, yes.";
cell:
	    load=p->arsenal[6].load;
	    orig=load->ammo;
	    if(l->skill==0||l->skill==5)
	      load->ammo+=40;
	    else
	      load->ammo+=20;
	    load->ammo=ClampI64(load->ammo,0,maxCells);
	    if(load->ammo!=orig||new_gun) {
rem:
	      if(got_msg)
		ST_Message(p,got_msg);
	      p->pickup_amt+=6;
	      if(t->template->flags&TF_ARTIFACT)
	        l->stats.have_items++;
	      ThingDel(l,t);
	    }
	    break;
	  case 2002: //Chaingun
	    got_msg="You got the chaingun!";
	    new_gun=!p->arsenal[3].available;
	    load=p->arsenal[3].load;
	    p->arsenal[3].available=TRUE;
	    picked_up_gun=3;
	    orig=load->ammo;
	    if(l->skill==0||l->skill==5)
	      load->ammo+=40;
	    else
	      load->ammo+=20;
	    load->ammo=ClampI64(load->ammo,0,maxBullets);
	    if(load->ammo!=orig||new_gun) 
	      goto rem;
	    break;
	  case 2005: //Chainsaw
	    got_msg="A chainsaw!  Find some meat!";
	    new_gun=!p->arsenal[5].available;
	    picked_up_gun=5;
	    p->arsenal[5].available=TRUE;
	    if(new_gun)
	      goto rem;
	  case 2004: //Plasma gun
	    got_msg="You got the plasma gun!";
	    new_gun=!p->arsenal[6].available;
	    picked_up_gun=6;
	    load=p->arsenal[6].load;
	    p->arsenal[6].available=TRUE;
	    goto cell;
	  case 2003: //Rocket luancher
	    got_msg="You got the rocket launcher!";
	    picked_up_gun=4;
	    new_gun=!p->arsenal[4].available;
	    load=p->arsenal[4].load;
	    p->arsenal[4].available=TRUE;
	    orig=load->ammo;
	    if(l->skill==0||l->skill==5)
	      load->ammo+=2;
	    else
	      load->ammo+=1;
	    load->ammo=ClampI64(load->ammo,0,maxRockets);
	    if(load->ammo!=orig||new_gun) 
	      goto rem;
	    break;
	  case 2001: //Shutgun
	    picked_up_gun=2;
	    got_msg="You got the shotgun!";
	    new_gun=!p->arsenal[2].available;
	    load=p->arsenal[2].load;
	    p->arsenal[2].available=TRUE;
	    orig=load->ammo;
	    if(l->skill==0||l->skill==5)
	      load->ammo+=8;
	    else
	      load->ammo+=4;
	    load->ammo=ClampI64(load->ammo,0,maxBullets);
	    if(load->ammo!=orig||new_gun)
	      goto rem;
	    break;
	  case 2008: //4 shells
	    got_msg="Picked up 4 shotgun shells.";
	    load=p->arsenal[2].load;
	    orig=load->ammo;
	    load->ammo+=4;
	    load->ammo=ClampI64(load->ammo,0,maxShells);
	    if(load->ammo!=orig) 
	      goto rem;
	    break;
	  case 2048: //Box of bullets
	    load=p->arsenal[1].load;
	    got_msg="Picked up a box of bullets.";
	    orig=load->ammo;
	    if(l->skill==0||l->skill==5)
	      load->ammo+=100;
	    else
	      load->ammo+=50;
	    load->ammo=ClampI64(load->ammo,0,maxBullets);
	    if(load->ammo!=orig)
	      goto rem;
	    break;
	  case 2046: //Box of rockets
	    got_msg="Picked up a box of rockets.";
	    load=p->arsenal[4].load;
	    orig=load->ammo;
	    if(l->skill==0||l->skill==5)
	      load->ammo+=10;
	    else
	      load->ammo+=5;
	    load->ammo=ClampI64(load->ammo,0,maxRockets);
	    if(load->ammo!=orig)
	      goto rem;
	    break;
	  case 2049: //Box of shotfgu
 	    got_msg="Picked up a box of shotgun shells.";
	    load=p->arsenal[2].load;
	    orig=load->ammo;
	    if(l->skill==0||l->skill==5)
	      load->ammo+=40;
	    else
	      load->ammo+=20;
	    load->ammo=ClampI64(load->ammo,0,maxRockets);
	    if(load->ammo!=orig)
	      goto rem;
	    break;
	  case 2007: //clip
	    got_msg="Picked up a clip.";
	    load=p->arsenal[1].load;
	    orig=load->ammo;
	    if(l->skill==0||l->skill==5)
	      load->ammo+=20;
	    else
	      load->ammo+=10;
	    load->ammo=ClampI64(load->ammo,0,maxBullets);
	    if(load->ammo!=orig) 
	      goto rem;
	    break;
	  case 2047: //Energy cell
	    got_msg="Picked up an energy cell.";
	    goto cell;
	  case 17: //Energy cell pack
	    got_msg="Picked up an energy cell pack.";
	    load=p->arsenal[6].load;
	    orig=load->ammo;
	    load->ammo+=20;
	    load->ammo=ClampI64(load->ammo,0,maxCells);
	    if(load->ammo!=orig)
	      goto rem;
	    break;
	  case 2010: //Rocket
	    got_msg="Picked up a rocket.";
	    load=p->arsenal[4].load;
	    orig=load->ammo;
	    load->ammo+=1;
	    load->ammo=ClampI64(load->ammo,0,maxRockets);
	    if(load->ammo!=orig)
	      goto rem;
	    break;
	  case 2045:
	    p->light_goggles_time=120*30;
	    got_msg="Light Amplification Visor";
	    goto rem;
          case 2026: //Computer map
	    got_msg="Computer Area Map";
	    l->has_map=TRUE;
	    goto rem;
	  case 8: //Backpack
	    if(!p->has_backpack) {
              p->has_backpack=TRUE;
	      maxBullets=400;
	      maxShells=200;
	      maxRockets=100;
	      maxCells=600;
	    }
	    //Poo poo cells
	    load=p->arsenal[6].load;
	    load->ammo=ClampI64(load->ammo+20,0,maxCells);
	    //4 Shothun shells
	    load->ammo=ClampI64(load->ammo,0,maxCells);
	    load=p->arsenal[2].load;
	    load->ammo=ClampI64(load->ammo+4,0,maxShells);
	    //10 bullets
	    load=p->arsenal[1].load;
	    load->ammo=ClampI64(load->ammo+10,0,maxBullets);
	    //1 rocket
	    load=p->arsenal[4].load;
	    load->ammo=ClampI64(load->ammo+1,0,maxRockets);
	    got_msg="Picked up a backpack full of ammo!";
	    goto rem;
	    //Yeah homie,we bout to get some power ups
	  case 2015:
	    got_msg="Picked up an armor bonus.";
	    orig=p->armor;
	    p->armor=ClampI64(p->armor+1,0,200);
	    if(orig!=p->armor)
	      goto rem;
	    break;
	  case 2014:
	    got_msg="Picked up an health bonus.";
	    orig=p->health;
	    p->health=ClampI64(p->health+1,0,200);
	    if(orig!=p->health)
	      goto rem;
	    break;
	  case 2024:
	    p->invisible_time=60*30;
	    got_msg="Partial Invisibility";
	    goto rem;
	  case 2022:
	    //Invincible
	    p->invincible_time=30*30;
	    got_msg="Invulnerability!";
	    goto rem;
	  case 83: //Megasphere
	    got_msg="MegaSphere!";
	    p->health=200;
	    p->armor=200;
	    goto rem;
	  case 2013: //Supercharge
	    got_msg="Supercharge!";
	    orig=p->health;
	    p->health=ClampI64(p->health+100,0,200);
	    if(orig!=p->health)
	      goto rem;
	    break;
	  case 2018: //de-facto Armor
	    got_msg="Picked up the armor.";
	    if(p->armor>=100)
	      break;
	    p->armor=100.;
	    goto rem;
	  case 2019: //megarmor
	    got_msg="Picked up the MegaArmor!";
	    if(p->armor>=200)
	      break;
	    p->armor=200.;
	    goto rem;
	  case 2012:
	    got_msg="Picked up a medikit.";
	    if(p->health>=100)
	      break;
	    p->health=ClampI64(p->health+25,0,100);
	    goto rem;
	  case 2011:
	    got_msg="Picked up a stimpack.";
	    if(p->health>=100)
	      break;
	    p->health=ClampI64(p->health+10,0,100);
	    goto rem;
	  case 2023:
	    got_msg="Berserk!";
	    p->bezerk_time=30*30; //assumes 30 ticks a motherfuckin second
	    if(p->health<100.)
	      p->health=100.;
            SwapWeapon(p,0);
	    goto rem;
	  case 2025: //Radiuation suit
	    got_msg="Radiation Shielding Suit";
	    p->rad_suit_time=60*30; //assumes 30 ticks a motherfuckin second
	    goto rem;
//Keys
	  case 5: //BLue keycard
	    got_msg="Picked up a blue keycard.";
	    l->has_blue_key=TRUE;
	    goto rem;
	  case 40: //BLue skull key
	    got_msg="Picked up a blue skull key.";
	    l->has_blue_key=TRUE;
	    goto rem;
	  case 38: //Red skull key
	    got_msg="Picked up a red skull key.";
	    l->has_red_key=TRUE;
	    goto rem;
	  case 13: //Red keycard
	    got_msg="Picked up a red keycard.";
	    l->has_red_key=TRUE;
	    goto rem;
	  case 39: //Yellow skull key
	    got_msg="Picked up a yellow skull key.";
	    l->has_yellow_key=TRUE;
	    goto rem;
	  case 6: //Yellow keycard
	    got_msg="Picked up a yellow keycard.";
	    l->has_yellow_key=TRUE;
	    goto rem;
      }
    }
  }
  if(picked_up_gun!=-1&&new_gun)
    SwapWeapon(p,picked_up_gun);
  I64SetDel(things);
}

Bool PlayerAttack(F64 shots_per_minute,F64 min_damage,F64 max_damage,F64 range,U64 rocket_type=0) {
  F64 cooldown=60./shots_per_minute,oa;
  p->weapon_cooldown=cooldown;
  if(Server_tS<p->last_attack+p->weapon_cooldown) return FALSE;
  if(!p->weapon_state) {
    p->weapon_state=1;
  } else
    p->weapon_state=2;
  p->last_attack=Server_tS;
  F64 angle=p->angle,r;
  F64 damage=Rand*(max_damage-min_damage)+min_damage;
  I64 idx;
//Use mouse angle as real angle,then restore
  oa=p->angle;
//Views in TOOM are reversed
  p->angle+=((GR_WIDTH-cursor_x)-GR_WIDTH/2)/ToF64(GR_WIDTH/2)*cam.fov/2;
  angle=p->angle;
  CDoomThing *target=PlayerPickTarget(l,p);
  if(target)
    angle=FArg(target->x-p->x,target->y-p->y);
//Account for mouse aim
  if(!rocket_type) {
    if(weaponIndex==2) {//Shotgun
      for(idx=0;idx!=7;idx++) {
	if(!idx)
	  r=0;
	else
          r=(Rand-.5); 
        LineAttack(l,p,target,range,angle+r*9.8*pi/360.,damage);
      }
    } else
//0,5 is fist/chainsaw
      LineAttack(l,p,target,range,angle,damage,weaponIndex==0||weaponIndex==5);
  } else {
    SpawnMissile(l,p,target,rocket_type);
  }
  if(weaponIndex!=0&&weaponIndex!=5)
    p->muzzle_flash_end_tS=Server_tS+1/10.;
  p->angle=oa;
  return TRUE;
}

U0 UpdateLevel(CDoomLevel *l) {
  CDoomSector *sector,*head=&l->sectors;
  UpdateThinkers(l);
  Physics(l);
  CheckPowerupPickup(l);
  if(p&&p->rad_suit_time)
    p->rad_suit_time=Clamp(p->rad_suit_time-1/30.,0.,60.);
  if(p&&p->bezerk_time)
    p->bezerk_time=Clamp(p->bezerk_time-1/30.,0.,60.);
  if(p&&p->light_goggles_time)
    p->light_goggles_time=Clamp(p->light_goggles_time-1/30.,0.,60.);
  if(p&&p->invincible_time)
    p->invincible_time=Clamp(p->invincible_time-1/30.,0.,30.);
  if(p&&p->invisible_time) {
    p->flags|=MF_SHADOW;
    p->invisible_time=Clamp(p->invisible_time-1/30.,0.,60.);
  } else if(p) {
    p->flags&=~MF_SHADOW;
  }
}



U0 PressAWall(CDoomLevel *l,CD2 *where,F64 angle,F64 height) {
  CD2 dummy;
  F64 floor,floor2,ceil,ceil2;
  I64 which_texture=0,idx,activated;
  Bool repeat=FALSE,passed=FALSE,is_on;
  U64 trigger;
  CDoomLinedef *ld;
  CDoomSidedef *sd;
  Vector *ldv;
  dummy.x=where->x;
  dummy.y=where->y;
  ld=MoveInLevel(l,&dummy,angle,64,1,1,height,COLLISF_PUSH_WALL);
  if(ld) {
    if(ld->front^^ld->back) {
      which_texture=1;
      if(ld->front) sd=ld->front;
      else if(ld->back) sd=ld->back;
    } else {
      ldv=CreateVector(2);
      ldv->data[0]=ld->end->x-ld->start->x;
      ldv->data[1]=ld->end->y-ld->start->y;
      dummy.x=where->x-ld->start->x;
      dummy.y=where->y-ld->start->y;
      if(IsFrontSideOfVector2D(ldv,&dummy)) {
        sd=ld->front;
        floor=ld->front->sector->floor_height;
        floor2=FloorRaise(ld,ld->front->sector);
        ceil=ld->front->sector->ceil_height;
        ceil2=CeilDepress(ld,ld->front->sector);
      } else {
        sd=ld->back;
        floor=ld->back->sector->floor_height;
        floor2=FloorRaise(ld,ld->back->sector);
        ceil=ld->back->sector->ceil_height;
        ceil2=CeilDepress(ld,ld->back->sector);
      }
      if(height<floor2) which_texture=0;
      else if(floor2<=height<=ceil2) which_texture=1;
      else which_texture=2;
      DestroyVector(ldv);
    }    
    for(idx=0;idx!=2;idx++)
      switch(which_texture) {
        case 2:

	  if(ld->special_type&&AltSwitchTexture(sd->upper_texture[0],idx,&is_on)) {
pass:
	    if(ld->special_type->type=='Door')
	      trigger=ld->special_type(CDoomDoor*)->trigger;
	    else if(ld->special_type->type=='Ceil')
	      trigger=ld->special_type(CDoomCeil*)->trigger;
	    else if(ld->special_type->type=='Floor')
	      trigger=ld->special_type(CDoomFloor*)->trigger;
	    else if(ld->special_type->type=='Lift')
	      trigger=ld->special_type(CDoomLift*)->trigger;
	    if(trigger.u8[1]=='P')
	      activated=TriggerLinedef(l,ld,WACTIVATE_PUSH,p);
	    else
	      activated=TriggerLinedef(l,ld,WACTIVATE_SWITCH,p);
	    passed=TRUE;
	    if(activated) {
	      Spawn(&PlaySoundTask,"SWTCHN","snd",0,Fs);
	      AddButtonThinker(l,sd,which_texture,trigger.u8[1]!='1',is_on);
	    }
	  }
	  break;
        case 1:
	  if(ld->special_type&&AltSwitchTexture(sd->middle_texture[0],idx))
	    goto pass;
	  break;
        case 0:
	  if(ld->special_type&&AltSwitchTexture(sd->lower_texture[0],idx))
	    goto pass;
	  break;
      }
  }
  if(!passed&&ld)
    TriggerLinedef(l,ld,WACTIVATE_SWITCH,p);
}


U0 AnimateTask(I64)
{
//Nroots hack,kiling this task will kill the child task
  Spawn(&ST_UpdateFacesTask,NULL,NULL,,Fs);
  while(TRUE)
    {   
    AnimateFire(p);
    Refresh;  
  }
}


U0 UpdateCameraFromPlayer(CDoomCamera *cam,CDoomPlayer *p) {
  F64 angle;
  CDoomSector *s=GetSectorForCoord(l,p->x,p->y);
//if were are dead,sink the camera
  if(p->health<=0.) {
    cam->h=Clamp(cam->h-12*1/30.,p->height+8,p->height+32);
  } else 
    cam->h=p->height+41;
  if(s) cam->h=Clamp(cam->h,s->floor_height+1.,s->ceil_height-4.);
  cam->x=p->x;
  cam->y=p->y;
  if(p->stare_at&&p->health<=0.) {
//We are dead(?) and looking at who killed us
    angle=FArg(p->stare_at->x-cam->x,p->stare_at->y-cam->y);
    cam->angle=(cam->angle+angle)/2;
  } else {
    cam->angle=p->angle;
  }
}



WinMax;
U0 InitLevel(CDoomLevel *l) {
  CDoomThing *t,*head=&l->things,*next;
  CDoomSector *s;
  for(t=head->next;t!=head;t=next) {
    next=t->next;
    if(p!=t)
      switch(t->template->type) {
//Players
        case 1:
        case 2:
        case 3:
        case 4:
	  ThingDel(l,t);
	  break;
        default:
      }
    if(s=GetSectorForCoord(l,t->x,t->y)) {
//Non-monster floating things hang from the ceiling
      if(t->template->flags&TF_FLOATING&&!(t->template->flags&TF_SHOOTABLE)) {
        t->height=s->ceil_height-t->template->height;
      } else
        t->height=s->floor_height;
    }
  }
  InitMonsters(l);
}
U0 FreeLevel(CDoomLevel *l) {
  CDoomSector *s,*head=&l->sectors;
  I64 idx=l->block_map_cols*l->block_map_rows;
  while(--idx>=0) {
    I64SetDel(l->block_map_things[idx]);
  }
  for(s=head->next;s!=head;s=s->next) {
    I64SetDel(s->things);
  }
  QueDel(&l->things);
  QueDel(&l->sidedefs);
  QueDel(&l->subsectors);
  QueDel(&l->thinkers);
  Free(l->segs);
  QueDel(&l->sectors);
  QueDel(&l->sidedefs);
  Free(l->vertices);
  QueDel(&l->linedefs);
  Free(l->block_map_data);
  Free(l->action_linedefs);
  Free(l);
}


extern U0 SaveGame(U8 *filename,U8 *title="Quick");
extern U0 LoadGame(U8 *filename);
#include "Automap.HC";
#include "Menu.HC";
U8 *NextLevel(U8 *nm,Bool special=FALSE) {
//Episode 1
  if(!StrCmp(nm,"E1M1")) 
    return "E1M2";
  else if(!StrCmp(nm,"E1M2")) 
    return "E1M3";
  else if(!StrCmp(nm,"E1M3"))  {
    if(special) return "E1M9";
    return "E1M4";
  }
  else if(!StrCmp(nm,"E1M4"))
    return "E1M5";
  else if(!StrCmp(nm,"E1M5")) 
    return "E1M6";
  else if(!StrCmp(nm,"E1M6")) 
    return "E1M7";
  else if(!StrCmp(nm,"E1M7")) 
    return "E1M8";
  else if(!StrCmp(nm,"E1M9")) 
    return "E1M5";
//Episode 2
  if(!StrCmp(nm,"E2M1")) 
    return "E2M2";
  else if(!StrCmp(nm,"E2M2")) 
    return "E2M3";
  else if(!StrCmp(nm,"E2M3")) 
    return "E2M4";
  else if(!StrCmp(nm,"E2M4"))
    return "E2M5";
  else if(!StrCmp(nm,"E2M5"))  {
    if(special) return "E2M9";
    return "E2M6";
  } else if(!StrCmp(nm,"E2M6")) 
    return "E2M7";
  else if(!StrCmp(nm,"E2M7")) 
    return "E2M8";
  else if(!StrCmp(nm,"E2M9")) 
    return "E2M6";
//Episode 3
  if(!StrCmp(nm,"E3M1")) 
    return "E3M2";
  else if(!StrCmp(nm,"E3M2")) 
    return "E3M3";
  else if(!StrCmp(nm,"E3M3")) 
    return "E3M4";
  else if(!StrCmp(nm,"E3M4"))
    return "E3M5";
  else if(!StrCmp(nm,"E3M5"))
    return "E3M6";
  else if(!StrCmp(nm,"E3M6")) { 
    if(special) return "E3M9";
    return "E3M7";
  } else if(!StrCmp(nm,"E3M7")) 
    return "E3M8";
  else if(!StrCmp(nm,"E3M9")) 
    return "E3M7";
//Episode 4
  if(!StrCmp(nm,"E4M1")) 
    return "E4M2";
  else if(!StrCmp(nm,"E4M2")) {
    if(special) return "E4M9";
    return "E4M3";
  } else if(!StrCmp(nm,"E4M3")) 
    return "E4M4";
  else if(!StrCmp(nm,"E4M4"))
    return "E4M5";
  else if(!StrCmp(nm,"E4M5"))
    return "E4M6";
  else if(!StrCmp(nm,"E4M6"))
    return "E4M7";
  else if(!StrCmp(nm,"E4M7")) 
    return "E4M8";
  else if(!StrCmp(nm,"E4M9")) 
    return "E4M3";
  //Intermission
  return NULL;
}
#include"Finale.HC";
U0 PlayLevel(Bool init=TRUE) { 
  WinBorder;
  WinMax;
  DocClear;
  Bool transition=FALSE;
  CDoomThing *t,*head;
  U8 *next_lvl;
  CDC *new,*old;
  if(music_task)
    Kill(music_task,FALSE);
  music_task=Spawn(&SongTaskDOOM,l->map_name[3]-'1',"Song",0,Fs);
ent:;
  CDoomLevel *l2;
  if(init) {
    if(!transition) {
      p=PlayerNew(l);
    } else  {
      transition=FALSE;
      head=&l->things;
      screen_melt=TRUE;
      for(t=head->next;t!=head;t=t->next) {
//https://doomwiki.org/wiki/Thing_types#Other
        if(t->thing_type==1) {
	  p->x=t->x;
	  p->y=t->y;
	  p->angle=t->angle;
	  QueIns(p,&l->things);
	  break;
        }
      }
    }
    PlayerMove(l,p,0);   
    InitLevel(l);
  }
  if(screen_melt) {
    screen_melt=FALSE;
    Server_tS; //Update server time
    paused=TRUE;
    old=DCCopy(gr.dc2);
    new=DCCopy(gr.dc2);
    UpdateCameraFromPlayer(&cam,p);
    DrawDoomWorld(&cam,l,new);
    ScreenMelt(gr.dc,new,old);
    DCDel(old),DCDel(new);
    Unpause;
  }
//Reset the animation task for newly loaded player
  if(Fs->animate_task)
    Kill(Fs->animate_task,FALSE);
  Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
//Return to parent instance  of PlayLevel(if recursivly called)
  //But be sure to initailize the level and player
  if(in_level) return;
  in_level=TRUE;
  I64 a,b;
  U64 mr;
  Unpause;
  while(!l->ended) {
    if(screen_melt) {
      screen_melt=FALSE;
      Server_tS; //Update server time
      paused=TRUE;
      old=DCCopy(gr.dc2);
      new=DCCopy(gr.dc2);
      UpdateCameraFromPlayer(&cam,p);
      DrawDoomWorld(&cam,l,new);
      ScreenMelt(doom_scrn,new,old);
      DCDel(old),DCDel(new);
      Unpause;
    }
    UpdateCameraFromPlayer(&cam,p);
    DrawDoomWorld(&cam,l,doom_scrn);

    if(!paused) {
      AutomapInteract;

      if(am_state.active)
        DrawAutomap(doom_scrn,l);
      ST_Start(p);

      //mouse camera pan.
      cursor_x=ms.pos.x;
      if(cursor_tx!=cursor_x)
      {
        if(cursor_x<1)
	{
	  cursor_x=1;
        }
        cursor_x=ms.pos.x;   
        cursor_tx = cursor_x;
        weapons.x_off=cursor_x-GR_WIDTH/2;
      }

      //weapon switch.
      cursor_z=ms.pos.z;
      if(cursor_tz!=cursor_z)
      {
//cursor_z my be greater than 2,so check with previous value for difference
        if(cursor_z-cursor_tz<0)
	{
	  AddWeaponIndex(TRUE);
        }
        else
        { 
	  AddWeaponIndex(FALSE); 
        }   
        cursor_tz = cursor_z;
      }


#define SCRN_MARGIN 200
      #define SCRN_TURN_RATE (pi/1.5/30.)
      if(SCRN_MARGIN>cursor_x) {
        p->angle+=Lerp((SCRN_MARGIN-cursor_x)/ToF64(SCRN_MARGIN),0,SCRN_TURN_RATE);
      } else if(GR_WIDTH-SCRN_MARGIN<cursor_x) {
        p->angle-=Lerp((cursor_x-(GR_WIDTH-SCRN_MARGIN))/ToF64(SCRN_MARGIN),0,SCRN_TURN_RATE);
      }


      if(p->health>0.) {
        if(Bt(kbd.down_bitmap,SC_CURSOR_UP)||Bt(kbd.down_bitmap,Char2ScanCode('w'))) {
	  p->running=Bt(kbd.down_bitmap,SC_SHIFT);
	  PlayerMove(l,p,1);
	  UpdateCameraFromPlayer(&cam,p);
        }
        if(Bt(kbd.down_bitmap,SC_CURSOR_DOWN)||Bt(kbd.down_bitmap,Char2ScanCode('s'))) {
	  p->running=Bt(kbd.down_bitmap,SC_SHIFT);
	  PlayerMove(l,p,-1);
	  UpdateCameraFromPlayer(&cam,p);
        }
        if(Bt(kbd.down_bitmap,Char2ScanCode('a'))||Bt(kbd.down_bitmap,SC_CURSOR_LEFT)) {
	  p->running=Bt(kbd.down_bitmap,SC_SHIFT);
	  PlayerMove(l,p,1,pi/2);
	  UpdateCameraFromPlayer(&cam,p);
        }
        if(Bt(kbd.down_bitmap,Char2ScanCode('d'))||Bt(kbd.down_bitmap,SC_CURSOR_RIGHT)) {
	  p->running=Bt(kbd.down_bitmap,SC_SHIFT);
	  PlayerMove(l,p,1,-pi/2);
	  UpdateCameraFromPlayer(&cam,p);
        }
        if(ms.lb) {
	  ST_Fire(p);
        } else if(weaponIndex==6&&(WEAPON_FIRE==p->weapon_state||WEAPON_REFIRE==p->weapon_state)){ //Account for weapon pause on plasma gun
	  p->last_attack=Server_tS;
	  p->weapon_state=WEAPON_PAUSE;
	  p->weapon_cooldown=1/3.;
        }
        if(Server_tS>p->last_attack+p->weapon_cooldown) {
	  p->weapon_state=WEAPON_IDLE;
        }
        if(p->weapon_state==WEAPON_IDLE) {
	  if(Bt(kbd.down_bitmap,Char2ScanCode('1'))) {
	    SwapWeapon(p,1);
	  }
	  if(Bt(kbd.down_bitmap,Char2ScanCode('2'))) {
	    SwapWeapon(p,2);
	  }
	  if(Bt(kbd.down_bitmap,Char2ScanCode('3'))) {
	    SwapWeapon(p,3);
	  }
	  if(Bt(kbd.down_bitmap,Char2ScanCode('4'))) {
	    SwapWeapon(p,4);
	  }
	  if(Bt(kbd.down_bitmap,Char2ScanCode('5'))) {
	    SwapWeapon(p,5);
	  }
	  if(Bt(kbd.down_bitmap,Char2ScanCode('6'))) {
	    SwapWeapon(p,6);
	  }
	  if(Bt(kbd.down_bitmap,Char2ScanCode('7'))) {
	    SwapWeapon(p,7);
	  }
/*	  if(Bt(kbd.down_bitmap,Char2ScanCode('8'))) {
	    SwapWeapon(p,8);
	  }*/
	  if(Bt(kbd.down_bitmap,Char2ScanCode('0'))) {
	    SwapWeapon(p,0);
	  }
        }
        if(Bt(kbd.down_bitmap,Char2ScanCode(' ')&0xff)) {
	  PressAWall(l,&p->x,p->angle,p->height);
        }
      } 
//This accounts for key-press delay
      while((mr=ScanMsg(&a,&b))!=MSG_NULL) {
        if(mr==MSG_KEY_DOWN&&a==CH_ESC&&Bt(kbd.down_bitmap,Char2ScanCode(CH_ESC))) {
	  paused=TRUE;
	  Refresh;
	  FlushMsgs; //Flush Esc msg
	  break;
        }
	if(p->health<=0.) {
	  if(mr==MSG_MS_L_DOWN) {
	    goto play_again;
	  } else if(mr==MSG_KEY_DOWN&&a!=CH_ESC) {
play_again:
	    screen_melt=TRUE;
	    transition=FALSE;
	    next_lvl=LoadWadLevel(l->map_name,l->skill);
	    FreeLevel(l);
	    l=next_lvl;
	    PlayLevel(TRUE);
          }
        }
      }
    } else {
      mr=MainMenu;
      if(!mr) {
        Unpause;
      }
    }

    if(!paused) {
      UpdateLevel(l);
    }
    GrBlot(,0,0,doom_scrn);
    Refresh;
  }
ret:
  p->weapon_state=0;
  if(l->ended) Intermission(l,l->map_name[1]-'1',l->map_name[3]-'1');
  DCFill;
//Dont free the player,we will transfer him across the levels mofo
  transition=TRUE;
  QueRem(p);
//
  next_lvl=NextLevel(l->map_name,l->ended_special);
  if(!next_lvl) {
//EXM9
    Finale(doom_scrn,l->map_name[1]-'0');
    goto fin_level;
  }
  l2=LoadWadLevel(next_lvl,l->skill);  
 if(music_task)
    Kill(music_task,FALSE);
  music_task=Spawn(&SongTaskDOOM,l2->map_name[3]-'1',"Song",0,Fs);
  FreeLevel(l);
  l=NULL;
  l=l2;
  in_level=FALSE;
  init=TRUE;
  goto ent;
fin_level:
  p->weapon_state=0;
  in_level=FALSE;
  return;
}
U0 CrushThinker(CDoomLevel *l,CCrushThinker *t) {
  F64 tar_dst;
  CDoomSector *s=t->s;
  CrushThingsInSector(l,s);
  CDoomThing **crushed=GetCrushedThingsInSector(l,s),*T;
  I64 idx;
//Maybe it was stopped
  if(!s->cur_action_linedef) {
    QueRem(t);
    Free(t);
    Free(crushed);
    return;
  }
  if(t->going_up) {
    tar_dst=s->base_ceil_height;
    s->ceil_height+=t->base_speed;
    if(s->ceil_height>=tar_dst) {
      s->ceil_height=tar_dst;
      t->going_up=FALSE;
    }
  } else {
    tar_dst=s->base_floor_height+8;
//Slow crushers will slow down by /8
    if(*crushed&&t->base_speed<=DOOR_SPEED_SLOW) {
      s->ceil_height-=t->base_speed;
    } else
      s->ceil_height-=t->base_speed;
    if(s->ceil_height<=tar_dst) {
      s->ceil_height=tar_dst;
      t->going_up=TRUE;
    }
  }
//About 4 times damages a second
  if(ToI64(tS*32)&0x7==0) {
    for(idx=0;T=crushed[idx];idx++) {
      if(T->health>0.) {
        DamageMob(l,T,NULL,5);
        SpawnBloodPuff(l,&T->x,T->height,5);
      }
    }
  }
  Free(crushed);
  s->door_height_offset=s->ceil_height-s->base_floor_height;  
}

U0 AddCrushThinker(CDoomLevel *l,CDoomSector *s,CDoomLinedef *ld) {
  if(s->cur_action_linedef) return;
  CCrushThinker *t=AddThinker(l,&CrushThinker,"CCrushThinker");
  s->cur_action_linedef=ld;
  CDoomCrusher *c=ld->special_type);
  t->base_speed=c->speed;
  t->s=s;
  t->going_up=FALSE;
}


CDoomThing **GetCrushedThingsInSector(CDoomLevel *l,CDoomSector *s) {
  I64 cnt=0,idx;
  F64 gap=s->ceil_height-s->floor_height;
  CDoomThing *cur,**ret=NULL;;
  CI64Set *in_sector=s->things;
again:;
  for(idx=0;idx!=in_sector->cnt;idx++) {
    cur=in_sector->body[idx];
    if((cur->height-s->floor_height)+cur->template->height>gap) {
have:
      if(!ret)
        cnt++;
      else
        ret[cnt++]=cur;
    }
  }
  if(ret) return ret;
  if(!cnt) return CAlloc(8);
  ret=CAlloc((1+cnt)*8);
  cnt=0;
  goto again;
}
U0 ThingDel(CDoomLevel *l,CDoomThing *t) {
  RemovePosDataForThing(l,t);
  QueRem(t);
  Free(t);
}
#include "Save.HC";
U64 r;
CDC *title=GetGrLump("TITLEPIC");
while(TRUE) {
  TallBlot(doom_scrn,0,0,GR_HEIGHT,title);
  r=MainMenu;
  GrBlot(,0,0,doom_scrn);
  Refresh;
  if(!r) {
    DCFill;
    break;
  }
}
#endif
	