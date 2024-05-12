asm {
NORMAL_KEY_SCAN_DECODE_TABLE::
	DU8	0,CH_ESC,"1234567890-=",CH_BACKSPACE,'\t';
	DU8	"qwertyuiop[]",'\n',0,"as";
	DU8	"dfghjkl;'`",0,"\\zxcv";
	DU8	"bnm,./",0,'*',0,CH_SPACE,0,0,0,0,0,0;
	DU8	0,0,0,0,0,0,0,0,0,0,'-',0,0,0,'+',0;
SHIFT_KEY_SCAN_DECODE_TABLE::
	DU8	0,CH_SHIFT_ESC,"!@#\d%^&*()_+",CH_BACKSPACE,'\t';
	DU8	"QWERTYUIOP{}",'\n',0,"AS";
	DU8	"DFGHJKL:\"~",0,"|ZXCV";
	DU8	"BNM<>?",0,'*',0,CH_SHIFT_SPACE,0,0,0,0,0,0;
	DU8	0,0,0,0,0,0,0,0,0,0,'-',0,0,0,'+',0;
CTRL_KEY_SCAN_DECODE_TABLE::
	DU8	0,CH_ESC,"1234567890-=",CH_BACKSPACE,'\t';
	DU8	CH_CTRLQ,CH_CTRLW,CH_CTRLE,CH_CTRLR,CH_CTRLT,CH_CTRLY,CH_CTRLU,
		CH_CTRLI,CH_CTRLO,CH_CTRLP,"[]",'\n',0,CH_CTRLA,CH_CTRLS;
	DU8	CH_CTRLD,CH_CTRLF,CH_CTRLG,CH_CTRLH,CH_CTRLJ,CH_CTRLK,CH_CTRLL,
		";'`",0,"\\",CH_CTRLZ,CH_CTRLX,CH_CTRLC,CH_CTRLV;
	DU8	CH_CTRLB,CH_CTRLN,CH_CTRLM,",./",0,'*',0,CH_SPACE,0,0,0,0,0,0;
	DU8	0,0,0,0,0,0,0,0,0,0,'-',0,0,0,'+',0;
};
I64 Char2ScanCode(I64 ch,I64 sc_flags=0)
{//ASCII val to scan code (Slow).
  I64 i;
  U8 *table;
  if (sc_flags) {
    table=NORMAL_KEY_SCAN_DECODE_TABLE;
    if (sc_flags & SCF_CTRL || ch<26)
      table=CTRL_KEY_SCAN_DECODE_TABLE;
    else if (sc_flags & SCF_SHIFT || 'A'<=ch<='Z') {
      if (!(sc_flags & SCF_CAPS))
	table=SHIFT_KEY_SCAN_DECODE_TABLE;
    } else {
      if (sc_flags & SCF_CAPS)
	table=SHIFT_KEY_SCAN_DECODE_TABLE;
    }
    for (i=0;i<0x50;i++)
      if (table[i]==ch)
	return i|sc_flags;
    return sc_flags;
  } else {
    table=NORMAL_KEY_SCAN_DECODE_TABLE;
    for (i=0;i<0x50;i++)
      if (table[i]==ch)
	return i;
    table=SHIFT_KEY_SCAN_DECODE_TABLE;
    for (i=0;i<0x50;i++)
      if (table[i]==ch)
	return i|SCF_SHIFT;
    table=CTRL_KEY_SCAN_DECODE_TABLE;
    for (i=0;i<0x50;i++)
      if (table[i]==ch)
	return i|SCF_CTRL;
    return 0;
  }
}

U8 ScanCode2Char(I64 sc)
{//Scan code to ASCII val.
  U8 *table=NORMAL_KEY_SCAN_DECODE_TABLE;
  if (sc&SCF_E0_PREFIX)
    return 0;
  if (sc&SCF_CTRL)
    table=CTRL_KEY_SCAN_DECODE_TABLE;
  else if (sc&SCF_SHIFT) {
    if (!(sc&SCF_CAPS))
      table=SHIFT_KEY_SCAN_DECODE_TABLE;
  } else {
    if (sc&SCF_CAPS)
      table=SHIFT_KEY_SCAN_DECODE_TABLE;
  }
  sc&=0x7F;
  if (sc>=0x50)
    return 0;
  else
    return table[sc];
}
U8 scan_code_map[0x100]={
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,SC_SHIFT,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,SC_ENTER,SC_CTRL,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0x35,0,0,SC_ALT,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,SC_HOME,
	SC_CURSOR_UP,SC_PAGE_UP,0,SC_CURSOR_LEFT,0,SC_CURSOR_RIGHT,0,SC_END,
  SC_CURSOR_DOWN,SC_PAGE_DOWN,SC_INS,SC_DELETE,0,0,0,0,
	0,0,0,0,SC_GUI,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
};

U8 num_lock_map[0x100]={
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,8,9,10,0,5,6,7,0,2,
  3,4,11,0x34,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,

  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,SC_ENTER,SC_CTRL,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0x35,0,0,SC_ALT,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,SC_HOME,
	SC_CURSOR_UP,SC_PAGE_UP,0,SC_CURSOR_LEFT,0,SC_CURSOR_RIGHT,0,SC_END,
  SC_CURSOR_DOWN,SC_PAGE_DOWN,SC_INS,SC_DELETE,0,0,0,0,
	0,0,0,0,SC_GUI,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
};
U0 InputFilterTask()
{
  CJob *tmpc,*tmpc1;
  Bool old_filter;
  I64 old_flags=0;
  Fs->win_inhibit=WIG_USER_TASK_DFT;
  LBts(&(Fs->task_flags),TASKf_INPUT_FILTER_TASK);
  old_filter=LBts(&(Fs->last_input_filter_task->task_flags),TASKf_FILTER_INPUT);
  LBEqu(&(Fs->task_flags),TASKf_FILTER_INPUT,old_filter);
  while (TRUE) {
    JobsHndlr(old_flags);
    tmpc1=&(Fs->srv_ctrl.next_waiting);
    tmpc=tmpc1->next;
    if (tmpc==tmpc1)
      break;
    else {
      if (tmpc->job_code==JOBT_TEXT_INPUT) {
	QueRem(tmpc);
	//SetRFlags(old_flags);
	try
		ExePrint("%s",tmpc->aux_str);
	catch
	  Fs->catch_except=TRUE;
	JobDel(tmpc);
      } else
	break;
    }
  }
  Fs->next_input_filter_task->last_input_filter_task=Fs->last_input_filter_task;
  Fs->last_input_filter_task->next_input_filter_task=Fs->next_input_filter_task;
  if (!old_filter)
    LBtr(&(Fs->last_input_filter_task->task_flags),TASKf_FILTER_INPUT);
  //SetRFlags(old_flags);
}
U8 *Char2KeyName(I64 ch,Bool include_ctrl=TRUE)
{//ASCII val to key name.
  I64 i;
  U8 buf[STR_LEN];
  if (ch<=CH_SPACE) {
    switch [ch] {
      case '\n':
	StrCpy(buf,"ENTER");
	break;
      case CH_BACKSPACE:
	StrCpy(buf,"BACKSPACE");
	break;
      case '\t':
	StrCpy(buf,"TAB");
	break;
      case CH_ESC:
	StrCpy(buf,"ESC");
	break;
      case CH_SHIFT_ESC:
	StrCpy(buf,"SHIFT_ESC");
	break;
      case 0: //nobound switch
      case 29:
      case 30:
	*buf=0;
	break;
      case CH_SHIFT_SPACE:
	StrCpy(buf,"SHIFT_SPACE");
	break;
      case CH_SPACE:
	StrCpy(buf,"SPACE");
	break;
      default:
	if (include_ctrl)
	  StrCpy(buf,"CTRL ");
	buf[i=StrLen(buf)]=ch-1+'a';
	buf[i+1]=0;
	break;
    }
  } else if (Bt(char_bmp_printable,ch)) {
    *buf=ch;
    buf[1]=0;
  } else
    *buf=0;
  return StrNew(buf);
}

U8 *ScanCode2KeyName(I64 sc)
{//Scan code to key name.
  I64 ch;
  U8 buf[STR_LEN],*st;
  *buf=0;
  if (sc&SCF_CTRL)
    CatPrint(buf,"CTRL ");
  if (sc&SCF_ALT)
    CatPrint(buf,"ALT ");
  if (sc&SCF_SHIFT)
    CatPrint(buf,"SHIFT ");
  if (sc&SCF_NO_SHIFT)
    CatPrint(buf,"      ");
  if (ch=ScanCode2Char(sc&255)) {
    st=Char2KeyName(ch,FALSE);
    StrCpy(buf+StrLen(buf),st);
    Free(st);
  } else {
    switch (sc&255) {
      case SC_BACKSPACE:CatPrint(buf,"BACK");	break;
      case SC_CAPS:	CatPrint(buf,"CAPS");	break;
      case SC_NUM:	CatPrint(buf,"NUM");	break;
      case SC_SCROLL:	CatPrint(buf,"SCROLL");	break;
      case SC_CURSOR_UP:CatPrint(buf,"UP");	break;
      case SC_CURSOR_DOWN:CatPrint(buf,"DOWN");	break;
      case SC_CURSOR_LEFT:CatPrint(buf,"LEFT");	break;
      case SC_CURSOR_RIGHT:CatPrint(buf,"RIGHT"); break;
      case SC_PAGE_UP:	CatPrint(buf,"PAGE_UP");  break;
      case SC_PAGE_DOWN:CatPrint(buf,"PAGE_DOWN");break;
      case SC_HOME:	CatPrint(buf,"HOME");	break;
      case SC_END:	CatPrint(buf,"END");	break;
      case SC_INS:	CatPrint(buf,"INS");	break;
      case SC_DELETE:	CatPrint(buf,"DELETE");	break;
      case SC_F1:	CatPrint(buf,"F1");	break;
      case SC_F2:	CatPrint(buf,"F2");	break;
      case SC_F3:	CatPrint(buf,"F3");	break;
      case SC_F4:	CatPrint(buf,"F4");	break;
      case SC_F5:	CatPrint(buf,"F5");	break;
      case SC_F6:	CatPrint(buf,"F6");	break;
      case SC_F7:	CatPrint(buf,"F7");	break;
      case SC_F8:	CatPrint(buf,"F8");	break;
      case SC_F9:	CatPrint(buf,"F9");	break;
      case SC_F10:	CatPrint(buf,"F10");	break;
      case SC_F11:	CatPrint(buf,"F11");	break;
      case SC_F12:	CatPrint(buf,"F12");	break;
      case SC_GUI:	CatPrint(buf,"WINDOWS");  break;
      case SC_PRTSCRN1:	CatPrint(buf,"PRTSCRN1"); break;
      case SC_PRTSCRN2:	CatPrint(buf,"PRTSCRN2"); break;
    }
  }
  return StrNew(buf);
}

public I64 ScanMsg(I64 *_arg1=NULL,I64 *_arg2=NULL,I64 mask=~1,CTask *task=NULL)
{/*Check for a message of type specified by a one in the mask.
Throw-out messages not in mask.
If no message fit mask, return NULL immediately.
Remove desired message, return $LK,"msg_code",A="MN:MSG_CMD"$.
Note: This delivers messages from parent down to pop-up.
*/
  I64 res,old_flags;
  CJob *tmpc,*tmpc1;
  if (!task) task=Fs;
  old_flags=0;//GetRFlags;
  tmpc1=&task->srv_ctrl.next_waiting;
  while (TRUE) {
    if (task==Fs)
      JobsHndlr(old_flags);
    tmpc=tmpc1->next;
    if (tmpc==tmpc1)
      break;
    else {
      if (tmpc->job_code==JOBT_MSG) {
	QueRem(tmpc);
	//SetRFlags(old_flags);
	res=tmpc->msg_code;
	if (_arg1)
	  *_arg1=tmpc->aux1;
	if (_arg2)
	  *_arg2=tmpc->aux2;
	JobDel(tmpc);
	if (Bt(&mask,res))
	  goto sm_done;
      }
    }
    //SetRFlags(old_flags);
  }
  res=MSG_NULL;
  if (_arg1)
    *_arg1=0;
  if (_arg2)
    *_arg2=0;
  if (task->parent_task&&task->parent_task->popup_task==task) {
    //SetRFlags(old_flags);
    return ScanMsg(_arg1,_arg2,mask,task->parent_task);
  }
sm_done:
  //SetRFlags(old_flags);
  return res;
}
I64 FlushMsgs(CTask *task=NULL)
{//Throw away all messages.  Return count.
  I64 res=0,arg1,arg2;
  while (ScanMsg(&arg1,&arg2,~1,task))
    res++;
  return res;
}

I64 GetMsg(I64 *_arg1=NULL,I64 *_arg2=NULL,I64 mask=~1,CTask *task=NULL)
{//Wait for a message of type specified by a one in the mask.
//Throw-out all messages not in mask.
  //Returns $LK,"msg_code",A="MN:MSG_CMD"$. See $LK,"::/Demo/MsgLoop.HC"$.
  I64 res;
  if (!task) task=Fs;
  LBtr(&task->task_flags,TASKf_IDLE);
  while (!(res=ScanMsg(_arg1,_arg2,mask,task))) {
    LBts(&task->task_flags,TASKf_IDLE);
    Sleep(1);
  }
  LBtr(&task->task_flags,TASKf_IDLE);
  return res;
}

I64 ScanChar()
{//Checks for $LK,"MSG_KEY_DOWN",A="MN:MSG_KEY_DOWN"$ and returns 0 immediately if no key.
//Waits for $LK,"MSG_KEY_UP",A="MN:MSG_KEY_UP"$ of non-zero $LK,"ASCII",A="MN:CH_CTRLA"$ key and returns $LK,"ASCII",A="MN:CH_CTRLA"$ if key.
  //$LK,"ScanMsg",A="MN:ScanMsg"$() throws away other message types.
  I64 arg1a,arg2a,arg1b,arg2b;
  if (!ScanMsg(&arg1a,&arg2a,1<<MSG_KEY_DOWN)||!arg1a)
    return 0;
  else
    do GetMsg(&arg1b,&arg2b,1<<MSG_KEY_UP);
    while (!arg1b);  //Be careful of $LK,"SC_SHIFT",A="MN:SC_SHIFT"$ and $LK,"SC_CTRL",A="MN:SC_CTRL"$, etc.
  return arg1a;
}

Bool ScanKey(I64 *_ch=NULL,I64 *_scan_code=NULL,Bool echo=FALSE)
{//Checks for $LK,"MSG_KEY_DOWN",A="MN:MSG_KEY_DOWN"$ and returns FALSE immediately if no key.
//Sets $LK,"ASCII",A="MN:CH_CTRLA"$ and $LK,"scan_code",A="FI:::/Doc/CharOverview.DD"$.
  //Removes key message and returns TRUE.
  //$LK,"ScanMsg",A="MN:ScanMsg"$() throws away other message types.
  I64 ch=0,sc=0;
  if (ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN)) {
    if (_ch) *_ch=ch;
    if (_scan_code) *_scan_code=sc;
    if (echo)
      PutKey(ch,sc);
    return TRUE;
  } else {
    if (_ch) *_ch=0;
    if (_scan_code) *_scan_code=0;
    return FALSE;
  }
}

I64 GetKey(I64 *_scan_code=NULL,Bool echo=FALSE,Bool raw_cursor=FALSE)
{//Waits for $LK,"MSG_KEY_DOWN",A="MN:MSG_KEY_DOWN"$ message and returns $LK,"ASCII",A="MN:CH_CTRLA"$.
//Sets $LK,"scan_code",A="FI:::/Doc/CharOverview.DD"$.
  //$LK,"ScanKey",A="MN:ScanKey"$() throws away other message types.
  I64 ch,sc;
  Bool cursor_on=FALSE;
  while (!ScanKey(&ch,&sc,FALSE)) {
    LBts(&(Fs->task_flags),TASKf_IDLE);
    LBts(&(Fs->task_flags),TASKf_AWAITING_MSG);
    //Yields for us
    Sleep(1);
    LBtr(&(Fs->task_flags),TASKf_IDLE);
  }
  if (raw_cursor && cursor_on)
    "%c",CH_BACKSPACE;
  if (echo)
    PutKey(ch,sc);
  if (_scan_code) *_scan_code=sc;
  return ch;
}

I64 GetChar(I64 *_scan_code=NULL,Bool echo=TRUE,Bool raw_cursor=FALSE)
{//Waits for non-zero $LK,"ASCII",A="MN:CH_CTRLA"$ key.
//Sets $LK,"scan_code",A="FI:::/Doc/CharOverview.DD"$.
  I64 ch1;
  do ch1=GetKey(_scan_code,FALSE,raw_cursor);
  while (!ch1);
  if (echo)
    "\dPT\d%c\dFG\d",ch1;
  return ch1;
}

U8 *GetStr(U8 *msg=NULL,U8 *dft=NULL,I64 flags=0)
{//Returns a $LK,"MAlloc",A="MN:MAlloc"$()ed prompted string.  See $LK,"Flags",A="MN:GSF_SHIFT_ESC_EXIT"$.
  U8 *st,*bt2;
  if (IsRaw) {
    st=__GetStr(msg);
    if (!st) {
      if (dft)
        st=StrNew(dft);
      else
        st=StrNew("");
    }
    return st;
  }
  if (msg)
    "" msg,dft;
  st=(*fp_getstr2)(flags);
  if (!*st) {
    Free(st);
    if (dft)
      return StrNew(dft);
    else
      return StrNew("");
  }
  return st;
}

I64 GetS(U8 *buf,I64 size,Bool allow_ext=TRUE)
{//Prompt into fixed length string. Size must include terminator.
  U8 *st;
  I64 ch,i=0;
  if (!size || !buf) return 0;
  if (allow_ext) {
    st=GetStr;
    if (StrLen(st)>size-1) {
      MemCpy(buf,st,size-1);
      buf[size-1]=0;
    } else
      StrCpy(buf,st);
    i=StrLen(buf);
    Free(st);
  } else {
    while (TRUE) {
      ch=GetChar(,FALSE,FALSE);
      if (ch=='\n') {
	'' ch;
	break;
      } else if (ch==CH_BACKSPACE) {
	if (i>0) {
	  i--;
	  '' ch;
	}
      } else {
	if (i<size-1) {
	  buf[i++]=ch;
	  '' ch;
	}
      }
    }
    buf[i]=0;
  }
  return i;
}
U0 KbdInit() {
  MemSet(&kbd,0,sizeof(CKbdStateGlbls));
  kbd.fifo=FifoU8New(8);
  kbd.fifo2=FifoU8New(0x1000);
  kbd.scan_code_fifo=FifoI64New(0x1000);
  kbd.irqs_working=TRUE; //???
}
KbdInit;
I64 KbdMsgsQue()
{
  I64 arg1,arg2,msg_code=MSG_NULL;
  CTask *task_focus;
  if (TaskValidate(task_focus=sys_focus_task)) {
    while (FifoI64Rem(kbd.scan_code_fifo,&arg2)) {
      arg1=ScanCode2Char(arg2);
      if (arg2 & SCF_KEY_UP) {
	TaskMsg(task_focus,0,MSG_KEY_UP,arg1,arg2,0);
	msg_code=MSG_KEY_UP;
      } else {
	TaskMsg(task_focus,0,MSG_KEY_DOWN,arg1,arg2,0);
	msg_code=MSG_KEY_DOWN;
      }
    }
  }
  return msg_code;
}

static I64 kb_mtx=0;

static U0 KBCb(I64 s) {
  U8 *old_rip;
  I64 old_idle_pt_hits,time_out;
  while (LBts(&kb_mtx,0))
    PAUSE;
  SetFs(adam_task);
  kbd.last_down_scan_code=s;
  kbd.scan_code=s;
  BEqu(&kbd.down_bitmap,s&0x7f,!(s&SCF_KEY_UP));
  FifoI64Ins(kbd.scan_code_fifo,s);
  kbd.timestamp=cnts.jiffies;
  I64 c=ScanCode2Char(s&0x7f);
  if (keydev.fp_ctrl_alt_cbs &&
      !(s&SCF_KEY_UP)        &&
      s&SCF_ALT              &&
      s&SCF_CTRL             &&
      'a'<=c<='z') {
    if (keydev.fp_ctrl_alt_cbs[c-'a'])
      (*keydev.fp_ctrl_alt_cbs[c-'a'])(s);
  }
  if (!(s&SCF_KEY_UP) &&
     s&SCF_ALT        &&
     s&SCF_CTRL       &&
     (c=='c'||c=='x') &&
     TaskValidate(sys_focus_task)) {
    if (c=='c') {
      if (!Bt(&SYS_CTRL_ALT_FLAGS,CTRL_ALT_C)) {
        LBts(&SYS_CTRL_ALT_FLAGS,CTRL_ALT_C);
        goto await_yield;
      }
    } else if (c=='x') {
      if (!Bt(&SYS_CTRL_ALT_FLAGS,CTRL_ALT_X)) {
        LBts(&SYS_CTRL_ALT_FLAGS,CTRL_ALT_X);
  await_yield:
        time_out=cnts.jiffies;
        while (time_out-cnts.jiffies<ToI64(0.05*1000))
          if (IsFrozen(&cpu_structs[0])) {
            InterruptCore(0);
            break;
          } else break;
      }
    }
  }
  LBtr(&kb_mtx,0);
}
SetKBCallback(&KBCb);

I64 KbdMsEvtTime()
{//Timestamp of last key or mouse event.
  if (ms_hard.timestamp>kbd.timestamp)
    return ms_hard.timestamp;
  else
    return kbd.timestamp;
}
