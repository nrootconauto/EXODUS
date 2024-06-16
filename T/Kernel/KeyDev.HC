U0 PutKey(I64 ch=0,I64 sc=0)
{//See $LK,"Keyboard Devices",A="HI:Keyboard Devices/System"$.
  CKeyDevEntry *tmpk;
  if (ch||sc) {
    tmpk=keydev.put_key_head.next;
    if (!Bt(&(Fs->display_flags),DISPLAYf_SILENT)) {
      if (kbd.scan_code & SCF_SCROLL && sys_focus_task==Fs)
	while (kbd.scan_code & SCF_SCROLL)
	  Yield; //Wait on SCROLL LOCK Key
      while (tmpk!=&keydev.put_key_head) {
	if ((!(sc&SCF_KEY_DESC) || tmpk->flags & KDF_HAS_DESCS) &&
	      (*tmpk->put_key)(ch,sc))
	  break;
	tmpk=tmpk->next;
      }
    }
  }
}

U0 PutChars(U64 ch)
{//Output chars. Up to 8 chars in a single U64.
//Don't use this.    $LK,"See Print() shortcut.",A="FF:::/Doc/HolyC.DD,DemoHolyC"$
  if (IsSilent) return;
  if (IsRaw) {
    TOSPrint("%c",ch);
  } while (ch) {
    PutKey(ch&255,0);
    ch>>=8;
  }
}

//See KeyDev.HC in TempleOS
U0 PutS(U8 *st)
{//Use $LK,"Print",A="MN:Print"$(). See $LK,"Keyboard Devices",A="HI:Keyboard Devices/System"$.
//Don't use this.  $LK,"See Print() shortcut.",A="FF:::/Doc/HolyC.DD,DemoHolyC"$
  if (IsSilent) return;
  if(__IsCmdLine) {
    TOSPrint("%s",st);
    return;
  }
  I64 ch;
  U8 *ptr;
  Bool cont=TRUE;
  if (!st) return;
  CKeyDevEntry *tmpk=keydev.put_key_head.next;
  if (!Bt(&(Fs->display_flags),DISPLAYf_SILENT)) {
    if (kbd.scan_code & SCF_SCROLL && sys_focus_task==Fs)
      while (kbd.scan_code & SCF_SCROLL)
        Yield;
    while (cont && tmpk!=&keydev.put_key_head) {
      if (tmpk->put_s) {
        if ((*tmpk->put_s)(st))
	  break;
      } else {
        ptr=st;
        while (ch=*ptr++)
	  if ((*tmpk->put_key)(ch,0))
	    cont=FALSE;
      }
      tmpk=tmpk->next;
    }
  }
}



U0 KeyDescSet(U8 *fmt,...)
{//Call this from key hndlr to report desc in $LK,"KeyMap",A="MN:KeyMap"$().
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  StrCpy(keydev.desc,buf);
  keydev.hndlr=Caller;
  Free(buf);
}

U0 KeyDevRem(CKeyDevEntry *tmpk)
{//Remove StdOut hook and free.
  QueRem(tmpk);
  Free(tmpk);
}

CKeyDevEntry *KeyDevAdd(Bool (*fp_put_key)(I64 ch,I64 sc),
	Bool (*fp_puts)(U8 *st),I64 priority,Bool key_descs=FALSE)
{//Places hook in StdOut chain. See $LK,"Keyboard Devices",A="HI:Keyboard Devices/System"$.
  CKeyDevEntry *tmpk=keydev.put_key_head.last,
	*tmpk1=CAlloc(sizeof(CKeyDevEntry),adam_task);
  tmpk1->put_key=fp_put_key;
  tmpk1->put_s=fp_puts;
  tmpk1->priority=priority;
  if (key_descs)
    tmpk1->flags|=KDF_HAS_DESCS;
  while (tmpk->priority>priority)
    tmpk=tmpk->last;
  QueIns(tmpk1,tmpk);
  if (tmpk->priority==priority)
    KeyDevRem(tmpk);
  return tmpk1;
}


Bool KDInputFilterPutKey(I64 ch,I64 scan_code)
{
  if (Bt(&(Fs->task_flags),TASKf_INPUT_FILTER_TASK)) {
    Msg(MSG_KEY_DOWN,ch,scan_code);
    return TRUE;
  } else
    return FALSE;
}

Bool KDInputFilterPutS(U8 *st)
{
  I64 ch;
  if (Bt(&(Fs->task_flags),TASKf_INPUT_FILTER_TASK)) {
    while (ch=*st++)
      Msg(MSG_KEY_DOWN,ch,0);
    return TRUE;
  } else
    return FALSE;
}

U0 CtrlAltDel(I64)
{
  //LBts(sys_ctrl_alt_flags,CTRL_ALT_DEL);
}

U0 CtrlAltC(I64)
{
  U8 *old_rip;
  if(TaskValidate(sys_focus_task)) {
    if(!Bt(&sys_focus_task->task_flags,TASKf_BREAK_LOCKED)) {
      old_rip=sys_focus_task->rip;
      sys_focus_task->rsp-=8;
      sys_focus_task->rsp(U8**)[0]=old_rip;
      sys_focus_task->rip=&Break;
    } else
      LBts(&sys_focus_task->task_flags,TASKf_PENDING_BREAK);
  }
}

U0 CtrlAltF(I64)
{
  SwapI64(&text.font,&text.aux_font);
}

U0 CtrlAltM(I64)
{
  static F64 vol;
  F64 cur=GetVolume;
  if (cur>0.) {
    vol=cur;
    SetVolume(0.);
  } else
    SetVolume(vol);
}

U0 CtrlAltT(I64)
{
  //Spawn this explicitly on Core 0.
  //KBCb calls this from the loader core
  Spawn(&UserCmdLine,,,-2);
}

U0 CtrlAltX(I64)
{
  if(TaskValidate(sys_focus_task))
    Kill(sys_focus_task);
}
U0 CtrlAltN(I64) {
  if(TaskValidate(sys_focus_task))
    TaskFocusNext;
}

U0 CtrlAltP(I64) {
  static CBGR48 stdpal[COLORS_NUM],
//https://gitlab.com/tsoding/aoc-2021/-/blob/master/Home/Theme.HC
  gr_palette_gruv[COLORS_NUM]={
    0xebebdbdbb2b2, // BLACK
    0x454585858888, // BLUE
    0x989897971a1a, // GREEN
    0x68689d9d6a6a, // CYAN
    0xcccc24241d1d, // RED
    0xb1b162628686, // PURPLE
    0xfefe80801919, // BROWN
    0x3c3c38383636, // LTGRAY
    0x505049494545, // DKGRAY
    0x8383a5a59898, // LTBLUE
    0xb8b8bbbb2626, // LTGREEN
    0x8e8ec0c07c7c, // LTCYAN
    0xfbfb49493434, // LTRED
    0xd3d386869b9b, // LTPURPLE
    0xfafabdbd2f2f, // YELLOW
    0x282828282828  // WHITE
  };
  static Bool init=FALSE,toggle=FALSE;
  if (!init) {
    MemCpy(stdpal,gr_palette_std,sizeof gr_palette_std);
    init=TRUE;
  }
  if (!toggle) {
    GrPaletteSet(gr_palette_gruv);
    MemCpy(gr_palette_std,gr_palette_gruv,sizeof gr_palette_gruv);
    toggle=TRUE;
  } else {
    GrPaletteSet(stdpal);
    MemCpy(gr_palette_std,stdpal,sizeof stdpal);
    toggle=FALSE;
  }

}

U0 CtrlAltCBSet(U8 ch,U0 (*fp_hndlr)(I64 sc),
	U8 *no_shift_desc=NULL,U8 *shift_desc=NULL,Bool in_irq=FALSE)
{//Set callback for <CTRL-ALT-letter>.
  ch=ToUpper(ch)-'A';
  if (ch<26) {
    keydev.fp_ctrl_alt_cbs[ch]=fp_hndlr;

    Free(keydev.ctrl_alt_no_shift_descs[ch]);
    if (no_shift_desc)
      keydev.ctrl_alt_no_shift_descs[ch]=StrNew(no_shift_desc,adam_task);
    else
      keydev.ctrl_alt_no_shift_descs[ch]=NULL;

    Free(keydev.ctrl_alt_shift_descs[ch]);
    if (shift_desc)
      keydev.ctrl_alt_shift_descs[ch]=StrNew(shift_desc,adam_task);
    else
      keydev.ctrl_alt_shift_descs[ch]=NULL;

    BEqu(&keydev.ctrl_alt_in_irq_flags,ch,in_irq);
  }
}

U0 KeyDevInit()
{
  keydev.fp_ctrl_alt_cbs	=CAlloc(26*sizeof(U8 *));
  keydev.ctrl_alt_no_shift_descs=CAlloc(26*sizeof(U8 *));
  keydev.ctrl_alt_shift_descs	=CAlloc(26*sizeof(U8 *));
  keydev.ctrl_alt_in_irq_flags	=0;
  MemSet(&keydev.put_key_head,0,sizeof(CKeyDevEntry));
  QueInit(&keydev.put_key_head);
  KeyDevAdd(&KDInputFilterPutKey,&KDInputFilterPutS,0x40000000,FALSE);
  KeyDevAdd(&KDDocPutKey,&KDDocPutS,0x80000000,TRUE);
  CtrlAltCBSet('A',&CtrlAltA,"Cmd /Extended ASCII");
  CtrlAltCBSet('G',&CtrlAltG,"Cmd /Grid On","Cmd /Grid Off");
  //CtrlAltCBSet('C',&CtrlAltC,"Cmd /Break Execution",,TRUE); //Handled by input routine
  //CtrlAltCBSet('D',&CtrlAltD,"Cmd /Enter Debugger",,TRUE);
  CtrlAltCBSet('N',&CtrlAltN,"Cmd /Next Window",,TRUE);
  CtrlAltCBSet('F',&CtrlAltF,"Cmd /Toggle Aux Font");
  CtrlAltCBSet('M',&CtrlAltM,"Cmd /Toggle Mute");
  CtrlAltCBSet('N',&CtrlAltN,"Cmd /Next Focus Task",,TRUE);
  CtrlAltCBSet('T',&CtrlAltT,"Cmd /Terminal Window");
  //CtrlAltCBSet('V',&CtrlAltV,"Cmd /VGA Flush",,TRUE);
  //CtrlAltCBSet('X',&CtrlAltX,"Cmd /Kill Focused Task",,TRUE); Handled by input routine
  CtrlAltCBSet('B',&CtrlAltB,"Cmd /Bible");
  CtrlAltCBSet('Z',&CtrlAltZ,"Cmd /Zoom In",
	"Cmd /Zoom Out");
  CtrlAltCBSet('P',&CtrlAltP,"Cmd /Switch Palette");
  //CtrlAltCBSet('S',&CtrlAltS,"Cmd /Scrn Shot to Clip");
}
KeyDevInit;
