static I64 tq_lock=FALSE; 
U0 TaskQueIns(CTask *task,CTask *pred=NULL)
{//Insert a task in the scheduler running task queue.
//You have no business with this, probably.
  CTask *last;
  if (!pred) pred=Fs;
  while(LBts(&tq_lock,0)) {
    PAUSE;
  }
  last=pred->last_task;
  last->next_task=pred->last_task=task;
  task->last_task=last;
  task->next_task=pred;
  LBtr(&tq_lock,0);
}

U0 TaskQueRem(CTask *task)
{//Remove a task from the scheduler running task queue.
//Use $LK,"Suspend",A="MN:Suspend"$().
  CTask *next,*last;
  while(LBts(&tq_lock,0)) {
    PAUSE;
  }
  next=task->next_task;
  last=task->last_task;
  last->next_task=next;
  next->last_task=last;
  LBtr(&tq_lock,0);
}

U0 TaskQueInsChild(CTask *task)
{
  CTask *last,*pred;
  while(LBts(&tq_lock,0)) {
    PAUSE;
  }
  pred=task->parent_task->last_child_task;
  last=pred->last_sibling_task;
  last->next_sibling_task=pred->last_sibling_task=task;
  task->last_sibling_task=last;
  task->next_sibling_task=pred;
  LBtr(&tq_lock,0);
}

U0 TaskDel(CTask *task)
{//We delay freeing in case lingering ptr to reincarnated.
  HeapCtrlDel(task->code_heap);
  if (task->data_heap!=task->code_heap)
    HeapCtrlDel(task->data_heap);
  Free(task);
}

I64 TaskEnd()
{//Called with irq's off.
  CTask *task=Fs,*tmpt,*tmpt1;
  U8 *end_cb;
  if (task==sys_task_being_scrn_updated) {
    LBts(&task->task_flags,TASKf_KILL_TASK);
    return task->next_task;
  }
/*if (task->task_end_cb) {
task->wake_jiffy=0;
LBtr(&task->task_flags,TASKf_KILL_TASK);
TaskRstAwaitingMsg(task);
Suspend(task,FALSE);
task->rip=;
task->task_end_cb=NULL;
return task;
} */
  if (task->task_end_cb) {
    end_cb=task->task_end_cb;
    task->task_end_cb=NULL;
    Suspend(task,FALSE);
    Call(end_cb);
  }
  if (task->parent_task && task->parent_task->popup_task==task) {
    task->parent_task->popup_task=NULL;
    Kill(task->parent_task);
    return task->parent_task;
  }

  DrvsRelease;
  BlkDevsRelease;

  tmpt1=(&task->next_child_task)(U8 *)-offset(CTask.next_sibling_task);
  tmpt=tmpt1->next_sibling_task;
  if (tmpt!=tmpt1) {
    do {
      LBts(&tmpt->task_flags,TASKf_KILL_TASK);
      tmpt=tmpt->next_sibling_task;
    } while (tmpt!=tmpt1);
    return task->next_task;
  }
  if (LBtr(&task->display_flags,DISPLAYf_SHOW))
    LBts(&sys_semas[SEMA_UPDATE_WIN_Z_BUF],0);

  while (LBts(&task->task_flags,TASKf_TASK_LOCK)){
    PAUSE;
  }
  while (LBts(&task->srv_ctrl.flags,JOBCf_LOCKED)) {
    PAUSE;
  }

  JobQueDel(&task->srv_ctrl.next_waiting);
  JobQueDel(&task->srv_ctrl.next_done);

  if (sys_focus_task==task)
    sys_focus_task=NULL;
//QueRem
  task->task_signature(I64)=0;

  tmpt =task->next_input_filter_task;
  tmpt1=task->last_input_filter_task;
  tmpt1->next_input_filter_task=tmpt;
  tmpt ->last_input_filter_task=tmpt1;

  tmpt =task->next_sibling_task;
  tmpt1=task->last_sibling_task;
  tmpt1->next_sibling_task=tmpt;
  tmpt ->last_sibling_task=tmpt1;

  tmpt =task->next_task; //save to return
  TaskQueRem(task);

  LBtr(&task->srv_ctrl.flags,JOBCf_LOCKED);
  LBtr(&task->task_flags,TASKf_TASK_LOCK);

  task->wake_jiffy=cnts.jiffies+DYING_JIFFIES;
  while (LBts(&Gs->cpu_flags,CPUf_DYING_TASK_QUE))
    PAUSE
  QueIns(task,Gs->last_dying);
  LBtr(&Gs->cpu_flags,CPUf_DYING_TASK_QUE);
  return tmpt;
}

U0 Exit() {
  LBts(&Fs->task_flags,TASKf_KILL_TASK);
  Yield;
}

U0 SrvTaskCont()
{//Act as server task in a loop handling commands.
  I64 old_flags=0;
  //FlushMsgs;
  while (TRUE) {
    if (JobsHndlr(old_flags) && Fs->title_src==TTS_TASK_NAME)
      MemCpy(Fs->task_title,Fs->task_name,TASK_NAME_LEN);
    FlushMsgs;
    LBts(&(Fs->task_flags),TASKf_IDLE);
    LBts(&(Fs->task_flags),TASKf_AWAITING_MSG);
    Yield;
  }
}
static I64 StrLenCapped(U8 *str,I64 cap) {
  I64 l=0;
  while(str[l]&&l<cap)
    l++;
  return l;
}
I64 ExeCmdLine(CCmpCtrl *cc)
{//Terminal JIT-compile-and-execute loop for CCmpCtrl.
  I64 res=0,type,old_title_src=Fs->title_src;
  U8 *ptr,*ptr2,*ptr3,*old_task_title=StrNew(Fs->task_title);
  U8 *machine_code;
  F64 t0;
  CDocEntry *doc_e;
  CDoc *doc;
  if (Fs->title_src!=TTS_LOCKED_CONST)
    Fs->title_src=TTS_CUR_LEX;
  while (cc->token &&
	(cc->token!='}' || !(cc->flags & CCF_EXE_BLK)) ) {
    if (Fs->title_src==TTS_CUR_LEX) {
      ptr2=Fs->task_title;
      ptr3=ptr2+STR_LEN-1;
      if (cc->lex_include_stk->flags & LFSF_DOC) {
	doc_e=cc->lex_include_stk->cur_entry;
	doc=cc->lex_include_stk->doc;
	while (doc_e!=doc && ptr2<ptr3) {
	  switch (doc_e->type_u8) {
	    case DOCT_TEXT:
	      ptr=doc_e->tag;
	      while (*ptr && ptr2<ptr3)
		*ptr2++=*ptr++;
	      break;
	    case DOCT_TAB:
	    case DOCT_NEW_LINE:
	      *ptr2++='.';
	      break;
	  }
	  doc_e=doc_e->next;
	}
	if (ptr2<ptr3) *ptr2=0;
      } else
	if ((ptr=cc->lex_include_stk->line_start) && *ptr)
	  MemCpy(ptr2,ptr,StrLenCapped(ptr,STR_LEN-1)+1);
    }
    cc->flags&=~CCF_HAS_MISC_DATA;
    machine_code=LexStmt2Bin(cc,&type,CMPF_PRS_SEMICOLON);
    if (machine_code!=INVALID_PTR) {
      if (!(cc->flags&CCF_JUST_LOAD)) {
    t0=tS;
	res=Call(machine_code);
	Fs->answer=res;
	Fs->answer_time=tS-t0;
	Fs->answer_type=type;
	Fs->new_answer=TRUE;
	cc->pmt_line=0;
      }
      if (!(cc->flags&CCF_HAS_MISC_DATA))
	Free(machine_code);
    }
  }
  if (Fs->title_src!=TTS_LOCKED_CONST) {
    Fs->title_src=old_title_src;
    StrCpy(Fs->task_title,old_task_title);
  }
  Free(old_task_title);
  if (cc->flags&CCF_JUST_LOAD) {
    if (cc->error_cnt)
      return FALSE;
    else
      return TRUE;
  } else
    return res;
}
Bool TaskValidate(CTask *task)
{//return TRUE if task looks valid.
  I64 c=0,found=FALSE,unlock=FALSE;
  CTask *t,*t2;
  if (!task || !ChkPtr(task))
    return FALSE;
  //if(!cpu_structs) goto defacto;
  for (c=0;c!=mp_cnt;c++) {
    t=cpu_structs[c].seth_task;
    if (!t) goto defacto;
    if (t!=task) { 
      for (t2=t->next_task;t2!=t;t2=t2->next_task) {
        if (task==t2) {
          found=TRUE;
          break;
        }
      }
    } else 
      found=TRUE;
  }
  if(!found) return FALSE;
defacto:
  if (task->task_signature!=TASK_SIGNATURE_VAL)
    return FALSE;
  else
    return ToBool(task);
}

I64 TaskInit(CTask *task,I64 stk_size)
{//Returns Fs of task
  CDrv *dv;
  if(!task->data_heap) task->data_heap=&ahd;
  if(!task->code_heap) task->code_heap=&ahc;
  task->task_signature=TASK_SIGNATURE_VAL;
  task->addr=task->next_task=task->last_task=
	task->next_input_filter_task=task->last_input_filter_task=
	task;
    
  task->last_sibling_task=task->next_sibling_task=task;

  task->task_num=sys_num_spawned_tasks++;

  task->rflags=RFLAGG_NORMAL;
  task->win_inhibit=WIG_TASK_DFT;

  task->next_child_task=task->last_child_task=
	(&task->next_child_task)(U8 *)-offset(CTask.next_sibling_task);


  JobCtrlInit(&task->srv_ctrl);
  QueInit(&task->next_cc);
  QueInit(&task->next_except);
  QueInit(&task->next_ctrl);
  QueInit(&task->next_ode);

  task->fpu_mmx=MAllocAligned(sizeof(CFPU),0x10,task);
  MemCpy(task->fpu_mmx,
	SYS_FIXED_AREA+offset(CSysFixedArea.init_fpu_mmx),sizeof(CFPU));

  
  task->hash_table=HashTableNew(TASK_HASH_TABLE_SIZE,task);
  task->text_attr	=WHITE<<4+BLUE;
  task->border_src	=BDS_CONST;
  task->border_attr	=DrvTextAttrGet(':');
  task->title_src	=TTS_CONST;
  task->win_left	=1;
  task->win_right	=text.cols-2;
  task->win_top		=13;
  task->win_bottom	=text.rows-2;

  if (Fs->cur_dv) {
    task->cur_dv=Fs->cur_dv;
    task->cur_dir=StrNew(Fs->cur_dir,task);
  /*Seth tasks are the first,
   *so be sure to not assume Fs->cur_dv is set*/
  } else if (dv=Let2Drv('T',FALSE)) { 
    task->cur_dv=dv;
    task->cur_dir=StrNew("/",task);
  } else if (blkdev.home_dir) {//Beware Adam $LK,"TaskInit",A="FF:::/Kernel/KStart64.HC,TaskInit"$. I guess ok until $LK,"DskChg",A="FF:::/Kernel/KMain.HC,DskChg"$().
    task->cur_dv=blkdev.let_to_drv[*blkdev.home_dir-'A'];
    task->cur_dir=StrNew(blkdev.home_dir+2,task);
  } else
    task->cur_dir=StrNew("/Home",task);
  return task;
}
CTask *Spawn(U0 (*fp_start_addr)(U8 *data),U8 *data=NULL,U8 *task_name=NULL,
	I64 target_cpu=-1,	//-1 for current CPU. See $LK,"multi-core",A="FI:::/Demo/MultiCore/LoadTest.HC"$.
	CTask *parent=NULL,	//NULL means adam
	I64 stk_size=0,		//0=default
	I64 flags=1<<JOBf_ADD_TO_QUE)
{//Create task on core running at address.
//Alloc $LK,"CTask",A="MN:CTask"$ structure from code heap so addr will be short.
  //Could be alloced off of data heap.
  if (target_cpu>=0)
    return SpawnQue(fp_start_addr,data,task_name,target_cpu,
                    parent,stk_size,flags);
  CTask *task;
  if (target_cpu==-2) {
    //Insidious hack to allow the loader to spawn tasks safely(CTRL+ALT+T)
    target_cpu=0;
  } else if (target_cpu==-1) {
    target_cpu=Gs->num;
  }
  task=CAlloc32(sizeof(CTask),adam_task);
  if(!parent) {
    //if(cpu_structs[target_cpu])
    parent=cpu_structs[target_cpu].seth_task;
    if(!parent)
      parent=adam_task;
  }
  U8 **stack;
  if (!task_name) task_name="Unnamed Task";
  task->parent_task=parent;
  task->gs=parent->gs;
  task->code_heap=HeapCtrlInit(,task,0);
  task->data_heap=HeapCtrlInit(,task,1);
  TaskInit(task,0);
  task->hash_table->next=parent->hash_table;
  MemCpy(task->task_name,task_name,TASK_NAME_LEN);
  StrCpy(task->task_title,task->task_name);
  task->title_src=TTS_TASK_NAME;
//Insert the task into the QUE to avoid having despawn after it is spawned.
  task->stk=MAlloc(MEM_DFT_STK,task);
  stack=task->stk+MEM_DFT_STK;
  stack[-1]=data;
  stack[-2]=&Exit;
  task->rsp=stack-2;
  task->rip=fp_start_addr;
  if (Bt(&flags,JOBf_ADD_TO_QUE)) {
    TaskQueInsChild(task);
    if (cpu_structs[target_cpu].seth_task)
      TaskQueIns(task,cpu_structs[target_cpu].seth_task);
    else
      TaskQueIns(task,adam_task);
    //TaskQueIns(task);
    __AwakeCore(target_cpu);
  }
  return task;
}
U0 UserTaskCont()
{//Terminal key-input-execute loop.
  CCmpCtrl *cc;
  CDoc *doc;
  Bool cont=TRUE;
  do {
    cc=CmpCtrlNew(,CCF_CMD_LINE|CCF_PMT|CCF_QUESTION_HELP);
    QueIns(cc,Fs->last_cc);
    try {
      Lex(cc);
      ExeCmdLine(cc);
      cont=Bt(&cc->flags,CCf_PMT);
      QueRem(cc);
      CmpCtrlDel(cc);
    } catch {
      if ((doc=Fs->put_doc) && doc->doc_signature==DOC_SIGNATURE_VAL)
	DocUnlock(doc);
      PutExcept;
      Fs->catch_except=TRUE;
    }
  } while (cont);
}
U0 UserStartUp()
{//Run each time a user a spawned
  DocTermNew;
  if (!IsRaw) Type("::/Doc/Start.DD");
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  WinToTop;
  WinZBufUpdate;
}
U0 UserCmdLine(I64 dummy=0)
{//A user task ends-up calling this.
  no_warn dummy;
  Fs->win_inhibit=WIG_USER_TASK_DFT;
  UserStartUp;
  UserTaskCont;
}

CTask *User(U8 *fmt=NULL,...)
{//Create user term task.
  U8 *st;
  CTask *task=Spawn(&UserCmdLine);
  TaskWait(task);
  if (fmt) {
    st=StrPrintJoin(NULL,fmt,argc,argv);
    XTalk(task,st);
    Free(st);
  }
  
  return task;
}

U0 TaskDerivedValsUpdate(CTask *task=NULL,Bool update_z_buf=TRUE)
{//Those things calculated from other variables.
  if (!task) task=Fs;
  Bool old;
  PUSHFD
  old=!Bts(&(Fs->task_flags),TASKf_BREAK_LOCKED);  
  while (LBts(&task->task_flags,TASKf_TASK_LOCK)) {
    PAUSE;
  }
  WinDerivedValsUpdate(task);
  if (fp_update_ctrls) {
    (*fp_update_ctrls)(task);
    }
  if (update_z_buf && Bt(&task->display_flags,DISPLAYf_SHOW))
    LBts(&sys_semas[SEMA_UPDATE_WIN_Z_BUF],0);
  LBtr(&task->task_flags,TASKf_TASK_LOCK);
  if(old)
    BreakUnlock;
  POPFD
}

U0 BirthWait(CTask **_task) {
  while (!TaskValidate(*_task))
    Sleep(10);
}

U0 DeathWait(CTask **_task,Bool send_exit=FALSE)
{//Wait for task death.
  if (send_exit && TaskValidate(*_task)) {
    TaskWait(*_task,TRUE);
    XTalk(*_task,"Exit;\n");
  }
  while (TaskValidate(*_task)) {
    Sleep(10);
  }
  Yield;
}

U0 TaskKillDying()
{//Delay freeing to prevent asking for trouble with quick reincarnations.
//What if the user is doing this: DoTreeCheckers.
  CTaskDying *task,*task1;
  if (Gs->kill_jiffy<cnts.jiffies) {//Avoid doing as many lock operations.
    while (LBts(&Gs->cpu_flags,CPUf_DYING_TASK_QUE))
      PAUSE
    task=Gs->next_dying;
    while (task!=&Gs->next_dying && task->wake_jiffy<cnts.jiffies) {
      task1=task->next;
      QueRem(task);
      TaskDel(task);
      task=task1;
    }
    LBtr(&Gs->cpu_flags,CPUf_DYING_TASK_QUE);
    Gs->kill_jiffy=cnts.jiffies+DYING_JIFFIES;
  }
}