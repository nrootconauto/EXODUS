#ifndef PHYSICS
#define PHYSICS "P Pushin" 
#define FRICTION .90625
Bool IsCrushed(CDoomSector *s,CDoomThing *t) {
  F64 gap=s->ceil_height-s->floor_height;
  if(gap<=t->template->height)
    return TRUE;
  return FALSE;
}
//Accoutns for momentum and falling
U0 PhysicsOnThing(CDoomLevel *l,CDoomThing *thing) {
  CD2 at;
  CDoomLinedef *ld=NULL;
  CDoomSector *sec;
  CDoomActionSector *special;
  CDoomThing *target=NULL;
  CMonsterThinker *thinker=thing->thinker;
  CDoomMonsterTemplate *mt;
  F64 angle=FArg(thing->momx+thing->momx2,thing->momy+thing->momy2),damage;
  F64 mom_t=Sqrt(Sqr(thing->momx+thing->momx2)+Sqr(thing->momy+thing->momy2));
  I64 more_flags=0;
  if(thing->momx2||thing->momy2) { //Move AI momentum between frames
    thing->angle=FArg(thing->momx,thing->momy2);
    more_flags=COLLISF_MONSTER;
    if(!(thing->flags&TF_FLOATING))
      more_flags|=COLLISF_NO_DROP;
    if(mom_t>=1.)
      if(ld=MoveThingFinal(l,thing,angle,mom_t,more_flags|COLLISF_SLIDE|COLLISF_NO_HIT_THING|COLLISF_ADJUST_FOR_RADIUS,,thing,&target)) {
        if(target&&thing->flags&MF_SKULL_ATTACK) {
	  thing->flags&=~MF_SKULL_ATTACK;
	  DamageMob(l,target,thing,(23-3)*Rand+3);
        }
      }
  }
//Monster thikner && hit wall
  if(thinker&&thing->flags&TF_MONSTER&&ld)
    NewChaseDir(l,thinker);
  if(thinker&&thing->flags&TF_MONSTER) {
    mt=thing->template;
    if(mt!=doom_thing_types[87]) //Ignore Cube spawner
      if(FramePtr(mt->see_state)==thinker->state) {
        --thinker->steps_to_walk;
        if(thinker->steps_to_walk<=0) {
//In Enemy.HC,We set time to I16_MAX if STATE_UNTIL_DONE_WALKING
	  thinker->steps_to_walk=0;
	  thinker->state_start_tS=-I16_MAX;
        }
      }
  }
  if(ld&&more_flags&COLLISF_MONSTER) {
    ClientTriggerLinedef(l,ld,WACTIVATE_MONSTER|WACTIVATE_PUSH,thing);
  }
  thing->momx*=FRICTION;
  thing->momy*=FRICTION;
  if(thing->momy<1.)
    thing->momy=0.;
  if(thing->momx<1.)
    thing->momx=0.;
//Dont make props(?) adjst based on radius size
  if(thing->template->flags&TF_MONSTER||IsPlayer(thing)) {
    sec=GetHighestSectorInRadius(l,thing->x,thing->y,thing->template->radius);
  } else
    sec=GetSectorForCoord(l,thing->x,thing->y);
//Gravity
  if(!(thing->flags&TF_FLOATING)) {
    if(sec) {
      if(thing->height>sec->floor_height) {
        thing->height+=thing->momz;
        thing->momz-=GRAVITY;
      } else if(thing->height>sec->ceil_height) {
        thing->height=sec->ceil_height-thing->template->height;
//Hit the ceiling so bump down
        thing->momz=-GRAVITY;
      }
      thing->height=Clamp(thing->height,sec->floor_height,sec->ceil_height);
      if(thing->height==sec->floor_height) {
        if(IsPlayer(thing)&&!thing(CDoomPlayer*)->rad_suit_time) {
//Damaging fllor
	  damage=0;
	  switch(sec->special_type) {
	    case 7:
	      damage=5;
	      break;
	    case 5:
	      damage=10;
	      break;
	    case 16:
	      damage=20;
	      break;
	    case 4:
	      damage=20;
	      break;
	    case 11:
	      damage=20;
	      break;
	  }
	  if(!(ToI64(tS*32)&0x1f)&&damage) {
	    DamageMob(l,p,NULL,damage);
//E1M8 hell exit
	    if(sec->special_type==11&&p->health<11) {
	      l->ended=TRUE;
	    }
	  } 
        }
        thing->momz=0;
      }
    }
  }
}
U0 EchoSound(CDoomLevel *l,CDoomThing *thing,CDoomSector *s,F64 len) {
  I64 cnt=s->linedef_cnt,i;
  CDoomLinedef *ld;
  CDoomSector *other;
  F64 tdist;
  if(s->sound_check) return;
  s->noise_thing=thing;
  s->sound_check=TRUE;
  for(i=0;i!=cnt;i++) {
    ld=s->linedefs[i];
    if(ld->front&&ld->back)
      if(!(ld->flags&WAD_LINEDEFF_BLOCK_SOUND)) {
        if(ld->front->sector==s)
	  other=ld->back->sector;
	else
	  other=ld->front->sector;
	if(other->ceil_height>s->floor_height&&
	  s->ceil_height>other->floor_height) { //Open gap?
	  tdist=DistFromLine(&thing->x,ld->start,ld->end);
	  if(tdist<len) {
	    EchoSound(l,thing,other,len-tdist);
	  }
	}
      }
  }
}
U0 Physics(CDoomLevel *l) {
  CDoomThing *t,*head;
  CDoomSector *s;
  head=&l->sectors;
  for(s=head->next;s!=head;s=s->next) {
//Reset the paused awaiting for checking for monsters in the way
    s->paused=FALSE;
    s->sound_check=FALSE;
  }
  head=&l->things;
  for(t=head->next;t!=head;t=t->next) {
    if(IsPlayer(t)&&t(CDoomPlayer*)->made_a_sound) {
      t(CDoomPlayer*)->made_a_sound=FALSE;
      s=GetSectorForCoord(l,t->x,t->y);
      EchoSound(l,t,s,1024);
    }
    PhysicsOnThing(l,t);
  }
}
#endif
