#ifndef INTERMISSION
#define INTERMISSION "Thats all folks"
#define TITLEY ToI64(2*ToF64(GR_HEIGHT)/200)
#define SPACINGY ToI64(33*ToF64(GR_HEIGHT)/200)
#define STATSX (50*2)
#define STATSY ToI64(50*ToF64(GR_HEIGHT)/200)
#define TIMEX (16*2)
#define TIMEY (GR_HEIGHT-64)

#define ANIM_ALWAYS 0
#define ANIM_RAND 1
#define ANIM_LEVEL 2

CD2I64 lnodes[3][9]={
    // Episode 0 World Map
    {
	{ 185, 164 },	// location of level 0 (CJ)
	{ 148, 143 },	// location of level 1 (CJ)
	{ 69, 122 },	// location of level 2 (CJ)
	{ 209, 102 },	// location of level 3 (CJ)
	{ 116, 89 },	// location of level 4 (CJ)
	{ 166, 55 },	// location of level 5 (CJ)
	{ 71, 56 },	// location of level 6 (CJ)
	{ 135, 29 },	// location of level 7 (CJ)
	{ 71, 24 }	// location of level 8 (CJ)
    },
    // Episode 1 World Map should go here
    {
	{ 254, 25 },	// location of level 0 (CJ)
	{ 97, 50 },	// location of level 1 (CJ)
	{ 188, 64 },	// location of level 2 (CJ)
	{ 128, 78 },	// location of level 3 (CJ)
	{ 214, 92 },	// location of level 4 (CJ)
	{ 133, 130 },	// location of level 5 (CJ)
	{ 208, 136 },	// location of level 6 (CJ)
	{ 148, 140 },	// location of level 7 (CJ)
	{ 235, 158 }	// location of level 8 (CJ)
    },

    // Episode 2 World Map should go here
    {
	{ 156, 168 },	// location of level 0 (CJ)
	{ 48, 154 },	// location of level 1 (CJ)
	{ 174, 95 },	// location of level 2 (CJ)
	{ 265, 75 },	// location of level 3 (CJ)
	{ 130, 48 },	// location of level 4 (CJ)
	{ 279, 23 },	// location of level 5 (CJ)
	{ 198, 48 },	// location of level 6 (CJ)
	{ 140, 25 },	// location of level 7 (CJ)
	{ 281, 136 }	// location of level 8 (CJ)
    }
};

class CAnimT {
  I64 type;
  I64 period;
  I64 frames;
  CD2I64 at;
  I64 data1;
  CDC **frame_grs;
};
#define TICRATE 35.
CAnimT ep0animinfo[10]={
    { ANIM_ALWAYS, TICRATE/3, 3, { 224, 104 },0,NULL },
    { ANIM_ALWAYS, TICRATE/3, 3, { 184, 160 },0,NULL },
    { ANIM_ALWAYS, TICRATE/3, 3, { 112, 136 },0,NULL },
    { ANIM_ALWAYS, TICRATE/3, 3, { 72, 112 },0,NULL },
    { ANIM_ALWAYS, TICRATE/3, 3, { 88, 96 },0,NULL },
    { ANIM_ALWAYS, TICRATE/3, 3, { 64, 48 },0,NULL },
    { ANIM_ALWAYS, TICRATE/3, 3, { 192, 40 },0,NULL },
    { ANIM_ALWAYS, TICRATE/3, 3, { 136, 16 },0,NULL },
    { ANIM_ALWAYS, TICRATE/3, 3, { 80, 16 },0,NULL },
    { ANIM_ALWAYS, TICRATE/3, 3, { 64, 24 },0,NULL }
};
CAnimT ep1animinfo[9]={
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 1 ,NULL},
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 },2 ,NULL},
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 },3 ,NULL},
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 },4 ,NULL},
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 },5 ,NULL},
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 6 ,NULL},
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 7 ,NULL},
    { ANIM_LEVEL, TICRATE/3, 3, { 192, 144 }, 8 ,NULL},
    { ANIM_LEVEL, TICRATE/3, 1, { 128, 136 }, 8  ,NULL}
};
CAnimT ep2animinfo[6]={
    { ANIM_ALWAYS, TICRATE/3, 3, { 104, 168},0 ,NULL},
    { ANIM_ALWAYS, TICRATE/3, 3, { 40, 136 },0 ,NULL},
    { ANIM_ALWAYS, TICRATE/3, 3, { 160, 96 },0 ,NULL},
    { ANIM_ALWAYS, TICRATE/3, 3, { 104, 80 },0 ,NULL},
    { ANIM_ALWAYS, TICRATE/3, 3, { 120, 32 },0 ,NULL},
    { ANIM_ALWAYS, TICRATE/4, 3, { 40, 0 },0 ,NULL}
};

CDC *background;
CDC *anim_frames;
CDC *you_are_here;
CDC *you_are_here2;
CDC *splat;

U0 IntermessionLoadData(I64 ep,I64 level) {
  U8 buf[16],*tmp;
  I64 idx,idx2,anim_cnt;
  CAnimT *ep_ptr;
  switch(ep) {
    case 0:
      ep_ptr=ep0animinfo;
      anim_cnt=10;
      break;
    case 1:
      ep_ptr=ep1animinfo;
      anim_cnt=9;
      break;
    case 2:
      ep_ptr=ep2animinfo;
      anim_cnt=6;
      break;
    case 3:
      anim_cnt=0;
  }
  if(ep==3) {
    background=GetGrLump("INTERPIC");
    return;
  } else
    StrPrint(buf,"WIMAP%d",ep);
  if(!GetGrLump(buf))
    LoadGrLump(wad,buf);
  background=GetGrLump(buf);
  for(idx=0;idx!=anim_cnt;idx++) {
    ep_ptr[idx].frame_grs=CAlloc(8*ep_ptr[idx].frames);
    for(idx2=0;idx2!=ep_ptr[idx].frames;idx2++) {
      if(ep!=1||idx!=8) {
        StrPrint(buf,"WIA%d%2d%2d",ep,idx,idx2);  
//TempleOS pads with ' ',use '0' instead
        while(tmp=StrFirstOcc(buf," "))
	  *tmp='0';
        while(!GetGrLump(buf))
	  LoadGrLump(wad,buf);
        ep_ptr[idx].frame_grs[idx2]=GetGrLump(buf);
      } else 
        ep_ptr[idx].frame_grs[idx2]=ep_ptr[4].frame_grs[idx];
    }
  }
}
//Returns digits
I64 PrintNum(CDC *to_dc,I64 x,I64 y,I64 num) {
  U8 buf[16],buf2[16];
  I64 digits=0,idx;
  CDC *dc;
  do {
    buf[digits]=num%10;
    num/=10;
    digits++;
  }while(num);
  for(idx=0;idx<digits;idx++) {
    StrPrint(buf2,"WINUM%d",buf[idx]);
    dc=GetGrLump(buf2);
    x-=dc->width;
    GrBlot(to_dc,x,y,dc);
  }
  return digits;
}

U0 DrawPercent(CDC *to_dc,I64 x,I64 y,F64 have,F64 max) {
  if(!max) {
    max=1.;
  }
  PrintNum(to_dc,x,y,have/max*100);
  GrBlot(to_dc,x,y,GetGrLump("WIPCNT"));
}

U0 DrawAnimatedBackground(CDC *to_dc,I64 ep,I64 l) {
  I64 anim_cnt,idx,f;
  CAnimT *ep_ptr;
  CDC *with;
  F64 t=tS;
  switch(ep) {
    case 0:
      ep_ptr=ep0animinfo;
      anim_cnt=10;
      break;
    case 1:
      ep_ptr=ep1animinfo;
      anim_cnt=9;
      break;
    case 2:
      ep_ptr=ep2animinfo;
      anim_cnt=6;
      break;
    case 3:
      ep_ptr=NULL;
      anim_cnt=0;
      break;
  }
  for(idx=0;idx!=anim_cnt;idx++) {
    if(ep_ptr[idx].type==ANIM_LEVEL) {
      if(ep_ptr[idx].data1!=l)
	goto skip;
    }
    f=ToI64(t/(1./35.*ep_ptr[idx].period));
    f%=ep_ptr[idx].frames;
    with=ep_ptr[idx].frame_grs[f];
    GrBlot(to_dc,
	-with->x+ep_ptr[idx].at.x<<1,
	-with->y+ep_ptr[idx].at.y<<1,
	with);
skip:;
  }
}

U0 DrawSplats(CDC *to_dc,I64 ep,I64 l) {
//No splats for the final episode
  if(ep==3) return;
  I64 idx,x,y;
  CDC *s=GetGrLump("WISPLAT");
  for(idx=0;idx!=l;idx++) {
    x=2*lnodes[ep][idx].x-s->x*2;
    y=2*lnodes[ep][idx].y-s->y*2;
    GrBlot(to_dc,x,y,s);
  }

  //Use smaller one if not fit
  s=GetGrLump("WIURH0");
  x=2*lnodes[ep][l].x-s->x*2;
  y=2*lnodes[ep][l].y-s->y*2;
  if(x>=0&&x+s->width<=GR_WIDTH
        &&y>=0&&y+s->height<=GR_HEIGHT) {
    s=GetGrLump("WIURH1");
    x=2*lnodes[ep][l].x-s->x*2;
    y=2*lnodes[ep][l].y-s->y*2;
  }
  if(Blink) {
    GrBlot(to_dc,x,y,s);
  }
}

U0 DrawStats(CDC *to_dc,CDoomLevel *l,I64 ep,I64 l2,I64 tick=0) {
  I64 lw=3*16/2;
  I64 y=STATSY;
  GrBlot(to_dc,STATSX,y,GetGrLump("WIOSTK"));
  if(tick<l->stats.have_kills) {
    DrawPercent(to_dc,GR_WIDTH-STATSX,y,tick,l->stats.max_kills);
    tick=0;
  } else {
    DrawPercent(to_dc,GR_WIDTH-STATSX,y,l->stats.have_kills,l->stats.max_kills);
    tick-=l->stats.have_kills;
  }
  y+=lw;
  GrBlot(to_dc,STATSX,y,GetGrLump("WIOSTS"));
  if(tick<l->stats.have_secrets) {
    DrawPercent(to_dc,GR_WIDTH-STATSX,y,tick,l->stats.max_secrets);
    tick=0;
  } else {
    DrawPercent(to_dc,GR_WIDTH-STATSX,y,l->stats.have_secrets,l->stats.max_secrets);
    tick-=l->stats.have_secrets;
  }
  y+=lw;
  GrBlot(to_dc,STATSX,y,GetGrLump("WIOSTI"));
  if(tick<l->stats.have_items) {
    DrawPercent(to_dc,GR_WIDTH-STATSX,y,tick,l->stats.max_items);
    tick=0;
  } else {
    DrawPercent(to_dc,GR_WIDTH-STATSX,y,l->stats.have_items,l->stats.max_items);
    tick-=l->stats.have_items;
  }
//TODO par
}

extern U8 *NextLevel(U8 *nm,Bool special=FALSE);
extern U0 Finale(CDoomLevel*level,I64 ep);
U0 Intermission(CDoomLevel *lev,I64 ep,I64 l) {
  U8 buf[16];
  I64 state=0;
  I64 sc,ch,hit,y;
  CDC *dc;
  U8 *next=NextLevel(lev->map_name);
PrintI(lev->map_name,next);
PrintI(next,2);
#ifndef DOOM2
  IntermessionLoadData(ep,l);
#endif
  F64 start_ts=tS;
  FlushMsgs;
  while(state<2) {
    
#ifndef DOOM2
    GrBlot(doom_scrn,0,0,background);
    DrawAnimatedBackground(doom_scrn,ep,l);
#else
    LoadGrLump(wad,"INTERPIC");
    dc=GetGrLump("INTERPIC");
    GrBlot(doom_scrn,0,0,dc);
#endif
    if(!state) {
      y=TITLEY;
      dc=GetGrLump("WIF");
      GrBlot(doom_scrn,(GR_WIDTH-dc->width)/2,y,dc);
      y+=(5*dc->height)/4;
#ifndef DOOM2
      StrPrint(buf,"WILV%d%d",ep,l); //Lvel name
      LoadGrLump(wad,buf); //Will load once
      dc=GetGrLump(buf);
      if(!dc) {
        StrPrint(buf,"CWILV%d%d",ep,l); //Lvel name,ultimate doom
        LoadGrLump(wad,buf); //Will load once
        dc=GetGrLump(buf);
      }
      GrBlot(doom_scrn,(GR_WIDTH-dc->width)/2,y,dc);
      DrawSplats(doom_scrn,ep,l);
#else
//'MAP'XX (XX is map number(0 indexed))
      StrPrint(buf,"CWILV%02d",Str2I64(lev->map_name+3)-1); //-1 as levels start from 00(but are named MAP01-MAPXXX)
      LoadGrLump(wad,buf); //Will load once
      dc=GetGrLump(buf);
      GrBlot(doom_scrn,(GR_WIDTH-dc->width)/2,y,dc);
      y+=(5*dc->height)/4;
#endif

    } else {
      y=TITLEY;
      dc=GetGrLump("WIENTER");
      GrBlot(doom_scrn,(GR_WIDTH-dc->width)/2,y,dc);
      y+=(5*dc->height)/4;
#ifndef DOOM2
      StrPrint(buf,"WILV%d%d",ep,l+1); //Lvel name
      LoadGrLump(wad,buf); //Will load once
      dc=GetGrLump(buf);
      if(!dc) {
        StrPrint(buf,"CWILV%d%d",ep,l); //Lvel name,ultimate doom
        LoadGrLump(wad,buf); //Will load once
        dc=GetGrLump(buf);
      }
      if(!dc) return; //??? TODO text intermission
      GrBlot(doom_scrn,(GR_WIDTH-dc->width)/2,y,dc);
      DrawStats(doom_scrn,lev,ep,l,(tS-start_ts)*30.);
#else
     if(next) {
//'MAP'XX (XX is map number)
        StrPrint(buf,"CWILV%02d",Str2I64(lev->map_name+3));
        LoadGrLump(wad,buf); //Will load once
        dc=GetGrLump(buf);
        GrBlot(doom_scrn,(GR_WIDTH-dc->width)/2,y,dc);
      }
      DrawStats(doom_scrn,lev,ep,l,(tS-start_ts)*30.);
#endif
    }
    while(ScanKey) {
	FlushMsgs;
        state++;
    }
    GrBlot(,0,0,doom_scrn);
    Refresh;
  }
#ifdef DOOM2
    Finale(doom_scrn,Str2I64(lev->map_name+3));
#endif
}
#endif