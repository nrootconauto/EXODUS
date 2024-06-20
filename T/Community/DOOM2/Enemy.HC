//See enemy.c in doom3do
CDoomThingTemplate *imp_fireball;
CDoomThingTemplate *baron_fireball;
CDoomThingTemplate *mancubus_fireball;
CDoomThingTemplate *cacodemon_fireball;
CDoomThingTemplate *rocket;
CDoomThingTemplate *plasma_ball;
CDoomThingTemplate *bfg_ball;
CDoomThingTemplate *bfg_scanner_hit;
CDoomThingTemplate *skel_missile;
CDoomThingTemplate *vile_fire;
CDoomThingTemplate *spawn_cube;
CDoomThingTemplate *brain_explosion;
#define TICK_FPS_SCALE (1/30./3.) //Ticks_per_sec/fps
#define TICK_TIME (1/10.)

#define MISSILE_RANGE (64*32)
#define MELEE_RANGE 70
#define FLOATSPEED 2.
#define GRAVITY 1.5


class CPuffThinker:CDoomThinkerBase {
  CDoomThing *self;
  F64 spawn_time;
};
extern CPuffThinker *SpawnSmokePuff(CDoomLevel *l,CD2 *at,F64 h,F64 attack_range);


//These P pushers are used with FramePtrAdd
class CState {
  F64 time;
  CDoomAnimationFrame *anim_frames;
  U0 (*action)(CDoomLevel *,CDoomThinker *);
  U8 *next_state;
  CState *next_state_cache; //Filled in automatically
  Bool no_repeat;
};
//2 Special times
#define STATE_NO_REPEAT -1.
#define STATE_UNTIL_ANIM_DONE -2.
//See Physics.HC
#define STATE_UNTIL_DONE_WALKING -3.
U0 AddState(U8 *name,F64 ticks,CDoomAnimationFrame *f,U8 *fptr=NULL,U8 *next=NULL) {
  CState *s=CAlloc(sizeof CState);
  if(ticks==STATE_NO_REPEAT) {
    s->time=AnimationTime(f);
    s->no_repeat=TRUE;
  } else if(ticks==STATE_UNTIL_ANIM_DONE)
    s->time=AnimationTime(f);
  else if(ticks==STATE_UNTIL_DONE_WALKING)
    s->time=I16_MAX; //See Physics.HC
  else
    s->time=ticks;
  s->anim_frames=f;
  s->action=fptr;
  s->next_state=next;
  UH(name,s);
  FramePtrAdd(name,s);
}


class CBarrelThinker:CDoomThinkerBase {
  U64 signature;
  CDoomThing *self;
  F64 explode_start_tS; //0 for not started  
};
class CMonsterThinker:CDoomThinkerBase {
  U64 signature;
  CDoomThing *self;
  CDoomThing *parent; //Who shot the missle
  CDoomThing *target;
  F64 last_hit_time; //incoming damage to self
  F64 last_attack_time;
  F64 state_start_tS;
  F64 state_length;
  I64 steps_to_walk,reaction_time;
  F64 attack_time; //time to attack for
  I64 flags;
  CState *state;
  Bool ran_state;
};
U0 RadiusAttack(CDoomLevel *l,CDoomThing *dik,F64 boom) {
  CI64Set *in_rad=ThingsInRadius(l,dik->x,dik->y,boom);
  CDoomThing *cur;
  I64 idx;
  F64 angle,dist;
  for(idx=0;idx!=in_rad->cnt;idx++) {
    cur=in_rad->body[idx];
    dist=ApproxDist(cur->y-dik->y,cur->x-dik->x);
    if(dist<boom) {
      DamageMob(l,cur,dik,boom-dist);
    }
  }
  I64SetDel(in_rad);
}

class CFireThinker:CDoomThinkerBase {
  F64 end_tS;
  CDoomThing *self;
  CDoomThing *vile;
  CDoomThing *target;
};
U0 FireThinker(CDoomLevel *l,CFireThinker *t) {
  CDoomThing *self=t->self,*vile=t->vile,*target=t->target;
  F64 angle,dist;
  if(vile->health<=0.)
   goto done;
  angle=FArg(target->x-vile->x,target->y-vile->y);
  dist=ApproxDist(target->x-vile->x,target->y-vile->y);
  dist=ValidateLineOfSightShot(l,&vile->x,angle,dist,vile->height+16,target->height+16);  
  if(dist<0.) {
    RemovePosDataForThing(l,self);
    self->x=target->x-24*Cos(angle);
    self->y=target->y-24*Sin(angle);
    self->height=target->height;
    InitPosDataForThing(l,self);
  }
  if(t->end_tS<Server_tS) {
    ClientPlaySound("BAREXP");
    RadiusAttack(l,self,70);
done:
    QueRem(t);
    Free(t);
    ThingDel(l,self);
    return;
  }
}
U0 Sound(CMonsterThinker *t,U64 type) {
  if(type=='See')
    switch(t->self->template->type) {
      case 71: //Pain elemental
        ClientPlaySound("PESIT");
	break;
      case 67: //Mancubus
	ClientPlaySound("MANSIT");
	break;
      case 64: //Arhc vile
        ClientPlaySound("VILSIT");
	break;
      case 68:
        ClientPlaySound("BSPSIT");
	break;
      case 16:
	ClientPlaySound("CYBSIT");
        break;
      case 65: //Chain gunner
      case 9: //Shotgunna
      case 3004: //Zombie
        switch(Rand*2.99) {
	  case 0:
	    ClientPlaySound("POSIT1");
	    break;
	  case 1:
	    ClientPlaySound("POSIT2");
	    break;
	  case 2:
	    ClientPlaySound("POSIT3");
        }
        return;
      case 3001: //Imp
        switch(Rand*1.99) {
	  case 0:
	    ClientPlaySound("BGSIT1");
	    break;
	  case 1:
	    ClientPlaySound("BGSIT2");
	    break;
        }
        return;
      case 3002: //Pinky
      case 58: //invisible pinky
	ClientPlaySound("SGTSIT");
        break;
      case 69: //Hel knight
      case 3003: //Baron of hell
	ClientPlaySound("BRSSIT");
        break;
    }
  if(type=='Pain') {
    switch(t->self->template->type) {
      case 88: //Boss brain
PrintI("brain_p",1);
	ClientPlaySound("BOSPN");
	break;
      case 64: //arch vile
	ClientPlaySound("VIPAIN");
	break;
      case 71: //Pain elemental
        ClientPlaySound("PEPAIN");
	break;
      case 67:
	ClientPlaySound("MNPAIN");
	break;
      case 3006: //Skull fucker
      case 69: //Hel knight
      case 3003: //Baron of hell
      case 3002: //pinky
      case 58: //invisible pinky
      case 16: //Cyber demon
      case 68:
	ClientPlaySound("DMPAIN");
        break;
      case 9: //Shotgunna
      case 3004: //Zombie
      case 3001: //Imp
      case 65: //Chain gunner
	ClientPlaySound("POPAIN");
        break;
    }
  }
  if(type=='Die') {
    switch(t->self->template->type) {
      case 88: //Boss brain
	ClientPlaySound("BOSDTH");
	break;
      case 64: //Arch vile
	ClientPlaySound("VILDTH");
	break;
      case 71: //Pain elemental
        ClientPlaySound("PEDTH");
	break;
      case 67:
	ClientPlaySound("MANDTH");
	break;
      case 68:
        ClientPlaySound("BSPDTH");
	break;
      case 3006:// Skull poo poo brain
	ClientPlaySound("FIRXPL");
        break;
      case 3002: //Pinky
      case 58: //invisible pinky
	ClientPlaySound("SGTDTH");
        break;
      case 3003://baron of hell
	ClientPlaySound("BRSDTH");
        break;
      case 16:
	ClientPlaySound("CYBDTH");
        break;
      case 9: //Shotgunna
      case 3004: //Zombie
      case 65: //Chain gunner
        switch(Rand*2.99) {
	  case 0:
	    ClientPlaySound("PODTH1");
	    break;
	  case 1:
	    ClientPlaySound("PODTH2");
	    break;
	  case 2:
	    ClientPlaySound("PODTH3");
        }
        return;
      case 3001: //Imp
        switch(Rand*1.99) {
	  case 0:
	    ClientPlaySound("BGDTH1");
	    break;
	  case 1:
	    ClientPlaySound("BGDTH2");
	    break;
        }

    }
  }
  if(type=='XDie') {
    switch(t->self->template->type) {
      case 3004: //Zombie
      case 3001: //Imp
      case 9: //shotgunner
      case 65: //Chain gunner
	ClientPlaySound("POSLOP");
        break;
    }
  }
  if(type=='Attack') {
    switch(t->self->template->type) {
      case 67:
	ClientPlaySound("MANATK");
	break;
      case 3006: //Creppy ass flying skull
	ClientPlaySound("SKLATK");
        break;
      case 16:
	ClientPlaySound("RLAUNC");
        break;
      case 9: //Fuckin Shotgun asshole
      case 65: //Chaingunna
	ClientPlaySound("SHOTGN");
        break;
      case 69: //Hel knight
      case 3003://Baron of hell
      case 3001:  //Imp
	ClientPlaySound("FIRSHT");
        break;
      case 3004: //Zombie
	ClientPlaySound("PISTOL");
        break;
      case 68:
        ClientPlaySound("PLASMA");
	break;

    }
  }
  if(type=='Melee') {
    switch(t->self->template->type) {
      case 3006: //Creppy ass flying skull
	ClientPlaySound("SKLATK");
        break;
      case 3002://Pinky
      case 58: //invisible pinky
	ClientPlaySound("SGTATK");
        break;
      case 69: //Hel knight
      case 3003:// Baron of hell
      case 3001:  //Imp
	ClientPlaySound("CLAW");
        break;
    }
  }
}


class CMissileThinker:CDoomThinkerBase {
  CDoomThing *shooter,*self;
  F64 vslope;
  F64 state_start_tS;
  Bool hit;
};
class CSkelMissileThinker:CMissileThinker {
  CDoomThing *target;
};

U0 MissileThinker(CDoomLevel *l,CMissileThinker *t) {
  CDoomThing *self=t->self,*hit;
  CDoomProjectileTemplate *template=self->template;
  F64 dist=template->speed,splash;
  CI64Set *things;
  I64 i;
  CDoomLinedef *ld=NULL;  
  //If we hit ourself,move without checking for things
  //Exlucude the shooter,remove missile from the Que to avoid checking for it
  QueRem(self);
//No speeding through targets
  ld=MoveThingFinal(l,self,self->angle,dist,COLLISF_NO_HIT_THING|COLLISF_PROJECTILE,NULL,t->shooter,&hit);
  QueIns(self,&l->things);
  CDoomSector *s=GetSectorForCoord(l,self->x,self->y);
  if(!t->hit&&!hit) {
    self->animation=template->_idle_frames;
    self->height+=t->vslope*template->speed;
//Perhaps we went through a thing(Check in radius)
    things=ThingsInRadius(l,self->x,self->y,template->radius);
    for(i=0;i!=things->cnt;i++) {
      hit=things->body[i];
      if(hit->template&&hit!=t->shooter&&hit->health>0.) {
         if(ApproxDist(hit->x-self->x,hit->y-self->y)<template->radius+hit->template->radius) {
	  goto now;
        }
      }
    }
    hit=NULL;
now:;
    I64SetDel(things);
  } else {
    self->momx=0,self->momy=0;
    dist=AnimationTime(template->_hit_frames);
    if(Server_tS-self->anim_start_tS>=dist) {
      QueRem(t);
      Free(t);
      ThingDel(l,self);
    }
    return;
  }
  if(hit) {
    if(hit==t->shooter)
      goto next;
    DamageMob(l,hit,t->shooter,template->direct*(RandU16&7+1));
explode:
    t->hit=TRUE;
    self->anim_start_tS=Server_tS;
    self->anim_no_repeat=TRUE;
    self->animation=template->_hit_frames;
    splash=template->splash;
//Splash damae
    RadiusAttack(l,self,splash);
    switch(self->template->type) {
      case 33:
	ClientPlaySound("BAREXP");
        break;
      case 24:
	ClientPlaySound("FIRXPL");
        break;
    }
    return;
  }
next:
  if(ld) { //Hit something
    goto explode;
  }
  if(!(s->floor_height<self->height<s->ceil_height)) {
    goto explode;
  }
}

U0 TracerThinker(CDoomLevel *l,CSkelMissileThinker *t)
{
  F64 zd,dist;
  CDoomThing *dst=t->target,*self=t->self;
  CDoomProjectileTemplate *template=self->template;
  CPuffThinker *th=SpawnSmokePuff(l,&self->x,self->height,6);
  // adjust direction
  if(!dst)
    return;
  if(dst->health<=0.)
    return;
  F64 angle=Arg(dst->x-self->x,dst->y-self->y); 
  if(Sin(angle-self->angle)>0.) {
    self->angle+=pi/8/4.;
  } else if(Sin(angle-self->angle)<0.) {
    self->angle-=pi/8/4;
  }
  dist=ApproxDist(dst->x-self->x,dst->y-self->y);
  dist/=template->speed;
  if(dist<1) dist=1;
  self->momz=(dst->height-self->height)/dist;
}



U0 SkelMissileThinker(CDoomLevel *l,CMissileThinker *t) {
  TracerThinker(l,t);
  MissileThinker(l,t);
}

#define MELEE_RANGE 70.
#define JUST_HIT_TIME .75
CDoomThing *GetVisiblePlayer(CDoomThing *who) {
  CDoomThing *t,*nearest=NULL;
  F64 bdist=I16_MAX*I16_MAX,dist,angle,dist2;
  for(t=l->things.next;t!=&l->things;t=t->next) {
    if(IsPlayer(t)) {
      angle=FArg(t->x-who->x,t->y-who->y);
      dist=ApproxDist(t->x-who->x,t->y-who->y);
      dist2=ValidateLineOfSightShot(l,&who->x,angle,dist,who->height+who->template->height,t->height+t->template->height);
      if(dist<bdist&&dist2<dist) {
	nearest=t;
	bdist=dist;
      }
    }
  }
  return nearest;
}
U0 RemoveMonsterFromMem(CMonsterThinker *t) {
  ThingDel(l,t->self);
  QueRem(t);
  Free(t);
}

Bool MMove(CDoomLevel *l,CMonsterThinker *m) {
  CDoomThing *self=m->self,*target=m->target;
  CDoomSector *sec;
  CDoomLinedef *lv;
  F64 amt=self->template(CDoomMonsterTemplate*)->speed/1.5;
  CFifoI64 *crossed=FifoI64New(0x10);
  I64 allow_float=0;
  if(!(self->flags&TF_FLOATING))
    allow_float=COLLISF_NO_DROP;
  lv=MoveThingFinal(l,self,
        self->angle,
        amt,
        allow_float|COLLISF_NO_HIT_THING|COLLISF_MONSTER|COLLISF_ADJUST_FOR_RADIUS|COLLISF_SLIDE,
        crossed,
        self
        );
//I run the monsters' AI every 3 frames,so ust set the momentum to keep moving while we are waiting for next frame
  self->momx2=amt*Cos(self->angle);
  self->momy2=amt*Sin(self->angle);
  if(self->template->flags&TF_FLOATING) {
    if(sec=GetSectorForCoord(l,self->x,self->y)) {
      if(target&&self->height<target->height-FLOATSPEED) {
        self->height=Clamp(self->height+FLOATSPEED,sec->floor_height,sec->ceil_height);
      } else if(target&&self->height>FLOATSPEED+target->height){
        self->height=Clamp(self->height-FLOATSPEED,sec->floor_height,sec->ceil_height);
      }
    }
  }
//If we hit a line,try opening the door ?
  if(lv)
    ClientTriggerLinedef(l,lv,WACTIVATE_MONSTER|WACTIVATE_PUSH,self);
  while(FifoI64Rem(crossed,&lv)) {
    ClientTriggerLinedef(l,lv,WACTIVATE_MONSTER|WACTIVATE_WALK,self);
  }
  FifoI64Del(crossed);
  return !!lv;
}

Bool SetState(CDoomLevel *l,CMonsterThinker *m,U8 *st,CState *cached=NULL) {
  CState *s=NULL;
  CDoomThing *self=m->self;
  self->momx2=0;
  self->momy2=0;
  self->momz2=0;
  if(cached) s=cached;
  else if(st) s=FramePtr(st);
  m->state=s;
  if(!s) {
    if(st) DbgPrint("Unimplemented state ASK NROOT(%s)\n",st);
//You done silly
    RemoveMonsterFromMem(m);
    return FALSE;
  }
  if(s->anim_frames) {
    if(m->self->animation!=s->anim_frames) {
      m->self->anim_start_tS=Server_tS;
      m->self->animation=s->anim_frames;
    }
    m->self->anim_no_repeat=s->no_repeat;
  }
  m->state_start_tS=Server_tS;
  m->state_length=s->time;
  m->ran_state=FALSE;
}

U0 DamageMob(CDoomLevel *l,CDoomThing *target,CDoomThing *opp,F64 damage){
  CDoomMonsterTemplate *template=target->template;
  CMonsterThinker*thinker=target->thinker;
  CDoomPlayer *p2;
  F64 angle,thrust;
  if(!(target->flags&TF_SHOOTABLE))
    return;
  if(target->health<=0.) return;
//Kick away(unless chainsaw)
  if(IsPlayer(p)&&weaponIndex!=5) { //5 is chainsaw
    angle=FArg(target->x-p->x,target->y-p->y);
     thrust=(25*damage)/template->mass;
//If dead ,move forward sometimes
    if(damage<40&&damage>=target->health&&RandU64&1) {
      angle+=pi;
      thrust*=4;
    }
    target->momx+=thrust*Cos(angle);
    target->momy+=thrust*Sin(angle);
  }
  if(IsPlayer(target)) {
    p2=target;
    if(p2->invincible_time>0.)
      return;
    if(p2->armor<=100.) {
      damage-=damage*1/2.;
    } else {
      damage-=damage*1/3.;
    }
    p2->hurt_amt+=damage;
    p2->armor=Max(p2->armor-damage,0.);
  }
  target->health-=damage;
  if(IsPlayer(target))
    target(CDoomPlayer*)->stare_at=opp;
  if(0.>=target->health) {
    if(IsPlayer(target))
      target(CDoomPlayer*)->weapon_state=0; //Prevent ending current fireing of weapon
//If damage<=-spawn_health,we EXPLODE the body
    if(target->health<=-template->health&&template->gib_state) {
      target->health=0.;
      if(thinker&&thinker->signature=='Monster') {
        SetState(l,thinker,template->gib_state);
        return;
      }
    }
    target->health=0.;
    if(thinker&&thinker->signature=='Monster')
      SetState(l,thinker,template->death_state);
    return;
  }
  if(Rand<template->pain_chance&&thinker&&thinker->signature=='Monster') { //TODO check skull fly
    if(template->pain_state)
      SetState(l,thinker,template->pain_state);
  }

  if(thinker&&thinker->signature=='Monster') thinker->reaction_time=0;

  if(opp&&thinker&&thinker->signature=='Monster') {
    thinker->target=opp;
    if(template->see_state&&thinker->state==template->spawn_state) {
      SetState(l,thinker,template->see_state);
    }
  }
//TODO skull fly
}

U0 BarrelThinker(CDoomLevel *l,CBarrelThinker *m) {
  CDoomThing *self=m->self,*hit,*head=&l->things;
  F64 dist;
  if(self->health<=0.) {
    if(!m->explode_start_tS) {
      m->explode_start_tS=Server_tS;
      self->solid=FALSE;
      ClientPlaySound("BAREXP");
      self->flags&=~(TF_OBSTACLE|TF_SHOOTABLE);
      self->animation=self->template(CDoomMonsterTemplate*)->_dying_frames;
      self->anim_no_repeat=TRUE;
    } else {
      if(Server_tS-m->explode_start_tS>=AnimationTime(self->animation)) {
        for(hit=head->next;hit!=head;hit=hit->next) {
	  dist=ApproxDist(hit->x-self->x,hit->y-self->y);
	  if(hit!=self&&(hit->thinker||IsPlayer(hit))&&hit->flags&TF_SHOOTABLE) {
	    if(dist<128)
	      DamageMob(l,hit,NULL,dist);
	  }
        }
        ThingDel(l,self);
        QueRem(m);
        Free(m);
      }
    }
  }
}


U0 MonsterThinker(CDoomLevel *l,CMonsterThinker *m) {
  CDoomThing *self=m->self;
  CState *s=m->state;;
  if(s->action&&!m->ran_state) {
    m->ran_state=TRUE;(s->action)(l,m);
  }
//Class 10 pooperism
  if(m->state_start_tS+m->state_length<Server_tS) {
    if(!s->next_state_cache&&s->next_state)
      s->next_state_cache=FramePtr(s->next_state);
    s=s->next_state_cache;
    SetState(l,m,NULL,s);
  }
}
U0 InitMonsters(CDoomLevel *l) {
  CDoomThing *thing,*head=&l->things;
  CMonsterThinker *einstein;
  for(thing=head->next;thing!=head;thing=thing->next) {
    switch(thing->template->type) {
      case 2035:
        thing->health=thing->template(CDoomMonsterTemplate*)->health;
        einstein=AddThinker(l,&BarrelThinker,"CBarrelThinker");
	einstein->signature='Barrel';
        einstein(CBarrelThinker*)->self=thing;
        thing->thinker=einstein;
        break;
///See Things.TXT homedog
      case 88:
      case 64:
      case 68:
      case 3002:
      case 65:
      case 69:
      case 3003:
      case 3005:
      case 3001:
      case 3006:
      case 76:
      case 16:
      case 67:
      case 71:
      case 66:
      case 9:
      case 58:
      case 7:
      case 84:
      case 3004:
        thing->health=thing->template(CDoomMonsterTemplate*)->health;
        einstein=AddThinker(l,&MonsterThinker,"CMonsterThinker");
//	einstein->reaction_time=thing->template(CDoomMonsterTemplate*)->reaction_time;
	einstein->signature='Monster';
        einstein->self=thing;
        thing->thinker=einstein;
        SetState(l,einstein,thing->template(CDoomMonsterTemplate*)->spawn_state);
    }
  }
}


Bool CanSeeTarget(CDoomLevel *l,CMonsterThinker *t) {
  if(!t->target) return FALSE;
  CDoomThing *self=t->self;
  CDoomThing *tar=t->target;
  if(!self->template||!tar->template) return FALSE;
  F64 dist=ApproxDist(self->x-tar->x,self->y-tar->y),dist2;
  F64 angle=FArg(tar->x-self->x,tar->y-self->y);
//Returns -1 if we Pushin P didnt hit a wall
//TRUEfor monster(ignores linedefs that monsters cant pass mofo)    
  dist2=ValidateLineOfSightShot(l,&self->x,angle,dist,self->height+self->template->height,tar->height+tar->template->height);
  if(dist2>dist||dist2<0.) {
    return TRUE;
  }
  return FALSE;
}
U0 Sub1RandomTick(CDoomLevel *l,CMonsterThinker *t) {
  I64 d=RandU64&4;
  if(t->state_length<d)
    t->state_length=0.;
  else
    t->state_length-=d;
}
Bool CheckMeleeRange(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *thing=t->self;
  CDoomThing *target=t->target;
  if(!target) return FALSE;
  if(t->reaction_time) return FALSE;
  return ApproxDist(target->x-thing->x,target->y-thing->y)<MELEE_RANGE;
}

Bool CheckMissileRange(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *thing=t->self;
  CDoomThing *target=t->target;
  if(!target) return FALSE;
  if(t->reaction_time) return FALSE;
  F64 dist;
  if(t->last_hit_time>0.)
    if(Server_tS<JUST_HIT_TIME+t->last_hit_time) {
      t->last_hit_time=-1.;
      return TRUE;
    }
  if(!CanSeeTarget(l,t)) return FALSE;
  dist=ApproxDist(target->x-thing->x,target->y-thing->y);
  if(!thing->template(CDoomMonsterTemplate*)->melee_state)
    dist-=128.;
  if(thing->template->type==3006) //Lost soul
    dist/=2.;
  if(dist>200.)
    dist=200.;
  return RandU64&0xff<ToI64(dist);
}
//Choose an angle to chase in
U0 NewChaseDir(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *thing=t->self;
  CDoomThing *target=t->target;
  CD2 dummy;
  I64 drop=COLLISF_ADJUST_FOR_RADIUS|COLLISF_NO_HIT_THING|COLLISF_MONSTER,i;
  if(!(thing->flags&TF_FLOATING))
    drop|=COLLISF_NO_DROP;
  F64 angle,dist=ToF64(RandU64&0xf),off,mul,ld_a,x,y,th=thing->template->height;
  CDoomLinedef *ld;
  if(!target) return;
  if(Rand>.75&&CanSeeTarget(l,t))
    angle=FArg(target->x-thing->x,target->y-thing->y);
  else
    angle=thing->angle;
  dummy.x=thing->x;
  dummy.y=thing->y;
  ld=MoveInLevel(l,&dummy,angle,thing->template->radius,th,thing->template->radius,thing->height,drop,NULL,thing);
  if(!ld) {
    thing->angle=angle;
  } else { //Deflect off the wall
    x=ld->start->x;
    y=ld->start->y;
    ld_a=FArg(ld->end->x-x,ld->end->y-y);
    if((ld->end->x-x)*(thing->y-y)-(ld->end->y-y)*(thing->x-x)>0.)
      ld_a+=pi/2;
    else
      ld_a-=pi/2;
    thing->angle=ld_a-angle+pi;
    ld=MoveInLevel(l,&dummy,angle,thing->template->radius*3.,th,thing->template->radius,thing->height,drop,NULL,thing);
//Cant deflect,try circle
    if(ld) {
      thing->angle+=Rand*2*pi/8.;
      for(off=0;off<2*pi;off+=2*pi/8) {
	thing->angle+=2*pi/8;
        ld=MoveInLevel(l,&dummy,angle,thing->template->radius*3.,th,thing->template->radius,thing->height,drop,NULL,thing);
	if(!ld)
	   break;
      }
    }

  }
  t->steps_to_walk=RandU64&15;
  thing->momx2=Cos(thing->angle)*thing->template(CDoomMonsterTemplate*)->speed;
  thing->momy2=Sin(thing->angle)*thing->template(CDoomMonsterTemplate*)->speed;
//  thing->x=dummy.x;
//  thing->y=dummy.y;
}
Bool LookForPlayers(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *thing=t->self;
  CDoomThing *target=t->target;
  CDoomSector *s=GetSectorForCoord(l,thing->x,thing->y);
  F64 angle,dist;
  if(s&&s->noise_thing&&IsPlayer(s->noise_thing)) {
    target=t->target=s->noise_thing;
    return TRUE;
  }
  if(!CanSeeTarget(l,t)) {
new_target:
    t->target=GetVisiblePlayer(thing);
    return FALSE;
  }
see:
  if(!target||target->health<=0.)
    goto new_target;
  angle=FArg(target->x-thing->x,target->y-thing->y)-thing->angle;
  if(FCos(angle)<0.) {
    dist=ApproxDist(target->x-thing->x,target->y-thing->y);
    if(dist>MELEE_RANGE)
	return FALSE; 
  }
  t->attack_time=4.;
  return TRUE;
}
U0 Look(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *p=GetVisiblePlayer(t->self);
  t->target=p;
  if(!p) {
    return ;
  }
  Sound(t,'See');
  SetState(l,t,t->self->template(CDoomMonsterTemplate*)->see_state);
}
U0 Chase(CDoomLevel *l,CMonsterThinker *t) {
  if(t->reaction_time)
    --t->reaction_time;
  t->attack_time=Clamp(t->attack_time-TICK_TIME,0,I16_MAX);
  if(!t->target||t->target->health<=0.)  {
    if(LookForPlayers(l,t))
      return;
    SetState(l,t,t->self->template(CDoomMonsterTemplate*)->spawn_state);
    return;
  }
  if(t->self->flags&MF_JUST_ATTACKED) {
    t->self->flags&=~MF_JUST_ATTACKED;
    goto skip_attack;
  }
  if(t->self->template(CDoomMonsterTemplate*)->melee_state&&CheckMeleeRange(l,t)) {
    SetState(l,t,t->self->template(CDoomMonsterTemplate*)->melee_state);
    return;
  }
  if(t->steps_to_walk<=0&&t->self->template(CDoomMonsterTemplate*)->missile_state&&CheckMissileRange(l,t)) {
    SetState(l,t,t->self->template(CDoomMonsterTemplate*)->missile_state);
    return;
  }
skip_attack:
  if(!t->steps_to_walk)
    NewChaseDir(l,t);
  else if(MMove(l,t))
    NewChaseDir(l,t);
  //TODO chase sound
}
U0 FaceTarget(CDoomLevel *l,CMonsterThinker *t)  {
  CDoomThing *self=t->self;
  CDoomThing *target=t->target;
  if(target) {
    target->flags&=~MF_AMBUSH;
    self->angle=FArg(target->x-self->x,target->y-self->y);
    if(target->flags&MF_SHADOW) {
      self->angle+=(Rand-Rand)*pi/4;
    }
  }
}


//For blood and smoke
CDoomThingTemplate *blood_templates[3];
CDoomThingTemplate *smoke_templates[4];
U0 CreatePuffTemplates() {
  U8 buf[STR_LEN];
  I64 i,j;
  CDC *what;
  for(i=0;i!=3;i++) {
    blood_templates[i]=CAlloc(sizeof CDoomThingTemplate);
    StrPrint(buf,"BLOOD:%d",i);
    UH(buf,blood_templates[i]);
    blood_templates[i]->_animation=CAlloc(sizeof(CDoomAnimationFrame)*2);
    StrPrint(buf,"BLOODA:%d",i);
    UH(buf,blood_templates[i]->_animation);
    switch(i) {
      case 0: what=SpriteName2DC("BLUDA0"); break;
      case 1: what=SpriteName2DC("BLUDB0"); break;
      case 2: what=SpriteName2DC("BLUDC0"); break;
    }
    for(j=0;j!=8;j++) {
      blood_templates[i]->_animation->faces[j]=what;
      blood_templates[i]->_animation->chr='B';
    }
  }
  for(i=0;i!=4;i++) {
    smoke_templates[i]=CAlloc(sizeof CDoomThingTemplate);
    smoke_templates[i]->_animation=CAlloc(sizeof(CDoomAnimationFrame)*2);
    StrPrint(buf,"SMOKE:%d",i);
    UH(buf,smoke_templates[i]);
    StrPrint(buf,"SMUKEA:%d",i);
    UH(buf,smoke_templates[i]->_animation);
    switch(i) {
      case 0: what=SpriteName2DC("PUFFA0"); break;
      case 1: what=SpriteName2DC("PUFFB0"); break;
      case 2: what=SpriteName2DC("PUFFC0"); break;
      case 3: what=SpriteName2DC("PUFFD0"); break;
    }
    for(j=0;j!=8;j++) {
      smoke_templates[i]->_animation->faces[j]=what;
      smoke_templates[i]->_animation->chr='B';

    }
  }
}
CreatePuffTemplates;
U0 PuffThinker(CDoomLevel *l,CPuffThinker *puff) {
  CDoomThing *self=puff->self;
  CDoomThingTemplate **templates;
  I64 i,i2;
  CDoomSector *s=GetSectorForCoord(l,self->x,self->y);
  if(!s) {
//wut
    kill_puff:
    ThingDel(l,self);
    QueRem(puff);
    Free(puff);
    return;
  }
//  if(s->floor_height>=self->height)
//    goto kill_puff;
//I will goto the next puff frame
  if(Server_tS-puff->spawn_time>1./4./2.) {
    puff->spawn_time=Server_tS;
    for(i=0;i!=2;i++) {
      if(i==0)
        templates=blood_templates,i2=3;
      else
        templates=smoke_templates,i2=4;
      while(i2--) {
        if(templates[i2]==self->template)
	  break;
      }
      if(i2>=0) {
        i2++;
//No more animation frames
        if(i==0&&i2==3) goto kill_puff;
        else if(i==1&&i2==4) goto kill_puff;
	self->template=templates[i2];
//Update the animation
	self->animation=templates[i2]->_animation;
      }
    }
  }
}
U0 SpawnBloodPuff(CDoomLevel *l,CD2 *at,F64 h,F64 damage) {
  CDoomThing *blood=CAlloc(sizeof CDoomThing);
  CPuffThinker *t;
  blood->x=at->x,blood->y=at->y;
  blood->height=h;
  blood->momz=RandU64&15+2;
//Heres the deal,BLOOD1  is the messy-est
//BLOOD2 is the middle,
//BLOOD3 is the final frame of anmation
  if(damage>13.) {
//Whooping load of damage
    blood->template=blood_templates[0];
  } else if(damage>9.) {
    blood->template=blood_templates[1];
  } else {
    blood->template=blood_templates[2];
  }
  t=AddThinker(l,&PuffThinker,"CPuffThinker");
  t->spawn_time=Server_tS;
  QueIns(blood,&l->things);
  InitPosDataForThing(l,blood);
  t->self=blood;
  blood->animation=blood->template->_animation;
}
CPuffThinker *SpawnSmokePuff(CDoomLevel *l,CD2 *at,F64 h,F64 attack_range) {
  CDoomThing *smoke=CAlloc(sizeof CDoomThing);
  CPuffThinker *t;
  smoke->x=at->x,smoke->y=at->y;
  smoke->height=h;
  smoke->momz=RandU64&15+2;
  if(attack_range<MELEE_RANGE) {
//Use Puff 3 if we hit the wall,we dont want the spark puff's when Pwnin a wall homie
    smoke->template=smoke_templates[2];
  } else
    smoke->template=smoke_templates[0];
  t=AddThinker(l,&PuffThinker,"CPuffThinker");
  t->spawn_time=Server_tS;
  InitPosDataForThing(l,smoke);
  QueIns(smoke,&l->things);
  t->self=smoke;
  smoke->animation=smoke->template->_animation;
  return t;
} 
#define LA_TYPE_NORMAL 0
#define LA_TYPE_MELEE 1
#define LA_TYPE_INVISIBLE 2

CDoomThing *LineAttack(CDoomLevel *l,CDoomThing *self,CDoomThing *target,F64 range,F64 angle,F64 damage,I64 melee=0) {
  CDoomThing *hit=ShotSmacksAHomie(l,&self->x,angle,range,self->height+self->template->height-2,self);
  CDoomLinedef *ld;
  CD2 puff_pos,dummy;
  F64 angle2;
  F64 dist,src_h,dst_h,dist2;
  if(hit) {
    target=hit;
hit_target:
    dist2=ApproxDist(self->x-target->x,self->y-target->y);
    if(melee==LA_TYPE_MELEE&&dist2>range)
      return NULL;
//I will make some distance between the blood-puff and the target to avoid z-clipping
      //Angle from hit->self 
    angle2=FArg(self->x-hit->x,self->y-hit->y);
//Spawn a BLOOD PUFF,and I AINT talkin marshmellow
    dst_h=target->height+target->template->height/2;
    puff_pos.x=hit->x+5*Cos(angle2);
    puff_pos.y=hit->y+5*Sin(angle2);
//Smoke puffs come out of barrels
    if(hit->template&&hit->template->type==2035)
      SpawnSmokePuff(l,&puff_pos,dst_h,damage);
    else
      SpawnBloodPuff(l,&puff_pos,dst_h,damage);
    DamageMob(l,target,self,damage);
    return target;
  } else if(target) {
//Spawn a smoke puff as we missed
    src_h=self->height+self->template->height/2;
    dst_h=target->height+target->template->height/2;
    dist2=ApproxDist(self->x-target->x,self->y-target->y);
    dist=ValidateLineOfSightShot(l,&self->x,angle,dist2,src_h,dst_h); 
    if(melee==LA_TYPE_INVISIBLE)
      return NULL;
    if(melee==LA_TYPE_MELEE&&dist2>range)
      return NULL;
    if(dist>0.) {
      angle2=FArg(target->x-self->x,target->y-self->y);
      dst_h=Lerp(dist/dist2,src_h,dst_h); //Good enough?
      dist-=5.;
      puff_pos.x=self->x+dist*Cos(angle2);
      puff_pos.y=self->y+dist*Sin(angle2);
      SpawnSmokePuff(l,&puff_pos,dst_h,dist+5.);
    } if(dist<=0.) {
//Hit by chance
      hit=target;
      goto hit_target;
    } else
      goto defacto;
  } else {
defacto:
//Make shot right in front of us
    src_h=self->height+self->template->height/2;
    dist=ValidateLineOfSightShot(l,&self->x,angle,range,src_h,src_h); 
    if(melee==LA_TYPE_INVISIBLE)
      return NULL;
    if(melee==LA_TYPE_MELEE&&dist>range)
      return NULL;
    if(dist>=5.) {
      dist-=5.;
      puff_pos.x=self->x+dist*Cos(angle);
      puff_pos.y=self->y+dist*Sin(angle);
      SpawnSmokePuff(l,&puff_pos,src_h,dist+5.);
    } else if(dist>0.) {
//Really close to wall
      puff_pos.x=self->x+dist*Cos(angle);
      puff_pos.y=self->y+dist*Sin(angle);
      SpawnSmokePuff(l,&puff_pos,src_h,dist);
    }
//Check to see if we hit a shootable wall
    dummy.x=self->x;
    dummy.y=self->y;
    ld=MoveInLevel(l,&dummy,angle,dist+8,8.,16.,self->height,COLLISF_PROJECTILE);
    if(ld) {
      if(1<=self->template->type<=4) //Player types
        ClientTriggerLinedef(l,ld,WACTIVATE_SHOOT,self);
      else
        ClientTriggerLinedef(l,ld,WACTIVATE_SHOOT|WACTIVATE_MONSTER,self);
    }
  }
  return NULL;
}
U0 PosAttack(CDoomLevel *l,CMonsterThinker *t) {
  F64 angle,damage;
  if(t->target) {
    FaceTarget(l,t);
    t->self->flags|=MF_JUST_ATTACKED;
    Sound(t,'Attack');
    angle=t->self->angle;
    angle+=(.5-Rand)*pi/5;
    damage=((RandU64%4)+1)*3;
    LineAttack(l,t->self,t->target,MISSILE_RANGE,angle,damage);
  }
}
U0 SPosAttack(CDoomLevel *l,CMonsterThinker *t) {
  F64 bangle,angle,damage;
  I64 i;
  if(t->target) {
    Sound(t,'Attack');
    FaceTarget(l,t);
    t->self->flags|=MF_JUST_ATTACKED;
    bangle=t->self->angle;
    for(i=0;i!=3;i++) {
      angle=bangle;
      angle+=(Rand-.5)*180./pi*5;
      damage=((RandU64%4)+1)*3;
      LineAttack(l,t->self,t->target,MISSILE_RANGE,angle,damage);
    }
  }
}
U0 SpidRefire(CDoomLevel *l,CMonsterThinker *t) {
  FaceTarget(l,t);
  if(RandU64&255>=10) {
    if(!t->target||t->target->health<=0.||!CanSeeTarget(l,t))
      SetState(l,t,t->self->template(CDoomMonsterTemplate*)->see_state);
  }
}
extern U0 SpawnFly(CDoomLevel *,CMissileThinker*);
U0 SpawnFly2(CDoomLevel *l,CMissileThinker *t) {
  SpawnFly(l,t);
}
class CCubeThinker:CMissileThinker {
  CD2 start;
  CD2 end;
};

CMissileThinker *SpawnMissile(CDoomLevel *l,CDoomThing *t,CDoomThing *target,U64 type) {
  CDoomProjectileTemplate *template=NULL;
  CDoomThing *self;
  F64 dist,angle;
  CMissileThinker *think;
  if(type=='Skel') {
    template=skel_missile;
  } else if(type=='Imp') {
    template=imp_fireball;
  } else if(type=='Rocket'||type=='Cyber') {
    template=rocket;
  } else if(type=='Caco') {
    template=cacodemon_fireball;
  } else if(type=='Baron') {
    template=baron_fireball;
  } else if(type=='Plasma') {
    template=plasma_ball;
  } else if(type=='BFG') {
    template=bfg_ball;
  } else if(type=='Fat')
    template=mancubus_fireball;
  else if(type=='Brain') 
    template=spawn_cube;
  else if(type=='BrainExp') 
    template=brain_explosion;
  else
    throw('Missile');
  self=CAlloc(sizeof(CDoomThing),doom_task);
  if(target) {
    angle=FArg(target->x-t->x,target->y-t->y);
  } else
    angle=t->angle;
  if(target&&target->flags&MF_SHADOW) {
    angle+=(Rand-Rand)*pi/4;
  }
  self->x=t->x;
  self->y=t->y;
  self->angle=angle;
  self->height=t->height+t->template->height/2.;
  self->template=template;
  self->flags=template->flags;
  InitPosDataForThing(l,self);
  QueIns(self,l->things.next);
  if(type=='Brain') {
    think=AddThinker(l,&SpawnFly2,"CCubeThinker");
    think(CCubeThinker*)->start.x=self->x;
    think(CCubeThinker*)->start.y=self->y;
    think(CCubeThinker*)->end.x=target->x;
    think(CCubeThinker*)->end.y=target->y;
  } else if(type=='Skel') {
    think=AddThinker(l,&SkelMissileThinker,"CSkelMissileThinker");
    think(CSkelMissileThinker*)->target=target;
  } else  {
    think=AddThinker(l,&MissileThinker,"CMissileThinker");
  }
  think->self=self;
  think->shooter=t;
  if(target&&target->template) { //???
    dist=ApproxDist(target->x-self->x,target->y-self->y);
    think->vslope=(target->height+target->template->height/2.
	-self->height)/dist;
  } else
    think->vslope=0.;
  return think;
}
//Imp poo poo    
U0 TroopAttack(CDoomLevel *l,CMonsterThinker *t) {
  F64 damage;
  if(t->target) {
    FaceTarget(l,t);
    if(CheckMeleeRange(l,t)) {
      Sound(t,'Melee');
      damage=((RandU64&7)+1)*3;
      t->self->flags|=MF_JUST_ATTACKED;
      DamageMob(l,t->target,t->self,damage);
      return;
    }
    Sound(t,'Attack');
    t->self->flags|=MF_JUST_ATTACKED;
    SpawnMissile(l,t->self,t->target,'Imp');
  }
}
U0 BabyAttack(CDoomLevel *l,CMonsterThinker *t) {
  if(t->target) {
    FaceTarget(l,t);
    Sound(t,'Attack');
    t->self->flags|=MF_JUST_ATTACKED;
    SpawnMissile(l,t->self,t->target,'Plasma');
  }

}

U0 BabyRefire(CDoomLevel *l,CMonsterThinker *t) {
  FaceTarget(l,t);
  if(RandU64&255>=10) {
    if(!t->target||t->target->health<=0.||!CanSeeTarget(l,t))
      SetState(l,t,t->self->template(CDoomMonsterTemplate*)->see_state);
  }
}
U0 BrainSpit(CDoomLevel *l,CMonsterThinker *t) {
  static I64 nth=0;
  CDoomThing *thing;
  t->target=p; //only playr?
  CI64Set *spitters=I64SetNew;
  for(thing=l->things.next;thing!=&l->things;thing=thing->next) {
    if(thing->template)
      if(thing->template->type==89)
      I64SetAdd(spitters,thing);
  }
  SpawnMissile(l,spitters->body[++nth%spitters->cnt],t->target,'Brain');
  I64SetDel(spitters);
}
U0 SpawnFly(CDoomLevel *l,CCubeThinker *t) {
  CDoomThing *self=t->self,*new;
  CMonsterThinker *thinker;
  I64 r,spawn;
  F64 speed=self->template(CDoomProjectileTemplate*)->speed;
  self->height+=speed*t->vslope;
  self->animation=self->template(CDoomProjectileTemplate*)->_idle_frames;
  MoveThingFinal(l,self,self->angle,speed,COLLISF_PROJECTILE,NULL,t->shooter);
  if(ApproxDist(self->x-t->start.x,self->y-t->start.y)*.75>=
	ApproxDist(t->end.x-t->start.x,t->end.y-t->start.y)) {
    r=RandU16&0xff;
//https://doomwiki.org/wiki/Monster_spawner
    switch(r) {
      case 0 ... 50-1:
      spawn=0xbb9;
      break;case 50 ... 50+40-1:
      spawn=0xbba;
      break;case 50+40 ... 50 +30+40-1:
      spawn=0x3a;
      break;case 50+40+30 ... 50 +2*30+40-1:
      spawn=0xbba;
      break;case 50+2*30+40 ... 50+ 3*30+40-1:
      spawn=67;
      break;case 50+3*30+40 ... 50+ 3*30+40+24-1:
      spawn=69;
      break;case 50+3*30+40+24 ... 50+ 3*30+40+24+20-1:
      spawn=68;
      break;case 50+3*30+40+24+20 ... 50+3*30+40+24+20+10-1:
	spawn=0xbbb;
      break;case 50+3*30+40+24+20+2*10 ... 50+ 3*30+40+24+20+3*10-1:
	spawn=66;
      break;default:
	spawn=64;
    }	
    new=CAlloc(sizeof(CDoomThing),doom_task);
    QueIns(new,l->things.last);
    new->x=self->x;
    new->y=self->y;
    new->height=self->height;
    new->template=doom_thing_types[spawn]; 
    new->health=new->template(CDoomMonsterTemplate*)->health;
    thinker=AddThinker(l,&MonsterThinker,"CMonsterThinker");
    thinker->signature='Monster';
    thinker->self=new;
    new->thinker=thinker;
    new->flags=new->template->flags;
    SetState(l,thinker,new->template(CDoomMonsterTemplate*)->see_state);
    ThingDel(l,self);
    QueRem(t);
    Free(t);
    return;
  }
}


//Chaingunner
U0 CPosAttack(CDoomLevel *l,CMonsterThinker *t) {
  F64 damage;
  if(t->target) {
    FaceTarget(l,t);
    Sound(t,'Attack');
    t->self->flags|=MF_JUST_ATTACKED;
    damage=3+5*Rand*3;
    LineAttack(l,t->self,t->target,MISSILE_RANGE,t->self->angle+(Rand-.5)*pi/2.,damage);
  }
  if(RandU16&0xff<0xf) {
    SetState(l,t,t->self->template(CDoomMonsterTemplate*)->see_state);
  }
}


U0 CyberAttack(CDoomLevel *l,CMonsterThinker *t) {
  if(t->target) {
    FaceTarget(l,t);
    Sound(t,'Attack');
    t->self->flags|=MF_JUST_ATTACKED;
    SpawnMissile(l,t->self,t->target,'Rocket');    
  }
}

//Spectre
U0 SargAttack(CDoomLevel *l,CMonsterThinker *t) {
  F64 angle,damage;
  if(t->target) {
    FaceTarget(l,t);
    Sound(t,'Melee');
    if(ApproxDist(t->self->x-t->target->x,t->self->y-t->target->y)>MELEE_RANGE)
      return;
    angle=t->self->angle;
    angle+=(.5-Rand)*180./pi*5;
    damage=((RandU64&7)+1)*4;
    t->self->flags|=MF_JUST_ATTACKED;
    LineAttack(l,t->self,t->target,MELEE_RANGE,angle,damage);
  }
}

U0 CacodemonAttack(CDoomLevel *l,CMonsterThinker *t) {
  F64 damage;
  if(t->target) {
    FaceTarget(l,t);
    t->self->flags|=MF_JUST_ATTACKED;
    if(CheckMeleeRange(l,t)) {
      damage=((RandU64&7)+1)*8;
      Sound(t,'Melee');
      t->self->flags|=MF_JUST_ATTACKED;
      DamageMob(l,t->target,t->self,damage);
      return;
    }
    Sound(t,'Attack');
    t->self->flags|=MF_JUST_ATTACKED;
    SpawnMissile(l,t->self,t->target,'Caco');
  }
}

U0 CyberdemonAttack(CDoomLevel *l,CMonsterThinker *t) {
  F64 damage;
  if(t->target) {
    FaceTarget(l,t);
    Sound(t,'Attack');
    t->self->flags|=MF_JUST_ATTACKED;
    SpawnMissile(l,t->self,t->target,'Cyber');
  }
}

U0 BarronOfHellAttack(CDoomLevel *l,CMonsterThinker *t) {
  F64 damage;
  if(t->target) {
    FaceTarget(l,t);
    t->self->flags|=MF_JUST_ATTACKED;
    if(CheckMeleeRange(l,t)) {
      damage=((RandU64&7)+1)*11;
      Sound(t,'Melee');
      DamageMob(l,t->target,t,damage);
      return;
    }
    Sound(t,'Attack');
    SpawnMissile(l,t->self,t->target,'Baron');
  }
}

#define SKULL_ATTACK_SPEED (40.*30/7)
U0 SkullAttack(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *dest=t->target;
  CDoomThing *self=t->self;
  F64 dist;
  if(dest) {
    self->flags|=MF_SKULL_ATTACK;
    self->flags|=MF_JUST_ATTACKED;
    Sound(t,'Attack');
    FaceTarget(l,t);
    self->momx=SKULL_ATTACK_SPEED*Cos(self->angle);
    self->momy=SKULL_ATTACK_SPEED*Sin(self->angle);
    dist=ApproxDist(dest->x-t->self->x,dest->y-t->self->y);
    self->momz=(dest->height+dest->template->height/2-t->self->height)/dist;
  }
}
U0 Scream(CDoomLevel *l,CMonsterThinker *t) {
}

U0 BOOM(CDoomLevel *l,CMonsterThinker *t) {
//Major death
} 
U0 Pain(CDoomLevel *l,CMonsterThinker *t) {
    Sound(t,'Pain');
}

U0 DropItem(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *self=t->self,*new;
  I64 spawn=-1;
  switch(self->template->type) {
    case 9: //Shotgun gut
      spawn=2001;
    break;
    case 84: //Wolfenstein guy
    case 3004: //zombie
      spawn=2007;
    break;
    case 65: //Chain guunna
      spawn=2002;
    break;
  }
  if(spawn!=-1) {
    new=CAlloc(sizeof(CDoomThing),doom_task);
    new->x=self->x;
    new->y=self->y;
    new->height=self->height;
    new->template=doom_thing_types[spawn];
    InitPosDataForThing(l,new);
    QueIns(new,l->things.last);
    new->flags=new->template->flags;
  }
}

U0 Fall(CDoomLevel *l,CMonsterThinker *t) {
//Alive ???(Only drop once)
  CDoomThing *self=t->self;
  Sound(t,'Die');
  if(self->flags&TF_SHOOTABLE)
    DropItem(l,t);
  self->flags&=~(TF_SHOOTABLE|TF_OBSTACLE);
  self->solid=FALSE;
  l->stats.have_kills++;
}
U0 XFall(CDoomLevel *l,CMonsterThinker *t) {
//Alive ???(Only drop once)
  Sound(t,'XDie');
  if(t->self->flags&TF_SHOOTABLE)
    DropItem(l,t);
  t->self->flags&=~(TF_SHOOTABLE|TF_OBSTACLE);
  t->self->solid=FALSE;
  l->stats.have_kills++;
}
U0 NullState(CDoomLevel *l,CMonsterThinker *t) {
  //Remove the thinker but not the thing
/*  QueRem(t);
  Free(t);*/
}
U0 Explode(CDoomLevel *l,CMonsterThinker *t) {
  RadiusAttack(l,t->target,128);
}
U0 BossDeath(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *self=t->self;
//Check if the Drake treacherous twin's are all dead,then we fin ta trigger 666
  CDoomThing *treacherous_twin,*head=&l->things;
  static CDoomLinedef dummy;
//Yeah  will pwned em all homie,activate #666 Floor FloorToLowest
  //See Floors.TXT for more info on our dummy thang(37)
  MemSet(&dummy,0,sizeof CDoomLinedef); //Clear activated
#ifdef DOOM2
  if(!StrCmp("MAP07",l->map_name)) {
//Check all baby spiders r dead
    dummy.special_type=action_sector_types[158]; //Raise to texture
    dummy.sector_tag=667;
    for(
	  treacherous_twin=head->next;
	  head!=treacherous_twin;
	  treacherous_twin=treacherous_twin->next
    ) {
      if(treacherous_twin->template==doom_thing_types[68]) { //Baby spider
        if(treacherous_twin->health>0.)
	  goto skip_bspider;
      }
    }
    ClientTriggerLinedef(l,&dummy,-1,p); //-1 for all types
skip_bspider:;
    dummy.special_type=action_sector_types[37];
    dummy.sector_tag=666;
    for(
	  treacherous_twin=head->next;
	  head!=treacherous_twin;
	  treacherous_twin=treacherous_twin->next
    ) {
      if(treacherous_twin->template==doom_thing_types[67]) { //Fatass
	if(treacherous_twin->health>0.)
	  goto skip_fatass;
      }
    }
    ClientTriggerLinedef(l,&dummy,-1,p); //-1 for all types
skip_fatass:;
  }
  return;
#endif
  if(l->map_name[1]=='1') { //Episode 1
    for(
	  treacherous_twin=head->next;
	  head!=treacherous_twin;
	  treacherous_twin=treacherous_twin->next
    ) {
      if(treacherous_twin->template==self->template&&treacherous_twin->health>0.)
        return ;
    }
//Pick 1st player
    for(self=head->next;self!=head;self=self->next) {
      if(IsPlayer(self)) {
        ClientTriggerLinedef(l,&dummy,-1,p); //-1 for all types
        break;
      }
    }
  } else if(l->map_name[1]=='2'||l->map_name[1]=='3') { //E2M8 cyberdemon,E2M8 spiderdemon
    if(self->template==doom_thing_types[16]) //Cyberdemon
      l->ended=TRUE;
    if(self->template==doom_thing_types[7]) //spider guy
      l->ended=TRUE;
  } else if(l->map_name[1]=='4') {
    if(self->template==doom_thing_types[16]) { //Cyberdemon
//Pick 1st player
      for(self=head->next;self!=head;self=self->next)
        if(IsPlayer(self))
	  switch(l->map_name[3]) {
	    case '6':
	      dummy.special_type=action_sector_types[109]; //Open dont close
	      ClientTriggerLinedef(l,&dummy,WACTIVATE_WALK,p);
	      break;
	    case '8':
	      dummy.special_type=action_sector_types[38]; //lowest
	      ClientTriggerLinedef(l,&dummy,WACTIVATE_WALK,p);
	      break;
	  }
      if(self->template==doom_thing_types[7]) //spider guy
        l->ended=TRUE;
    }
  }
}
U0 Hoof(CDoomLevel *l,CMonsterThinker *t) {
  ClientPlaySound("HOOF");
  Chase(l,t);
} 

//Metal robot spider foot homie
U0 Metal(CDoomLevel *l,CMonsterThinker *t) {
  ClientPlaySound("METAL");
  Chase(l,t);
} 


U0 BabyMetal(CDoomLevel *l,CMonsterThinker *t) {
  ClientPlaySound("BSPWLK");
  Chase(l,t);
} 


U0 ExplodeMissle(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *self=t->self;
  self->momx=0.;
  self->momy=0.;
  self->momz=0.;
  SetState(l,t,t->self->template(CDoomMonsterTemplate*)->death_state);
  self->flags&=~MF_MISSILE; 
//Todo make some sound
}

U0 MissileHit(CDoomLevel *l,CMonsterThinker *t) {
  F64 damage;
  if(t) {
    damage=t->self->template(CDoomMonsterTemplate*)->damage*(RandU64&7+1);
    DamageMob(l,t->target,t->parent,damage);
  }
  ExplodeMissle(l,t);
}
U0 SkullHit(CDoomLevel *l,CMonsterThinker *t,CDoomThing *hit_thang) {
  F64 damage;
  CDoomThing *self=t->self;
  if(hit_thang) {
    damage=(RandU64&7+1)*t->self->template(CDoomMonsterTemplate*)->damage;
    DamageMob(l,hit_thang,t->self,damage);
  }
  self=t->self;
  self->flags&=~MF_SKULL_ATTACK;
  self->momx=0.;
  self->momy=0.;
  self->momz=0.;
  SetState(l,t,t->self->template(CDoomMonsterTemplate*)->spawn_state);
}
U0 FatRaise(CDoomLevel *l,CMonsterThinker *t) {
  FaceTarget(l,t);
  ClientPlaySound("MANSIT");
}
U0 FatAttack1(CDoomLevel *l,CMonsterThinker *t) {
  FaceTarget(l,t);
  CMissileThinker *th=SpawnMissile(l,t->self,t->target,'Fat');
  th->self->angle+=pi/6; //Correct value?
}
U0 FatAttack2(CDoomLevel *l,CMonsterThinker *t) {
  FaceTarget(l,t);
  CMissileThinker *th=SpawnMissile(l,t->self,t->target,'Fat');
  th->self->angle-=pi/6; //Correct value?
}
U0 FatAttack3(CDoomLevel *l,CMonsterThinker *t) {
  FaceTarget(l,t);
  CMissileThinker *th=SpawnMissile(l,t->self,t->target,'Fat');
  th->self->angle-=pi/6/2; //Correct value ?/2
  th=SpawnMissile(l,t->self,t->target,'Fat');
  th->self->angle+=pi/6/2; //Correct value?/2
}

I64 LostSoulCnt(CDoomLevel *l) {
  I64 ret=0;
  CDoomThing *head=&l->things,*cur;
  for(cur=head->next;cur!=head;cur=cur->next)
    if(cur->template==doom_thing_types[3006]) //Lost soul
      ret++;    
  return ret;
}

U0 PainAttack(CDoomLevel *l,CMonsterThinker *t) {
  if(!t->target) return;
  FaceTarget(l,t);
  if(LostSoulCnt(l)>=25)
    return;
  CDoomThing *thing=CAlloc(sizeof(CDoomThing),doom_task);
  QueIns(thing,l->things.last);
  thing->x=t->self->x;
  thing->y=t->self->y;
  thing->height=t->self->height;
  thing->template=doom_thing_types[3006];
  thing->health=thing->template(CDoomMonsterTemplate*)->health;
  CMonsterThinker *einstein=AddThinker(l,&MonsterThinker,"CMonsterThinker");
  einstein->signature='Monster';
  einstein->self=thing;
  einstein->target=t->target;
  thing->angle=t->self->angle;
  thing->thinker=einstein;
  thing->health=thing->template(CDoomMonsterTemplate*)->health;
  thing->flags=thing->template->flags;
  SetState(l,einstein,thing->template(CDoomMonsterTemplate*)->spawn_state);
  if(!MMove(l,einstein)) {
    DamageMob(l,einstein,einstein,10000);
    return;
  }
  SkullAttack (l,einstein);
}
U0 Vanish(CDoomLevel *l,CMonsterThinker *t) {
  RemoveMonsterFromMem(t);
}

U0 SkelWhoosh(CDoomLevel *l,CMonsterThinker *t) {
  if(!t->target) return;
  FaceTarget(l,t);
  ClientPlaySound("SKESWG");
}
U0 SkelFist(CDoomLevel *l,CMonsterThinker *t) {
  if(!t->target) return;
  FaceTarget(l,t);
  F64 damage=(Rand*10+1)*6;
  if(CheckMeleeRange(l,t)) {
    DamageMob(l,t->target,t->self,damage);
  }
}
U0 VileChase(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *self=t->self,*cur;
  CDoomMonsterTemplate *template;
  CI64Set *things=ThingsInRadius(l,self->x,self->y,8*64);//Good enough radius
  I64 idx;
  F64 angle;
  F64 dist;
  for(idx=0;idx!=things->cnt;idx++) {
    cur=things->body[idx];
    if(cur->health<=0&&cur->thinker&&cur->flags&TF_MONSTER) {
      angle=FArg(cur->x-self->x,cur->y-self->y);
      dist=ApproxDist(self->x-cur->x,cur->y-self->y);
      if(ValidateLineOfSightShot(l,&self->x,angle,dist,self->height+16,cur->height+16)<0.) {
        template=cur->template;
	if(template->resurrect_state) {
//	  cur->flags&=~TF_CORPSE;
	  SetState(l,cur->thinker,template->resurrect_state);
	  template=self->template;
	  SetState(l,t,self->template(CDoomMonsterTemplate*)->heal_state);
	  ClientPlaySound("SLOP");
          goto fin;
	}
      }
    }
  }
  Chase(l,t);
fin:;
  I64SetDel(things);
}
U0 VileStart(CDoomLevel *l,CMonsterThinker *t) {
  ClientPlaySound("VILATK");
}
U0 VileAttack(CDoomLevel *l,CFireThinker *t) {
  if(!t->target) return;
  F64 angle;
  ClientPlaySound("VILATK");
  CFireThinker *firet;
  FaceTarget(l,t);
  CDoomThing *fire=CAlloc(sizeof(CDoomThing),doom_task),*target=t->target;
  angle=FArg(target->x-t->self->x,target->y-t->self->y);
  fire->template=vile_fire;
  fire->x=target->x-24*Cos(angle);
  fire->y=target->y-24*Sin(angle);
  fire->height=target->height;
  fire->animation=vile_fire->_animation;
  InitPosDataForThing(l,fire);
  QueIns(fire,l->things.last);
  firet=AddThinker(l,&FireThinker,"CFireThinker");
  fire->thinker=firet;
  firet->self=fire;
  firet->target=target;
  firet->vile=t->self;
  firet->end_tS=AnimationTime(t->self->animation)+Server_tS;
}

U0 SkelMissile(CDoomLevel *l,CMonsterThinker *t) {
  SpawnMissile(l,t->self,t->target,'Skel');
}
U0 Resurrect(CDoomLevel *l,CMonsterThinker *t) {
  CDoomThing *self=t->self;
  CDoomMonsterTemplate *template=self->template;
  SetState(l,t,template->see_state);
  self->flags|=TF_SHOOTABLE|TF_OBSTACLE;
  self->health=template->health;
}
U0 BrainScream(CDoomLevel *l,CMonsterThinker *t) {
  Sound(t,'Die');
  CDoomThing *self=t->self,*new;
  CMissileThinker *thinker;
  F64 ox=self->x,oy=self->y,oz=self->height;
  F64 x,y=self->y-320,z,to_x=self->x+320;
  for(x=self->x-196;x<to_x;x+=8) {
    self->x=x;
    self->y=y;
    self->height=120+Rand*(620-128);
    thinker=SpawnMissile(l,self,p,'BrainExp');
    new=thinker->self;
    new->anim_start_tS=Server_tS;
    new->anim_no_repeat=TRUE;
    new->animation=new->template->animation;
    thinker->hit=TRUE;
  }
  self->x=ox;
  self->y=oy;
  self->height=oz;
}
U0 BrainDie(CDoomLevel *l,CMonsterThinker *t) {
  l->ended=TRUE;
}
//Yvng Poop toad here(Nrootconauto)
//I am NOT messing around with the C sprite names(they dont map to real sprite names)
//#define DOOM2
U0 LoadMonsterInfo() {
  CDoomProjectileTemplate *p;
  CDoomMonsterTemplate *t;
#ifdef DOOM2
//Wolfenstein guy
  t=doom_thing_types[84];
  t->health=50;
  t->mass=100;
  t->reaction_time=1/35.*8;
  t->pain_time=1/35.*6;
  t->pain_chance=170./256;
  UH("wolfidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("wolfchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("wolfatk",t->_attack_frames=GenerateCacheFrames(t,"EFGFGF"));
  UH("wolfhurt",t->_hurt_frames=GenerateCacheFrames(t,"HH"));
  UH("wolfdie",t->_dying_frames=GenerateCacheFrames(t,"IJKLM"));
  UH("wolfxdie",t->_gib_frames=GenerateCacheFrames(t,"NOPQRSTUV"));
  UH("wolfres",t->_resurrect_frames=GenerateCacheFrames(t,"MLKJI"));
  AddState(t->spawn_state="WOLF.STND",t->reaction_time,t->_idle_frames,&Look,"WOLF.STND");
  AddState(t->see_state="WOLF.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"WOLF.S_POSS_RUN");
  AddState(t->missile_state="WOLF.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"WOLF.S_POSS_ATK2");
  AddState("WOLF.S_POSS_ATK2",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&CPosAttack,"WOLF.S_POSS_ATK2");
  AddState(t->pain_state="WOLF.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"WOLF.S_POSS_RUN");
  AddState(t->death_state="WOLF.S_POSS_DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
  AddState(t->gib_state="WOLF.S_POSS_GIB",STATE_NO_REPEAT,t->_gib_frames,&XFall,"ST_NULL");
  AddState(t->resurrect_state="WOLF.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//Icon of sin(Cube)
  UH("cube",spawn_cube=CAlloc(sizeof CDoomProjectileTemplate));
  p=spawn_cube;
  p->type=66666;
  p->flags|=TF_FLOATING;
  p->radius=6.;
  p->height=32.;
  p->speed=10.;
  StrCpy(p->spr_base_name,"BOSF");
  UH("cubeanim",p->animation=p->_idle_frames=GenerateCacheFrames(p,"ABCD"));
//spawn cube
  t=doom_thing_types[87];
  t->flags&=~(TF_MONSTER|TF_OBSTACLE);
//Boss Brain
  t=doom_thing_types[88];
  t->health=250;
  t->mass=100000;
  t->reaction_time=1/35.*8;
  t->pain_time=1/35.*36;
  t->pain_chance=1.;
  StrCpy(p->spr_base_name,"BBRN");
  UH("brainidl",t->_idle_frames=GenerateCacheFrames(p,"A"));
  UH("brainpain",t->_hurt_frames=GenerateCacheFrames(p,"AB"));
  UH("braindie",t->_dying_frames=GenerateCacheFrames(p,"AAAA"));
  AddState(t->spawn_state="BRAIN.STND",75./10.,NULL,&BrainSpit,"BRAIN.STND");
  AddState(t->pain_state="BRAIN.PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"BRAIN.STND");
  AddState(t->death_state="BRAIN.DIE1",100/30.,t->_idle_frames,&BrainScream,"BRAIN.DIE2");
  AddState("BRAIN.DIE2",0,t->_idle_frames,&BrainDie,"ST_NULL");
//
  vile_fire=CAlloc(sizeof CDoomThingTemplate);
  StrCpy(vile_fire->spr_base_name,"FIRE");
  UH("FIREt",vile_fire);
  UH("FIREa",vile_fire->_animation=GenerateCacheFrames(vile_fire,"ABABCBCBCDCDCDEDEDEFEFEFGHGHGH"));
  vile_fire->flags|=TF_FLOATING;
  vile_fire->radius=20;
  vile_fire->height=16;
//Arch vile
  t=doom_thing_types[64];
  StrCpy(t->spr_base_name,"VILE");
  UH("archidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("archchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDDEEFF"));
  UH("archmelee",t->_melee_frames=GenerateCacheFrames(t,"GGHIJKLMNOP"));
  UH("archhurt",t->_hurt_frames=GenerateCacheFrames(t,"QQ"));
  UH("archdie",t->_dying_frames=GenerateCacheFrames(t,"QRSTUVWXYZ"));
  UH("archatk",t->_attack_frames=GenerateCacheFrames(t,"GGHIJKLMNOP"));
  UH("archheal",t->_heal_frames=GenerateCacheFrames(t,"\\\\\\"));
  t->pain_time=1/35.*10;
  t->reaction_time=1/35.*8;
  t->health=700;
  t->speed=16.;
  t->mass=500;
  t->damage=5;
  t->pain_chance=10./255;
  AddState(t->spawn_state="VILE.STND",8/10.,t->_idle_frames,&Look,"VILE.STND");
  AddState(t->see_state="VILE.CHASE",t->reaction_time/4.,t->_chase_frames,&VileChase,"VILE.CHASE");
  AddState(t->missile_state="VILE.ATK1",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&VileAttack,"VILE.CHASE");
  AddState(t->pain_state="VILE.PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"VILE.CHASE");
  AddState(t->heal_state="VILE.HEAL",STATE_UNTIL_ANIM_DONE,t->_heal_frames,NULL,"VILE.CHASE");
  AddState(t->death_state="VILE.DEAD",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
//
  UH("skjelball",skel_missile=CAlloc(sizeof CDoomProjectileTemplate));
  p=skel_missile;
  p->type=35;
  p->flags|=TF_FLOATING;
  p->radius=11.;
  p->height=8.;
  p->direct=10; //5 min,40 max
  p->direct_max=80;
  p->speed=350./30;
  StrCpy(p->spr_base_name,"FATB");
  UH("skelmidle",p->animation=p->_idle_frames=GenerateCacheFrames(p,"AB"));
  StrCpy(p->spr_base_name,"FATE"); //Eploding sprite
  UH("skemhit",p->_hit_frames=GenerateCacheFrames(p,"ABC"));
//Revenant
  t=doom_thing_types[66];
  StrCpy(t->spr_base_name,"SKEL");
  UH("revidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("revchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDDEEFF"));
  UH("revatk",t->_attack_frames=GenerateCacheFrames(t,"JJKK"));
  UH("revatkm",t->_melee_frames=GenerateCacheFrames(t,"GGHI"));
  UH("revhurt",t->_hurt_frames=GenerateCacheFrames(t,"LL"));
  UH("revdie",t->_dying_frames=GenerateCacheFrames(t,"LMNOPQ"));
  UH("revres",t->_resurrect_frames=GenerateCacheFrames(t,"QPONML"));
  t->pain_time=1/35.*10;
  t->reaction_time=1/35.*8;
  t->health=300;
  t->speed=8.;
  t->mass=4000;
  t->damage=5;
  t->pain_chance=100./255;
  AddState(t->spawn_state="SKEL.S_POSS_STND",8/10.,t->_idle_frames,&Look,"SKEL.S_POSS_STND");
  AddState(t->see_state="SKEL.S_POSS_RUN0",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"SKEL.S_POSS_RUN0");
  AddState(t->missile_state="SKEL.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"SKEL.S_POSS_ATK1");
  AddState("SKEL.S_POSS_ATK1",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&SkelMissile,"SKEL.S_POSS_RUN0");
  AddState(t->pain_state="SKEL.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"SKEL.S_POSS_RUN0");
  AddState(t->death_state="SKEL.DEAD",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
  AddState(t->melee_state="SKEL.S_POSS_MELE1",0,t->_melee_frames,&FaceTarget,"SKEL.S_POSS_MELE2");
  AddState("SKEL.S_POSS_MELE2",0,t->_melee_frames,&SkelWhoosh,"SKEL.S_POSS_MELE3");
  AddState("SKEL.S_POSS_MELE3",0,t->_melee_frames,&FaceTarget,"SKEL.S_POSS_MELE4");
  AddState("SKEL.S_POSS_MELE4",STATE_UNTIL_ANIM_DONE,t->_melee_frames,&SkelFist,"SKEL.S_POSS_RUN0");
  AddState(t->resurrect_state="SKEL.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//Pain elemental 
  t=doom_thing_types[71];
  StrCpy(t->spr_base_name,"PAIN");
  UH("painiidle",t->_idle_frames=GenerateCacheFrames(t,"A"));
  UH("painchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCC"));
  UH("painatk",t->_attack_frames=GenerateCacheFrames(t,"DEFF"));
  UH("painhurt",t->_hurt_frames=GenerateCacheFrames(t,"GG"));
  UH("paindie",t->_dying_frames=GenerateCacheFrames(t,"HIJKLM"));
  t->pain_time=1/35.*4;
  t->reaction_time=1/35.*8;
  t->health=600;
  t->speed=8.;
  t->mass=4000;
  t->damage=5;
  t->pain_chance=128./255;
  AddState(t->spawn_state="PAIN.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"PAIN.S_POSS_STND");
  AddState(t->see_state="PAIN.S_POSS_RUN0",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"PAIN.S_POSS_RUN0");
  AddState(t->missile_state="PAIN.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"PAIN.S_POSS_ATK2");
  AddState("PAIN.S_POSS_ATK2",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&PainAttack,"PAIN.S_POSS_RUN0");
  AddState(t->pain_state="PAIN.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"PAIN.S_POSS_RUN0");
  AddState(t->death_state="PAIN.DEAD",STATE_NO_REPEAT,t->_dying_frames,&Fall,"PAIN.DEAD2");
  AddState("PAIN.DEAD2",STATE_NO_REPEAT,t->_dying_frames,&Vanish,"ST_NULL");
  //Hell knight
  t=doom_thing_types[69];
  StrCpy(t->spr_base_name,"BOS2");
  UH("helliidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("hellchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("hellatk",t->_attack_frames=GenerateCacheFrames(t,"EFG"));
  UH("hellatk2",t->_melee_frames=GenerateCacheFrames(t,"EFG"));
  UH("hellhurt",t->_hurt_frames=GenerateCacheFrames(t,"HH"));
  UH("helldie",t->_dying_frames=GenerateCacheFrames(t,"IJKLMNO"));
  UH("hellres",t->_resurrect_frames=GenerateCacheFrames(t,"ONMLKJI"));
  t->pain_time=1/35.*4;
  t->reaction_time=1/35.*8;
  t->health=600;
  t->speed=8.;
  t->mass=1000;
  t->damage=5;
  t->pain_chance=50./255;
  AddState(t->spawn_state="HELL.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"HELL.S_POSS_STND");
  AddState(t->see_state="HELL.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"HELL.S_POSS_RUN");
  AddState(t->missile_state="HELL.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"HELL.S_POSS_ATK2");
  AddState(t->missile_state="HELL.S_POSS_ATK2",0,t->_idle_frames,&FaceTarget,"HELL.S_POSS_ATK3");
  AddState("HELL.S_POSS_ATK3",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&BarronOfHellAttack,"HELL.S_POSS_RUN");
  AddState(t->pain_state="HELL.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"HELL.S_POSS_RUN");
  AddState(t->death_state="HELL.S_POSS_DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
  AddState(t->resurrect_state="HELL.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//Mancubus ball
  UH("manball",mancubus_fireball=CAlloc(sizeof CDoomProjectileTemplate));
  p=mancubus_fireball;;
  p->flags|=TF_FLOATING;
  p->speed=700/30.;
  p->direct=8;
  p->radius=6.;
  p->height=8.;
  p->splash=128.;
  StrCpy(p->spr_base_name,"MANF");
  UH("manballidle",p->animation=p->_idle_frames=GenerateCacheFrames(p,"AB"));
  StrCpy(p->spr_base_name,"MISL");
  UH("manballhit",p->_hit_frames=GenerateCacheFrames(p,"BCD"));
//MAncubus
  t=doom_thing_types[67];
  StrCpy(t->spr_base_name,"FATT");
  UH("fatiidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("fatichase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDDEEFF"));
  UH("fatiatk",t->_attack_frames=GenerateCacheFrames(t,"GHIGHIGHIG"));
  UH("fatihurt",t->_hurt_frames=GenerateCacheFrames(t,"JJ"));
  UH("fatdie",t->_dying_frames=GenerateCacheFrames(t,"KLMNOPQRST"));
  UH("fatres",t->_resurrect_frames=GenerateCacheFrames(t,"RQPONMLK"));
  t->pain_time=1/35.*6;
  t->reaction_time=1/35.*8;
  t->health=600;
  t->speed=8.;
  t->mass=1000;
  t->damage=5;
  t->pain_chance=80./255;
  AddState(t->spawn_state="FATT.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"FATT.S_POSS_STND");
  AddState(t->see_state="FATT.S_POSS_RUN0",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"FATT.S_POSS_RUN0");
  AddState(t->missile_state="FATT.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"FATT.S_POSS_ATK1");
  AddState("FATT.S_POSS_ATK1",1/10.,t->_attack_frames,&FatAttack1,"FATT.S_POSS_ATK2");
  AddState("FATT.S_POSS_ATK2",1/10.,t->_attack_frames,&FaceTarget,"FATT.S_POSS_ATK3");
  AddState("FATT.S_POSS_ATK3",1/10.,t->_attack_frames,&FaceTarget,"FATT.S_POSS_ATK4");
  AddState("FATT.S_POSS_ATK4",1/10.,t->_attack_frames,&FatAttack2,"FATT.S_POSS_ATK5");
  AddState("FATT.S_POSS_ATK5",1/10.,t->_attack_frames,&FaceTarget,"FATT.S_POSS_ATK6");
  AddState("FATT.S_POSS_ATK6",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&FatAttack3,"FATT.S_POSS_RUN0");
  AddState(t->pain_state="FATT.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"FATT.S_POSS_RUN0");
  AddState(t->death_state="FATT.DEAD",0,t->_dying_frames,&Scream,"FATT.DEAD2");
  AddState("FATT.DEAD2",STATE_NO_REPEAT,t->_dying_frames,&Fall,"FATT.DEAD3");
  AddState("FATT.DEAD3",STATE_NO_REPEAT,t->_dying_frames,&BossDeath,"ST_NULL");
  AddState(t->resurrect_state="FATT.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//Baby Spider
  t=doom_thing_types[68];
  StrCpy(t->spr_base_name,"BSPI");
  UH("bspiidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("bspichase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDDEEFF"));
  UH("bspiatk",t->_attack_frames=GenerateCacheFrames(t,"GHH"));
  UH("bspihurt",t->_hurt_frames=GenerateCacheFrames(t,"II"));
  UH("bspidie",t->_dying_frames=GenerateCacheFrames(t,"JKLMNOP"));
  UH("bspres",t->_resurrect_frames=GenerateCacheFrames(t,"PONMLKJ"));
  t->pain_time=1/35.*6;
  t->reaction_time=1/35.*8;
  t->health=500;
  t->speed=12.;
  t->mass=600;
  t->damage=5;
  t->pain_chance=128./255;
  AddState(t->spawn_state="BSPI.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"BSPI.S_POSS_STND");
  AddState(t->see_state="BSPI.S_POSS_RUN0",t->reaction_time/2,t->_chase_frames,&Chase,"BSPI.S_POSS_RUN0");
  AddState("BSPI.S_POSS_RUN1",t->reaction_time/2,t->_chase_frames,&Chase,"BSPI.S_POSS_RUN2");
  AddState("BSPI.S_POSS_RUN2",0,t->_chase_frames,&BabyMetal,"BSPI.S_POSS_RUN3");
  AddState("BSPI.S_POSS_RUN3",t->reaction_time/2,t->_chase_frames,&Chase,"BSPI.S_POSS_RUN0");
  AddState(t->missile_state="BSPI.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"BSPI.S_POSS_ATK2");
  AddState("BSPI.S_POSS_ATK2",1/3.,t->_attack_frames,&BabyAttack,"BSPI.S_POSS_ATK3");
  AddState("BSPI.S_POSS_ATK3",1/3.,t->_attack_frames,&BabyRefire,"BSPI.S_POSS_ATK2");
  AddState(t->pain_state="BSPI.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"BSPI.S_POSS_RUN0");
  AddState(t->death_state="BSPI.DEAD",0,t->_dying_frames,&Fall,"BSPI.DEAD2");
  AddState("BSPI.DEAD2",STATE_NO_REPEAT,t->_dying_frames,&BossDeath,"ST_NULL");
  AddState(t->resurrect_state="BSPI.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//Chaingun guy
  t=doom_thing_types[65];
  StrCpy(t->spr_base_name,"CPOS");
  UH("cgres",t->_resurrect_frames=GenerateCacheFrames(t,"NMLKJIH"));
  UH("cgidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("cgchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("cgattack",t->_attack_frames=GenerateCacheFrames(t,"EFEF"));
  UH("cgdhurt",t->_hurt_frames=GenerateCacheFrames(t,"GG"));
  UH("cgdying",t->_dying_frames=GenerateCacheFrames(t,"HIJKLMN"));
  UH("cggib",t->_gib_frames=GenerateCacheFrames(t,"OPQRST"));
  t->health=70;
  t->mass=100;
  t->pain_chance=170/256.;
  t->pain_time=1/35.*6;
  t->damage=3;
  t->reaction_time=1/35.*8;
  t->speed=8;
  AddState(t->spawn_state="CPOS.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"CPOS.S_POSS_STND");
  AddState(t->see_state="CPOS.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"CPOS.S_POSS_RUN");
  AddState(t->resurrect_state="CPOS.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_chase_frames,&Resurrect,"CPOS.S_POSS_RUN");
  AddState(t->missile_state="CPOS.S_POSS_ATK2",1/2.5,t->_attack_frames,&CPosAttack,"CPOS.S_POSS_ATK2");
  AddState(t->pain_state="CPOS.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"CPOS.S_POSS_RUN");
  AddState(t->death_state="CPOS.S_POSS_DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
  AddState(t->gib_state="CPOS.S_POSS_GIB",STATE_NO_REPEAT,t->_gib_frames,&XFall,"ST_NULL");
#endif
//Player
  t=doom_thing_types[1];
  UH("plyidle",t->_idle_frames=GenerateCacheFrames(t,"A"));
  UH("plychase",t->_chase_frames=GenerateCacheFrames(t,"ABCD"));
  UH("plyatk",t->_attack_frames=GenerateCacheFrames(t,"EF"));
  UH("plyhurt",t->_hurt_frames=GenerateCacheFrames(t,"GG"));
  UH("plydie",t->_dying_frames=GenerateCacheFrames(t,"HIJKLMN"));
  UH("plyohfuck",t->_gib_frames=GenerateCacheFrames(t,"OPQRSTUVW"));

  //https://doomwiki.org/wiki/Barrel
  t=doom_thing_types[2035];
  t->mass=100.;
  t->health=20;
  t->_idle_frames=t->_animation;
  StrCpy(t->spr_base_name,"BEXP");
  UH("barrelDIE",t->_dying_frames=GenerateCacheFrames(t,"ABCDE"));
  //https://doomwiki.org/wiki/Imp
  AddState("ST_NULL",0.,NULL,&NullState,"ST_NULL");
  t=doom_thing_types[0xbb9];
  UH("impidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("impchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("impmelee",t->_melee_frames=GenerateCacheFrames(t,"EFG"));
  UH("impatk",t->_attack_frames=GenerateCacheFrames(t,"EFG"));
  UH("imphurt",t->_hurt_frames=GenerateCacheFrames(t,"HH"));
  UH("impdie",t->_dying_frames=GenerateCacheFrames(t,"IJKLM"));
  UH("impohfuck",t->_gib_frames=GenerateCacheFrames(t,"NOPQRSTU"));
  t->pain_time=1/35.*4;
  t->reaction_time=1/35.*8;
  t->health=60;
  t->speed=8.;
  t->mass=100;
  t->damage=3;
  t->pain_chance=200./255;
  AddState(t->spawn_state="IMP.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"IMP.S_POSS_STND");
  AddState(t->see_state="IMP.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"IMP.S_POSS_RUN");
  AddState(t->missile_state="IMP.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"IMP.S_POSS_ATK2");
  AddState("IMP.S_POSS_ATK2",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&TroopAttack,"IMP.S_POSS_RUN");
  AddState(t->pain_state="IMP.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"IMP.S_POSS_RUN");
  AddState(t->death_state="IMP.S_POSS_DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
  AddState(t->gib_state="IMP.S_POSS_GIB",STATE_NO_REPEAT,t->_gib_frames,&XFall,"ST_NULL");
  AddState(t->resurrect_state="IMP.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//BFG blast
  UH("bfgball",bfg_ball=CAlloc(sizeof CDoomProjectileTemplate));
  p=bfg_ball;
  p->type=35;
  p->flags|=TF_FLOATING;
  p->radius=13.;
  p->height=8.;
  p->direct=100; //5 min,40 max
  p->direct_max=800;
  p->speed=875./30;
  StrCpy(p->spr_base_name,"BFS1");
  UH("bfgidle",p->animation=p->_idle_frames=GenerateCacheFrames(p,"AB"));
  StrCpy(p->spr_base_name,"PLE1"); //Eploding sprite
  UH("bfghit",p->_hit_frames=GenerateCacheFrames(p,"ABCDEF"));
//Plasma shot
  UH("plasma",plasma_ball=CAlloc(sizeof CDoomProjectileTemplate));
  p=plasma_ball;
  p->type=34;
  p->flags|=TF_FLOATING;
  p->radius=13.;
  p->height=8.;
  p->direct=5.; //5 min,40 max
  p->direct_max=40.;
  p->speed=875./30;
  StrCpy(p->spr_base_name,"PLSS");
  UH("plasmaidle",p->animation=p->_idle_frames=GenerateCacheFrames(p,"AB"));
  StrCpy(p->spr_base_name,"PLSE"); //Eploding sprite
  UH("plasmahit",p->_hit_frames=GenerateCacheFrames(p,"ABCDE"));
//Fireball and I aint talkin alchohol
  UH("impfire",imp_fireball=CAlloc(sizeof CDoomProjectileTemplate));
  p=imp_fireball;
  p->flags|=TF_FLOATING;
  p->direct=3;
  p->speed=350/30.;
  p->radius=6.;
  p->height=8.;
  StrCpy(p->spr_base_name,"BAL1");
  UH("impfireidle",p->animation=p->_idle_frames=GenerateCacheFrames(p,"AB"));
  UH("impfirehit",p->_hit_frames=GenerateCacheFrames(p,"CDE"));
//https://doomwiki.org/wiki/Baron_of_Hell
  t=doom_thing_types[0xbbb];
  t->pain_time=1/35.*4;
  t->reaction_time=1/35.*8;
  t->health=1000;
  t->damage=10;
  t->pain_chance=16.8/100.;
  t->speed=8.; //TODO check it
  t->mass=1000.;
  UH("baronidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("baronchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("baronmelee",t->_melee_frames=GenerateCacheFrames(t,"EFG"));
  UH("baronatk",t->_attack_frames=GenerateCacheFrames(t,"EFG"));
  UH("baronhurt",t->_hurt_frames=GenerateCacheFrames(t,"HH"));
  UH("barondie",t->_dying_frames=GenerateCacheFrames(t,"IJKLM"));
  UH("baronohfuck",t->_gib_frames=GenerateCacheFrames(t,"NOPQRSTU"));
  AddState(t->spawn_state="BARON.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"BARON.S_POSS_STND");
  AddState(t->see_state="BARON.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"BARON.S_POSS_RUN");
  AddState(t->missile_state="BARON.S_POSS_ATK2",0,t->_idle_frames,&FaceTarget,"BARON.S_POSS_ATK3");
  AddState("BARON.S_POSS_ATK3",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&BarronOfHellAttack,"BARON.S_POSS_RUN");
  AddState(t->pain_state="BARON.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"BARON.S_POSS_RUN");
  AddState(t->death_state="BARON.S_POSS_DIE",STATE_UNTIL_ANIM_DONE,t->_idle_frames,&Fall,"BARON.S_POSS_DIE2");
  AddState("BARON.S_POSS_DIE2",STATE_NO_REPEAT,t->_dying_frames,&BossDeath,"ST_NULL");
//Booger ball
  UH("baronfb",baron_fireball=CAlloc(sizeof CDoomProjectileTemplate));
  p=baron_fireball;
  p->flags|=TF_FLOATING;
  p->speed=525/30.;
  p->direct=8;
  p->radius=6.;
  p->height=8.;
  StrCpy(p->spr_base_name,"BAL7");
  UH("boogeridle",p->animation=p->_idle_frames=GenerateCacheFrames(p,"AB"));
  UH("boogerihit",p->_hit_frames=GenerateCacheFrames(p,"CDE"));
//Flying meatball
  t=doom_thing_types[0xbbd];
  t->pain_time=1/35.*6;
  t->reaction_time=1/35.*8;
  t->health=400.;
  t->speed=8.;
  t->mass=400;
  t->radius=31;
  t->pain_chance=.50;
  UH("cacoidle",t->_idle_frames=GenerateCacheFrames(t,"A"));
  UH("cacochase",t->_chase_frames=GenerateCacheFrames(t,"A"));
  UH("cacomele",t->_melee_frames=GenerateCacheFrames(t,"BCD"));
  UH("cacoatk",t->_attack_frames=GenerateCacheFrames(t,"BCD"));
  UH("cacohurt",t->_hurt_frames=GenerateCacheFrames(t,"BCD"));
  UH("cacdie",t->_dying_frames=GenerateCacheFrames(t,"GHIJKL"));
//Kako in greek
  AddState(t->spawn_state="CACO.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"CACO.S_POSS_STND");
  AddState(t->see_state="CACO.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"CACO.S_POSS_RUN");
  AddState(t->missile_state="CACO.S_POSS_ATK1",t->reaction_time,t->_idle_frames,&FaceTarget,"CACO.S_POSS_ATK2");
  AddState(t->missile_state="CACO.S_POSS_ATK2",t->reaction_time,t->_idle_frames,&FaceTarget,"CACO.S_POSS_ATK3");
  AddState("CACO.S_POSS_ATK3",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&CacodemonAttack,"CACO.S_POSS_RUN");
  AddState(t->pain_state="CACO.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"CACO.S_POSS_RUN");
  AddState(t->death_state="CACO.S_POSS_DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
//Cacodemon ball
  UH("kakoballw",cacodemon_fireball=CAlloc(sizeof CDoomProjectileTemplate));
  p=cacodemon_fireball;
  p->flags|=TF_FLOATING;
  p->speed=350/35.;;
  p->direct=5;
  p->radius=6.;
  p->height=8.;
  StrCpy(p->spr_base_name,"BAL2");
  UH("kakoboogeridle",p->animation=p->_idle_frames=GenerateCacheFrames(p,"AB"));
  UH("kakoboogerhit",p->_hit_frames=GenerateCacheFrames(p,"CDE"));
//Rocket
  UH("rocket",rocket=CAlloc(sizeof CDoomProjectileTemplate));
  p=rocket;
  p->type=33;
  p->flags|=TF_FLOATING;
  p->direct=20.;
  p->splash=128.;
  p->radius=11.;
  p->speed=700./30.;
  p->height=8.;
  StrCpy(p->spr_base_name,"MISL");
  UH("rocketidle",p->animation=p->_idle_frames=GenerateCacheFrames(p,"A"));
  UH("rockethit",p->_hit_frames=GenerateCacheFrames(p,"BCD"));
//Brain expliosion
  UH("brainexp",brain_explosion=CAlloc(sizeof CDoomProjectileTemplate));
  p=brain_explosion;
  p->flags|=TF_FLOATING;
  StrCpy(p->spr_base_name,"MISL");
  UH("brainexphit",p->animation=p->_hit_frames=GenerateCacheFrames(p,"BCD"));

//Pink demon
  t=doom_thing_types[0xbba];
  t->reaction_time=1/35.*8;
  t->pain_time=1/35.*4;
  t->health=150.;
  t->speed=10.;
  t->mass=400.;
  t->damage=4;
  t->pain_chance=180./255.;
  UH("pinkidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("pinkchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("pinkmelee",t->_melee_frames=GenerateCacheFrames(t,"EFG"));
  UH("pinkatk",t->_attack_frames=GenerateCacheFrames(t,"EFG"));
  UH("pinkhurt",t->_hurt_frames=GenerateCacheFrames(t,"HH"));
  UH("pinkdie",t->_dying_frames=GenerateCacheFrames(t,"IJKLMN"));
  UH("pinkres",t->_resurrect_frames=GenerateCacheFrames(t,"NMLKJI"));
  AddState(t->spawn_state="PANKY.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"PANKY.S_POSS_STND");
  AddState(t->see_state="PANKY.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"PANKY.S_POSS_RUN");
  AddState(t->melee_state="PANKY.S_POSS_ATK1",t->reaction_time,t->_idle_frames,&FaceTarget,"PANKY.S_POSS_ATK2");
  AddState("PANKY.S_POSS_ATK2",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&SargAttack,"PANKY.S_POSS_RUN");
  AddState(t->pain_state="PANKY.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"PANKY.S_POSS_RUN");
  AddState(t->death_state="PANKY.S_POSS_DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
  AddState(t->resurrect_state="PANKY.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//Skull demon
  t=doom_thing_types[0xbbe];
  t->reaction_time=1/35.*8;
  t->pain_time=1/35.*6;
  t->health=100.;
  t->speed=8.;
  t->skull_attack_speed=20.;
  t->mass=50.;
  t->pain_chance=1;
  t->damage=3.;
  UH("skullidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("skullchase",t->_chase_frames=GenerateCacheFrames(t,"AB"));
  UH("skullmele",t->_melee_frames=GenerateCacheFrames(t,"CDCD"));
  UH("skullatk",t->_attack_frames=GenerateCacheFrames(t,"CDCD"));
  UH("skullhurt",t->_hurt_frames=GenerateCacheFrames(t,"EE"));
  UH("skulldie",t->_dying_frames=GenerateCacheFrames(t,"FGHIJK"));
  AddState(t->spawn_state="SKULL.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"SKULL.S_POSS_STND");
  AddState(t->see_state="SKULL.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"SKULL.S_POSS_RUN");
  AddState(t->missile_state="SKULL.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"SKULL.S_POSS_ATK2");
  AddState(t->missile_state="SKULL.S_POSS_ATK2",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&SkullAttack,"SKULL.S_POSS_RUN");
  AddState(t->pain_state="SKULL.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"SKULL.S_POSS_RUN");
  AddState(t->death_state="SKULL.S_POSS_DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,NULL);
//Shotgun guy
  t=doom_thing_types[9];
  t->reaction_time=1/35.*8;
  t->pain_time=1/35.*6;
  t->health=30;
  t->speed=8;
  t->mass=100;
  t->damage=3;
  t->pain_chance=170./255.;
  UH("shotidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("shotchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("shotmele",t->_melee_frames=GenerateCacheFrames(t,"EFE"));
  UH("shotatk",t->_attack_frames=GenerateCacheFrames(t,"EFE"));
  UH("shotdie",t->_dying_frames=GenerateCacheFrames(t,"HIJKL"));
  UH("shothurt",t->_hurt_frames=GenerateCacheFrames(t,"GG"));
  UH("shotgib",t->_gib_frames=GenerateCacheFrames(t,"MNOPQRSTU"));
  UH("shotres",t->_resurrect_frames=GenerateCacheFrames(t,"LKJIH"));

  AddState(t->spawn_state="SHOTGUN.S_POSS_STND",STATE_UNTIL_ANIM_DONE,t->_idle_frames,&Look,"SHOTGUN.S_POSS_STND");
  AddState(t->see_state="SHOTGUN.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"SHOTGUN.S_POSS_RUN");
  AddState(t->missile_state="SHOTGUN.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"SHOTGUN.S_POSS_ATK2");
  AddState("SHOTGUN.S_POSS_ATK2",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&SPosAttack,"SHOTGUN.S_POSS_RUN");
  AddState(t->pain_state="SHOTGUN.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"SHOTGUN.S_POSS_RUN");
  AddState(t->death_state="SHOTGUN.S_POSS_DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
  AddState(t->gib_state="SHOTGUN.S_POSS_GIB",STATE_NO_REPEAT,t->_gib_frames,&XFall,"ST_NULL");
  AddState(t->resurrect_state="SPOSS.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//Transparent demon
  t=doom_thing_types[0x3a];
  t->reaction_time=1/35.*8;
  t->pain_time=1/35.*4;
  t->health=150;
  t->speed=10;
  t->mass=400.;
  t->pain_chance=180./255.;
  t->damage=4.;
  UH("specidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("specchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("specmele",t->_melee_frames=GenerateCacheFrames(t,"EFG"));
  UH("specatk",t->_attack_frames=GenerateCacheFrames(t,"EFG"));
  UH("spechurt",t->_hurt_frames=GenerateCacheFrames(t,"HH"));
  UH("specdie",t->_dying_frames=GenerateCacheFrames(t,"IJKLMN"));
  UH("specres",t->_resurrect_frames=GenerateCacheFrames(t,"NMLKJI"));

  AddState(t->spawn_state="TRANS.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"TRANS.S_POSS_STND");
  AddState(t->see_state="TRANS.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"TRANS.S_POSS_RUN");
  AddState(t->melee_state="TRANS.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"TRANS.S_POSS_ATK2");
  AddState("TRANS.S_POSS_ATK2",10,t->_idle_frames,&SargAttack,"TRANS.S_POSS_RUN");
  AddState(t->pain_state="TRANS.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"TRANS.S_POSS_RUN");
  AddState(t->death_state="TRANS.S_POSS_DIE",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Fall,"TRANS.S_POSS_DIE2");
  AddState("TRANS.S_POSS_DIE2",STATE_NO_REPEAT,t->_dying_frames,NULL,"ST_NULL");
  AddState(t->resurrect_state="TRANS.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//Scrotum spider
  t=doom_thing_types[0x7];
  t->reaction_time=1/35.*8;
  t->pain_time=1/35.*6;
  t->health=3000;
  t->speed=12;
  t->mass=1000;
  t->pain_chance=40/255.;
  t->damage=3;
  UH("spididle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("spidchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDDEEFF"));
  UH("spidmele",t->_melee_frames=GenerateCacheFrames(t,"GHH"));
  UH("spidatk",t->_attack_frames=GenerateCacheFrames(t,"GHHH"));
  UH("spidhurt",t->_hurt_frames=GenerateCacheFrames(t,"II"));
  UH("spiddie",t->_dying_frames=GenerateCacheFrames(t,"JKLMNOPQRSS"));
  AddState(t->spawn_state="SPIDER_LOOK",10/35.,t->_idle_frames,&Look,"SPIDER_LOOK");
  AddState(t->see_state="SPIDER.RUN1",3/35.,t->_chase_frames,&Metal,"SPIDER.RUN2");
  AddState("SPIDER.RUN2",9/35.,t->_chase_frames,&Chase,"SPIDER.RUN1");
  AddState(t->missile_state="SPIDER.ATK1",3/35.*4,t->_attack_frames,&FaceTarget,"SPIDER.ATK2");
  AddState("SPIDER.ATK2",4/35.*4,t->_attack_frames,&SPosAttack,"SPIDER.ATK3");
  AddState("SPIDER.ATK3",4/35.*4,t->_attack_frames,&SPosAttack,"SPIDER.ATK4");
  AddState("SPIDER.ATK4",1/35.*4,t->_attack_frames,&SpidRefire,"SPIDER.ATK1");
  AddState(t->death_state="SPIDER.DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,"SPIDER.DIE2");
  AddState("SPIDER.DIE2",0,t->_dying_frames,&BossDeath,"ST_NULL");

//Zombieman
  t=doom_thing_types[0xbbc];
  t->reaction_time=1/35.*8;
  t->pain_time=1/35.*6;
  t->health=20;
  t->speed=8;
  t->mass=100;
  t->pain_chance=200/255.;
  UH("zomidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("zomchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("zommele",t->_melee_frames=GenerateCacheFrames(t,"EFE"));
  UH("zomatk",t->_attack_frames=GenerateCacheFrames(t,"EFE"));
  UH("zomhurt",t->_hurt_frames=GenerateCacheFrames(t,"GG"));
  UH("zomdie",t->_dying_frames=GenerateCacheFrames(t,"HIJKL"));
  UH("zomdxdie",t->_gib_frames=GenerateCacheFrames(t,"MNOPQRSTU"));
  UH("zombres",t->_resurrect_frames=GenerateCacheFrames(t,"KJIH"));
  AddState(t->spawn_state="ZOMBIE.S_POSS_STND",t->reaction_time,t->_idle_frames,&Look,"ZOMBIE.S_POSS_STND");
  AddState(t->see_state="ZOMBIE.S_POSS_RUN",STATE_UNTIL_DONE_WALKING,t->_chase_frames,&Chase,"ZOMBIE.S_POSS_RUN");
  AddState(t->missile_state="ZOMBIE.S_POSS_ATK1",0,t->_idle_frames,&FaceTarget,"ZOMBIE.S_POSS_ATK2");
  AddState("ZOMBIE.S_POSS_ATK2",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&PosAttack,"ZOMBIE.S_POSS_RUN");
  AddState(t->pain_state="ZOMBIE.S_POSS_PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"ZOMBIE.S_POSS_RUN");
  AddState(t->death_state="ZOMBIE.S_POSS_DIE",STATE_NO_REPEAT,t->_dying_frames,&Fall,"ST_NULL");
  AddState(t->gib_state="ZOMBIE.S_POSS_GIB",STATE_NO_REPEAT,t->_gib_frames,&XFall,"ST_NULL");
  AddState(t->resurrect_state="ZOMBIE.RESURRECT",STATE_UNTIL_ANIM_DONE,t->_resurrect_frames,&Resurrect,t->see_state);
//Cyber demon
  t=doom_thing_types[16];
  t->reaction_time=8*1/35.;
  t->pain_time=20*1/35.;
  t->mass=1000;
  t->health=4000;
  t->speed=16;
  t->pain_chance=20./255;
  UH("cyberidle",t->_idle_frames=GenerateCacheFrames(t,"AB"));
  UH("cyberchase",t->_chase_frames=GenerateCacheFrames(t,"AABBCCDD"));
  UH("cyberattack",t->_attack_frames=GenerateCacheFrames(t,"EF"));
  UH("cyberhurt",t->_hurt_frames=GenerateCacheFrames(t,"G"));
  UH("cyberdying",t->_dying_frames=GenerateCacheFrames(t,"HIJKLMNOPP"));
  AddState(t->spawn_state="CYBER.STND",t->reaction_time,t->_idle_frames,&Look,"CYBER.STND");
  AddState(t->see_state="CYBER.RUN1",t->reaction_time/4,t->_chase_frames,&Hoof,"CYBER.RUN2");
  AddState("CYBER.RUN2",t->reaction_time,t->_chase_frames,&Chase,"CYBER.RUN3");
  AddState("CYBER.RUN3",t->reaction_time,t->_chase_frames,&Chase,"CYBER.RUN4");
  AddState("CYBER.RUN4",0,t->_chase_frames,&Metal,"CYBER.RUN1");
  AddState(t->missile_state="CYBER.ATK1",3,t->_chase_frames,&FaceTarget,"CYBER.ATK2");
  AddState("CYBER.ATK2",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&CyberAttack,"CYBER.ATK3");
  AddState("CYBER.ATK3",0,t->_attack_frames,&FaceTarget,"CYBER.ATK4");
  AddState("CYBER.ATK4",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&CyberAttack,"CYBER.ATK5");
  AddState("CYBER.ATK5",0,t->_attack_frames,&FaceTarget,"CYBER.ATK6");
  AddState("CYBER.ATK6",STATE_UNTIL_ANIM_DONE,t->_attack_frames,&CyberAttack,"CYBER.RUN1");
  AddState(t->death_state="CYBER.DIE",STATE_UNTIL_ANIM_DONE,t->_dying_frames,&Fall,"CYBER.DIE2");
  AddState("CYBER.DIE2",STATE_NO_REPEAT,t->_dying_frames,&BossDeath,"ST_NULL");
  AddState(t->pain_state="CYBER.PAIN",STATE_UNTIL_ANIM_DONE,t->_hurt_frames,&Pain,"CYBER.RUN1");
//BFG scaner hit
  UH("bfgfizzle",bfg_scanner_hit=CAlloc(sizeof CDoomThingTemplate));
  p=bfg_scanner_hit;
  p->flags|=TF_FLOATING;
  p->radius=13.;
  StrCpy(p->spr_base_name,"BFE2");
  UH("bfgfizzlean",p->_animation=GenerateCacheFrames(p,"ABCD"));
};

LoadMonsterInfo;
class CBFGScannerThinker:CDoomThinkerBase {
  CDoomThing *who_fired;
  F64 start_at;
  F64 angle;
};
class CBFGPuffThinker:CDoomThinkerBase {
  CDoomThing *self;
  F64 start_tS;
};
U0 BFGPuffThinker(CDoomLevel *l,CBFGPuffThinker *puff) {
  CDoomThing *self=puff->self;
  if(Server_tS-puff->start_tS>=AnimationTime(self->animation)) {
    ThingDel(l,self);
    QueRem(puff);
    Free(puff);
  }
}
U0 BFGThinker(CDoomLevel *l,CBFGScannerThinker *bfg) {
  if(bfg->start_at>Server_tS)
    return;
  CDoomThing *hit;
  CDoomThing *fizzle;
  CBFGPuffThinker *puff;
  I64 scan;
  F64 angle=bfg->angle-pi/180.*45/2.;
  for(scan=0;scan!=40;scan++) {
    if(hit=LineAttack(l,bfg->who_fired,NULL,1024,angle,Rand*(87-49)+49,LA_TYPE_INVISIBLE)) {
      fizzle=CAlloc(sizeof(CDoomThing),doom_task);
      fizzle->x=hit->x;
      fizzle->y=hit->y;
      fizzle->height=hit->height+hit->template->height/2.;
      fizzle->anim_no_repeat=TRUE;
      fizzle->template=bfg_scanner_hit;
      QueIns(fizzle,l->things.last);
      puff=AddThinker(l,&BFGPuffThinker,"CBFGPuffThinker");
      puff->self=fizzle;
      puff->start_tS=Server_tS;
      InitPosDataForThing(l,fizzle);
      fizzle->anim_start_tS=Server_tS;
    }
    angle+=pi/180.*45/40.;
  }
  QueRem(bfg);
  Free(bfg);
}
U0 AddBFGTracers(CDoomLevel *l,CDoomPlayer *p) {
  CBFGScannerThinker *t=AddThinker(l,&BFGThinker,"CBFGScannerThinker");
  t->who_fired=p;
  t->start_at=Server_tS+16.*1/30.;
  t->angle=p->angle;
}