//#include "Weapons.HC";
extern Bool PlayerAttack(F64 shots_per_min,F64 min_damage,F64 max_damage,F64 range,U64 rocket_type=0);

#define SCREENWIDTH 640
#define SCREENHEIGHT 480

/*
**
** 	STATUSBARDATA/DEFINITIONS
**
*/
// For Responder
//#define ST_TOGGLECHAT			KEY_ENTER

// Location of status bar
#define ST_X				0
#define ST_X2				104
#define ST_FX  				143
#define ST_FY  				169

/*
**
** 	GLBLVARS
**
*/


// ST_Start() has just been called
static Bool st_firsttime = FALSE;
// whether left-side main status bar is active
static Bool st_statusbaron;
//used to change display of ammo left
I16 weaponIndex =0;
I32 maxBullets = 200;
I32 maxShells = 50;
I32 maxRockets = 50;
I32 maxCells = 300;



/*
**
** 	CLASSES
**
*/


I16 GetWeaponIndex()
{
  return weaponIndex;
}

Bool AddWeaponIndex(Bool pos)
{
  I64 idx;
  if(pos)
    {
#ifdef DOOM2
    for(idx=weaponIndex+1;idx!=9;idx++)
#else
    for(idx=weaponIndex+1;idx!=8;idx++)
#endif
      if(p->arsenal[idx].available)
        {
        weaponIndex=idx;
	break;
      }
  }
  else
    {
    for(idx=weaponIndex-1;idx>=0;idx--)
      if(p->arsenal[idx].available)
        {
        weaponIndex=idx;
	break;
      }
  }
}

// Multiple Icon widget
class MultiIcon
{
     // center-justified location of icons
    I64 x;
    I64 y;

    I64 x_off;
    I64 y_off; //Added by nroot


    // last icon number
    I64 oldinum;

    // pointer to current icon
    CDC *icon_dc;

    I64 state;
    I64 old_state;
    
    // user data
    I64 flash_x_off;
    I64 flash_y_off;
    CDC *flash_dc;
};




/*
**
** 	WIDGETS
**
*/



// face status widget
static MultiIcon	toom_faces;  
// weapon anims
static MultiIcon	weapons;

//weapons
static CDC*	SHOTGUN2;
static CDC*		PUNCH;
static CDC*		PUNCH1;
static CDC*		PUNCH2;
static CDC*		PUNCH3;
static CDC*		PISTOL;
static CDC*		PISTOLU;
static CDC*		PISTOL1;
static CDC*		PISTOL2;
static CDC*		PISTOL3;
static CDC*		PISTOLF;
static CDC*		SHOTGUN;
static CDC*		SHOTGUN1;
static CDC*		SHOTGUN2;
static CDC*		SHOTGUN3;
static CDC*		SHOTGUNF1;
static CDC*		SHOTGUNF2;
static CDC*		CHAINGUN;
static CDC*		CHAINGUN1;
static CDC*		CHAINGUNF1;
static CDC*		CHAINGUNF2;
static CDC*		MISSILELAUNCHER;
static CDC*		MISSILELAUNCHER1;
static CDC*		MISSILELAUNCHERF1;
static CDC*		MISSILELAUNCHERF2;
static CDC*		MISSILELAUNCHERF3;
static CDC*		MISSILELAUNCHERF4;
static CDC*		CHAINSAW;
static CDC*		CHAINSAW1;
static CDC*		CHAINSAW2;
static CDC*		CHAINSAW3;
static CDC*		PLASMAGUN;
static CDC*		PLASMAGUN1;
static CDC*		PLASMAGUNF1;
static CDC*		PLASMAGUNF2;
static CDC*		BFG;
static CDC*		BFG1;
static CDC*		BFG2;
static CDC*		BFGF1;
static CDC*		BFGF2;

//status bar and faces
static CDC*		ST;
static CDC*		FACE00;
static CDC*		FACE0L;
static CDC*		FACE0R;
static CDC*		FACE10;
static CDC*		FACE1L;
static CDC*		FACE1R;
static CDC*		FACE20;
static CDC*		FACE2L;
static CDC*		FACE2R;
static CDC*		FACE30;
static CDC*		FACE3L;
static CDC*		FACE3R;
static CDC*		FACE40;
static CDC*		FACE4L;
static CDC*		FACE4R;

//numbers
static CDC*		NUM0;
static CDC*		NUM1;
static CDC*		NUM2;
static CDC*		NUM3;
static CDC*		NUM4;
static CDC*		NUM5;
static CDC*		NUM6;
static CDC*		NUM7;
static CDC*		NUM8;
static CDC*		NUM9;
static CDC*		NUMPCT;

static CDC*		NUMS0;
static CDC*		NUMS1;
static CDC*		NUMS2;
static CDC*		NUMS3;
static CDC*		NUMS4;
static CDC*		NUMS5;
static CDC*		NUMS6;
static CDC*		NUMS7;
static CDC*		NUMS8;
static CDC*		NUMS9;

static CDC*		big_nums[10];
static CDC*		small_nums[10];
static CDC*		STGNUM[10];
static CDC*		STKEYS[6];
static CDC		*STARMS;
static Bool st_stopped = TRUE;

/*
**
**	FUNCTIONS
**
*/



static I64 st_palette = 0;
I64 DoomPrint(CDC *dc,I64 x,I64 y,U8 *fmt,...) {
  fmt=StrPrintJoin(NULL,fmt,argc,argv);
  I64 len=StrLen(fmt),idx,c,ox=x;
  CDC *ch_dc;
  U8 lump_name[16];
  for(idx=0;idx!=len;idx++) {
    c=ToUpper(fmt[idx]);
    if('!'<=c<='_') {
      StrPrint(lump_name,"STCFN%3d",c);
      while(StrOcc(lump_name,' '))
        *StrFirstOcc(lump_name," ")='0';
      ch_dc=GetGrLump(lump_name);
      if(ch_dc) {
        if(dc) GrBlot(dc,x-ch_dc->x*2,y-ch_dc->y*2,ch_dc);
        x+=ch_dc->width;
      } else
	x+=4*2;
    } else if(c=='\n') {
      x=ox;
      y+=11*2;
    } else 
      x+=4*2;
  }
  Free(fmt);
  return x;
} 

U0 DrawNumber(CDoomPlayer *p, U32 x, U32 y, U16 weapon,Bool large,Bool percent=FALSE)
{
  I64 ch;
  U32 num_width=10;
  if(large) num_width=28;
//bullets

  U64 ammoNum;
#ifdef DOOM2
  if(weapon>=9)
#else
  if(weapon>=8)
#endif
    {
    switch(weapon)
      {
      case 8:
        ammoNum=maxBullets;
        break;

      case 9:
        ammoNum=maxShells;
        break;

      case 10:
        ammoNum=maxRockets;
        break;

      case 11:
        ammoNum=maxCells;
        break;
      case 12: //health
        ammoNum=p->health;
        break;
      case 13: //armor
        ammoNum=p->armor;
        break;
    }
  }
  else
    {
    ammoNum = p->arsenal[weapon].load->ammo;
  }


  U8 buf[STR_LEN];
  StrPrint(buf,"%d",ammoNum);
  x+=(3+percent)*num_width/2;
  x-=(percent+StrLen(buf))*num_width/2;
  for(ch=0;ch!=StrLen(buf);ch++) {
    if(large)
      GrBlot(doom_scrn,x,y,big_nums[buf[ch]-'0']);
    else 
      GrBlot(doom_scrn,x,y,small_nums[buf[ch]-'0']);
    x+=num_width;
  }

  if(percent)    
    GrBlot(doom_scrn,x,y,NUMPCT);
}

U0 BlotWithLighting(CDC *to,I64 x,I64 y,CDC *dc,F64 light=255,Bool invis=FALSE) {
  I64 w=dc->width>>1,h=dc->height>>1,i,i2;
  U16 *src,*dst,*dst2;
  I32 lighting;
  U16 trans_pixel=TRANSPARENT|TRANSPARENT<<8;
  U16 black_pixel=BLACK|BLACK<<8;
  Bool god_mode=GodModeFilter;
  light+=LightOffset;
  x&=~1;
  for(i2=0;i2!=h;i2++) {
    if(to->height>i2*2+y>=0) {
      src=&dc->body[i2*2*dc->width_internal];
      dst=&to->body[x+(i2<<1+y)*to->width_internal];
      dst2=dst(U8*)+to->width_internal;
      for(i=0;i!=w;i++) {
        if(0<=x+i*2<to->width) {
	  if(invis) {
	    if(RandU16<ToI64(0x10000*.75)) {
	      if(*src!=trans_pixel)
	        lighting=black_pixel;
	      else
	        lighting=trans_pixel;
	    } else
	      lighting=trans_pixel;
	  } else
	    lighting=LookupLighting(*src,light,0.,god_mode);
	  if(lighting&0xff!=TRANSPARENT) {
	    *dst=lighting&0xffff;
	    *dst2=lighting>>16;
	  }
        }
        ++dst;
        ++dst2;
        src++;
      }
    }
  }
}

U0 ST_refreshBackground(CDoomPlayer *p)
{
  I64 idx,ix,iy;
  CDC *dc;
  F64 add;
  CDoomSector *s=GetSectorForCoord(l,p->x,p->y);

  if(Server_tS<p->muzzle_flash_end_tS)
    add=MUZZLE_FLASH_LIGHT;
  else
    add=0;

  if (st_statusbaron)
    {
//
    //WEAPONS
    //
    weapons.y=(200./480)*480-120;

    if(dc=weapons.icon_dc)
      BlotWithLighting(doom_scrn,weapons.x+weapons.x_off-dc->x*2,
	    weapons.y+weapons.y_off-dc->y*2,
	    dc,s->cur_light_level+add,ToBool(p->flags&MF_SHADOW));//weapon
    if(dc=weapons.flash_dc)
      BlotWithLighting(doom_scrn,
	    weapons.x+weapons.flash_x_off+weapons.x_off-dc->x*2,
	    weapons.y+weapons.y_off-dc->y*2,
	    dc,s->cur_light_level+add,ToBool(p->flags&MF_SHADOW));

      //STATUSBAR

    GrBlot(doom_scrn,0,SCREENHEIGHT-64,ST); //Read the ST

//Face
    if(toom_faces.icon_dc)
      GrBlot(doom_scrn,SCREENWIDTH/2-25,SCREENHEIGHT-60,///2-25 -60
	  toom_faces.icon_dc);//faces

    //bullets max
    DrawNumber(p,SCREENWIDTH-44,SCREENHEIGHT-55,8,FALSE);
    DrawNumber(p,SCREENWIDTH-44,SCREENHEIGHT-43,9,FALSE);
    DrawNumber(p,SCREENWIDTH-44,SCREENHEIGHT-30,10,FALSE);
    DrawNumber(p,SCREENWIDTH-44,SCREENHEIGHT-18,11,FALSE);

    //current ammo
    DrawNumber(p,SCREENWIDTH-84,SCREENHEIGHT-55,1,FALSE);
    DrawNumber(p,SCREENWIDTH-84,SCREENHEIGHT-43,2,FALSE);        
    DrawNumber(p,SCREENWIDTH-84,SCREENHEIGHT-30,4,FALSE);
    DrawNumber(p,SCREENWIDTH-84,SCREENHEIGHT-18,6,FALSE);

    //current ammo large
    DrawNumber(p,8,SCREENHEIGHT-52,weaponIndex,TRUE);
//current health
    DrawNumber(p,SCREENWIDTH-542,SCREENHEIGHT-52,12,TRUE,TRUE);
//current armor
    DrawNumber(p,SCREENWIDTH-282,SCREENHEIGHT-52,13,TRUE,TRUE);    
  }

  GrBlot(doom_scrn,208,SCREENHEIGHT-64,STARMS);

  for(idx=2;idx<=7;idx++) {
    switch(idx) {
      start:
        iy=212*2;
        case 2:
	  ix=111*2+2*12*0;
	  break;
        case :
	  ix=111*2+2*12*1;
	  break;
        case :
	  ix=111*2+2*12*2;
	  break;
      end:
        break;
      start:
        iy=222*2;
        case :
	  ix=111*2+2*12*0;
	  break;
        case :
	  ix=111*2+2*12*1;
	  break;
        case :
	  ix=111*2+2*12*2;
	  break;
      end:;
    }
    if(!p->arsenal[idx].available) {
      GrBlot(doom_scrn,ix,iy,STGNUM[idx]);
    } else
      GrBlot(doom_scrn,ix,iy,small_nums[idx]);

    if(l->has_red_key) {
      GrBlot(doom_scrn,2*239,212*2,STKEYS[2]);
    }
    if(l->has_blue_key) {
      GrBlot(doom_scrn,2*239,222*2,STKEYS[0]);
    }
    if(l->has_yellow_key) {
      GrBlot(doom_scrn,2*239,232*2,STKEYS[1]);
    }

  }
}

U0 ST_refresh(CDoomPlayer *p)
{
  ST_refreshBackground(p);
  if(*p->message) {
    DoomPrint(doom_scrn,4,5,p->message);
    if(Server_tS>p->message_end_tS)
      *p->message=0;
  }
}

U0 ST_Message(CDoomPlayer *p,U8 *msg) {
  StrCpy(p->message,msg);
  p->message_end_tS=Server_tS+2.5;
}

U0 InitWidgets()
{
  MemSet(&toom_faces,0,sizeof MultiIcon);
  MemSet(&weapons,0,sizeof MultiIcon);
}



U0 ST_ReadOnce()
{
  U8 dummy[16];
  I64 idx;
  if(st_firsttime ==FALSE)
    {
//not efficent
    st_firsttime = TRUE;
    InitWidgets();

    //STATUS BARS
    CWadDirectory *wad_dir=wad->body+wad->directory_ptr;  //Wads have a base pointer where the "directories" are stored

    for(idx=0;idx!=10;idx++) {
      StrPrint(dummy,"STGNUM%d",idx);
      STGNUM[idx]=GetGrLump(dummy);
    }

    for(idx=0;idx!=6;idx++) {
      StrPrint(dummy,"STKEYS%d",idx);
      STKEYS[idx]=GetGrLump(dummy);
    }

    STARMS=GetGrLump("STARMS");


    ST = GetGrLump("STBAR");
    for(idx=0;idx!=10;idx++) {
      StrPrint(dummy,"STTNUM%d",idx);
      big_nums[idx]=GetGrLump(dummy);
    }
    NUMPCT=GetGrLump("STTPRCNT");

    for(idx=0;idx!=10;idx++) {
      StrPrint(dummy,"STYSNUM%d",idx);
      small_nums[idx]=GetGrLump(dummy);
    }

  }
}

U0 AnimateFire(CDoomPlayer *p)
{
  U8 *anim=NULL;
  U8 *template=NULL;
  U8 *flash_template=NULL;
  U8 *flash_anim=NULL;
  U8 *pause_anim=NULL;
  U8 *idle_anim=NULL;
  U8 buf[STR_LEN];
  I64 fr,l,flash_off=0,ostate;
  F64 wait,next_frame;
  switch(weaponIndex)
    {
    case 0://punch
      if(p->weapon_state) ClientPlaySound("PUNCH");
      anim="BCDCB";
      template="PUNG%c0";
      idle_anim="A";
      break;
    case 1://pistol
      if(p->weapon_state) ClientPlaySound("PISTOL");
      anim="ABC";
      template="PISG%c0";
      flash_template="PISF%c0";
      flash_anim="A";
      flash_off=2;
      idle_anim="A";
      break;
    case 2://shotgun
      if(p->weapon_state) ClientPlaySound("SHOTGN");
      anim="AABCDCBAA";
      template="SHTG%c0";
      flash_template="SHTF%c0";
      flash_anim="AB";
      flash_off=0;
      idle_anim="A";
      break;
    case 3://chaingun
      if(p->weapon_state) ClientPlaySound("PISTOL");
      anim="ABB";
      template="CHGG%c0";
      flash_template="CHGF%c0";
      flash_anim="AB";
      idle_anim="A";
      flash_off=0;
      break;
    case 4://missile launcher
      if(p->weapon_state) ClientPlaySound("RLAUNC");
      template="MISG%c0";
      anim="BBB";
      flash_template="MISF%c0";
      flash_anim="ABCD";
      flash_off=0;
      idle_anim="A";
      break;
    case 5://chainsaw
      if(p->weapon_state) ClientPlaySound("SAWFUL"); 
      template="SAWG%c0";
      anim="ABB";
      idle_anim="CD";
      break;
    case 6://plasma gun
      if(p->weapon_state) ClientPlaySound("PLASMA");
      template="PLSG%c0";
      anim="A";
      pause_anim="B";
      flash_off=0;
      flash_template="PLSF%c0";
      flash_anim="AB";
      idle_anim="A";
      break;
    case 7://BFG
      if(p->weapon_state) ClientPlaySound("BFG");
      template="BFGG%c0";
      anim="ABBB";
      flash_template="BFGF%c0";
      flash_anim="AB";
      flash_off=1;
      idle_anim="A";
      break;
    case 8:
      if(p->weapon_state) ClientPlaySound("DSHTGN");
      template="SHT2%c0";
      anim="AABCDEFGHA";
      flash_template="SHT2%c0";
      flash_anim="IJ";
      flash_off=5;
      idle_anim="A";
      break;
  }
  weapons.flash_dc=NULL;
  ostate=p->weapon_state;
  if(p->weapon_state==0) {
    l=StrLen(idle_anim);
    for(fr=0;fr!=l;fr++) {
      StrPrint(buf,template,idle_anim[fr]);
      weapons.icon_dc=GetGrLump(buf);
      next_frame=.033*5+Server_tS;
      while(next_frame>Server_tS) {
        if(ostate!=p->weapon_state)
	  break;
        Refresh;
      }
    }
  } else if(p->weapon_state==1||p->weapon_state==2) {
    l=StrLen(anim);
    wait=p->weapon_cooldown/l;
    if(wait>=.030) {
      for(fr=0;fr!=l;fr++) {
        StrPrint(buf,template,anim[fr]);
        weapons.flash_dc=NULL;
        weapons.icon_dc=GetGrLump(buf);
        if(flash_anim&&fr>=flash_off) {
	  if(fr-flash_off<StrLen(flash_anim)) {
	    StrPrint(buf,flash_template,flash_anim[fr-flash_off]);
	    weapons.flash_dc=GetGrLump(buf);
	  }
        }
        next_frame=wait+Server_tS;
        while(next_frame>Server_tS) {
	  if(ostate!=p->weapon_state)
	    break;
	  Refresh;
        }
      }
    }
  } else if(p->weapon_state==3) { //PAUSEING
    l=StrLen(pause_anim);
    wait=p->weapon_cooldown/l;
    if(wait>=.030) {
      for(fr=0;fr!=l;fr++) {
        StrPrint(buf,template,pause_anim[fr]);
        weapons.icon_dc=GetGrLump(buf);
        next_frame=wait+Server_tS;
        while(next_frame>Server_tS) {
	  if(ostate!=p->weapon_state)
	    break;
	  Refresh;
        }
      }
    }
  }
}

U0 SwapWeapon(CDoomPlayer *p,I64 weapon)
{
  if(!p->arsenal[weapon].available)
    return;
  weaponIndex = weapon;
}
extern U0 AddBFGTracers(CDoomLevel*,CDoomThing*);
U0 ST_Fire(CDoomPlayer *p)
{
  switch(weaponIndex) {
    case 0: //First
      if(p->bezerk_time)
        PlayerAttack(123.5,20,200,70);
      else
        PlayerAttack(123.5,2,20,70);
      break;
    start:
      case 1: //Pistol
        if(p->arsenal[weaponIndex].load->ammo>0) {
	  if(PlayerAttack(150.,5,15,200*64.))
	    --p->arsenal[weaponIndex].load->ammo;
        }
        break;
      case 2: //Shotgun
        if(p->arsenal[weaponIndex].load->ammo>0) {
	  if(PlayerAttack(56.8,5,15,200*64.))
	    --p->arsenal[weaponIndex].load->ammo;
        }
        break;
      case 3: //Chainhun
        if(p->arsenal[weaponIndex].load->ammo>0) {
	  if(PlayerAttack(525,5,15,200*64.))
	    --p->arsenal[weaponIndex].load->ammo;
        }

        break;
      case 4: //Rocket
        if(p->arsenal[weaponIndex].load->ammo>0) {
	  if(PlayerAttack(105,20,160,200*64.,'Rocket'))
	    --p->arsenal[weaponIndex].load->ammo;
        }
        break;
      case 5: //Chainsaw
        PlayerAttack(525,2,20, 70);
        break;
      case 6: //Plsmaa
        if(p->arsenal[weaponIndex].load->ammo>0) {
	  if(PlayerAttack(700,5,40,200*64.,'Plasma'))
	    --p->arsenal[weaponIndex].load->ammo;
        }
        break;
      case 7: //Big poopin gun
        if(p->arsenal[weaponIndex].load->ammo>=20) {
	  if(PlayerAttack(52.5,100,800,200*64.,'BFG')) {
            AddBFGTracers(l,p);
	    p->arsenal[weaponIndex].load->ammo-=20;
	  }
        }
        break;
	case 8: //Suoper Shotgun
        if(p->arsenal[weaponIndex].load->ammo>=2) {
	  if(PlayerAttack(56.8,5,15,200*64.))
	    p->arsenal[weaponIndex].load->ammo-=2;
        }
	break;
    end:
      p->made_a_sound=TRUE;
  }
}


U0 ST_Exit()
{
}

CBGR48 defacto_pal[COLORS_NUM];
GrPaletteGet(defacto_pal);
U0 ST_DoPaletteStuff(CDoomPlayer *p,I64 pal) {
  static I64 old_pal=0;
  if(old_pal==pal) return;
  old_pal=pal;
//https://doomwiki.org/wiki/PLAYPAL
  F64 r,g,b;
  F64 percent;
  CBGR48 pal2[COLORS_NUM];
  I64 c;
  MemCpy(pal2,defacto_pal,sizeof(CBGR48)*COLORS_NUM);
  GrPaletteSet(pal2);
  if(!pal) return;
  switch(pal) {
    case 2...8:
      percent=1/9.*(pal-2+1);
      r=255,g=0,b=0;
      break;
    start:
      r=215,g=186,b=69;
      case 10:
        break;
        percent=.25;
      case 11:
        percent=.375;
        break;
      case 12:
        percent=.50;
        break;
    end:
      break;
    case 13:
      r=0,g=255,b=0;
      percent=.125;
      break;
  } 
  r*=0xffff/255.;
  g*=0xffff/255.;
  b*=0xffff/255.;
  for(c=0;c!=COLORS_NUM;++c) {
    pal2[c].r=(r*percent+pal2[c].r*(1.-percent));
    pal2[c].g=(g*percent+pal2[c].g*(1.-percent));
    pal2[c].b=(b*percent+pal2[c].b*(1.-percent));
  }
  GrPaletteSet(pal2);
}

CDC *ST_UpdateFacesTask(I64) {
  F64 old_health=100,angle,delay;
  U8 health_f,f2,stared_at;
  U8 *base,buf[STR_LEN];
  if(p) old_health=p->health;
again:;
  stared_at=FALSE;
  delay=0;
  if(p) {
    f2='0';
    base="ST";
    if(80<=p->health) {
      health_f='0';
    } else if(60<=p->health) {
      health_f='1';
    } else if(40<=p->health) {
      health_f='2';
    } else if(20<=p->health) {
      health_f='3';
    } else if(1<=p->health) {
      health_f='4';
    } else {
      toom_faces.icon_dc=GetGrLump("STFDEAD0");
      Refresh;
      goto again;
    }

    if(p->stare_at&&p->health>=1.) {
      angle=FArg(p->stare_at->y-p->x,p->stare_at->y-p->y);
//World is drawn backwards
      if(Sin(angle-p->angle)<0.)
        base="TL";
      else
        base="TR";
      delay=10*30;
      stared_at=TRUE;
    }
    if(old_health!=p->health) {
      if(old_health-p->health>=20.) {
        base="OUCH";
        delay=30*30;
      } else {
	base="KILL";
        delay=5*30;
      }
      old_health=p->health;
    }
    if(!StrCmp(base,"ST")) {
      if(Bt(kbd.down_bitmap,SC_CURSOR_LEFT)||Bt(kbd.down_bitmap,Char2ScanCode('a')))
        f2='0';
      else if(Bt(kbd.down_bitmap,SC_CURSOR_RIGHT)||Bt(kbd.down_bitmap,Char2ScanCode('d')))
        f2='2';
      else 
        f2='1';
    }
    if(StrLen(base)==2)
      StrPrint(buf,"STF%s%c%c",base,health_f,f2);
    else
      StrPrint(buf,"STF%s%c",base,health_f); 
    toom_faces.icon_dc=GetGrLump(buf);
    Sleep(delay);
    if(stared_at)
      p->stare_at=NULL,stared_at=FALSE;
  }
  Refresh;
  goto again;
}

U0 ST_Start(CDoomPlayer *p)
{
  I64 pal=0;
  st_statusbaron=TRUE;
  ST_ReadOnce();
  ST_refresh(p);
//ST_createWidgets();
  //ST_refresh();
  if(p->bezerk_time) {
    if(p->bezerk_time>20-8) {
      pal=7; 
    } else if(p->bezerk_time>7) {
      pal=4; 
    } else if(p->bezerk_time) {
      pal=2;
    }
  }
  if(p->hurt_amt) {
    pal=ClampI64(MaxI64(pal,ToI64(p->hurt_amt-- +7)>>3+2),2,8);
    if(p->hurt_amt<0.) p->hurt_amt=0.;
  } 
  if(!pal&&p->pickup_amt) {
    pal=ClampI64(ToI64(p->pickup_amt-- +7)>>3+10,10,12);
    if(p->pickup_amt<0.) p->pickup_amt=0.;
  } else 
    p->pickup_amt=MaxI64(p->pickup_amt---1,0); //Drain pickup amont to avoid wiating until bezerk is gone
 
  if(!pal&&p->rad_suit_time) {
    pal=13;
    if(p->rad_suit_time<5&&Blink)
      pal=0;
  }
  ST_DoPaletteStuff(p,pal);
}