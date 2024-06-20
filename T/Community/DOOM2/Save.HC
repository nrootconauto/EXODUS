#ifndef SAVE_H
#define SAVE_H "Christ Saves"
//
// 12/13/23 Nrootconauto if feeling like saying fuck alot today
//
I64 GetThingIndex(CDoomLevel *l,CDoomThing *t) {
  CQue *head=&l->things,*cur;
  I64 idx=0;
  for(cur=head->next;head!=cur;cur=cur->next) {
    if(cur==t)
      return idx;
    idx++;
  }
  return -1;
}
I64 GetThinkerIndex(CDoomLevel *l,U8 *t) {
  CQue *head=&l->thinkers,*cur;
  I64 idx=0;
  for(cur=head->next;head!=cur;cur=cur->next) {
    if(cur==t)
      return idx;
    idx++;
  }
  return -1;
}
I64 GetLinedefIndex(CDoomLevel *l,U8 *t) {
  CQue *head=&l->linedefs,*cur;
  I64 idx=0;
  for(cur=head->next;head!=cur;cur=cur->next) {
    if(cur==t)
      return idx;
    idx++;
  }
  return -1;
}
I64 GetSectorIndex(CDoomLevel *l,U8 *t) {
  CQue *head=&l->sectors,*cur;
  I64 idx=0;
  for(cur=head->next;head!=cur;cur=cur->next) {
    if(cur==t)
      return idx;
    idx++;
  }
  return -1;
}
I64 GetSidedefIndex(CDoomLevel *l,U8 *t) {
  CQue *head=&l->sidedefs,*cur;
  I64 idx=0;
  for(cur=head->next;head!=cur;cur=cur->next) {
    if(cur==t)
      return idx;
    idx++;
  }
  return -1;
}
//DONT FUCKIN FREE 
U8 *GetUNStr(U8 *ptr) {
  CHashTable *tab=doom_task->hash_table;
  U8 buf[STR_LEN],*buf_ptr=buf;
  U8 **value,*new_ptr;
  I64 bucket;
  CHashGeneric *tmph,*next;
  for(bucket=0;bucket<=tab->mask;bucket++) {
    for(tmph=tab->body[bucket];tmph;tmph=next) {
      next=tmph->next;
      if(tmph->type&HTT_FRAME_PTR&&tmph->user_data0==ptr)
        if(!StrNCmp("Unique.",tmph->str,7))
	  return tmph->str;
    }
  }
  return NULL;
}

U0 SaveGame(U8 *filename,U8 *title) {
  filename=ExtDft(filename,"prumnE"); //Greek word for that fuckin ass sauce
  CQue *head,*cur;
  CHashGeneric *g;
  I64 idx;
  GunAvail *avail;
  CDoc *doc=DocNew(filename);
  U8 buf[STR_LEN],*buf_ptr=buf;
  head=&l->things;
  idx=0;
  DocPrint(doc,"SAVE_NAME:%s\n",title);
  DocPrint(doc,"TIME:%n\n",Server_tS);
  DocPrint(doc,"MAP:%s\n",l->map_name);
  DocPrint(doc,"SKILL:%d\n",l->skill);
  DocPrint(doc,"THING_CNT:%d\n",QueCnt(head));
  for(cur=head->next;cur!=head;cur=cur->next) {
    if(cur==p)
      DocPrint(doc,"[player]:\n");
    else
      DocPrint(doc,"[thing]:\n");
    DocPrint(doc,"%n\n",cur(CDoomThing*)->x);
    DocPrint(doc,"%n\n",cur(CDoomThing*)->y);
    DocPrint(doc,"%n\n",cur(CDoomThing*)->angle);
    DocPrint(doc,"%n\n",cur(CDoomThing*)->height);
    DocPrint(doc,"%n\n",cur(CDoomThing*)->health);
    DocPrint(doc,"%n\n",cur(CDoomThing*)->momx);
    DocPrint(doc,"%n\n",cur(CDoomThing*)->momy);
    DocPrint(doc,"%n\n",cur(CDoomThing*)->momz);
    DocPrint(doc,"%n\n",cur(CDoomThing*)->anim_start_tS);
    DocPrint(doc,"%s\n",GetUNStr(cur(CDoomThing*)->animation));
    DocPrint(doc,"%s\n",GetUNStr(cur(CDoomThing*)->template));
    DocPrint(doc,"%d\n",cur(CDoomThing*)->flags);
    DocPrint(doc,"%d\n",cur(CDoomThing*)->solid);
    DocPrint(doc,"%d\n",cur(CDoomThing*)->anim_no_repeat);
    DocPrint(doc,"%d\n",GetThinkerIndex(l,cur(CDoomThing*)->thinker));
    if(cur==p) {
      DocPrint(doc,"%n\n",cur(CDoomPlayer*)->armor);
      DocPrint(doc,"%n\n",cur(CDoomPlayer*)->rad_suit_time);
      DocPrint(doc,"%n\n",cur(CDoomPlayer*)->bezerk_time);
      DocPrint(doc,"%d\n",cur(CDoomPlayer*)->has_backpack);
    }
    idx++;
  }

  head=&l->thinkers;
  DocPrint(doc,"THINKER_CNT:%d\n",QueCnt(head));
  for(cur=head->next;cur!=head;cur=cur->next) {
    DocPrint(doc,"[Thinker:%s]:\n",cur(CDoomThinker*)->cls_name);
    if(!StrCmp(cur(CDoomThinker*)->cls_name,"CFireThinker")) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CFireThinker*)->self));
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CFireThinker*)->vile));
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CFireThinker*)->target));
      DocPrint(doc,"%n\n",cur(CFireThinker*)->end_tS);     
    } else if(!StrCmp(cur(CDoomThinker*)->cls_name,"CBarrelThinker")) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CBarrelThinker*)->self));
      DocPrint(doc,"%n\n",cur(CBarrelThinker*)->explode_start_tS);
    }
    else if(!StrCmp(cur(CDoomThinker*)->cls_name,"CMonsterThinker")) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CMonsterThinker*)->self));
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CMonsterThinker*)->parent));
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CMonsterThinker*)->target));
      DocPrint(doc,"%n\n",cur(CMonsterThinker*)->last_hit_time);
      DocPrint(doc,"%n\n",cur(CMonsterThinker*)->last_attack_time);
      DocPrint(doc,"%n\n",cur(CMonsterThinker*)->state_start_tS);
      DocPrint(doc,"%n\n",cur(CMonsterThinker*)->state_length);
      DocPrint(doc,"%d\n",cur(CMonsterThinker*)->steps_to_walk);
      DocPrint(doc,"%d\n",cur(CMonsterThinker*)->reaction_time);
      DocPrint(doc,"%n\n",cur(CMonsterThinker*)->attack_time);
      DocPrint(doc,"%d\n",cur(CMonsterThinker*)->flags);
      DocPrint(doc,"%s\n",GetUNStr(cur(CMonsterThinker*)->state));
      DocPrint(doc,"%d\n",cur(CMonsterThinker*)->ran_state);
    }
    else if(!StrCmp(cur(CDoomThinker*)->cls_name,"CMissileThinker")) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CMissileThinker*)->shooter));
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CMissileThinker*)->self));
      DocPrint(doc,"%n\n",cur(CMissileThinker*)->vslope);
      DocPrint(doc,"%n\n",cur(CMissileThinker*)->state_start_tS);
      DocPrint(doc,"%d\n",cur(CMissileThinker*)->hit);
    }
    else if(!StrCmp(cur(CDoomThinker*)->cls_name,"CCubeThinker")) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CMissileThinker*)->shooter));
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CMissileThinker*)->self));
      DocPrint(doc,"%n\n",cur(CMissileThinker*)->vslope);
      DocPrint(doc,"%n\n",cur(CMissileThinker*)->state_start_tS);
      DocPrint(doc,"%d\n",cur(CMissileThinker*)->hit);
      DocPrint(doc,"%n\n",cur(CCubeThinker*)->start.x);
      DocPrint(doc,"%n\n",cur(CCubeThinker*)->start.y);
      DocPrint(doc,"%n\n",cur(CCubeThinker*)->end.x);
      DocPrint(doc,"%n\n",cur(CCubeThinker*)->end.y);
    } else if(!StrCmp(cur(CDoomThinker*)->cls_name,"CStairsThinker")) {
      DocPrint(doc,"%d\n",GetSectorIndex(l,cur(CStairsThinker*)->s));
      DocPrint(doc,"%n\n",cur(CStairsThinker*)->start_h);
      DocPrint(doc,"%n\n",cur(CStairsThinker*)->start_tS);
      DocPrint(doc,"%n\n",cur(CStairsThinker*)->target_h);
      DocPrint(doc,"%n\n",cur(CStairsThinker*)->speed);
    }
    else if(!StrCmp("CTeleportThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CTeleportThinker*)->fog));
    }
    else if(!StrCmp("CDonutThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%n\n",cur(CDonutThinker*)->start_tS);
      DocPrint(doc,"%d\n",GetLinedefIndex(l,cur(CDonutThinker*)->ld));
    }
    else if(!StrCmp("CDoomThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data1);
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data2);
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data3);
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data4);
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data5);
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data6);
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data7);
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data8);
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data9);
      DocPrint(doc,"%d\n",cur(CDoomThinker*)->user_data10);
    } else if(!StrCmp("CButtonThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetSidedefIndex(l,cur(CButtonThinker*)->s));
      DocPrint(doc,"%n\n",cur(CButtonThinker*)->switch_tS);
      DocPrint(doc,"%d\n",cur(CButtonThinker*)->which_part);
      DocPrint(doc,"%d\n",cur(CButtonThinker*)->repeat);
    } else if(!StrCmp("CCeilThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%n\n",cur(CCeilThinker*)->target_start);
      DocPrint(doc,"%n\n",cur(CCeilThinker*)->target_end);
      DocPrint(doc,"%n\n",cur(CCeilThinker*)->start_tS);
      DocPrint(doc,"%n\n",cur(CCeilThinker*)->speed);
      DocPrint(doc,"%n\n",cur(CCeilThinker*)->wait);
      DocPrint(doc,"%d\n",GetSectorIndex(l,cur(CCeilThinker*)->s));
      DocPrint(doc,"%d\n",cur(CCeilThinker*)->going_up);
      DocPrint(doc,"%d\n",cur(CCeilThinker*)->going_up);
    } else if(!StrCmp("CLiftThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%n\n",cur(CLiftThinker*)->target_start);
      DocPrint(doc,"%n\n",cur(CLiftThinker*)->target_end);
      DocPrint(doc,"%n\n",cur(CLiftThinker*)->start_tS);
      DocPrint(doc,"%n\n",cur(CLiftThinker*)->speed);
      DocPrint(doc,"%n\n",cur(CLiftThinker*)->wait_time);
      DocPrint(doc,"%d\n",GetSectorIndex(l,cur(CLiftThinker*)->s));
      DocPrint(doc,"%d\n",GetLinedefIndex(l,cur(CLiftThinker*)->ld));
      DocPrint(doc,"%s\n",GetUNStr(cur(CLiftThinker*)->action));
      DocPrint(doc,"%d\n",cur(CLiftThinker*)->going_up);
      DocPrint(doc,"%d\n",cur(CLiftThinker*)->going_down);
      DocPrint(doc,"%d\n",cur(CLiftThinker*)->reverting);
      DocPrint(doc,"%d\n",cur(CLiftThinker*)->waiting);
    } else if(!StrCmp("CDoorThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%n\n",cur(CDoorThinker*)->target_start);
      DocPrint(doc,"%n\n",cur(CDoorThinker*)->target_end);
      DocPrint(doc,"%n\n",cur(CDoorThinker*)->start_tS);
      DocPrint(doc,"%n\n",cur(CDoorThinker*)->speed);
      DocPrint(doc,"%n\n",cur(CDoorThinker*)->wait_time);
      DocPrint(doc,"%d\n",GetSectorIndex(l,cur(CDoorThinker*)->s));
      DocPrint(doc,"%d\n",GetLinedefIndex(l,cur(CDoorThinker*)->ld));
      DocPrint(doc,"%s\n",GetUNStr(cur(CDoorThinker*)->action));
      DocPrint(doc,"%d\n",cur(CDoorThinker*)->opening);
      DocPrint(doc,"%d\n",cur(CDoorThinker*)->closing);
      DocPrint(doc,"%d\n",cur(CDoorThinker*)->waiting);
      DocPrint(doc,"%d\n",cur(CDoorThinker*)->reverting);
    } else if(!StrCmp("CPuffThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CPuffThinker*)->self));
      DocPrint(doc,"%n\n",cur(CPuffThinker*)->spawn_time);
    } else if(!StrCmp("CCrushThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetSectorIndex(l,cur(CCrushThinker*)->s));
      DocPrint(doc,"%n\n",cur(CCrushThinker*)->base_speed);
      DocPrint(doc,"%d\n",cur(CCrushThinker*)->going_up);
    } else if(!StrCmp("CLight1",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetSectorIndex(l,cur(CLight1*)->s));
      DocPrint(doc,"%n\n",cur(CLight1*)->end_tS);
    } else if(!StrCmp("CLightStrobe",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetSectorIndex(l,cur(CLightStrobe*)->s));
      DocPrint(doc,"%n\n",cur(CLightStrobe*)->end_tS);
      DocPrint(doc,"%n\n",cur(CLightStrobe*)->rand_offset);
      DocPrint(doc,"%d\n",cur(CLightStrobe*)->mask);
    } else if(!StrCmp("CLightFire",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetSectorIndex(l,cur(CLightFire*)->s));
      DocPrint(doc,"%n\n",cur(CLightFire*)->end_tS);
    } else if(!StrCmp("CLightBlinkThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetSectorIndex(l,cur(CLightBlinkThinker*)->s));
      DocPrint(doc,"%n\n",cur(CLightBlinkThinker*)->begin_at_tS);
      DocPrint(doc,"%n\n",cur(CLightBlinkThinker*)->change_tS);
      DocPrint(doc,"%d\n",cur(CLightBlinkThinker*)->on);
    } else if(!StrCmp("CBFGScannerThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CBFGScannerThinker*)->who_fired));
      DocPrint(doc,"%n\n",cur(CBFGScannerThinker*)->start_at);
      DocPrint(doc,"%n\n",cur(CBFGScannerThinker*)->angle);
    } else if(!StrCmp("CBFGPuffThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CBFGPuffThinker*)->self));
      DocPrint(doc,"%n\n",cur(CBFGPuffThinker*)->start_tS);
    } else if(!StrCmp("CSkelMissileThinker",cur(CDoomThinker*)->cls_name)) {
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CSkelMissileThinker*)->self));
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CSkelMissileThinker*)->shooter));
      DocPrint(doc,"%n\n",cur(CSkelMissileThinker*)->vslope);
      DocPrint(doc,"%n\n",cur(CSkelMissileThinker*)->state_start_tS);
      DocPrint(doc,"%d\n",cur(CSkelMissileThinker*)->hit);
      DocPrint(doc,"%d\n",GetThingIndex(l,cur(CSkelMissileThinker*)->target));
    }else {
//Do Nothing
    }
  }
  DocPrint(doc,"ARSENAL:\n");
  DocPrint(doc,"EQUIP:%d\n",weaponIndex);
#ifdef DOOM2
  for(idx=0;idx!=9;idx++) {
#else
  for(idx=0;idx!=8;idx++) {
#endif
    avail=&p->arsenal[idx];
    DocPrint(doc,"%d\n",avail->available);
    if(avail->load)
      DocPrint(doc,"%d\n",avail->load->ammo);
    else
      DocPrint(doc,"%d\n",0);
  }
  DocPrint(doc,"KEYS:%d,%d,%d\n",l->has_red_key,l->has_blue_key,l->has_yellow_key);
  head=&l->sectors;
  for(cur=head->next;head!=cur;cur=cur->next) {
    DocPrint(doc,"%n,%n,%n\n",
	  cur(CDoomSector*)->floor_height,
	  cur(CDoomSector*)->ceil_height,
	  cur(CDoomSector*)->cur_light_level
	  );
    DocPrint(doc,"%d,%d,%d,%d\n",
	  GetLinedefIndex(l,cur(CDoomSector*)->cur_action_linedef),
	  cur(CDoomSector*)->tx_changed,
	  cur(CDoomSector*)->special_type,
	  GetSectorIndex(l,cur(CDoomSector*)->changed_from_sector));
  }
  DocPrint(doc,"%d\n",l->stats.have_kills);
  DocPrint(doc,"%d\n",l->stats.have_items);
  DocPrint(doc,"%d\n",l->stats.have_secrets);
  DocPrint(doc,"%n\n",l->stats.time);
  head=&l->linedefs;
  for(cur=head->next;cur!=head;cur=cur->next) {
    DocPrint(doc,"%d\n",cur(CDoomLinedef *)->activated);
    DocPrint(doc,"%d\n",cur(CDoomLinedef *)->seen);
  }
  DocPrint(doc,"%d\n",l->has_map);
  DocPrint(doc,"%n\n",p->light_goggles_time);
  DocPrint(doc,"%n\n",p->invincible_time);
  DocPrint(doc,"%n\n",p->invisible_time);
  DocWrite(doc);  
  DocDel(doc);
  Free(filename);
}
union COmniThinker {
  CDoomThinker doom;
  CDonutThinker donut;
  CTeleportThinker teleport;
  CStairsThinker stairs;
  CMissileThinker missile;
  CMonsterThinker monster;
  CBarrelThinker barrel;
  CDoorThinker door;
  CFireThinker fire;
  CLiftThinker lift;
  CCubeThinker cube;
};
CDoomThinker *GetNthThinker(CDoomLevel *l,I64 n) {
  CQue *head=&l->thinkers,*cur;
  I64 idx=0;
  if(n==-1) return NULL;
  for(cur=head->next;cur!=head;cur=cur->next)
    if(idx++==n)
      return cur;
  return NULL;
}
CDoomSidedef *GetNthSidedef(CDoomLevel *l,I64 n) {
  CQue *head=&l->sidedefs,*cur;
  I64 idx=0;
  if(n==-1) return NULL;
  for(cur=head->next;cur!=head;cur=cur->next)
    if(idx++==n)
      return cur;
  return NULL;
}
CDoomSector *GetNthSector(CDoomLevel *l,I64 n) {
  CQue *head=&l->sectors,*cur;
  I64 idx=0;
  if(n==-1) return NULL;
  for(cur=head->next;cur!=head;cur=cur->next)
    if(idx++==n)
      return cur;
  return NULL;
}
CDoomThing *GetNthThing(CDoomLevel *l,I64 n) {
  CQue *head=&l->things,*cur;
  I64 idx=0;
  if(n==-1) return NULL;
  for(cur=head->next;cur!=head;cur=cur->next)
    if(idx++==n)
      return cur;
  return NULL;
}
CDoomThing *GetNthLinedef(CDoomLevel *l,I64 n) {
  CQue *head=&l->linedefs,*cur;
  I64 idx=0;
  if(n==-1) return NULL;
  for(cur=head->next;cur!=head;cur=cur->next)
    if(idx++==n)
      return cur;
  return NULL;
}


U0 LoadGame(U8 *filename) {
  filename=ExtDft(filename,"prumnE");
  I64 state=0;
  CQue *head;
  CDC *old,*new;
  CDoomThing *thing;
  CDoomSector *sector;
  COmniThinker *thinker,*next;
  CDoomLinedef *ld;
  U8 *optr,*ptr;
  U8 buf[STR_LEN],*buf_ptr=buf,buf2[STR_LEN];
  GunAvail *avail;
  I64 cnt,idx,i64,idx2,red,blue,yellow,weapon;
  I64 texture_changed,texture_src;
  F64 f64,level_time;
  ptr=FileRead(filename);
  StrUtil(ptr,SUF_REM_CTRL_CHARS);
  optr=ptr;
  ptr=StrScan(ptr,"SAVE_NAME:%s\n",&buf_ptr);
  ptr=StrScan(ptr,"TIME:%n\n",&level_time);
  ptr=StrScan(ptr,"MAP:%s\n",&buf_ptr);
  ptr=StrScan(ptr,"SKILL:%d\n",&i64);
  if(l) FreeLevel(l);
  l=NULL;
  l=LoadWadLevel(buf,i64);
  head=&l->things;
  for(thing=head->next;thing!=head;thing=next) {
    next=thing->next;
    ThingDel(l,thing);
  }
  QueDel(&l->things);
  QueDel(&l->thinkers);
  QueInit(&l->thinkers);
  QueInit(&l->things);
  while(*ptr) {
    switch(state) {
      case 0: //Thing cnt
        ptr=StrScan(ptr,"THING_CNT:%d\n",&cnt);
        state=1;
        for(idx=0;idx!=cnt;idx++) {
	  thing=CAlloc(sizeof(CDoomPlayer),doom_task); //CDoomPlayer is the biggest one
	  QueIns(thing,l->things.last);
        }
        break;
      case 1: //Things
        thing=l->things.next;
        for(idx=0;idx!=cnt;idx++) {
	  if(*ptr!='[')
	    throw('fuck');
	  ptr=StrScan(ptr,"[%s]:\n",&buf_ptr);
	  StrCpy(buf2,buf);
	  ptr=StrScan(ptr,"%n\n",&f64);
	  thing->x=f64;
	  ptr=StrScan(ptr,"%n\n",&f64);
	  thing->y=f64;
	  ptr=StrScan(ptr,"%n\n",&f64);
	  thing->angle=f64;
	  ptr=StrScan(ptr,"%n\n",&f64);
	  thing->height=f64;
	  ptr=StrScan(ptr,"%n\n",&f64);
	  thing->health=f64;
	  ptr=StrScan(ptr,"%n\n",&f64);
	  thing->momx=f64;
	  ptr=StrScan(ptr,"%n\n",&f64);
	  thing->momy=f64;
	  ptr=StrScan(ptr,"%n\n",&f64);
	  thing->momz=f64;
	  ptr=StrScan(ptr,"%n\n",&f64);
	  thing->anim_start_tS=f64;
	  ptr=StrScan(ptr,"%s\n",&buf_ptr);
	  thing->animation=FramePtr(buf);
	  ptr=StrScan(ptr,"%s\n",&buf_ptr);
	  thing->template=FramePtr(buf);
	  ptr=StrScan(ptr,"%d\n",&i64);
	  thing->flags=i64;
	  ptr=StrScan(ptr,"%d\n",&i64);
	  thing->solid=i64;
	  ptr=StrScan(ptr,"%d\n",&i64);
	  thing->anim_no_repeat=i64;
	  ptr=StrScan(ptr,"%d\n",&i64);
	  thing->thinker=i64;
	  if(!StrCmp(buf2,"player")) {
	    p=thing;
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thing(CDoomPlayer*)->armor=f64;
	    ptr=StrScan(ptr,"%n\n",&thing(CDoomPlayer*)->rad_suit_time);
	    ptr=StrScan(ptr,"%n\n",&thing(CDoomPlayer*)->bezerk_time);	    
	    ptr=StrScan(ptr,"%d\n",&i64);
	    if(thing(CDoomPlayer*)->has_backpack=i64) {
	      maxBullets=400;
	      maxShells=200;
	      maxRockets=100;
	      maxCells=600;
	    } else {
	      maxBullets=200;
	      maxShells=50;
	      maxRockets=50;
	      maxCells=300;
	    }
	  }
	  thing=thing->next;
        }
        state=2;
        break;
      case 2: //thinkers cnt
        ptr=StrScan(ptr,"THINKER_CNT:%d\n",&cnt);
        state=3;
        for(idx=0;idx!=cnt;idx++) {
	  thinker=CAlloc(sizeof(COmniThinker),doom_task);
	  QueIns(thinker,l->thinkers.last);
        }
        break;
      case 3: //thinkers
        thinker=l->thinkers.next;
        for(idx=0;idx!=cnt;idx++) {
	  if(*ptr!='[') {
	    DocMax;
	    "%s\n",ptr;
	    throw('fuck');
	  }
	  ptr=StrScan(ptr,"[Thinker:%s]:\n",&buf_ptr);
	  StrCpy(thinker->doom.cls_name,buf);
	  if(!StrCmp(buf,"CFireThinker")) {
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->fire.self=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->fire.vile=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->fire.target=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->fire.end_tS=f64;
	    thinker->doom.fun_ptr=&FireThinker;
	  } else if(!StrCmp(buf,"CBarrelThinker")) {
	    thinker->doom.fun_ptr=&BarrelThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->barrel.self=GetNthThing(l,i64);
	    thinker->barrel.signature='Barrel';
	    thinker->barrel.explode_start_tS=f64;
	  } else if(!StrCmp(buf,"CMonsterThinker")) {
	    thinker->doom.fun_ptr=&MonsterThinker;
	    thinker->monster.signature='Monster';
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->monster.self=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->monster.parent=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->monster.target=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->monster.last_hit_time=f64;
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->monster.last_attack_time=f64;
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->monster.state_start_tS=f64;
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->monster.state_length=f64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->monster.steps_to_walk=i64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->monster.reaction_time=i64;
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->monster.attack_time=f64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->monster.flags=i64;
	    ptr=StrScan(ptr,"%s\n",&buf_ptr);
	    thinker->monster.state=FramePtr(buf);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->monster.ran_state=i64;
	  } else if(!StrCmp(buf,"CMissileThinker")) {
	    thinker->doom.fun_ptr=&MissileThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->missile.shooter=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->missile.self=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->missile.vslope=f64;
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->missile.state_start_tS=f64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->missile.hit=i64;
	  } else if(!StrCmp(buf,"CCubeThinker")) {
	    thinker->doom.fun_ptr=&SpawnFly;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->missile.shooter=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->missile.self=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->missile.vslope=f64;
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->missile.state_start_tS=f64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->missile.hit=i64;
	    ptr=StrScan(ptr,"%n\n%n\n%n\n%n\n",
		&thinker->cube.start.x,
		&thinker->cube.start.y,
		&thinker->cube.end.x,
		&thinker->cube.end.y
		);
	  } else if(!StrCmp(buf,"CTeleportThinker")) {
	    thinker->doom.fun_ptr=&TeleportFogThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->teleport.fog=GetNthThing(l,i64);
	  } else if(!StrCmp(buf,"CDonutThinker")) {
	    thinker->doom.fun_ptr=&DonutThinker;
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker->donut.start_tS=f64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->donut.ld=GetNthLinedef(l,i64);
	  } else if(!StrCmp(buf,"CDoomThinker")) {
	    for(idx2=0;idx2!=10;idx2++) {
	      ptr=StrScan(ptr,"%d\n",&i64);
	      (&thinker->doom.user_data1)[idx2]=i64;
	    }
	  } else if(!StrCmp("CButtonThinker",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&ButtonThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CButtonThinker*)->s=GetNthSidedef(l,i64);
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker(CButtonThinker*)->switch_tS=f64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CButtonThinker*)->which_part=i64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CButtonThinker*)->repeat=i64;
	  } else if(!StrCmp("CCeilThinker",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&CeilThinker;
	    ptr=StrScan(ptr,"%n\n",&thinker(CCeilThinker*)->target_start);
	    ptr=StrScan(ptr,"%n\n",&thinker(CCeilThinker*)->target_end);
	    ptr=StrScan(ptr,"%n\n",&thinker(CCeilThinker*)->start_tS);
	    ptr=StrScan(ptr,"%n\n",&thinker(CCeilThinker*)->speed);
	    ptr=StrScan(ptr,"%n\n",&thinker(CCeilThinker*)->wait);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CCeilThinker*)->s=GetNthSector(l,i64);
//These are U8's
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CCeilThinker*)->going_up=i64;
	    ptr=StrScan(ptr,"%d\n",&thinker(CCeilThinker*)->going_down);
	    thinker(CCeilThinker*)->going_down=i64;
	  } else if(!StrCmp("CLiftThinker",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&LiftThinker;
	    ptr=StrScan(ptr,"%n\n",&thinker(CLiftThinker*)->target_start);
	    ptr=StrScan(ptr,"%n\n",&thinker(CLiftThinker*)->target_end);
	    ptr=StrScan(ptr,"%n\n",&thinker(CLiftThinker*)->start_tS);
	    ptr=StrScan(ptr,"%n\n",&thinker(CLiftThinker*)->speed);
	    ptr=StrScan(ptr,"%n\n",&thinker(CLiftThinker*)->wait_time);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLiftThinker*)->s=GetNthSector(l,i64);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLiftThinker*)->ld=GetNthLinedef(l,i64);
	    ptr=StrScan(ptr,"%s\n",&buf_ptr);
	    thinker(CLiftThinker*)->action=FramePtr(buf);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLiftThinker*)->going_up=i64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLiftThinker*)->going_down=i64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLiftThinker*)->reverting=i64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLiftThinker*)->waiting=i64;
	  } else if(!StrCmp("CDoorThinker",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&DoorThinker;
	    ptr=StrScan(ptr,"%n\n",&thinker(CDoorThinker*)->target_start);
	    ptr=StrScan(ptr,"%n\n",&thinker(CDoorThinker*)->target_end);
	    ptr=StrScan(ptr,"%n\n",&thinker(CDoorThinker*)->start_tS);
	    ptr=StrScan(ptr,"%n\n",&thinker(CDoorThinker*)->speed);
	    ptr=StrScan(ptr,"%n\n",&thinker(CDoorThinker*)->wait_time);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CDoorThinker*)->s=GetNthSector(l,i64);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CDoorThinker*)->ld=GetNthLinedef(l,i64);
	    ptr=StrScan(ptr,"%s\n",&buf_ptr);
	    thinker(CDoorThinker*)->action=FramePtr(buf);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CDoorThinker*)->opening=i64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CDoorThinker*)->closing=i64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CDoorThinker*)->waiting=i64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CDoorThinker*)->reverting=i64;
	  } else if(!StrCmp("CPuffThinker",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&PuffThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CPuffThinker*)->self=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%n\n",&thinker(CPuffThinker*)->spawn_time);
	  } else if(!StrCmp("CCrushThinker",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&CrushThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CCrushThinker*)->s=GetNthSector(l,i64);
	    ptr=StrScan(ptr,"%n\n",&thinker(CCrushThinker*)->base_speed);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CCrushThinker*)->going_up=i64;
	  } else if(!StrCmp("CLight1",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&Light1Thinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLight1*)->s=GetNthSector(l,i64);
	    ptr=StrScan(ptr,"%n\n",&thinker(CLight1*)->end_tS);
	  } else if(!StrCmp("CLightStrobe",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&LightStrobeThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLightStrobe*)->s=GetNthSector(l,i64);
	    ptr=StrScan(ptr,"%n\n",&thinker(CLightStrobe*)->end_tS);
	    ptr=StrScan(ptr,"%n\n",&thinker(CLightStrobe*)->rand_offset);
	    ptr=StrScan(ptr,"%d\n",&thinker(CLightStrobe*)->mask);
	  } else if(!StrCmp("CLightFire",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&LightFireThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLightFire*)->s=GetNthSector(l,i64);
	    ptr=StrScan(ptr,"%n\n",&thinker(CLightFire*)->end_tS);
	  } else if(!StrCmp("CLightBlinkThinker",thinker(CDoomThinker*)->cls_name)) {
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLightBlinkThinker*)->s=GetNthSector(l,i64);
	    thinker->doom.fun_ptr=&LightBlinkThinker;
	    ptr=StrScan(ptr,"%n\n",&thinker(CLightBlinkThinker*)->begin_at_tS);
	    ptr=StrScan(ptr,"%n\n",&thinker(CLightBlinkThinker*)->change_tS);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CLightBlinkThinker*)->on=i64;
	  } else if(!StrCmp("CBFGScannerThinker",thinker(CDoomThinker*)->cls_name)) {
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker->doom.fun_ptr=&BFGThinker;
	    thinker(CBFGScannerThinker*)->who_fired=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%n\n",&thinker(CBFGScannerThinker*)->start_at);
	    ptr=StrScan(ptr,"%n\n",&thinker(CBFGScannerThinker*)->angle);
	  } else if(!StrCmp("CBFGPuffThinker",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&BFGPuffThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CBFGPuffThinker*)->self=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%n\n",&thinker(CBFGPuffThinker*)->start_tS);
	  } else if(!StrCmp("CBFGPuffThinker",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&BFGPuffThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CBFGPuffThinker*)->self=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%n\n",&thinker(CBFGPuffThinker*)->start_tS);
	  } else if(!StrCmp("CSkelMissileThinker",thinker(CDoomThinker*)->cls_name)) {
	    thinker->doom.fun_ptr=&SkelMissileThinker;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CSkelMissileThinker*)->self=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CSkelMissileThinker*)->shooter=GetNthThing(l,i64);
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker(CSkelMissileThinker*)->vslope=f64;
	    ptr=StrScan(ptr,"%n\n",&f64);
	    thinker(CSkelMissileThinker*)->state_start_tS=f64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CSkelMissileThinker*)->hit=i64;
	    ptr=StrScan(ptr,"%d\n",&i64);
	    thinker(CSkelMissileThinker*)->target=GetNthThing(l,i64);
	  } else {
	    next=thinker->doom.next;
	    QueRem(thinker);
	    Free(thinker);
	    thinker=next;
	    goto skip_thinker;
	  }
	  thinker=thinker->doom.next;
skip_thinker:;
        }
        state++;
        break;
      case 4: //Arsenal
        ptr=StrScan(ptr,"ARSENAL:\n");
        ptr=StrScan(ptr,"EQUIP:%d\n",&weapon);
#ifdef DOOM2
        for(idx=0;idx!=9;idx++) {
#else
        for(idx=0;idx!=8;idx++) {
#endif
	  avail=&p->arsenal[idx];
	  switch(idx) {
	    case 0...2:
	    case 4:
	    case 6:
	      avail->load=CAlloc(sizeof(AmmoType),doom_task);
	      break;
	    case 3:
	      avail->load=p->arsenal[1].load;
	      break;
	    case 5:
	      avail->load=p->arsenal[0].load;
	      break;
	    case 7:
	      avail->load=p->arsenal[6].load;
	      break;
	    case 8:
	      avail->load=p->arsenal[2].load;
	      break;
	  }
	  ptr=StrScan(ptr,"%d\n",&i64);
	  avail->available=i64;
	  ptr=StrScan(ptr,"%d\n",&i64);
	  avail->load->ammo=i64;
        }
        SwapWeapon(p,weapon);
        state++;
        break;
      case 5:
        ptr=StrScan(ptr,"KEYS:%d,%d,%d\n",&red,&blue,&yellow);
        l->has_red_key=red,l->has_blue_key=blue,l->has_yellow_key=yellow;
        state++;
        break;
      case 6:
        head=&l->sectors;
        for(sector=head->next;head!=sector;sector=sector->next) {
	  ptr=StrScan(ptr,"%n,%n,%n\n",
	        &sector->floor_height,
	        &sector->ceil_height,
	        &sector->cur_light_level);
	  ptr=StrScan(ptr,"%d,%d,%d,%d\n",
	        &i64,
	        &texture_changed,
	        &sector->special_type,
	        &texture_src);
	  sector->cur_action_linedef=GetNthLinedef(l,i64);
	  if(texture_src!=-1&&texture_changed) {
	    MemCpy(&sector->floor_dc,&(GetNthSector(l,texture_src)->floor_dc),8*4);
	  }
        }
        state++;
        break;
      case 7:
        ptr=StrScan(ptr,"%d\n",&l->stats.have_kills);
        ptr=StrScan(ptr,"%d\n",&l->stats.have_items);
        ptr=StrScan(ptr,"%d\n",&l->stats.have_secrets);
        ptr=StrScan(ptr,"%n\n",&l->stats.time);
        state++;
        break;
      case 8:
        head=&l->linedefs;
        for(ld=head->next;ld!=head;ld=ld->next) {
	  ptr=StrScan(ptr,"%d\n",&i64);
	  ld->activated=i64;
	  ptr=StrScan(ptr,"%d\n",&i64);
	  ld->seen=i64;
        }
        state++;
        break;
      case 9:
        ptr=StrScan(ptr,"%d\n",&i64);
        l->has_map=i64;
        state++;
        break;
      case 10:
        ptr=StrScan(ptr,"%n\n",&p->light_goggles_time);
        state++;
        break;
      case 11:
        ptr=StrScan(ptr,"%n\n",&p->invincible_time);
        state++;
        break;
      case 12:
        ptr=StrScan(ptr,"%n\n",&p->invisible_time);
        state++;
        break;
      default:
        goto fin;
    }
  }
fin:
  head=&l->things;
  for(thing=head->next;head!=thing;thing=thing->next) {
    thing->thinker=GetNthThinker(l,thing->thinker);
    InitPosDataForThing(l,thing);
  }
  for(thing=head->next;head!=thing;thing=next) {
    next=thing->next;
    if(!thing->template){
      ThingDel(l,thing);
    }
  }
  Free(optr);
  Free(filename);
  screen_melt=TRUE;
  Unpause(level_time);
  PlayLevel(FALSE);
}
#endif