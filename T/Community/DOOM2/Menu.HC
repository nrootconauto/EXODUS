#ifndef MENU
#define MENU "poop"
extern U0 PlayLevel(Bool init=TRUE);
#define SWSTRING	\
"this is the shareware version of doom.\n\n"\
"you need to order the entire trilogy.\n\n" \
"press a key."


class CMenuItem {
  U64 value;
  CDC *gr;
  I16 state; //-1 for end
  I16 x,y;
  U8 name[29];
  U8 hot_key;
};
CMenuItem **active_menu=NULL;
I64 active_menu_item=0;
//Free this
CMenuItem *CreateMenu(...) {
  CMenuItem *ret=CAlloc(sizeof(CMenuItem)*(1+argc/3));
  I64 idx;
  for(idx=0;idx<argc/3;idx++) {
    StrCpy(ret[idx].name,argv[idx*3]);
    ret[idx].hot_key=argv[idx*3+2];
    ret[idx].value=argv[idx*3+1];
  }
  ret[idx].state=-1;
  return ret;
}
U0 MenuDraw(CDC *dc,CMenuItem *items,I64 offx,I64 offy,I64 cur_active=0) {
  if(!items) return 0;
  CDC *skull;
  I64 x,y;
  I64 h=0,basey;
  I64 cnt=0,idx;
  h=offy*2;
  for(idx=0;items[idx].state!=-1;idx++) {
    skull=GetGrLump(items[idx].name);
//Item now availble,some WAD's might not have episode 4 os just stop counting
    if(!skull)
      break;
    items[idx].gr=skull;
    items[idx].x=offx*2;
    items[idx].y=h;
    h+=20+skull->height;
    cnt++;
  }
  if(Blink)
    skull=GetGrLump("M_SKULL1");
  else
    skull=GetGrLump("M_SKULL2");
  for(idx=0;idx!=cnt;idx++) {
    GrBlot(dc,items[idx].x,items[idx].y,items[idx].gr);
    if(cur_active==idx) {
      x=items[idx].x-skull->width-10;
      y=items[idx].y+items[idx].gr->height/2-skull->height/2;
      GrBlot(dc,x,y,skull);
    }
  }
}
U64 MenuInteract(CDC *dc,CMenuItem *items,I64 offx,I64 offy) {
  if(!items) return 0;
  static U8 *old_items=NULL;
  if(old_items!=items) {
    old_items=items;
    active_menu_item=0;
  }
  I64 code=INVALID_PTR;
  I64 cur_active=active_menu_item;
  CDC *skull;
  I64 a,b;
  I64 msx=ms.pos.x;
  I64 msy=ms.pos.y;
  I64 cnt=0,idx;
  I64 x,y;
//Update items gr properites
  MenuDraw(dc,items,offx,offy,cur_active);
  for(idx=0;items[idx].state!=-1;idx++)
    cnt++;
retry:
    switch(ScanMsg(&a,&b)) {
      case 0:
	break;
      start:
        msx=ms.pos.x;
        msy=ms.pos.y;
        for(idx=0;idx!=cnt;idx++) {
	  y=items[idx].y;
          if(items[idx].gr!=NULL){
	  if(y<=msy<=y+items[idx].gr->height) {
	    cur_active=idx;
	    break;
	  }}
        }
        case MSG_MS_MOVE:
	  break;
        case MSG_MS_L_DOWN:
	  code=items[cur_active].value;
	  break;
      end:
        goto retry;  //try all events for frame
      case MSG_KEY_DOWN:
        if(b&0xff==SC_CURSOR_UP&&cur_active>0) {
	  cur_active--;
        } else if(b&0xff==SC_CURSOR_DOWN&&cur_active+1<cnt) {
	  cur_active++;
        } else if(a=='\n') {
	  code=items[cur_active].value;
        } else if(a==CH_ESC) {
	  code=0;
          FlushMsgs;
          goto fin;
	} else {
          for(idx=0;idx!=cnt;idx++) {
	    if(items[idx].hot_key==a)
	      code=items[cur_active].value;
	  }
	}
      default:
        goto retry; //try all events for frame
    }
  if(code!=INVALID_PTR) {
    Spawn(&PlaySoundTask,"SWTCHN","snd",0,Fs);
    FlushMsgs;
    active_menu=NULL;
  }
  active_menu_item=cur_active;
  MenuDraw(dc,items,offx,offy,cur_active);
fin:
  return code;
}
U64 EpisodeMenu() {
  static CMenuItem *items=CreateMenu(
    "M_EPI1",'1','1',
    "M_EPI2",'2','2',
    "M_EPI3",'3','3',
    "M_EPI4",'4','4'
  );
  active_menu=items;
  return MenuInteract(doom_scrn,items,48,63);
}
U64 NewGameMenu() {
  static CMenuItem *items=CreateMenu(
    "M_JKILL",'1','i',
    "M_ROUGH",'2','h',
    "M_HURT",'3','h',
    "M_ULTRA",'4','u',
    "M_NMARE",'5','n'
  );
  active_menu=items;
  return MenuInteract(doom_scrn,items,48,63);
}

extern I64 LoadSaveInteract(CDC *to,Bool save);
U0 MenuMessage(U8 *str) {
  I64 y=200-(1+StrOcc(str,'\n'))*18/2,w;
  U8 buf[STR_LEN];
loop:;
  if(!StrOcc(str,'\n')) {
    w=DoomPrint(NULL,0,0,"%s",str);
    DoomPrint(doom_scrn,GR_WIDTH/2-w/2,y,"%s",str);
  } else {
    StrCpy(buf,str);
    *StrFirstOcc(buf,"\n")=0;
    w=DoomPrint(NULL,0,0,"%s",buf);
    DoomPrint(doom_scrn,GR_WIDTH/2-w/2,y,"%s",buf);
    str+=StrLen(buf)+1;
    y+=24;
    goto loop;
  }
}
U64 MainMenu() {
againm:;
  static I64 state=0,ep,s;
  static CMenuItem *items=CreateMenu(
        "M_NGAME",'NGAME','n',
        "M_LOADG",'LOADG','l',
        "M_SAVEG",'SAVEG','s',
        "M_RDTHIS",'RDTHIS','r',
        "M_QUITG",'QUITG','q'
        );
  U8 level[STR_LEN],next=FALSE;
  U64 r,a,b;
  CDC *dc,*old,*new;
  CDoomLevel *oldl;
  switch(state) {
    case 0:
      r=MenuInteract(doom_scrn,items,97,67);
      if(r=='NGAME') {
#ifdef DOOM2
        state=2;
#else
        state=1;
#endif
      } else if(r=='LOADG') {
        state=7;
        active_menu_item=0;
      } else if(r=='SAVEG') {
        state=6;
        active_menu_item=0;
      } else if(r=='RDTHIS') {
        state=4;
      } else if(r=='QUITG') {
        DCFill;
        Exit;
      } else if(!r)
        return 0;
      break;
    case 1:
      ep=EpisodeMenu;
      if(ep&&ep!=INVALID_PTR) {
        state=2;
      } else if(!ep)
        state=0;
      break;
    case 2:
      s=NewGameMenu;
      if(s&&s!=INVALID_PTR) {
        state=0;
#ifdef DOOM2
        if(l) {FreeLevel(l);l=NULL;}
        l=LoadWadLevel("MAP01",s-'1'+1);
        screen_melt=TRUE;
//This will check if we are in a level,otherwise the world is just swapped with l
        PlayLevel;
        return 0;
#else
        StrPrint(level,"E%cM1",ep);

        active_menu=NULL;
	oldl=l;
        l=LoadWadLevel(level,s-'1'+1);
        if(!l) {
	  l=oldl;
	  state=8;
	  break;
        }
        if(oldl)
	  FreeLevel(oldl);
        screen_melt=TRUE;
//This will check if we are in a level,otherwise the world is just swapped with l
        PlayLevel;
        return 0;
#endif
      } else if(!s)
#ifdef DOOM2
        state=0;
#else
        state=1;
#endif
      break;
    start:
      switch(ScanMsg(&a,&b)) {
        case MSG_KEY_DOWN:
	  if(a=='\n')
	    next=TRUE;
	  else if(a==CH_ESC)
	    next=TRUE;
	  break;
        case MSG_MS_L_DOWN:
	  next=TRUE;
	  break;
      }
      case 4:
#ifdef DOOM2
        dc=GetGrLump("HELP");
        GrBlot(doom_scrn,0,0,dc);
        if(next) {
	  state=0;
	  FlushMsgs;
        }
#else
        dc=GetGrLump("HELP1");
        GrBlot(doom_scrn,0,0,dc);
        if(next) {
	  state=5;
	  FlushMsgs;
        }
        break;
#endif
      case 5:
        dc=GetGrLump("HELP2");
        if(dc) {
	  GrBlot(doom_scrn,0,0,dc);
	  if(next) {
	    state=0;
	    FlushMsgs;
	  }
        } else {
	  state=0;
	  FlushMsgs;
        }
        break;
      case 8:
        MenuMessage(SWSTRING);
        if(next) {
	  state=0;
	  FlushMsgs;
        }
        break;
    end:
      break;;
    case 6:
      r=LoadSaveInteract(doom_scrn,TRUE);
      if(r==-1)
        state=0;
      return r;
    case 7:
      r=LoadSaveInteract(doom_scrn,FALSE);
      if(r==-1)
        state=0;
      return r;

  }
  return INVALID_PTR;
}

U0 DrawSaveLoadBorder(CDC *to,I64 x,I64 y) {
  CDC *dc=GetGrLump("M_LSLEFT");
  I64 i;
  GrBlot(to,x-8*2,y-7*2,dc);
  dc=GetGrLump("M_LSCNTR");
  for(i=0;i!=24;i++) {
    GrBlot(to,x,y-7*2,dc);
    x+=8*2;
  }
  dc=GetGrLump("M_LSRGHT");
  GrBlot(to,x,y-7*2,dc);
}

I64 LoadSaveInteract(CDC *to,Bool save) {
//THIS IS NOT ANORMAL MENU,so reset active_menu_item WHEN YOU ARE DONE
  I64 i,x=80*2,y=54*2;
  I64 a,b;
  U8 *fptr,buf[STR_LEN],*buf_ptr=buf;
  static U8 titles[6][STR_LEN];
  static Bool enter_name=FALSE;
  static Bool poll_again=TRUE;
  static U8 save_name[STR_LEN];
  CDC *dc,*skull;
  if(poll_again) {
    if(!FileFind("/ToomSave")) DirMk("/ToomSave");
    for(i=0;i!=6;i++) {
      StrPrint(buf,"/ToomSave/SAVE%d.SAVE",i);
      if(FileFind(buf)) {
        fptr=FileRead(buf);
        StrScan(fptr,"SAVE_NAME:%s\n",&buf_ptr);
        StrCpy(titles[i],buf);
        Free(fptr);
      } else
        StrCpy(titles[i],"");
    }
    poll_again=FALSE;
  }
  if(Blink)
    skull=GetGrLump("M_SKULL1");
  else
    skull=GetGrLump("M_SKULL2");
  if(save)
    dc=GetGrLump("M_SAVEG");
  else
    dc=GetGrLump("M_LOADG");
  GrBlot(to,72*2,28*2,dc);
  if(!enter_name){
    while(i=ScanMsg(&a,&b)) {
      switch(i) {
	case MSG_MS_L_DOWN:
	  goto press;
	case MSG_MS_MOVE:
	  active_menu_item=ClampI64((ms.pos.y-y)/(20*2),0,5);
	  break;
        case MSG_KEY_DOWN:
	  if(b.u8[0]==SC_CURSOR_UP) {
	    active_menu_item=ClampI64(active_menu_item-1,0,5);
	  } else if(b.u8[0]==SC_CURSOR_DOWN) {
	    active_menu_item=ClampI64(active_menu_item+1,0,5);
	  } else if(a=='\n') {
press:
	    if(save) {
	      enter_name=TRUE;
	      StrCpy(save_name,titles[active_menu_item]);
	      goto lenter_name;
	    } else {
	      StrPrint(buf,"/ToomSave/SAVE%d.SAVE",active_menu_item);
              active_menu_item=0;
	      if(FileFind(buf)) {
		LoadGame(buf);
	      }
	      return -1;
	    }
	  } else if(a==CH_ESC) {
	    active_menu_item=0;
	    return -1;
	  }
      }
    }
  } else {
//save==TRUE if here
lenter_name:;
    while(i=ScanMsg(&a,&b)) {
      if(i==MSG_KEY_DOWN) {
        if(a==CH_BACKSPACE&&StrLen(save_name)) {
	  save_name[StrLen(save_name)-1]=0;
        } else if(a=='\n') {
	  enter_name=FALSE;
	  StrPrint(buf,"/ToomSave/SAVE%d.SAVE",active_menu_item);
	  poll_again=TRUE;
	  SaveGame(buf,save_name);
	  active_menu_item=0;
	  return -1;
        } else if(a==CH_ESC) {
	  enter_name=FALSE;
	  poll_again=TRUE; //We modiefed the tiles[x] here
	  active_menu_item=0;
	  return -1;
        } else if(Bt(char_bmp_displayable,a)) {
	  if(StrLen(save_name)<24)
	    CatPrint(save_name,"%c",a);
        }
	StrCpy(titles[active_menu_item],save_name);
      }
    }    
  }
  active_menu_item=ClampI64(active_menu_item,0,5);
  for(i=0;i!=6;i++) {
    DrawSaveLoadBorder(to,x,y);
    if(enter_name&&Blink&&i==active_menu_item) {
      DoomPrint(to,x,y-2*2,"%s_",titles[i]); //-2*2 was choosen by what looks good
    } else
      DoomPrint(to,x,y-2*2,"%s",titles[i]);
    if(active_menu_item==i) {
      GrBlot(to,
	    x-16-skull->width-skull->x*2,
	    y-skull->height/2-skull->y*2,
	    skull);
    }
    y+=20*2;
  }
  return INVALID_PTR;
}
