#ifndef DOORS
#define DOORS "wealth provoke stormy inhabitant "

//https://doomwiki.org/wiki/Linedef_type#Terminology
//P  == Push
//S  == Switch
//W  == Walkover
//G  == Gun
// 1 == Once
// R == Repeat
#define DOOR_SPEED_SLOW (16*(1/35.)/2*4)
#define DOOR_SPEED_NORMAL (16*(1/35.)*4)
#define DOOR_SPEED_FAST (16*(1/35.)*4*4)
#define DOOR_SPEED_TURBO 64.


#define DOOR_ACTION_OPEN_WAIT_CLOSE 1
#define DOOR_ACTION_OPEN 2 //Stays open
#define DOOR_ACTION_CLOSE 3 //Stays closed
#define DOOR_ACTION_CLOSE_WAIT_OPEN 4

#define DOOR_LOCK_RED 1
#define DOOR_LOCK_BLUE 2
#define DOOR_LOCK_YELLOW 4

class CDoomDoor {
  U64 type;
  U64 trigger;
  I64 key;
  F64 speed;
  F64 wait;
  I64 monster;
  I64 action;
};

#define LIFT_STOP 1
#define LIFT_RAISE_NEXT_FLOOR 2
#define LIFT_RAISE_32 3
#define LIFT_RAISE_24 4
#define LIFT_LOWEST_FLOOR 5
#define LIFT_LOW_HIGH_REPEAT 6
#define LIFT_CEIL_TOGGLE 7
class CDoomLift {
  U64 type;
  U64 trigger;
  F64 delay;
  I64 target;
  I64 model;
  F64 speed;
  U8 zero_type;
  U8 texture_change;
  U8 type_change;
  U8 monster;
};

#define FLOOR_DST_LOWEST 1
#define FLOOR_ABS_24 2
#define FLOOR_ABS_512 3
#define FLOOR_DST_HIGHEST_CEIL 4
#define FLOOR_DST_HIGHEST_CEIL_ADD_8 5
#define FLOOR_DST_HIGHEST_FLOOR 6
#define FLOOR_DST_HIGHEST_FLOOR_ADD_8 7
#define FLOOR_DST_LOWEST_CEIL 8
#define FLOOR_DST_LOWEST_CEIL_SUB_8 9
#define FLOOR_DST_LOWEST_FLOOR 10
#define FLOOR_DST_LOWEST_FLOOR_SUB_8 11
#define FLOOR_DST_NEXT_FLOOR 12
#define FLOOR_DST_ANAL_BEADS 13
#define FLOOR_DST_LOWEST_TEXTURE 14

#define FLOOR_DIR_NONE 0
#define FLOOR_DIR_UP 1
#define FLOOR_DIR_DOWN 2


#define FLOOR_MODEL_NONE 0
#define FLOOR_MODEL_TRIGGER 1
#define FLOOR_MODEL_NUMBERED 2

class CDoomFloor:CDoomLift {
  U64 direction;
  I64 crush;
};

#define CEIL_DST_FLOOR 1
#define CEIL_DST_HIGHEST_CEIL 2
#define CEIL_DST_FLOOR8 3
#define CEIL_DST_LOWEST_CEIL 4
#define CEIL_DST_HIGHEST_FLOOR 5

class CDoomCeil {
  U64 type;
  U64 trigger;
  U64 direction;
  F64 speed;
  I64 target;
  Bool crush;
};

class CDoomExit {
  U64 type;
  U64 trigger;
  Bool secret;
};

union CDoomActionSector {
  U64 type;
  CDoomDoor door;
  CDoomCeil ceil;
  CDoomFloor floor;
  CDoomLift lift;
};

class CDoomDonut {
  U64 type;
  U64 trigger;
};

CDoomActionSector *action_sector_types[0x10000];
MemSet(action_sector_types,0,0x10000*8);

#define DOOM_DOORS_FILE "Doors.TXT"
#define DOOM_FLOORS_FILE "Floors.TXT"
U8 *ReadALine(U8 **fbuf) {
  U8 *en,*st=*fbuf,*buf;
  if(!*st) return NULL;
  if(en=StrFirstOcc(st,"\n")) {
    buf=MAlloc(en-st+2);
    MemCpy(buf,st,en-st+1);
    buf[en-st+1]=0;
    *fbuf=en+1;
    return buf;
  }
  *fbuf+=StrLen(st);
  return StrNew(st);
}

#define DOOM_DONUTS_FILE "Donuts.TXT"
U0 LoadDonuts() {
  CDoomDonut *d;
  U8 *optr=FileRead(DOOM_DONUTS_FILE),*fptr=optr,*ln;
  I64 num;
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  while(ln=ReadALine(&fptr)) {
    if(*ln=='#'||*ln==0)
      goto skip;
    StrScan(ln,"%d\t%s\t%s\n",&num,&cls_ptr,&trig_ptr);
    d=CAlloc(sizeof CDoomDonut);
    d->type='Donut';
    d->trigger=trig[0](U16);
    action_sector_types[num]=d;
skip:;
    Free(ln);
  }
  Free(optr);
}



#define TP_ORIENT_SET 1
#define TP_ORIENT_PRESERVE 2
#define TP_DEST_TP_THING 1
#define TP_DEST_TAGGED_LINE 2
#define TP_DEST_TAGGED_LINE_REV 3
class CDoomTeleporter {
  U64 type;
  U64 trigger;
  Bool silent,monster,player,pad[5];
  I32 orient,dest;
};

#define DOOM_TELEPORTERS_FILE "Teleporters.TXT"
U0 LoadTeleporters() {
  CDoomTeleporter *t;
  U8 *optr=FileRead(DOOM_TELEPORTERS_FILE),*fptr=optr,*ln;
  I64 num;
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  U8 silent[STR_LEN],*silent_ptr=silent;
  U8 mon[STR_LEN],*mon_ptr=mon;
  U8 player[STR_LEN],*player_ptr=player;
  U8 orient[STR_LEN],*orient_ptr=orient;
  U8 dest[STR_LEN],*dest_ptr=dest;
  StrUtil(optr,SUF_REM_CTRL_CHARS);
  while(ln=ReadALine(&fptr)) {
    if(!*ln||*ln=='#') goto skip;
    StrScan(ln,"%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
	&num,
	&cls_ptr,
	&trig_ptr,
	&silent_ptr,
	&mon_ptr,
	&player_ptr,
	&orient_ptr,
	&dest_ptr);
    t=CAlloc(sizeof CDoomTeleporter); 
    action_sector_types[num]=t;
    t->type='Teleport';
    t->trigger=trig[0](U16);
    if(!StrCmp(silent,"Yes"))
      t->silent=TRUE;
    else if(!StrCmp(silent,"No"))
      t->silent=FALSE;
    else
      throw('Doom');
    if(!StrCmp(mon,"Yes"))
      t->monster=TRUE;
    else if(!StrCmp(mon,"No"))
      t->monster=FALSE;
    else
      throw('Doom');
    if(!StrCmp(player,"Yes"))
      t->player=TRUE;
    else if(!StrCmp(player,"No"))
      t->player=FALSE;
    else
      throw('Doom');
    if(!StrCmp(orient,"Set"))
      t->orient=TP_ORIENT_SET;
    else if(!StrCmp(orient,"Preserve"))
      t->orient=TP_ORIENT_PRESERVE;
    else
      throw('Doom');
    if(!StrCmp(dest,"TP thing in tagged sector")) {
      t->dest=TP_DEST_TP_THING;
    } else if(!StrCmp(dest,"Line with same tag")) {
      t->dest=TP_DEST_TAGGED_LINE;
    } else if(!StrCmp(dest,"Line with same tag (reversed)")) {
      t->dest=TP_DEST_TAGGED_LINE_REV;
    } else
      throw('Doom');
skip:;
    Free(ln);
  }
}


#define DOOM_CEILS_FILE "Ceils.TXT"
U0 LoadCeils() {
  CDoomCeil *ceil;
  U8 *optr=FileRead(DOOM_CEILS_FILE),*fptr,*ln;
  StrUtil(optr,SUF_REM_CTRL_CHARS);
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  U8 dir[STR_LEN],*dir_ptr=dir;
  U8 speed[STR_LEN],*speed_ptr=speed;
  U8 change[STR_LEN],*change_ptr=change;
  U8 model[STR_LEN],*model_ptr=model;
  U8 monster[STR_LEN],*monster_ptr=monster;
  U8 crush[STR_LEN],*crush_ptr=crush;
  U8 dst[STR_LEN],*dst_ptr=dst;
  I64 num;
  fptr=optr;
  while(ln=ReadALine(&fptr)) {
    if(*ln=='#'||*ln==0)
      goto skip;
    StrScan(ln,"%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
	  &num,
	  &cls_ptr,
	  &trig_ptr,
	  &dir_ptr,
	  &speed_ptr,
	  &change_ptr,
	  &model_ptr,
	  &monster_ptr,
	  &crush_ptr,
	  &dst_ptr
	  );
    ceil=CAlloc(sizeof CDoomLift);
    ceil->type='Ceil';
    action_sector_types[num]=ceil;
    ceil->trigger=trig[0](U16);

    if(!StrCmp(dir,"Up"))
      ceil->direction=FLOOR_DIR_UP;
    else if(!StrCmp(dir,"Dn"))
      ceil->direction=FLOOR_DIR_DOWN;
    else
      throw('Doom');

    if(!StrCmp("Slow",speed))
      ceil->speed=DOOR_SPEED_SLOW;
    else if(!StrCmp("Normal",speed))
      ceil->speed=DOOR_SPEED_NORMAL;
    else if(!StrCmp("Fast",speed))
      ceil->speed=DOOR_SPEED_FAST;
    else if(!StrCmp("Turbo",speed))
      ceil->speed=DOOR_SPEED_TURBO;
    else if(!StrCmp("Inst",speed))
      ceil->speed=1000.;
    else throw('Doom');

      //All these are unused(change,model,monseter,crush)?
    if(!StrCmp("Floor",dst))
      ceil->target=CEIL_DST_FLOOR;
    else if(!StrCmp("Highest Neighbor Ceiling",dst))
      ceil->target=CEIL_DST_HIGHEST_CEIL;
    else if(!StrCmp("8 Above Floor",dst))
      ceil->target=CEIL_DST_FLOOR8;
    else if(!StrCmp("Lowest Neighbor Ceiling",dst))
      ceil->target=CEIL_DST_LOWEST_CEIL;
    else if(!StrCmp("Highest Neighbor Floor",dst))
      ceil->target=CEIL_DST_HIGHEST_FLOOR;
    else
      throw('Doom');
skip:      
    Free(ln);
  }
  Free(optr);
}


#define DOOM_LIFTS_FILE "Platforms.TXT"

U0 LoadLifts() {
  U8 *optr=FileRead(DOOM_LIFTS_FILE),*fptr,*ln;
  StrUtil(optr,SUF_REM_CTRL_CHARS);
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  U8 speed[STR_LEN],*speed_ptr=speed;
  U8 change[STR_LEN],*change_ptr=change;
  U8 model[STR_LEN],*model_ptr=model;
  U8 monster[STR_LEN],*monster_ptr=monster;
  U8 target[STR_LEN],*target_ptr=target;
  U8 delays[STR_LEN],*delay_ptr=delays;
  F64 delay;
  I64 num;
  CDoomLift *lift;
  fptr=optr;
  while(ln=ReadALine(&fptr)) {
    if(*ln=='#') goto skip;
    StrScan(ln,"%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
	&num,
	&cls_ptr,
	&trig_ptr,
	&delay_ptr,
	&speed_ptr,
	&change_ptr,
	&model_ptr,
	&monster_ptr,
	&target_ptr
    );
    lift=CAlloc(sizeof CDoomLift);
    lift->type='Lift';
    action_sector_types[num]=lift;
    lift->trigger=trig[0](U16);
    if(*delays!='-')
      lift->delay=Str2F64(delays);
    else
      lift->delay=-1;
    if(*speed!='-') {
      if(!StrCmp("Slow",speed))
      lift->speed=DOOR_SPEED_SLOW;
      else if(!StrCmp("Normal",speed))
      lift->speed=DOOR_SPEED_NORMAL;
      else if(!StrCmp("Fast",speed))
      lift->speed=DOOR_SPEED_FAST;
      else if(!StrCmp("Turbo",speed))
      lift->speed=DOOR_SPEED_TURBO;
      else if(!StrCmp("Inst",speed))
      lift->speed=1000.;
      else throw('Doom');
    }
    if(*change!='-') {
      if(!StrCmp("Tx",change))
	lift->texture_change=TRUE;
      else if(!StrCmp("Tx0",change))
	lift->texture_change=lift->zero_type=TRUE;
      else if(!StrCmp("TxTy",change))
	lift->texture_change=TRUE,lift->type_change=TRUE;
      else if(!StrCmp("None",change))
	;
      else
        throw('Doom');
    }
    if(*model!='-') {
      if(!StrCmp("Trg",model))
        lift->model=FLOOR_MODEL_TRIGGER;
      else if(!StrCmp("Num",model))
        lift->model=FLOOR_MODEL_NUMBERED;
      else
	throw('Doom');
    } else
      lift->model=FLOOR_MODEL_NONE;
    if(*monster!='-') {
      if(!StrCmp("Yes",monster))
        lift->monster=TRUE;
      else if(!StrCmp("No",monster))
        lift->monster=FALSE;     
    }
    if(!StrCmp("Raise 24 Units",target)) {
      lift->target=LIFT_RAISE_24;
    } else if(!StrCmp("Raise 32 Units",target)) {
      lift->target=LIFT_RAISE_32;
    } else if(!StrCmp("Raise Next Floor",target)) {
      lift->target=LIFT_RAISE_NEXT_FLOOR;
    } else if(!StrCmp("Lowest and Highest Floor (perpetual)",target)) {
      lift->target=LIFT_LOW_HIGH_REPEAT;
    } else if(!StrCmp("Stop",target)) {
      lift->target=LIFT_STOP;
    } else if(!StrCmp("Lowest Neighbor Floor (lift)",target)) {
      lift->target=LIFT_LOWEST_FLOOR;
    } else if(!StrCmp(" Ceiling (toggle)",target)) {
      lift->target=LIFT_CEIL_TOGGLE;
    }
skip:;
  }
  Free(optr);
}
U0 LoadFloors() {
  U8 *optr=FileRead(DOOM_FLOORS_FILE),*fptr,*ln;
  I64 num;
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  U8 direction[STR_LEN],*direction_ptr=direction;
  U8 speed[STR_LEN],*speed_ptr=speed;
  U8 change[STR_LEN],*change_ptr=change;
  U8 mdl[STR_LEN],*mdl_ptr=mdl;
  U8 monster[STR_LEN],*monster_ptr=monster;
  U8 crush[STR_LEN],*crush_ptr=crush;
  U8 target[STR_LEN],*target_ptr=target;
  CDoomFloor *floor;
  StrUtil(optr,SUF_REM_CTRL_CHARS);
  fptr=optr;
  while(ln=ReadALine(&fptr)) {
    if(*ln=='#') goto skip;
    StrScan(ln,"%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
	  &num,
	  &cls_ptr,
	  &trig_ptr,
	  &direction_ptr,
	  &speed_ptr,
	  &change_ptr,
	  &mdl_ptr,
	  &monster_ptr,
	  &crush_ptr,
	  &target_ptr
	  );
    floor=CAlloc(sizeof CDoomFloor);
    floor->type='Floor';
    action_sector_types[num]=floor;
//Todo What the poo poo ants
    if(!StrCmp(cls,"Ext")) {
    } else if(!StrCmp(cls,"Reg")) {
    } else if(!StrCmp(cls,"Gen")) {
    }
//trigga
    floor->trigger=trig[0](U16); 
//Sped
    if(!StrCmp("Slow",speed)) {
      floor->speed=DOOR_SPEED_SLOW;
    } else if(!StrCmp("Fast",speed)) {
      floor->speed=DOOR_SPEED_FAST;
    } else if(!StrCmp("Normal",speed)) {
      floor->speed=DOOR_SPEED_NORMAL;
    } else if(!StrCmp("Turbo",speed)) {
      floor->speed=DOOR_SPEED_TURBO;
    } else if(speed[0]=='-') {
      floor->speed=0;
    } else 
      throw('Floor');
//Durectin
    if(!StrCmp("Up",direction)) {
      floor->direction=FLOOR_DIR_UP;
    } else if(!StrCmp("Dn",direction)) {
      floor->direction=FLOOR_DIR_DOWN;
    } else if(direction[0]=='-') {
      floor->direction=FLOOR_DIR_NONE;
    } else
      throw('Floor');
//cange
    if(!StrCmp("None",change)) {
    } else if(!StrCmp("TxTy",change)) {
      floor->texture_change=TRUE;
      floor->type_change=TRUE;
    } else if(!StrCmp("Tx",change)) {
      floor->texture_change=TRUE;
    } else if(!StrCmp("Ty",change)) {
      floor->type_change=TRUE;
    } else if(change[0]=='-') {
//Nothing to do
    }else
      throw('Floor');
//Instagram thot(model)
    if(!StrCmp("--",mdl)) {
      floor->model=FLOOR_MODEL_NONE;
    } else if(!StrCmp("Trg",mdl)) {
      floor->model=FLOOR_MODEL_TRIGGER;
    } else if(!StrCmp("Num",mdl)) {
      floor->model=FLOOR_MODEL_NUMBERED;
    } else
      throw('Floor');  
//Japanese tencacle pornstar(monster property)
    if(!StrCmp("No",monster)) {
      floor->monster=FALSE;
    } else if(!StrCmp("Yes",monster)) {
      floor->monster=TRUE;
    } else if(monster[0]=='-') {
    } else
      throw('Floor'); 
//Orange Soda (Crush property)
    if(!StrCmp("No",crush)) {
      floor->crush=FALSE;
    } else if(!StrCmp("Yes",crush)) {
      floor->crush=TRUE;
    } else if(crush[0]=='-') {
    } else
      throw('Floor'); 
//Target
    if(!StrCmp("Lowest Neighbor Floor",target)) {
      floor->target=FLOOR_DST_LOWEST;
    } else if(!StrCmp("Next Neighbor Floor",target)) {
      floor->target=FLOOR_DST_NEXT_FLOOR;
    } else if(!StrCmp("Lowest Neighbor Ceiling",target)) {
      floor->target=FLOOR_DST_LOWEST_CEIL;
    } else if(!StrCmp("Lowest Neighbor Ceiling - 8",target)) {
      floor->target=FLOOR_DST_LOWEST_CEIL_SUB_8;
    } else if(!StrCmp("Highest Neighbor Floor",target)) {
      floor->target=FLOOR_DST_HIGHEST_FLOOR;
    } else if(!StrCmp("Highest Neighbor Floor + 8",target)) {
      floor->target=FLOOR_DST_HIGHEST_FLOOR_ADD_8;
    } else if(!StrCmp("Absolute 24",target)) {
      floor->target=FLOOR_ABS_24;
    } else if(!StrCmp("Abs Shortest Lower Texture",target)) {
      floor->target=FLOOR_DST_LOWEST_TEXTURE;
    } else if(!StrCmp("Absolute 512",target)) {
      floor->target=FLOOR_ABS_512;
    } else if(!StrCmp("None",target)) {
    } else 
      throw('Floor');
skip:
    Free(ln);
  }
  Free(optr);
}

U0 LoadDoors() {
  U8 *optr=FileRead(DOOM_DOORS_FILE),*fptr,*ln;
  I64 num;
  CDoomDoor *door;
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  U8 key[STR_LEN],*key_ptr=key;
  U8 speed[STR_LEN],*speed_ptr=speed;
  U8 wait[STR_LEN],*wait_ptr=wait;
  U8 monster[STR_LEN],*monster_ptr=monster;
  U8 action[STR_LEN],*action_ptr=action;
  StrUtil(optr,SUF_REM_CTRL_CHARS);
  fptr=optr;
  while(ln=ReadALine(&fptr)) {
    if(*ln=='#') goto skip;
    StrScan(ln,"%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
	&num,
	&cls_ptr,
	&trig_ptr,
	&key_ptr,
	&speed_ptr,
	&wait_ptr,
	&monster_ptr,
	&action_ptr
	);
   door=CAlloc(sizeof CDoomDoor);
   door->type='Door';
   action_sector_types[num]=door;
   //Trigger
   door->trigger=trig[0](U16); 
   //Key
   if(!StrCmp("Yell",key)) {
     door->key=DOOR_LOCK_YELLOW;
   } else if(!StrCmp("Blue",key)) {
     door->key=DOOR_LOCK_BLUE;
   } else if(!StrCmp("Red",key)) {
     door->key=DOOR_LOCK_RED;
   } else if(!StrCmp("No",key)) {
     door->key=0;
   } else
     throw('Door');
   //Speed
  if(!StrCmp("Slow",speed)) {
    door->speed=DOOR_SPEED_SLOW;
  } else if(!StrCmp("Fast",speed)) {
    door->speed=DOOR_SPEED_FAST;
  } else 
    throw('Door');
  //Wait
  if(!StrCmp(wait,"--")) {
    door->wait=0.;
  } else if(StrOcc(wait,'s')) {
    door->wait=Str2F64(wait);
  } else 
    throw('Door');
  //Monster
  if(!StrCmp(monster,"Yes"))
    door->monster=TRUE;
  else if(!StrCmp(monster,"No"))
    door->monster=FALSE;
  else
    throw('Door');//Action
  if(!StrCmp("Open, Wait, Then Close",action)) {
    door->action=DOOR_ACTION_OPEN_WAIT_CLOSE;
  } else if(!StrCmp("Open and Stay Open",action)) {
    door->action=DOOR_ACTION_OPEN;
  } else if(!StrCmp("Close and Stay Closed",action)) {
    door->action=DOOR_ACTION_CLOSE;
  } else if(!StrCmp("Close, Wait, Then Open",action)) {
    door->action=DOOR_ACTION_CLOSE_WAIT_OPEN;
  } else 
    throw('Door');
skip:
    Free(ln);
  }
 
  Free(optr);
}

#define DOOM_EXITS_FILE "Exits.TXT"

U0 LoadExits() {
  I64 num;
  CDoomExit *exit;
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  U8 secret[STR_LEN],*sec_ptr=secret;
  U8 *fptr=FileRead(DOOM_EXITS_FILE),*optr=fptr,*ln;
  while(ln=ReadALine(&fptr)) {
    if(*ln=='#') goto skip;
    StrScan(ln,"%d\t%s\t%s\t%s\n",
	&num,
	&cls_ptr,
	&trig_ptr,
	&sec_ptr);
    exit=CAlloc(sizeof CDoomExit);
    exit->type='Exit';
    action_sector_types[num]=exit;
    exit->trigger=trig[0](U16);
    exit->secret=!StrCmp("Secret",secret);
skip:
  }
  Free(optr);
}

#define STAIRS_FILE "Stairs.TXT"
class CDoomStairs {
  U64 type,trigger;
  F64 speed;
  I64 step;
};
U0 LoadStairs() {
  I64 num;
  CDoomStairs *stairs;
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  U8 speed[STR_LEN],*speed_ptr=speed;
  U8 *fptr=FileRead(STAIRS_FILE),*optr=fptr,*ln;
  I64 step;
  while(ln=ReadALine(&fptr)) {
    if(*ln=='#') goto skip;
    StrScan(ln,"%d\t%s\t%s\tUp\t%s\t%d\t",
	&num,
	&cls_ptr,
	&trig_ptr,
	&speed_ptr,
	&step);
    stairs=CAlloc(sizeof(CDoomStairs));
    stairs->trigger=trig[0](U16);
    stairs->type='Stairs';
    action_sector_types[num]=stairs;
//Sped
    if(!StrCmp("Slow",speed)) {
      stairs->speed=DOOR_SPEED_SLOW;
    } else if(!StrCmp("Fast",speed)) {
      stairs->speed=DOOR_SPEED_FAST;
    } else if(!StrCmp("Normal",speed)) {
      stairs->speed=DOOR_SPEED_NORMAL;
    } else if(!StrCmp("Turbo",speed)) {
      stairs->speed=DOOR_SPEED_TURBO;
    } else if(speed[0]=='-') {
      stairs->speed=0;
    } else 
      throw('Stairs');
    stairs->step=step;
skip:
  }
  Free(optr);
}

class CDoomScroller1 {
  U64 type;
//If offset_type is set,it is scrolled by x/y offsets as rates
  I64 x,offset_type;
};

U0 LoadScrollers1() {
  CDoomScroller1 *s=CAlloc(sizeof CDoomScroller1);
  s->type='Scroll1';
  action_sector_types[48]=s;
  s->x=1;

  s=CAlloc(sizeof CDoomScroller1);
  s->type='Scroll1';
  action_sector_types[85]=s;
  s->x=-1;

  s=CAlloc(sizeof CDoomScroller1);
  s->type='Scroll1';
  action_sector_types[255]=s;
  s->offset_type=TRUE;

}

class CDoomCrusher {
  U64 type;
  U64 trigger;
  F64 speed;
  Bool monster;
  Bool silent;
 Bool turn_on;
};


U0 LoadCrushers() {
  CDoomCrusher *new;
  I64 num;
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  U8 speed[STR_LEN],*speed_ptr=speed;
  U8 mon[STR_LEN],*mon_ptr=mon;
  U8 silent[STR_LEN],*silent_ptr=silent;
  U8 action[STR_LEN],*action_ptr=action;
  U8 *fptr=FileRead("Crushers.TXT"),*optr=fptr,*ln;
  StrUtil(fptr,SUF_REM_CTRL_CHARS);
  while(ln=ReadALine(&fptr)) {
    if(!*ln||*ln=='#')
      goto skip;
    StrScan(ln,"%d\t%s\t%s\t%s\t%s\t%s\t%s\n",&num,&cls_ptr,&trig_ptr,&speed_ptr,&mon_ptr,&silent_ptr,&action_ptr);
    new=CAlloc(sizeof CDoomCrusher);
    action_sector_types[num]=new;
    new->type='Crush';

    new->trigger=trig[0](U16);

    if(!StrCmp(speed,"Slow"))
      new->speed=DOOR_SPEED_SLOW;
    else if(!StrCmp(speed,"Fast"))
      new->speed=DOOR_SPEED_FAST;
    else if(speed[0]!='-')
      throw('Doom');
   
    if(!StrCmp(silent,"Yes"))
      new->silent=TRUE;
    else if(!StrCmp(silent,"No"))
      new->silent=FALSE;
    else if(speed[0]!='-')
      throw('Doom');

    if(!StrCmp(action,"Start"))
      new->turn_on=TRUE;
    else if(!StrCmp(action,"Stop"))
      new->turn_on=FALSE;
    else if(speed[0]!='-')
      throw('Doom');

   
skip:
    Free(ln);
  }
  Free(optr);
}

#define LIGHT_35 1
#define LIGHT_255 2
#define LIGHT_BLINK 3
#define LIGHT_MAX_NIEGHBOR 4
#define LIGHT_MIN_NIEGHBOR 5
class CDoomLight {
  U64 type,trigger;
  I64 target;
};
U0 LoadLights() {
  CDoomLight *new;
  I64 num;
  U8 *optr=FileRead("Lights.TXT"),*fptr=optr,*ln;
  U8 cls[STR_LEN],*cls_ptr=cls;
  U8 trig[STR_LEN],*trig_ptr=trig;
  U8 what[STR_LEN],*what_ptr=what;
  while(ln=ReadALine(&fptr)) {
    if(!*ln||*ln=='#')
      goto skip;
    StrScan(ln,"%d\t\%s\t%s\t%s\n",&num,&cls_ptr,&trig_ptr,&what_ptr);
    new=CAlloc(sizeof CDoomLight);
    action_sector_types[num]=new;
    new->type='Light';

    new->trigger=trig[0](U16);   
   
    if(!StrCmp(what,"255 Units"))
      new->target=LIGHT_255;
    else if(!StrCmp(what,"35 Units"))
      new->target=LIGHT_35;
    else if(!StrCmp(what,"Blinking"))
      new->target=LIGHT_BLINK;
    else if(!StrCmp(what,"Maximum Neighbor"))
      new->target=LIGHT_MAX_NIEGHBOR;
    else if(!StrCmp(what,"Minimum Neighbor"))
      new->target=LIGHT_MIN_NIEGHBOR;
    else
       throw('Doom');
skip:;
    Free(ln);
  }  
  Free(optr);
}
LoadLights;
LoadExits;
LoadDoors;
LoadFloors;
LoadLifts;
LoadCeils;
LoadDonuts;
LoadTeleporters;
LoadStairs;
LoadScrollers1;
LoadCrushers;
I64 idx;
U8 buf[STR_LEN];
for(idx=0;idx!=0x10000;idx++)
  if(action_sector_types[idx]) {
    StrPrint(buf,"ACTION%d",idx,action_sector_types[idx]);
    UH(buf,action_sector_types[idx]);
  }
#endif