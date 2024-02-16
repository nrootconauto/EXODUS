CHeapCtrl *HeapCtrlInit(CHeapCtrl *hc=NULL,CTask *task=NULL,CBlkPool*bp)
{//See $LK,"HeapLog",A="MN:HeapLog"$() for an example.
//Duplicated for $LK,"Adam Task",A="FF:::/Kernel/KStart64.HC,CHeapCtrl.bp"$.
  if (!hc)
    hc=ACAlloc(sizeof(CHeapCtrl));
  MemSet(hc,0,sizeof(CHeapCtrl));
  hc->hc_signature=HEAP_CTRL_SIGNATURE_VAL;
  hc->mem_task=task;
  hc->bp=bp;
  QueInit(&hc->next_mem_blk);
  hc->last_mergable=NULL;
  hc->next_um=hc->last_um=(&hc->next_um)(U8 *)-offset(CMemUsed.next);
  return hc;
}



U0 HeapCtrlDel(CHeapCtrl *hc)
{//Free all blks alloced to a HeapCtrl.
  CMemBlk *m,*m1;
  Bool old;
  if (hc&&hc!=&ahc) {
    PUSHFD
    old=!Bts(&(Fs->task_flags),TASKf_BREAK_LOCKED);
    while (LBts(&hc->locked_flags,HClf_LOCKED))
      PAUSE
    m=hc->next_mem_blk;
    while (m!=&hc->next_mem_blk) {
      m1=m->next;
      MemPagTaskFree(m,hc);
      m=m1;
    }
    LBtr(&hc->locked_flags,HClf_LOCKED);
    if(old)
		BreakUnlock;
    POPFD
    if(hc!=&ahc)
      Free(hc);
  }
}
