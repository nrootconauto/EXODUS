#ifndef DOOM_WAD
#define DOOM_WAD" Whats Poppin"
#define DEBUG 1
#include "Set.HC";
U32 class CRGB {
  U8 r,g,b,a;
};
class CDoomGr {
  CRGB *palette;
  I64 pname_cnt;
  U64 *pnames;
  CI64Set *sprite_names;
} *dgr;

#include "Serialize.HC";
class CWad {
  U8 body[0];
  U8 ident[4];
  U32 lump_cnt;
  U32 directory_ptr;
}; 

I64 wad_cnt=0;
CWad *wads[0x100];
I64 wad_sizes[0x100];

CWad *wad;
CWad *LoadWad(U8 *filename) {
  wads[wad_cnt]=FileRead(filename,&wad_sizes[wad_cnt]);
  if(!wad_cnt) wad=wads[wad_cnt];
  wad_cnt++;
}

#include "ModMan.HC";


#define TICK_TIME (1/30.)

#include "DoomGr.HC";
#include "Numbers/Vector.HC";
#include "World.HC";
#include "Things.HC";
//https://doomwiki.org/wiki/WAD
class CWadDirectory {
  U32 ptr;
  U32 lump_size;
  U8 lump_name[8];
};



//https://doomwiki.org/wiki/Thing
class CWadThing {
#define  WAD_THINGF_SKILL12 1
#define  WAD_THINGF_SKILL3 2
#define  WAD_THINGF_SKILL45 4
#define  WAD_THINGF_WAIT 8 //Monster will be waiting
#define  WAD_THINGF_MULTIPLAYER 0x10 //For multiplayer maps 
  I16 x,y,angle;
  U16 thing_type,flags;
};

//https://doomwiki.org/wiki/Linedef
class CWadLinedef {
  U16 start_vertex;
  U16 end_vertex;
#define WAD_LINEDEFF_WALL 1 //Wall for player and monsters
#define WAD_LINEDEFF_WALL_MONSTER 2 //Wall for monsters only
#define WAD_LINEDEFF_2SIDED 4
#define WAD_LINEDEFF_UPPER_UNPEGGED 8
#define WAD_LINEDEFF_LOWER_UNPEGGED 0x10
#define WAD_LINEDEFF_SECRET 0x20
#define WAD_LINEDEFF_BLOCK_SOUND 0x40
#define WAD_LINEDEFF_NO_SHOW_ON_MAP 0x80
#define WAD_LINEDEFF_SHOW_ON_MAP 0x100
  U16 flags;
  U16 special_type;
  U16 sector_tag;
  U16 front,back; //See CWadSidedef
};

class CWadSidedef {
  I16 x_offset;
  I16 y_offset;
  U8 upper_texture_name[8];
  U8 lower_texture_name[8];
  U8 middle_texture_name[8];
  U16 sector;
};

class CWadSector {
  I16 floor_height;
  I16 ceil_height;
  U8 floor_texture_name[8];
  U8 ceil_texture_name[8];
  I16 	light_level;
#define WAD_SECTOR_NORMAL 0
#define WAD_SECTOR_BLINK_RAND 1
#define WAD_SECTOR_BLINK05 2
#define WAD_SECTOR_BLINK1 3
#define WAD_SECTOR_BLINK05_DAM20 4
#define WAD_SECTOR_DAM10 5
#define WAD_SECTOR_DAM5 7
#define WAD_SECTOR_LIGHT 8 //Ossicaltes
#define WAD_SECTOR_SECRET 9
#define WAD_SECTOR_DOOR_CLOSE30 10 //(Ceiling) Door clooses after 30 seconds
#define WAD_SECTOR_END 11 //20 damage a second,level END's when dead
#define WAD_SECTOR_BLINK1_2 12
#define WAD_SECTOR_BLINK05_2 13
#define WAD_SECTOR_DOOR_OPEN300 14 //(Ceiling) Door opens after 300 seconds
#define WAD_SECTOR_DAM20 16
#define WAD_SECTOR_BLINK_RAND_2 17
  I16 special_type;
  U16 tag_number;
};

class CWadVertex {
  I16 x,y;
};


class CWadSeg {
  U16 start_vertex,end_vertex;
  I16 angle,linedef;
//0 is same dir as linedef,else opposite
  I16 opposite_side,offset; 

};


class CWadSubsector {
//Consistys of SEGS
  U16 cnt;
  U16 first;
}; 


//extern class CDoomAnimationFrame;
class CDoomThing:CQue {
  F64 x,y,angle,height,health;
  F64 momx2,momy2,momz2; //Monster momentum  per game-tick
  F64 momx,momy,momz; //Move momentum
  F64 anim_start_tS;
  CDoomAnimationFrame *animation;
  U16 thing_type,pad[3];
  CDoomThingTemplate *template;
  I64 flags;
  I64 hash;
  Bool solid,anim_no_repeat,pad[6];
  U8 *thinker;
};
extern class CDoomSector;

class CDoomSidedef:CQue {
  I16 yoff,xoff;
  CDC *upper_texture[4]; //These are for animations
  CDC *lower_texture[4];
  CDC *middle_texture[4];
  CDoomSector *sector;
};



class CBoundBoxI16 {
  I16 y2,y,x2,x;
};

class CWadBSPNode {
  I16 x,y;
  I16 dx,dy;
  CBoundBoxI16 left,right;
//Dont ask me what these do
  U16 left_child,right_child;
};

class CBoundBoxF64 {
  F64 y,y2,x,x2;
};


class CDoomBSPNode:CQue {
  U64 signature;
  CDoomBSPNode *left_child,*right_child;
  CDoomBSPNode *parent;
  F64 x,y;
  F64 dx,dy;  
  CBoundBoxF64 left,right;
  Bool visited;
};

Bool BoundBoxF64Inside(F64 x,F64 y,CBoundBoxF64 *box) {
  if(box->x<box->x2) 
    if(!(box->x<=x<=box->x2))
      return FALSE;
  if(box->y<box->y2) 
    if(!(box->y<=y<=box->y2))
      return FALSE;
  if(box->x>box->x2) 
    if(!(box->x2<=x<=box->x))
      return FALSE;
  if(box->y>box->y2) 
    if(!(box->y2<=y<=box->y))
      return FALSE;
  return TRUE;
}

class CDoomLinedef:CQue {
  CD2 *start,*end;
  CDoomSidedef *front;
  CDoomSidedef *back;
  I64 sector_tag;
  I16 flags;
  CDoomActionSector *special_type;
  I16 pad[2];
//private
  CD2 clip_start,clip_end;
  Bool in_view,seen,activated;
};


class CDoomBSPSeg {
  CD2 *start,*end;
  CDoomLinedef *linedef;
  I64 size,offset;
  Bool back_side;
};

class CDoomSubsector:CQue {
  U64 signature;
  I64 cnt;
  CDoomSector *sector;
  CDoomBSPSeg *first;
};
class CDoomSector:CQue {
  CDC *floor_dc[4];
  CDC *ceil_dc[4];
  F64 ceil_height;
  F64 floor_height;
  F64 base_ceil_height;
  F64 base_floor_height;
  F64 base_light_level,cur_light_level;
  I64 special_type;
  I64 tag_number;
  I64 linedef_cnt;
  I64 idx;
  CDoomLinedef **linedefs;
//Private
//I will render the floors then I will cast them to the screen
//I tried everything else but I just cant figure out how to draw the floors
  CDoomLinedef *cur_action_linedef;
  CDoomThing *noise_thing; //Last thing that made a noise
  CI64Set *things;
  F64 door_height_offset;
  I64 visplane_idx;
  Bool drawn;
  Bool paused; //Pause the action on the sector
  Bool bumped_into; //used for re-opening doors
  Bool sound_check;
//TRUE if the texture/type has changed
  Bool tx_changed;
  Bool ty_changed;
  CDoomSector *changed_from_sector;  //This is the sector we changed from
};

class CLevelStats {
  I64 have_kills,max_kills;
  I64 have_items,max_items;
  I64 have_secrets,max_secrets;
  F64 time;
};


class CDoomLevel {
  CQue things,sidedefs;
  CQue subsectors;
  CQue bsp_nodes;
  CQue thinkers;
  CDoomBSPSeg *segs;
  CQue sectors;
  CDoomBSPNode *root_node;
  I64 vertice_cnt;
  CD2 *vertices;
  CQue linedefs;
 I64 block_map_x_off,block_map_y_off;
  I64 block_map_cols,block_map_rows;
  I64 *block_map_offsets;
  I64 skill,episode;
  CI64Set **block_map_things;
  CDoomSector **block_map_data;
  CDoomLinedef **action_linedefs;
  CLevelStats stats;
//ended is TRUE if we exited the level by pressing a button etc
  Bool has_red_key,has_blue_key,has_yellow_key,ended,ended_special;
  Bool has_map;
  U8 *reject;
  I64 sector_cnt;
  U8 map_name[8]; //EXMY
};

class CWadTexturePatch {
  I16 origin_x,origin_y;
  I16 patch_index;
  I16 unused,unused2;
};

class CWadTexture {
  U8 name[8];
  I32 unused;
  I16 w,h;
  I32 unused2;
  I16 patch_cnt; 
  CWadTexturePatch patches[0];
};

class CWadTEXTURE1 {
  I32 num_textures;
  I32 texture_offsets[0];
};
U8 *Upper8(U8 *eight) {
  I64 cnt=8;
  while(--cnt>=0)
   eight[cnt]=ToUpper(eight[cnt]);
  return eight;
}

CDC *TextureName2DC(U8 *name) {
  U8 buf[16];
  U8 name2[9];
  name2[8]=0;
  MemCpy(name2,name,8);
  Upper8(name2);
  StrPrint(buf,"Txr.%s",name2);
  return FramePtr(buf,doom_task);
}

CDC *SpriteName2DC(U8 *name) {
  U8 buf[16];
  U8 name2[9];
  name2[8]=0;
  MemCpy(name2,name,8);
  Upper8(name2);
  StrPrint(buf,"Spr.%s",name2);
  return FramePtr(buf,doom_task);
}


CDC *PNameIndexToDC(I64 idx,CDoomGr *gr) {
  U8 name[9],buf[16];
  name[8]=0;
  MemCpy(name,&gr->pnames[idx],8);
  Upper8(name);
  StrPrint(buf,"Pat.%s",name);
  return FramePtr(buf,doom_task);
}


U0 LoadWadTEXTUREs(CWadTEXTURE1 *header,CDoomGr *gr) {
  I64 texture,i,anim_cnt,x,y;
  U8 name[9],buf[16];
  CDC *result,*patch;
  CWadTexture *map_texture;
  for(texture=0;texture!=header->num_textures;texture++) {
    map_texture=header(U8*)+header->texture_offsets[texture];
    result=DCNew(map_texture->w*2,map_texture->h*2);
    DCFill(result,TRANSPARENT);
    name[8]=0;
    MemCpy(name,map_texture->name,8);
    for(i=0;i!=map_texture->patch_cnt;i++) {
      if(patch=PNameIndexToDC(map_texture->patches[i].patch_index,gr))
      GrBlot(result,
	map_texture->patches[i].origin_x*2,
	map_texture->patches[i].origin_y*2,
	patch);
    }
    for(x=0;x!=result->width;x++)
      for(y=0;y!=result->height;y++) {
	if(GrPeek0(result,x,y)==TRANSPARENT)
	  goto fin;
      }
//MAKE SURE TO SET THIS FOR THE RENDERER
    result->flags|=DCF_NO_TRANSPARENTS;
fin:
    Upper8(name);
    StrPrint(buf,"Txr.%s",name);
    UH(buf,result);
    FramePtrAdd(buf,result,doom_task);
  }
}

I64 StrCmp8(U8 *a,U8 *b) {
  if(StrLen(a)>8||StrLen(b)>8)
    return StrNCmp(a,b,8);
  return StrCmp(a,b);
}


// Patches.
// A patch holds one or more columns.
// Patches are used for sprites and all masked pictures,
// and we compose textures from the TEXTURE1/2 lists
// of patches.
class patch_t 
{ 
    I32 width;		// bounding box size 
    I32 height; 
    I32 leftoffset;	// pixels to the left of origin 
    I32 topoffset;	// pixels below the origin 
    I64 columnofs[8];	// only [width] used
    // the [0] is &columnofs[width] 
};


//
// W_CheckNumForName
// Returns -1 if name not found.
//

I64 W_CheckNumForName (U8 *name,CWad *doom_wad,I64 inst=1)
{

    U8 name8[9];    
    
    I32		v1;
    I32		v2;
    CWadDirectory*	lump_p;

    // make the name into two integers for easy compares
    MemCpy (name8,name,8);

    // in case the name was a fill 8 chars
    name8[8] = 0;

    // case insensitive
    for(v1=0;v1!=8;v1++)
      name8[v1]=ToUpper(name8[v1]);

    // scan backwards so patch lump files take precedence
    CWadDirectory *lumpinfo = doom_wad(U8*)+doom_wad->directory_ptr;
    lump_p=lumpinfo+doom_wad->lump_cnt;

    while (lump_p-- != lumpinfo)
    {
	if (!StrCmp8(lump_p->lump_name,name8))
	{
	    if(--inst<=0)
	      return lump_p - lumpinfo;
	}
    }

   return -1;
}

//
//Nroot,get lump by num
//
U8 *W_GetLumpPtrFromNum(I64 idx,CWad *wad,I64 *lump_len=NULL) {
  CWadDirectory *dir=wad(U8*)+wad->directory_ptr;
  dir+=idx;
  if(lump_len) *lump_len=dir->lump_size;
  return wad(U8*)+dir->ptr;
} 
//
// Nroot,Get pointer to lump
//
// wad can be NULL for iterating through all the laoded WAD's
U8 *W_GetLumpPtrFromName(U8 *name,CWad *wad=NULL,I64 *lump_len=NULL,I64 which=1) {
  I64 idx,widx;
  if(wad) {
      idx=W_CheckNumForName(name,wad,which);
      return W_GetLumpPtrFromNum(idx,wad,lump_len);
  }
  for(widx=wad_cnt-1;widx>=0;widx--) {
    idx=W_CheckNumForName(name,wads[widx],which);
    if(idx!=-1) {
      return W_GetLumpPtrFromNum(idx,wads[widx],lump_len);
    }
  }
  return NULL;
}



U0 AddLinedefToSector(CDoomSector *ld,CDoomSector *s) {
  CDoomLinedef **list=MAlloc(8*(s->linedef_cnt+1));
  if(s->linedef_cnt)
    MemCpy(list,s->linedefs,8*s->linedef_cnt);
  Free(s->linedefs);
  s->linedefs=list;
  list[s->linedef_cnt++]=ld;
}

CDoomBSPNode *DoomWhichBSPNode(F64 x,F64 y,CDoomLevel *level,CDoomSubsector **ss=NULL) {
  CDoomBSPNode *cur_node=level->root_node;
  CD2 pline_body[2];
  Bool left,right;
  CD2 dummy;
  F64 x2,y2;
  if(ss) *ss=NULL;
  while(TRUE) {
    if(!cur_node)
      break;
//Check which side of parition line
    x2=x-cur_node->x;
    y2=y-cur_node->y;
    if(y2*cur_node->dx-x2*cur_node->dy<0.) {
      if(cur_node->left_child->signature!='NODE') {
        if(ss) *ss=cur_node->left_child;
        return cur_node;
      }
      cur_node=cur_node->left_child;
    }  else {
      if(cur_node->right_child->signature!='NODE') {
        if(ss) *ss=cur_node->right_child;
        return cur_node;
      }
      cur_node=cur_node->right_child;
    }
//
  }
  return NULL;
}

#include "Intersect.HC"

class CWadPnames {
  I32 len;
  U64 names[0];
};


I64 PNameIndex(U8 *name,CDoomGr *gr) {
  I64 idx=gr->pname_cnt;
  while(--idx>=0) {
    if(!StrCmp8(&gr->pnames[idx],name))
      return idx;
  }
  return -1;
}
extern CDC *GetGrLump(U8 *name);
U0 LoadGrLump(CWad *wad,U8 *name) {
  I64 idx;
  for(idx=wad_cnt-1;idx>=0;idx--) {
    wad=wads[idx];
    if(W_CheckNumForName(name,wad)!=-1)
      goto pass; 
  }
  return ;
pass:
  CWadDirectory *wad_dir=wad->body+wad->directory_ptr;
  U8 lump_name[9],buf[16];
  wad_dir+=W_CheckNumForName(name,wad);
  MemCpy(lump_name,wad_dir->lump_name,8);
  Upper8(lump_name);
  lump_name[8]=0;
  StrPrint(buf,"Gr.%s",lump_name);
  if(FramePtr(buf,doom_task))
    return;
  CDC *gr=ReadDoomImage(wad->body+wad_dir->ptr);
  UH(buf,gr);
  FramePtrAdd(buf,gr,doom_task);
}

CDC *GetGrLump(U8 *name) {
  CDC *ret;
  U8 name2[9],buf[16];
  name2[8]=0;
  MemCpy(name2,name,8);
  Upper8(name2);
  StrPrint(buf,"Gr.%s",name2);
  if(ret=FramePtr(buf,doom_task)) 
    return ret;
  LoadGrLump(wad,name2);
  return FramePtr(buf,doom_task);
}


//
// Nroots note,$BK,1$USE W_GetLumpPtrFromName("name",NULL) to consult Patch WADs first$BK,0$
//
CDoomGr *LoadWadGr() {
  CDoomGr *ret=CAlloc(sizeof(CDoomGr));
  CWadDirectory *wad_dir;
  I64 idx,pass;
  U8 lump_name[9],*tmp,buf[16];
  CWadPnames *pnames;
  CDC *gr;
  ret->sprite_names=I64SetNew;
//Load Player palett
  ret->palette=LoadPLAYPALFromLump(W_GetLumpPtrFromName("PLAYPAL",NULL));
//Find the sprites start
  pass=1;
  wad=wads[0];
  do {
    wad_dir=wad->body+wad->directory_ptr;
    idx=W_CheckNumForName("S_START",wad,pass);
    if(idx==-1)
      break;
    wad_dir+=idx;
found_sstart:
    wad_dir++; //Move past S_START
    if(StrCmp8(wad_dir->lump_name,"S_END")) {
      lump_name[8]=0;
      MemCpy(lump_name,wad_dir->lump_name,8);
      gr=ReadDoomImage(W_GetLumpPtrFromName(lump_name,NULL)); //See note above funcrtion
      Upper8(lump_name);
      StrPrint(buf,"Spr.%s",lump_name);
      I64SetAdd(ret->sprite_names,StrNew(lump_name));
      FramePtrAdd(buf,gr,doom_task);
      goto found_sstart;
    }
    pass++;
  } while(TRUE);
//Yeah homie,im straight up gunna load Flats. Take a moment to praise God
  pass=1;
  do {
    wad_dir=wad->body+wad->directory_ptr;
    idx=W_CheckNumForName("F_START",wad,pass);
    if(idx==-1)
      break;
    wad_dir+=idx;
found_fstart:
    wad_dir++; //Move past F_START
    if(StrCmp8(wad_dir->lump_name,"F_END")) {
//There are lumps like F1_START/F1_END/F2_START/F2_END
      //There are empty are are used for shareware/registered lumps
      if(wad_dir->lump_size) {
        lump_name[8]=0;
        MemCpy(lump_name,wad_dir->lump_name,8);
        gr=ReadDoomFlat(W_GetLumpPtrFromName(lump_name,NULL),ret->palette); //See note above funcrtion
        tmp=MStrPrint("F.%s",lump_name);
        Upper8(tmp);
        UH(tmp,gr);
        FramePtrAdd(tmp,gr,doom_task);
        Free(tmp);
      }
      goto found_fstart;
    }
    pass++;
  } while(TRUE);
//Load Wall Patch names(ONLYUSE LASTFOR NOW)
  I64 widx;
  for(widx=0;widx!=wad_cnt;widx++) {
    pass=1;
    wad=wads[widx];
    do {
      wad_dir=wad->body+wad->directory_ptr;
      idx=W_CheckNumForName("PNAMES",wad,pass);
      if(idx==-1) break;
      wad_dir+=idx;
found_pnames:
      pnames=wad->body+wad_dir->ptr;
      ret->pname_cnt=pnames->len;
      Free(ret->pnames);
      ret->pnames=MAlloc(ret->pname_cnt*8);
      MemCpy(ret->pnames,pnames->names,ret->pname_cnt*8);
//Load wall patches
      wad_dir=wad->body+wad->directory_ptr;
found_pstart:
      for(idx=0;idx!=ret->pname_cnt;idx++) { 
	  lump_name[8]=0;
	  MemCpy(lump_name,&ret->pnames[idx],8);
	  Upper8(lump_name);
        if(W_GetLumpPtrFromName(lump_name,NULL)) {
	  gr=ReadDoomImage(W_GetLumpPtrFromName(lump_name,NULL)); //See note above funcrtion
	  StrPrint(buf,"Pat.%s",lump_name);
	  UH(buf,gr);
	  FramePtrAdd(buf,gr,doom_task);
        }
      }
try_text:
      if(W_CheckNumForName("TEXTURE1",wad,pass)!=-1)
        LoadWadTEXTUREs(W_GetLumpPtrFromName("TEXTURE1",wad,,pass),ret);
      if(W_CheckNumForName("TEXTURE2",wad,pass)!=-1)
        LoadWadTEXTUREs(W_GetLumpPtrFromName("TEXTURE2",wad,,pass),ret);
      pass++;
    } while(TRUE);
  }


  LoadGrLump(NULL,"STBAR");
  LoadGrLump(NULL,"STARMS");
  for(idx=0;idx!=10;idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"STTNUM%d",idx);
    LoadGrLump(NULL,lump_name);
    lump_name[0]=0;
    CatPrint(lump_name,"STGNUM%d",idx);
    LoadGrLump(NULL,lump_name);
  }

  for(idx=0;idx!=6;idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"STKEYS%d",idx);
    LoadGrLump(NULL,lump_name);
  }

  LoadGrLump(NULL,"STTPRCNT");
  for(idx=0;idx!=10;idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"STYSNUM%d",idx);
    LoadGrLump(NULL,lump_name);
  }

  for(idx='!';idx<='_';idx++) {
    StrPrint(lump_name,"STCFN%3d",idx-'!');
    while(StrOcc(lump_name,' '))
      *StrFirstOcc(lump_name," ")='0';
    LoadGrLump(NULL,lump_name);
  }

  //Intermission
  LoadGrLump(NULL,"WIURH0");
  LoadGrLump(NULL,"WIURH1");
  LoadGrLump(NULL,"WISPLAT");
  LoadGrLump(NULL,"WIPCNT");
  LoadGrLump(NULL,"WIF");
  LoadGrLump(NULL,"WIENTER");
  LoadGrLump(NULL,"WIOSTK");
  LoadGrLump(NULL,"WIOSTI");
  LoadGrLump(NULL,"WIOSTS");
  LoadGrLump(NULL,"WISCRT2");
  LoadGrLump(NULL,"WIFRGS");
  LoadGrLump(NULL,"WICOLON");
  LoadGrLump(NULL,"WIPAR");
  for(idx=0;idx!=10;idx++) {
    StrPrint(lump_name,"WINUM%d",idx);
    LoadGrLump(NULL,lump_name);

  }
//FACES

  LoadGrLump(NULL,"STFST01");
  LoadGrLump(NULL,"STFST00");
  LoadGrLump(NULL,"STFST02");

  //MAINMENU
  LoadGrLump(NULL,"M_NGAME");
  LoadGrLump(NULL,"M_LOADG");
  LoadGrLump(NULL,"M_OPTION");
  LoadGrLump(NULL,"M_SAVEG");
  LoadGrLump(NULL,"M_RDTHIS");
  LoadGrLump(NULL,"M_QUITG");
  LoadGrLump(NULL,"M_EP1");
  LoadGrLump(NULL,"M_EP2");
  LoadGrLump(NULL,"M_EP3");
  LoadGrLump(NULL,"M_EP4");

  LoadGrLump(NULL,"M_JKILL");
  LoadGrLump(NULL,"M_ROUGH");
  LoadGrLump(NULL,"M_HURT");
  LoadGrLump(NULL,"M_ULTRA");
  LoadGrLump(NULL,"M_NMARE");

  LoadGrLump(NULL,"TITLEPIC");
  LoadGrLump(NULL,"M_QUITG");
  LoadGrLump(NULL,"M_OPTION");
  LoadGrLump(NULL,"M_SKULL1");
  LoadGrLump(NULL,"M_SKULL2");
  LoadGrLump(NULL,"M_LGTTL");
  LoadGrLump(NULL,"M_ABOUT");
  LoadGrLump(NULL,"HELP1");
  LoadGrLump(NULL,"AQCONC14");
  LoadGrLump(NULL,"M_HURT");
  LoadGrLump(NULL,"M_DOOM");
  LoadGrLump(NULL,"RW1_3");
  LoadGrLump(NULL,"RW12_3");
  LoadGrLump(NULL,"M_SKILL");
  LoadGrLump(NULL,"M_JKILL");
  LoadGrLump(NULL,"M_ROUGH");
  LoadGrLump(NULL,"M_ULTRA");
  LoadGrLump(NULL,"M_NMARE");
  LoadGrLump(NULL,"M_EPI1");
  LoadGrLump(NULL,"M_EPI2");
  LoadGrLump(NULL,"M_EPI3");
  LoadGrLump(NULL,"M_EPI4");
  LoadGrLump(NULL,"M_EPISOD");
  LoadGrLump(NULL,"M_SGTTL");

  //numbers
  LoadGrLump(NULL,"STCFN048");
  LoadGrLump(NULL,"STCFN049");
  LoadGrLump(NULL,"STCFN050");
  LoadGrLump(NULL,"STCFN051");
  LoadGrLump(NULL,"STCFN052");
  LoadGrLump(NULL,"STCFN053");
  LoadGrLump(NULL,"STCFN054");
  LoadGrLump(NULL,"STCFN055");
  LoadGrLump(NULL,"STCFN056");
  LoadGrLump(NULL,"STCFN057");

  //letters
  LoadGrLump(NULL,"STCFN065");
  LoadGrLump(NULL,"STCFN066");
  LoadGrLump(NULL,"STCFN067");
  LoadGrLump(NULL,"STCFN068");
  LoadGrLump(NULL,"STCFN069");
  LoadGrLump(NULL,"STCFN070");
  LoadGrLump(NULL,"STCFN071");
  LoadGrLump(NULL,"STCFN072");
  LoadGrLump(NULL,"STCFN073");
  LoadGrLump(NULL,"STCFN074");
  LoadGrLump(NULL,"STCFN075");
  LoadGrLump(NULL,"STCFN076");
  LoadGrLump(NULL,"STCFN077");
  LoadGrLump(NULL,"STCFN078");
  LoadGrLump(NULL,"STCFN079");
  LoadGrLump(NULL,"STCFN080");
  LoadGrLump(NULL,"STCFN081");
  LoadGrLump(NULL,"STCFN082");
  LoadGrLump(NULL,"STCFN083");
  LoadGrLump(NULL,"STCFN084");
  LoadGrLump(NULL,"STCFN085");
  LoadGrLump(NULL,"STCFN086");
  LoadGrLump(NULL,"STCFN087");
  LoadGrLump(NULL,"STCFN088");
  LoadGrLump(NULL,"STCFN089");
  LoadGrLump(NULL,"STCFN090");

  //WEAPONS
  //PUNCH
  LoadGrLump(NULL,"PUNGA0");
  LoadGrLump(NULL,"PUNGB0");
  LoadGrLump(NULL,"PUNGC0");
  LoadGrLump(NULL,"PUNGD0");

//
#ifdef DOOM2
  LoadGrLump(NULL,"HELP1");
#endif

  //PISTOL
  for(idx='A';idx<='E';idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"PISG%c0",idx);
    LoadGrLump(NULL,lump_name);
  }
//SHOTGUN   
  for(idx='A';idx<='D';idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"SHTG%c0",idx);
    LoadGrLump(NULL,lump_name);
  }
//CHAINGUN
  for(idx='A';idx<='B';idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"CHGG%c0",idx);
    LoadGrLump(NULL,lump_name);
  }
//MISSILELAUNCHER
  for(idx='A';idx<='B';idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"MISG%c0",idx);
    LoadGrLump(NULL,lump_name);
  }
  for(idx='A';idx<='D';idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"MISF%c0",idx);
    LoadGrLump(NULL,lump_name);
  }
//CHAINSAW
  for(idx='A';idx<='D';idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"SAWG%c0",idx);
    LoadGrLump(NULL,lump_name);
  }
//PLASMAGUN
  for(idx='A';idx<='B';idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"PLSG%c0",idx);
    LoadGrLump(NULL,lump_name);
  }
//BFG
  for(idx='A';idx<='B';idx++) {
    lump_name[0]=0;
    CatPrint(lump_name,"BFGG%c0",idx);
    LoadGrLump(NULL,lump_name);
  }
  return ret;
}


Bool InBound(F64 a,F64 l,F64 h) {
  if(l<h)
    return l-.1<=a<=h+.1;
  return h-.1<=a<=l+.1;
}

class CWadBlockMapHeader {
  I16 x_off,y_off;
  I16 num_cols,num_rows;
};
CDC *GetFlatDC(U8 *name) {
  U8 tmp_name[16];
  StrPrint(tmp_name,"F.%s",name);
  Upper8(tmp_name);
  return FramePtr(tmp_name,doom_task);
}
extern U0 LoadLightingThinkers(CDoomLevel *l);
extern U0 InitPosDataForThing(CDoomLevel *l,CDoomThing *t);
CDoomLevel *LoadWadLevel(U8 *level_name,I64 skill=1) {
  I64 idx,cnt,x,y,min,max;
  U16 *offs;
  U8 name[STR_LEN],*reject;
  CDC **arr;
  CWad *wad;
  CDoomLevel *level=CAlloc(sizeof CDoomLevel);
  CDoomThing *dthing;
  CWadThing *wthing;
  CWadVertex *vertex;
  CWadDirectory *wad_dir;
  CWadBSPNode *wnode;
  CDoomBSPNode *dnode,**dnode_list;
  CWadLinedef *wlinedef;
  CDoomLinedef *dlinedef,**dlinedef_list;
  CDoomSubsector *dss,**sslist;
  CWadSubsector *wss;
  CWadSeg *wseg;
  CDoomBSPSeg *dseg,*dseg_list;
  CWadSector *wsect;
  CDoomSector **dsect_list,*dsect;
  CWadSidedef *wside;
  CDoomSidedef *dside,**dside_list;
  CWadBlockMapHeader *wbmh;
  QueInit(&level->sidedefs);
  QueInit(&level->thinkers);
  QueInit(&level->sectors);
  QueInit(&level->things);
  QueInit(&level->linedefs);
  QueInit(&level->bsp_nodes);
  QueInit(&level->subsectors);
  level->skill=skill;
  name[8]=0;
  cnt=wad_cnt;
  while(--cnt>=0) {
    wad=wads[cnt];
    wad_dir=wad->body+wad->directory_ptr;
    for(idx=0;idx!=wad->lump_cnt;idx++) {
      if(!StrCmp8(wad_dir->lump_name,level_name))
        goto found;
      wad_dir++;
    }
  }
  Free(level);
  return NULL;
found:
//Order of other lumps is important
  //rest will not be used for now
  //Move past level lump
  wad_dir++;
//Things
  cnt=wad_dir->lump_size/sizeof(CWadThing);
  wthing=wad_dir->ptr+wad->body;
  for(idx=0;idx!=cnt;idx++) {
//https://doomwiki.org/wiki/E4M3:_Sever_the_Wicked_(Doom)
//If no flags are set for the spawns,stil handle them
    if(wthing->thing_type==1)
      goto pass_thing;
    if(wthing->flags&WAD_THINGF_MULTIPLAYER)
      goto skip_thing;
    switch(skill) {
      case 0:
      case 1:
      case 2:
        if(wthing->flags&WAD_THINGF_SKILL12)
	  goto pass_thing;
        break;
      case 3:
        if(wthing->flags&WAD_THINGF_SKILL3)
	  goto pass_thing;
        break;
      case 4:
      case 5:
        if(wthing->flags&WAD_THINGF_SKILL45)
	  goto pass_thing;
        break;
    }
    goto skip_thing;
pass_thing:
    dthing=CAlloc(sizeof CDoomThing);
    dthing->x=wthing->x;
    dthing->y=wthing->y;
    dthing->angle=wthing->angle*pi/180;
    dthing->thing_type=wthing->thing_type;
    dthing->template=doom_thing_types[wthing->thing_type];
    if(dthing->template->flags&TF_ARTIFACT)
      level->stats.max_items++;
    if(dthing->template->flags&TF_MONSTER)
      level->stats.max_kills++;
    dthing->flags=dthing->template->flags;
    QueIns(dthing,level->things.last);
skip_thing:
    wthing++;
  }
  level->episode=level_name[1]-'1'+1;
//Load vertexes first P
  cnt=wad_dir[3].lump_size/sizeof(CWadVertex);
  vertex=wad_dir[3].ptr+wad->body;
  level->vertice_cnt=cnt;
  level->vertices=MAlloc(sizeof(CD2)*cnt);
  UH2("LVERTS",level->vertices);
  if(StrCmp8("VERTEXES",wad_dir[3].lump_name)) throw('Wad');
  for(idx=0;idx!=cnt;idx++) {
    level->vertices[idx].x=vertex->x;
    level->vertices[idx].y=vertex->y;
    vertex++;
  }
//SIDEDEFS
  cnt=wad_dir[2].lump_size/sizeof(CWadSidedef);
  wside=wad_dir[2].ptr+wad(U8*);
  dside_list=MAlloc(8*cnt);
  if(StrCmp8("SIDEDEFS",wad_dir[2].lump_name)) throw('Wad');
  for(idx=0;idx!=cnt;idx++) {
    dside=CAlloc(sizeof CDoomSidedef);
    StrPrint(name,"SD.%d",idx);
    UH2(name,dside);
    dside->xoff=wside->x_offset;
    dside->yoff=wside->y_offset;
    name[8]=0;
    MemCpy(name,wside->middle_texture_name,8);
    Upper8(name);
    dside->middle_texture[0]=TextureName2DC(name);
    MemCpy(name,wside->upper_texture_name,8);
    Upper8(name);
    dside->upper_texture[0]=TextureName2DC(name);
    MemCpy(name,wside->lower_texture_name,8);
    Upper8(name);
    dside->lower_texture[0]=TextureName2DC(name);
//https://doomwiki.org/wiki/Animated_wall
    for(x=0;x!=3;x++) {
      switch(x) {
	  break;case 0:
	  arr=dside->middle_texture;
	  MemCpy(name,wside->middle_texture_name,8);
	  break;case 1:
	  arr=dside->upper_texture;
	  MemCpy(name,wside->upper_texture_name,8);
	  break;case 2:
	  arr=dside->lower_texture;
	  MemCpy(name,wside->lower_texture_name,8);
      }
      Upper8(name);
      if(!StrNCmp(name,"BLODGR1",5)) {
        arr[0]=TextureName2DC("BLODGR1");
        arr[1]=TextureName2DC("BLODGR2");
        arr[2]=TextureName2DC("BLODGR3");
        arr[3]=TextureName2DC("BLODGR4");
      }
      if(!StrNCmp(name,"BLODRIP1",7)) {
        arr[0]=TextureName2DC("BLODRIP1");
        arr[1]=TextureName2DC("BLODRIP2");
        arr[2]=TextureName2DC("BLODRIP3");
        arr[3]=TextureName2DC("BLODRIP4");
      }
      if(!StrNCmp(name,"FIREBLU1",7)) {
        arr[0]=TextureName2DC("FIREBLU1");
        arr[1]=TextureName2DC("FIREBLU2");
      }
      if(!StrNCmp(name,"FIRELAV3",7)) {
        arr[0]=TextureName2DC("FIRELAVA3");
        arr[1]=TextureName2DC("FIRELAVA");
      }
      if(!StrNCmp("FIREMAG1",name,7)) {
        arr[0]=TextureName2DC("FIREMAG1");
        arr[1]=TextureName2DC("FIREMAG2");
        arr[2]=TextureName2DC("FIREMAG3");
      }
      if(!StrNCmp("FIREWALA",name,7)) {
        arr[0]=TextureName2DC("FIREWALA");
        arr[1]=TextureName2DC("FIREWALB");
        arr[2]=TextureName2DC("FIREWALL");
      }
      if(!StrNCmp("GSTFONT1",name,7)) {
        arr[0]=TextureName2DC("GSTFONT1");
        arr[1]=TextureName2DC("GSTFONT2");
        arr[2]=TextureName2DC("GSTFONT3");
      }
      if(!StrNCmp("ROCKRED1",name,7)) {
        arr[0]=TextureName2DC("ROCKRED1");
        arr[1]=TextureName2DC("ROCKRED2");
        arr[2]=TextureName2DC("ROCKRED3");
      }
      if(!StrNCmp("SLADRIP1",name,7)) {
        arr[0]=TextureName2DC("SLADRIP1");
        arr[1]=TextureName2DC("SLADRIP2");
        arr[2]=TextureName2DC("SLADRIP3");
      }
    }
    dside_list[idx]=dside;
    QueIns(dside,level->sidedefs.last);
    wside++;
  }  
//LINEDEFS
  cnt=wad_dir[1].lump_size/sizeof(CWadLinedef);
  wlinedef=wad_dir[1].ptr+wad(U8*);
  dlinedef_list=CAlloc(8*cnt);
  if(StrCmp8("LINEDEFS",wad_dir[1].lump_name)) throw('Wad');
  for(idx=0;idx!=cnt;idx++) {
    dlinedef=CAlloc(sizeof(CDoomLinedef));
    StrPrint(name,"LD.%d",idx);
    UH2(name,dlinedef);

    dlinedef->start=wlinedef->start_vertex+level->vertices;
    dlinedef->end=wlinedef->end_vertex+level->vertices;
    if(wlinedef->front!=0xffff)
      dlinedef->front=dside_list[wlinedef->front];
    if(wlinedef->back!=0xffff)
      dlinedef->back=dside_list[wlinedef->back];
    dlinedef->sector_tag=wlinedef->sector_tag;
    dlinedef->flags=wlinedef->flags;
    dlinedef->special_type=action_sector_types[wlinedef->special_type];
    if(wlinedef->special_type&&!dlinedef->special_type) {
      DbgPrint("Unimp special linedef(%d) at ld %d\n",wlinedef->special_type,idx);
    }
    dlinedef_list[idx]=dlinedef;
    QueIns(dlinedef,level->linedefs.last);
    wlinedef++;
  }
// Bsp NODES
  cnt=wad_dir[6].lump_size/sizeof(CWadBSPNode);
  wnode=wad_dir[6].ptr+wad(U8*);
  if(StrCmp8("NODES",wad_dir[6].lump_name)) throw('Wad');
  dnode_list=MAlloc(cnt*8);
  for(idx=0;idx!=cnt;idx++) {
    dnode=CAlloc(sizeof CDoomBSPNode);
    StrPrint(name,"ND.%d",idx);
    UH2(name,dnode);
    dnode->x=wnode->x;
    dnode->y=wnode->y;
    dnode->dx=wnode->dx;
    dnode->dy=wnode->dy;
    dnode->left.x=wnode->left.x;
    dnode->left.y=wnode->left.y;
    dnode->left.x2=wnode->left.x2;
    dnode->left.y2=wnode->left.y2;
    dnode->right.x=wnode->right.x;
    dnode->right.y=wnode->right.y;
    dnode->right.x2=wnode->right.x2;
    dnode->right.y2=wnode->right.y2;
    dnode->signature='NODE';
    QueIns(dnode,&level->bsp_nodes);
    dnode_list[idx]=dnode;
    wnode++;
  } 
//Load SEGS first homie
  cnt=wad_dir[4].lump_size/sizeof(CWadSeg);
  wseg=wad_dir[4].ptr+wad(U8*);
  dseg_list=level->segs=CAlloc(sizeof(CDoomBSPSeg)*cnt);
  UH2("SEGS",dseg_list);
  if(StrCmp8("SEGS",wad_dir[4].lump_name)) throw('Wad');
  for(idx=0;idx!=cnt;idx++) {
    dseg=&dseg_list[idx];
    dseg->start=&level->vertices[wseg->start_vertex];
    dseg->end=&level->vertices[wseg->end_vertex];
    dseg->linedef=dlinedef_list[wseg->linedef];
    dseg->offset=wseg->offset;
    dseg->back_side=wseg->opposite_side;
    wseg++;
  }  
// SSECTORS 
  cnt=wad_dir[5].lump_size/sizeof(CWadSubsector);
  wss=wad_dir[5].ptr+wad(U8*);
  sslist=CAlloc(cnt*8);
  if(StrCmp8("SSECTORS",wad_dir[5].lump_name)) throw('Wad');
  for(idx=0;idx!=cnt;idx++) {
    dss=CAlloc(sizeof(CDoomSubsector));
    StrPrint(name,"SubS.%d",idx);
    UH2(name,dss);
    QueIns(dss,&level->subsectors);
    dss->signature='SSECTOR';
    dss->cnt=wss->cnt;
    dss->first=&level->segs[wss->first];
    sslist[idx]=dss;
    wss++;
  }
//Redo again,look for child nodes
  wnode=wad_dir[6].ptr+wad(U8*);
  cnt=wad_dir[6].lump_size/sizeof(CWadBSPNode);
  for(idx=0;idx!=cnt;idx++) {
    if(!(wnode->left_child&(1<<15))) {
      dnode_list[idx]->left_child=dnode_list[wnode->left_child&(1<<15-1)];
      dnode_list[idx]->left_child->parent=dnode_list[idx];
    } else {
//SSECTORS
      dnode_list[idx]->left_child=sslist[wnode->left_child&(1<<15-1)];
    }
    if(!(wnode->right_child&(1<<15))) {
      dnode_list[idx]->right_child=dnode_list[wnode->right_child&(1<<15-1)];
      dnode_list[idx]->right_child->parent=dnode_list[idx];
    } else {
//SSECTORS
      dnode_list[idx]->right_child=sslist[wnode->right_child&(1<<15-1)];
    }
    wnode++;
  }
  level->root_node=dnode_list[cnt-1];
//SECTORS
  cnt=wad_dir[7].lump_size/sizeof(CWadSector);
  level->sector_cnt=cnt;
  wsect=wad_dir[7].ptr+wad(U8*);
  dsect_list=CAlloc(cnt*8);
  if(StrCmp8("SECTORS",wad_dir[7].lump_name)) throw('Wad');
  for(idx=0;idx!=cnt;idx++) {
    dsect=CAlloc(sizeof(CDoomSector));
    StrPrint(name,"Sec.%d",idx);
    UH2(name,dsect);
    QueIns(dsect,level->sectors.last);
    dsect->idx=idx;
    dsect->floor_height=wsect->floor_height;
    dsect->ceil_height=wsect->ceil_height;
    dsect->base_floor_height=wsect->floor_height;
    dsect->base_ceil_height=wsect->ceil_height;
    MemCpy(name,wsect->floor_texture_name,8);
    dsect->floor_dc[0]=GetFlatDC(name);
    MemCpy(name,wsect->ceil_texture_name,8);
    dsect->ceil_dc[0]=GetFlatDC(name);
//https://doomwiki.org/wiki/Animated_flat
    for(x=0;x!=2;x++) {
      switch(x) {
	  break;case 0:
	  arr=dsect->floor_dc;
	  MemCpy(name,wsect->floor_texture_name,8);
	  break;case 1: 
	  arr=dsect->ceil_dc;
	  MemCpy(name,wsect->ceil_texture_name,8);
      }
      if(!StrNCmp(name,"NUKAGE",5)){
        arr[0]=GetFlatDC("NUKAGE1");
        arr[1]=GetFlatDC("NUKAGE2");
        arr[2]=GetFlatDC("NUKAGE3");
        arr[3]=GetFlatDC("NUKAGE4");
      }
      if(!StrNCmp(name,"FWATER",6)){
        arr[0]=GetFlatDC("FWATER1");
        arr[1]=GetFlatDC("FWATER2");
        arr[2]=GetFlatDC("FWATER3");
        arr[3]=GetFlatDC("FWATER4");
      }
      if(!StrNCmp(name,"LAVA",4)){
        arr[0]=GetFlatDC("LAVA1");
        arr[1]=GetFlatDC("LAVA2");
        arr[2]=GetFlatDC("LAVA3");
        arr[3]=GetFlatDC("LAVA4");
      }
      if(!StrNCmp(name,"BLOOD",5)){
        arr[0]=GetFlatDC("BLOOD1");
        arr[1]=GetFlatDC("BLOOD2");
        arr[2]=GetFlatDC("BLOOD3");
      }
      if(!StrNCmp(name,"RROCK",5)){
        arr[0]=GetFlatDC("RROCK05");
        arr[1]=GetFlatDC("RROCK06");
        arr[2]=GetFlatDC("RROCK07");
        arr[3]=GetFlatDC("RROCK08");
      }
      if(!StrNCmp(name,"SLIME01",7)){
        arr[0]=GetFlatDC("SLIME01");
        arr[1]=GetFlatDC("SLIME02");
        arr[2]=GetFlatDC("SLIME03");
        arr[3]=GetFlatDC("SLIME04");
      }
      if(!StrNCmp(name,"SLIME05",7)){
        arr[0]=GetFlatDC("SLIME05");
        arr[1]=GetFlatDC("SLIME06");
        arr[2]=GetFlatDC("SLIME07");
        arr[3]=GetFlatDC("SLIME08");
      }
      if(!StrNCmp(name,"SLIME09",7)){
        arr[0]=GetFlatDC("SLIME09");
        arr[1]=GetFlatDC("SLIME10");
        arr[2]=GetFlatDC("SLIME11");
        arr[3]=GetFlatDC("SLIME12");
      }
    }
    dsect->base_light_level=wsect->light_level;
    dsect->cur_light_level=wsect->light_level;
    dsect->special_type=wsect->special_type;
    dsect->tag_number=wsect->tag_number;
    dsect->things=I64SetNew;
    dsect_list[idx]=dsect;
    if(dsect->special_type==9) //Secret
      level->stats.max_secrets++;
    wsect++;
  }
//SECTORS(2) Get sidedefs for the sector
  cnt=wad_dir[2].lump_size/sizeof(CWadSidedef);
  wside=wad_dir[2].ptr+wad(U8*);
  for(idx=0;idx!=cnt;idx++) {
    dside_list[idx]->sector=dsect_list[wside->sector];
    wside++;
  }
//SECTORS(3) Get all the linedefs for the sector,also assign sectors based on tag
  cnt=wad_dir[1].lump_size/sizeof(CWadLinedef);
  wlinedef=wad_dir[1].ptr+wad(U8*);
  if(StrCmp8("LINEDEFS",wad_dir[1].lump_name)) throw('Wad');
  for(idx=0;idx!=cnt;idx++) {
    if(dlinedef_list[idx]->front) {
      AddLinedefToSector(
	    dlinedef_list[idx],
	    dlinedef_list[idx]->front->sector
	    );
    }
    if(dlinedef_list[idx]->back) {     
      AddLinedefToSector(
	    dlinedef_list[idx],
	    dlinedef_list[idx]->back->sector
	    );
    }
  }
//REJECT
  reject=wad_dir[8].ptr+wad(U8*);
  cnt=CeilI64(level->sector_cnt*level->sector_cnt,8)/8;
  level->reject=MAlloc(cnt);
  MemCpy(level->reject,reject,cnt);
//BLOCKMAP
  wbmh=wad_dir[9].ptr+wad(U8*);
  if(StrCmp8("BLOCKMAP",wad_dir[9].lump_name)) throw('Wad');
  cnt=wbmh->num_cols*wbmh->num_rows;
  offs=wbmh+1;
  level->block_map_y_off=wbmh->y_off;
  level->block_map_x_off=wbmh->x_off;
  level->block_map_offsets=MAlloc(8*cnt);
  UH2("BMO",level->block_map_offsets);
  level->block_map_cols=wbmh->num_cols;
  level->block_map_rows=wbmh->num_rows;
  level->block_map_things=MAlloc(8*wbmh->num_cols*wbmh->num_rows);
  x=wbmh->num_cols*wbmh->num_rows;
  while(--x>=0) {
    level->block_map_things[x]=I64SetNew;
  }
  for(x=0;x!=wbmh->num_cols;x++) {
    for(y=0;y!=wbmh->num_rows;y++) {
//These pooparoos are relatvie the the BLOCKMAP header,so get rid of the header/offsets poop
      idx=(offs[x+y*wbmh->num_cols]*2-sizeof(CWadBlockMapHeader)-2*cnt)/2;
      level->block_map_offsets[x+y*wbmh->num_cols]=idx;
    }
  }
//Assign sectors to subsectors
  for(dss=level->subsectors.next;dss!=&level->subsectors;dss=dss->next) {
    if(!dss->first->back_side)
      dss->sector=dss->first->linedef->front->sector;
    else
      dss->sector=dss->first->linedef->back->sector;
  }
  offs+=cnt;
  cnt=(wad_dir[9].lump_size-sizeof(CWadBlockMapHeader)-cnt*sizeof(I16))/sizeof(I16);
  level->block_map_data=MAlloc(8*cnt);
  UH2("BMD",level->block_map_data);
  while(--cnt>=0) {
    if(offs[cnt]==0xFFFF)
      level->block_map_data[cnt]=NULL;
    else
      level->block_map_data[cnt]=dlinedef_list[offs[cnt]];
  }
  Free(sslist);
  Free(dside_list);
  Free(dsect_list);
  Free(dnode_list);
  Free(dlinedef_list);
  StrCpy(level->map_name,level_name);
  LoadLightingThinkers(level);
  for(dthing=level->things.next;dthing!=&level->things;dthing=dthing->next) {
    InitPosDataForThing(level,dthing);
  }
  return level;
}

U0 DumpWad(CWad *wad) {
  I64 lump,ptr,lump_sz,ptr2;
  U8 *name;
  ptr=wad->directory_ptr;
  for(lump=0;lump!=wad->lump_cnt;lump++) {
    "LUMP:%c(%X)\n",(name=(wad->body+ptr)(CWadDirectory*)->lump_name)(U64*)[0],
	lump_sz=(wad->body+ptr)(CWadDirectory*)->lump_size;
    if(!StrCmp("THINGS",name)) {
      ptr2=(wad->body+ptr)(CWadDirectory*)->ptr;
      "THING:\n"
      "\tX:%d\n",(wad->body+ptr)(CWadThing*)->x;
      "\tY:%d\n",(wad->body+ptr)(CWadThing*)->y;
      "\tANGLE:%n\n",(wad->body+ptr)(CWadThing*)->angle/ToF64(I16_MAX)*2*pi;
      "\tTYPE:%X\n",(wad->body+ptr)(CWadThing*)->thing_type;
    }
    ptr(CWadDirectory*)++;
  }
  
}

//
I64 cnt=wad_cnt;
dgr=LoadWadGr;
CDoomLevel *l=NULL;
#endif
