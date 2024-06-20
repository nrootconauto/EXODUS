

U0 PlayerMove(CDoomLevel *l,CDoomPlayer *p,F64 dir=1,F64 angle=0) {
  F64 speed=dir;
  if(p->running) speed*=20.;
  else speed*=9.;
  angle+=p->angle;
  CFifoI64 *crossed_f=FifoI64New(16);
  CDoomSector *s=GetSectorForCoord(l,p->x,p->y);
  CDoomLinedef *crossed;
  CDoomLinedef *hit=MoveThingFinal(l,p,angle,speed,COLLISF_NO_HIT_THING|COLLISF_SLIDE|COLLISF_ADJUST_FOR_RADIUS,crossed_f,p);
  while(FifoI64Rem(crossed_f,&crossed)) {
    ClientTriggerLinedef(l,crossed,WACTIVATE_WALK,p);
  }
//Walking includes "walking into a wall"?
  if(hit) ClientTriggerLinedef(l,hit,WACTIVATE_PUSH|WACTIVATE_WALK,p);
  FifoI64Del(crossed_f);
  if(s&&s->special_type==9) {
    s->special_type=0;
    ++l->stats.have_secrets;
  }
}

U0 PlayerLook(CDoomPlayer *p,F64 angle) {
  p->angle=angle;
}

CDoomPlayer *PlayerNew(CDoomLevel *l) {
  U16 gunsInit=0;
  CDoomPlayer *p=CAlloc(sizeof(CDoomPlayer),doom_task);
  QueIns(p,&l->things);
  p->template=doom_thing_types[1];
  p->flags|=TF_SHOOTABLE;
  p->health=100;
  p->armor=0;
  for(gunsInit=0;gunsInit<9;gunsInit++)
  {
    //p->arsenal[gunsInit]->load = CAlloc(sizeof(AmmoType));
    //p->arsenal[gunsInit]->load->ammo=999;
    //p->arsenal[gunsInit]->load->baseDamage=2;
    //p->arsenal[gunsInit]->load->splash=FALSE;   
            
    switch(gunsInit)
    {
      case 0://fists
	p->arsenal[gunsInit].available = TRUE;
        p->arsenal[gunsInit].load = CAlloc(sizeof(AmmoType),doom_task);
        p->arsenal[gunsInit].load->ammo=0;
        p->arsenal[gunsInit].baseDamage=2;
        p->arsenal[gunsInit].load->splash=FALSE;   
        break;
      case 1://pistol
	p->arsenal[gunsInit].available = TRUE;
        p->arsenal[gunsInit].load = CAlloc(sizeof(AmmoType),doom_task);
        p->arsenal[gunsInit].load->ammo=50;
        p->arsenal[gunsInit].baseDamage=4;
        p->arsenal[gunsInit].load->splash=FALSE;   
        break;
      case 2://shotgun
        p->arsenal[gunsInit].load = CAlloc(sizeof(AmmoType),doom_task);
        p->arsenal[gunsInit].load->ammo=0;
        p->arsenal[gunsInit].baseDamage=4;
        p->arsenal[gunsInit].load->splash=FALSE;   
        break;
      case 3://chaingun
        p->arsenal[gunsInit].load = p->arsenal[1].load;
        p->arsenal[gunsInit].baseDamage=4;
        break;
      case 4://rocket launcher
        p->arsenal[gunsInit].load = CAlloc(sizeof(AmmoType),doom_task);
        p->arsenal[gunsInit].load->ammo=0;
        p->arsenal[gunsInit].baseDamage=20;
        p->arsenal[gunsInit].load->splash=TRUE;
        break;
      case 5://chainsaw
        p->arsenal[gunsInit].load = p->arsenal[0].load;
        p->arsenal[gunsInit].baseDamage=3;
        break;
      case 6://plasma
        p->arsenal[gunsInit].load = CAlloc(sizeof(AmmoType),doom_task);
        p->arsenal[gunsInit].load->ammo=0;
        p->arsenal[gunsInit].baseDamage=5;
        p->arsenal[gunsInit].load->splash=FALSE;
        break;
      case 7://bfg
        p->arsenal[gunsInit].load = p->arsenal[6].load;
        p->arsenal[gunsInit].baseDamage=100;
        break;
      case 8://Super shotgun
        p->arsenal[gunsInit].load = p->arsenal[2].load;
        p->arsenal[gunsInit].baseDamage=100;
        break;
    }

  }
  weaponIndex=1;
  CDoomThing *t,*head=&l->things;
  for(t=head->next;t!=head;t=t->next) {
//https://doomwiki.org/wiki/Thing_types#Other
    if(t->thing_type==1) {
      p->x=t->x;
      p->y=t->y;
      p->angle=t->angle;
      break;
    }
  }
  return p;
}

CDoomThing *PlayerPickTarget(CDoomLevel *l,CDoomPlayer *p) {
//best_diff is cosine of angle diference,MORE same == higher value
  CDoomThing *cur,*head=&l->things,*best=NULL;
  F64 dist,angle,margin=22*(pi/180),has,h2,a2,best_diff=0;
  h2=p->template->height/2;
  for(cur=head->next;head!=cur;cur=cur->next) 
    if(cur->flags&TF_SHOOTABLE&&cur!=p) {
      dist=ApproxDist(cur->x-p->x,cur->y-p->y);
      if(dist<=16.*64) {
	a2=FArg(cur->x-p->x,cur->y-p->y);
	a2%=2*pi;
	p->angle%=2*pi;
        angle=(a2-p->angle)%(2*pi);
        if(-margin<=angle<=margin) {
	  has=Abs(Cos(a2-p->angle));
	  if(has>best_diff&&ValidateLineOfSightShot(l,&p->x,a2,dist+1,p->height+h2,cur->height+cur->template->height/2)<0.) {
	    best_diff=has;
	    best=cur;
	  }
        }
      }
    }
  return best;
}

