Bool ChkPtr(U8 *ptr)
{//Check if addr is valid ptr.
  return __IsValidPtr(ptr);
}

Bool ChkCodePtr(U8 *ptr)
{//Check if addr is valid code addr.
  return __IsValidPtr(ptr) && ptr < I32_MAX;
}

public Bool ChkOnStk(U8 *ptr,CTask *task=NULL) {
  if (!task) task=Fs;
  U8 *stk=task->stk;
  I64 stk_size=MSize(stk);
  return stk<=ptr<stk+stk_size;
}

U8 *Caller(I64 num=1)
{//Returns the addr of the fun which called this one,
//or the caller of the caller, etc.
  U8 **rbp=GetRBP,**ptr;
  while (num--) {
    if (rbp>=*rbp)
      return NULL;
    rbp=*rbp;
    if (!ChkOnStk(rbp,Fs))
      return NULL;
  }
  ptr=rbp+1;
  return *ptr;
}

U8 *__CallerBP(U8 **rbp,I64 num=1)
{//Returns the addr of the fun which called this one,
//or the caller of the caller, etc.
  U8 **ptr;
  while (num--) {
    if(!ChkPtr(rbp)) return NULL;
    if (rbp>=*rbp)
      return NULL;
    rbp=*rbp;
    if (!ChkOnStk(rbp,Fs))
      return NULL;
  }
  ptr=rbp+1;
  if(!ChkPtr(ptr)) return NULL;
  return *ptr;
}

U8 *TaskCaller(CTask *task=NULL,I64 num=0,Bool saved_context=FALSE)
{//Fetches addr of Nth caller on task's stk.
  U8 **ptr,**rbp,**rsp;
  if (!task) task=Fs;
  if (!saved_context && task==Fs)
    return Caller(num+1);
  if (!TaskValidate(task))
    return NULL;
  rbp=task->rbp;
  rsp=task->rsp;
  if (num) {
    while (rbp) {
      if(!ChkOnStk(rbp,task))
        break;
      ptr=rbp+1;
      //Here's the deal, I assume wine muddies the caller stack
      //to make it not show bogus, in FFI_CALL_TOS_0_BP, I zero the caller ptr
      if(!ptr) break;
      if (! --num)
	return *ptr;
      if (rbp>=*rbp)
	break;
      rbp=*rbp;
    }
    return NULL;
  } else {
    if (task->rip==_RET)
      return *rsp;
    else
      return task->rip;
  }
}
U0 FaultCB(U8 **rbp,U8 *fptr) {
    I64 bt=1;
    U8 *ln,*fn;
    CHashFun *f=FunSegFind(fptr,NULL);
    TOSPrint("ENTERED FAULT\n");
    
    ln=SrcEdLink(fptr);
    if (!ln) ln=StrNew("???");
    if (f)
        TOSPrint("[%d] %s,%s\n",0,f->str,ln);
    else
        TOSPrint("[%d] %s\n",0,ln);
    Free(ln);
    
    //__CallerBP will return NULL if we cant go up the stack more
    for (bt=0;__CallerBP(rbp,bt);bt++) {
        ln=SrcEdLink(__CallerBP(rbp,bt));
        if (!ln) ln=StrNew("???");
        f=FunSegFind(__CallerBP(rbp,bt),NULL);
//Add 1,(+0 is RIP)
        if (f)
            TOSPrint("[%d] %s,%s\n",bt+1,f->str,ln);
        else
            TOSPrint("[%d] %s\n",bt+1,ln);
        Free(ln);
    }
    //Exit;
}

CTask *GetDebuggedProcess() {
  CHashGlblVar *dtask=HashFind("DFs",Fs->hash_table,HTT_GLBL_VAR);
  if (dtask) return dtask->data_addr(CTask**)[0];
  return Fs;
}
 
U0 CallerRep(U8 **rbp=NULL,CTask *task=NULL)
{//Prints a report of calling routines.
  I64 **ptr;
  if (!task) task=GetDebuggedProcess;
  if (!rbp) {
    if (task==Fs)
      rbp=GetRBP;
    else
      rbp=task->rbp;
  }
  "CallerRep:\n";
  while (ChkOnStk(rbp,task)) {
    ptr=rbp+1;
    "%08X:%08tX:%P\n",ptr,*ptr,*ptr;
    if (rbp>=*rbp)
      break;
    rbp=*rbp;
  }
}

U0 DebuggerSpawn(CTask *debugee) {  
  U8 *src_link;
  Fs->win_inhibit=WIG_USER_TASK_DFT;
  DocTermNew;
  LBts(&(Fs->display_flags),DISPLAYf_SHOW);
  "$$BK,1$$Debugging DFs(0x%X)$$BK,0$$\n",debugee->addr;
  "Type 'DbgHelp;' for help,it's a bit different than TempleOS.\n";
  "Oh,and welcome to %P(%s)\n",debugee->rip,src_link=SrcEdLink(debugee->rip);
  "\n";
  Free(src_link);
  ExePrint("CTask *DFs=0x%X;;\n",debugee);
  WinToTop;
  WinZBufUpdate;
  UserTaskCont;
}
/*
 * $BK,1$README$BK,0$
 * In Wine(and Windows?) A INT3 will give us the RIP of the INT3
 * So we need to advance past this INT3 to avoid INT3'ing forever
 *
 * Thus I am using a seperate DebuggerLand for Windows
 */
U0 DebuggerLandWin(I64 sig,I64 *gps) {
  CBpt *bp;
  CHashTable *old;
  CTask clone;
  UnblockSignals;
  if(Fs==sys_winmgr_task) {
    //Oh no,you crashed the window manager
    TOSPrint("You crashed the window manager, attempting restart\n");
    //Shutdown;
    old=Fs->hash_table;
    Fs->hash_table=sys_task_being_scrn_updated->hash_table;
    FaultCB(gps[5],gps[16]);
    Fs->hash_table=old;
    sys_task_being_scrn_updated->draw_it=NULL;
    //Don't use Kill() normally, just directly shut it down
    LBts(&sys_task_being_scrn_updated->task_flags,TASKf_KILL_TASK);
    sys_winmgr_task=Spawn(&WinMgrTask);
    Exit;
  }
  FaultCB(gps[5],gps[16]);
  Bool b=FALSE;
//General purpose registers are in this order,16 is RIP
  _RAX=gps[0];
  _RCX=gps[1];
  _RDX=gps[2];
  _RBX=gps[3];
  _RSP=gps[4];
  _RBP=gps[5];
  _RSI=gps[6];
  _RDI=gps[7];
  _R8=gps[8];
  _R9=gps[9];
  _R10=gps[10];
  _R11=gps[11];
  _R12=gps[12];
  _R13=gps[13];
  _R14=gps[14];
  _R15=gps[15];
//Exception,rip is 16
  _RIP=gps[16];
//18 is rflags
  Fs->rflags=gps[18];
  Fs->rflags&=~(1<<RFLAGf_TRAP);
  if(sig==5) { //SIGTRAP
    if(LBtr(&(Fs->task_flags),TASKf_DISABLE_BPTS))
      if(!LBtr(&(Fs->task_flags),TASKf_JUST_STEPPED)) {
        MemCpy(&clone,Fs,sizeof CTask);
        goto fin;
      }
//If we SIGTRAP'ed,we probaly hit an IHT3
    if(bp=BptFind(_RIP,Fs)) {
        LBts(&Fs->task_flags,TASKf_DISABLE_BPTS);
        Fs->rflags|=1<<RFLAGf_TRAP;
    } else if(ChkPtr(_RIP))
      if(_RIP(U8*)[0]==OC_BPT) //Advance if we hit a stray BPT
        _RIP++;
  }
  MemCpy(&clone,Fs,sizeof CTask);
  CTask *task=Spawn(&DebuggerSpawn,&clone,"Debugger",0,Fs,,1<<JOBf_WAKE_MASTER|1<<JOBf_ADD_TO_QUE);
  DeathWait(&task);
  if(sig!=5) //SIGTRAP
    Exit;
fin:
  //There  are 16 gps,and rip and rflags
  MemCpy(&Fs->rip,&clone.rip,(16+2)*8);
  MemCpy(Fs->fpu_mmx,gps[17],sizeof CFPU);
  Fs->task_flags=clone.task_flags;
  Fs->bpt_lst=clone.bpt_lst;
  Call(_TASK_CONTEXT_RESTORE);
}

//
//$BK,1$README$BK,0$
//On linux,the trap comes after the INT3
//So keep this in mind as check _RIP-1 for the breakpoint
//
//TODO unify with win
U0 DebuggerLand(I64 sig,I64 *gps) {
  CBpt*bp;
  CHashTable *old;
  CTask clone;
  UnblockSignals;
  if(Fs==sys_winmgr_task) {
    TOSPrint("You crashed the window manager, attempting restart\n");
    //Shutdown;
    old=Fs->hash_table;
    Fs->hash_table=sys_task_being_scrn_updated->hash_table;
    FaultCB(gps[5],gps[16]);
    Fs->hash_table=old;
    sys_task_being_scrn_updated->draw_it=NULL;
    //Equivalent to Exit() on the task in question
    LBts(&sys_task_being_scrn_updated->task_flags,TASKf_KILL_TASK);
    sys_winmgr_task=Spawn(&WinMgrTask);
    Exit;
  }
  FaultCB(gps[5],gps[16]);
  //General purpose registers are in this order,16 is RIP
  /* http://wiki.osdev.org/X86-64_Instruction_Encoding
   * (https://archive.md/kdCG4) */
  _RAX=gps[0];
  _RCX=gps[1];
  _RDX=gps[2];
  _RBX=gps[3];
  _RSP=gps[4];
  _RBP=gps[5];
  _RSI=gps[6];
  _RDI=gps[7];
  _R8=gps[8];
  _R9=gps[9];
  _R10=gps[10];
  _R11=gps[11];
  _R12=gps[12];
  _R13=gps[13];
  _R14=gps[14];
  _R15=gps[15];
//Exception,rip is 16
  _RIP=gps[16];
//18 is rflags
  Fs->rflags=gps[18];
  Fs->rflags&=~(1<<RFLAGf_TRAP);
  if (sig==5) { //SIGTRAP
    if (LBtr(&Fs->task_flags,TASKf_DISABLE_BPTS)) {
      if (!LBtr(&Fs->task_flags,TASKf_JUST_STEPPED))
        goto fin;
    } else {
//ONLYCHECK IFBREAKPOINTSWEREN'tDISABLED
      //If we SIGTRAP'ed,we probaly hit an IHT3
      if(bp=BptFind(_RIP-1,Fs)) {
        _RIP--;
        LBts(&(Fs->task_flags),TASKf_DISABLE_BPTS);
        Fs->rflags|=1<<RFLAGf_TRAP;
      }
    }

  }
  MemCpy(&clone,Fs,sizeof CTask);
  CTask *task=Spawn(&DebuggerSpawn,&clone,"Debugger",0,Fs,,1<<JOBf_WAKE_MASTER|1<<JOBf_ADD_TO_QUE);
  DeathWait(&task);
  if (sig!=5) //SIGTRAP
    Exit;
fin:
  MemCpy(&Fs->rip,&clone.rip,(16+2)*8);
  MemCpy(Fs->fpu_mmx,gps[17],sizeof CFPU);
  Fs->task_flags=clone.task_flags;
  Fs->bpt_lst=clone.bpt_lst;
  Call(_TASK_CONTEXT_RESTORE);
}
CBpt *BptFind(U8 *needle_addr,CTask *haystack_task=NULL,Bool rem=FALSE)
{
  CBpt *res=NULL,*tmpb,*tmpb1,*tmpb2;
  Bool bl;
  if (!haystack_task) haystack_task=GetDebuggedProcess;
  PUSHFD
  bl=BreakLock;
  tmpb1=&haystack_task->bpt_lst;
  tmpb=haystack_task->bpt_lst;
  while (tmpb) {
    tmpb2=tmpb->next;
    if (tmpb->addr==needle_addr) {
      res=tmpb;
      if (rem)
	tmpb1->next=tmpb2;
      else
	tmpb1=&tmpb->next;
    } else
      tmpb1=&tmpb->next;
    tmpb=tmpb2;
  }
  if(bl)
    BreakUnlock;
  POPFD
  return res;
}

Bool BptS(U8 *addr,CTask *task=NULL,Bool live=TRUE)
{//Set breakpoint.
  CBpt *tmpb;
  Bool res=TRUE,bl;
  if (!task) task=GetDebuggedProcess;
  PUSHFD
  bl=BreakLock;
  if (!(tmpb=BptFind(addr,task,FALSE))) {
    tmpb=CAlloc(sizeof(CBpt),task);
    tmpb->addr=addr;
    tmpb->val=*addr;
    res=FALSE;
    tmpb->next=task->bpt_lst;
    task->bpt_lst=tmpb;
    if (task==GetDebuggedProcess && live)
      *addr=OC_BPT;
  }
  if(bl)
    BreakUnlock;
  POPFD
  return res;
}

Bool BptR(U8 *addr,CTask *task=NULL,Bool live=TRUE,Bool rem=TRUE)
{//Rem breakpoint.
  CBpt *tmpb;
  Bool res=FALSE,bl;
  if (!task) task=GetDebuggedProcess;
  PUSHFD
  bl=BreakLock;
  if (tmpb=BptFind(addr,task,rem)) {
    if (task==GetDebuggedProcess && live)
      *tmpb->addr=tmpb->val;
    res=TRUE;
    if (rem)
      Free(tmpb);
  }
  if(bl)
    BreakUnlock;
  POPFD
  return res;
}

Bool B(U8 *addr,CTask *task=NULL,Bool live=TRUE)
{//Toggle breakpoint.
//Return: TRUE if removed.
  Bool res=FALSE,bl;
  PUSHFD
  bl=BreakLock;
  if (BptFind(addr,task,FALSE)) {
    BptR(addr,task,live,TRUE);
    res=TRUE;
  } else
    BptS(addr,task,live);
  if(bl)
    BreakUnlock;
  POPFD
  return res;
}

I64 B2(CTask *task=NULL,Bool live=TRUE)
{//Rem all breakpoints.
//Return: cnt of removed.
  I64 res=0,bl;
  CBpt *tmpb,*tmpb1;
  if (!task) task=GetDebuggedProcess;
  PUSHFD
  bl=BreakLock;
  tmpb=task->bpt_lst;
  task->bpt_lst=NULL;
  while (tmpb) {
    tmpb1=tmpb->next;
    if (task==GetDebuggedProcess && live)
      *tmpb->addr=tmpb->val;
    Free(tmpb);
    tmpb=tmpb1;
    res++;
  }
  if(bl)
    BreakUnlock;
  POPFD
  return res;
}

U0 G(U8 *ip=INVALID_PTR,CTask *task=NULL)
{//Go
  if (!task) task=GetDebuggedProcess;
  if (ip!=INVALID_PTR) task->rip=ip;
  if (BptFind(task->rip,task))
    "\nDo one of the following, first:\n"
	  ">S;\t\t\t//Single step\n"
	  ">B2;\t\t\t//Clear all break points\n"
	  ">G2;\t\t\t//Clear all break points and Go\n\n";
  else {
    LBtr(&task->task_flags,TASKf_DISABLE_BPTS);
    LBtr(&task->rflags,RFLAGf_TRAP);//No single step
    Exit;
  }
}

U0 G2(U8 *ip=INVALID_PTR,CTask *task=NULL)
{//Rem all breakpoints and Go.
  if (!task) task=GetDebuggedProcess;
  B2(task);
  G(ip,task);
}

U0 BList(CTask *task=NULL) {
  if(!task) task=GetDebuggedProcess;
  CBpt *bp=&task->bpt_lst;
  U8 *slink;
  for(bp=bp->next;bp;bp=bp->next) {
    "\t%P(%s)\n",bp->addr,slink=SrcEdLink(bp->addr);
    Free(slink);
  }
}

public Bool ViewFrameVars(I64 frame=0,I64 depth=2) {
  U8 **rbp;
  CTask *t=GetDebuggedProcess;
  CHash *fun;
  U8 *rip;
  I64 oframe=frame;
  if(t==Fs) rbp=GetRBP,rip=NULL;
  else rbp=t->rbp,rip=t->rip;
  while(frame>0) {
    rip=rbp[1];
    rbp=*rbp;
    if(!ChkOnStk(rbp,t)) return FALSE;
    frame--;
  }
  fun=FunSegFind(rip,NULL);
  if(!fun) return FALSE;
  FunRep(fun->str,rbp,depth,t,!oframe);
  return TRUE;
}

U0 DbgHelp()
{
  "\n"
        "The cmd line is basically the same as TempleOS.	Here are some common\n"
        "debugging commands.\n\n"
        ">ClassRep(DFs,\"CTask\",1);\t//Dump current task record.\n"
        ">ClassRep(DFs,,1);\t\t//(It knows lastclass.)\n"
        ">CallerRep;\t\t\t//Stack trace report.\n"
        ">Da(DFs->rsp);\t\t\t//Dump stk.\n"
        ">Dr;\t\t\t\t//Dump Regs.\n"
        ">1+2*3+&Print;\t\t\t//Show calculation res.\n"
        ">*(0x70000)(I64 *)=0x123456789;\t//Assign value to 0x70000-0x70007.\n"
        ">DFs->_rax=0x1234;\t\t\t//Set RAX to 0x1234.\n"
        ">DFs->_rip=&Break;\t\t//Set RIP.\n"
        ">I64 i;\t\t\t\t//Declare variable.\n"
        ">i=DFs->rax+DFs->rbx;\t\t\t//Assign to variable.\n"
        ">U(&Print+0x8);\t\t\t//Unassemble Print.\n"
        ">Uf(\"Print\");\t\t\t//Unassembler function \"Print\".\n"
        ">Man(\"Print\");\t\t\t//Edit Src for \"Print\".\n"
        ">E(DFs->rip);\t\t\t//Edit Src Code.\n"
        ">B(&Main+0x20);\t\t\t//Toggle break point.\n"
        ">B2;\t\t\t\t//Clear all break points.\n"
        ">S;\t\t\t\t//Single step.\n"
        ">G;\t\t\t\t//Resume execution.\n"
        ">G2;\t\t\t\t//B2;VGAFlush;WinFocus;G;\n"
        ">ViewFrameVars;\t\t\t//Examine the variables at a frame\n"
        ">Exit;\t\t\t\t//Exit debugger.\n\n";
}
public U0 S(U8 *ip=INVALID_PTR,CTask *task=NULL) //Single-step.
{//Single step.
  Bool bl=BreakLock;
  if (!task) task=GetDebuggedProcess;
  PUSHFD
  if (ip!=INVALID_PTR) task->rip=ip;
/* https://en.wikipedia.org/wiki/Trap_flag
 * (https://archive.md/1GmTs) */
  LBts(&task->task_flags,TASKf_DISABLE_BPTS);
  LBts(&task->task_flags,TASKf_JUST_STEPPED);
  LBts(&task->rflags,RFLAGf_TRAP);
  POPFD
  if(bl) BreakUnlock;
  Exit;
}
#define STK_REP_LEN 32
U0 StkRep(CTask *task=NULL)
{//Reports whats on the stk.
  I64 i,j,addr,
	**rbp,**rsp,*my_rsp[STK_REP_LEN],bl;
  CHashTable *old_hash=Fs->hash_table;
  if (!task) task=GetDebuggedProcess;
  if (!TaskValidate(task))
    return;
  PUSHFD
  bl=BreakLock;
  if (task==Fs) {
    rbp=GetRBP;
    rsp=rbp+3;
    rbp=*rbp;
  } else {
    rsp=task->rsp;
    rbp=task->rbp;
  }
  if (task->rip==_RET)
    addr=*rsp;
  else
    addr=task->rip;
  MemCpy(my_rsp,rsp,STK_REP_LEN*sizeof(U8 *));
  if(bl)
    BreakUnlock;
  POPFD
  Fs->hash_table=task->hash_table;
  for (i=0;i<STK_REP_LEN;i++) {
    "%08X [RSP+%04X]: %016X ",rsp+i,
	  i*sizeof(U8 *),my_rsp[i];
    while (TRUE) {
      if (!(task->stk<=rbp<
	    task->stk(U8 *)+MSize(task->stk)))
	break;
      j=rbp-rsp;
      if (j>=i)
	break;
      addr=my_rsp[j+1];
      if (rbp>=my_rsp[j])
	break;
      rbp=my_rsp[j];
    }
    if (my_rsp[i]==addr)
      "$$RED$$";
    "%P$$FG$$\n",my_rsp[i];
  }
  '\n';
  Fs->hash_table=old_hash;
}


U0 Dr(CTask *task=NULL)
{//Dump regs
  I64 i;
  if (!task) task=GetDebuggedProcess;
  for (i=0;i<16;i++)
    "%3Z:%016X\n",i,"ST_U64_REGS",*TaskRegAddr(task,i);
  "RIP:%016X\n",task->rip;
}

U0 D(U8 *addr,I64 cnt=0x80,Bool show_offset=TRUE)
{//Dump mem, showing offsets.
//See $LK,"DocD",A="MN:DocD"$() for a live dump.
  I64 i,j,ch;
  U8 *ptr=addr;
  while (cnt) {
    if (show_offset)
      "%08X",ptr-addr;
    else
      "%010X",ptr;
    if (cnt>16)
      j=16;
    else
      j=cnt;
    for (i=0;i<j;i++)
      "%02X ",ptr[i];
    for (;i<16;i++)
      "";
    for (i=0;i<j;i++) {
      ch=ptr[i];
      if (ch<CH_SHIFT_SPACE || ch==CH_BACKSPACE)
	ch='.';
      '' ch;
      if (ch=='$$')
	'' ch;
    }
    '\n';
    cnt-=j;
    ptr+=j;
  }
}

U0 Dm(U8 *addr,I64 cnt=0x80)
{//Show mem addr, not offsets.
  D(addr,cnt,FALSE);
}

U0 Da(U8 **addr,I64 cnt=0x10)
{//Dump mem, showing symbolic addresses.
  while (cnt-->0) {
    "%08X:%08X,%P\n",addr,*addr,*addr;
    addr++;
  }
}
