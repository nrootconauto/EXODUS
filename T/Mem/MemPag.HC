U0 SysBadFree(I64 *ptr)
{
   "AT:%p\n",ptr;
   throw('BadFree');
}

U0 SysBadMAlloc(I64 *ptr)
{
  throw('BadMallo');
}
U8 *MemPagAlloc(I64 pags,CBlkPool *bp=NULL)
{/*Alloc pags from BlkPool. Don't link to task.
(Linking to a task means they will be freed when the task dies.)
It might give you more than you asked for.

Return: NULL if out of memory.
*/
  CMemBlk *res=NULL,*m;
  I64 i;
  Bool old;
  PUSHFD
  old=!Bts(&(Fs->task_flags),TASKf_BREAK_LOCKED); 
  res=NewVirtualChunk(pags<<MEM_PAG_BITS,!bp);
  if(!res) return NULL;
  ins:
  QueInit(res);
  QueInit(&res->next2);
  res->pags=pags;
  res->mb_signature=MBS_UNUSED_SIGNATURE_VAL;

at_done:
at_done2:
  if(old)
	BreakUnlock;
  POPFD
  return res;
}

U0 MemPagFree(CMemBlk *m,CBlkPool *bp=NULL)
{//Return non-task pags to BlkPool.
  I64 i,pags;
  Bool old;
  if (m) {
    PUSHFD
    old=!Bts(&(Fs->task_flags),TASKf_BREAK_LOCKED); 
    pags=m->pags;
    m->mb_signature=MBS_UNUSED_SIGNATURE_VAL;
    FreeVirtualChunk(m,pags<<MEM_PAG_BITS);
    if(old)
	  BreakUnlock;
    POPFD
  }
}

CMemBlk *MemPagTaskAlloc(I64 pags,CHeapCtrl *hc)
{/*hc must be locked.  Don't preempt this routine.
Currently, this is only called from $LK,"MAlloc",A="MN:MAlloc"$().
Return: NULL if out of memory.
*/
  CMemBlk *res;
  I64 threshold,cnt,size;
  CMemUnused *uum,**_uum,**_ptr;
  if (res=MemPagAlloc(pags,hc->bp)) {
    QueIns(res,hc->last_mem_blk);
    res->mb_signature=MBS_USED_SIGNATURE_VAL;
    hc->alloced_u8s+=res->pags<<MEM_PAG_BITS;

    //Tidy-up free lst (Move into heap hash)
    //because if free lst gets long, delay causes crash.
    threshold=MEM_HEAP_HASH_SIZE>>4;
#assert MEM_HEAP_HASH_SIZE>>4>=sizeof(U8 *)
    do {
      cnt=0;
      _uum=&hc->malloc_free_lst;
      while (uum=*_uum) {
#assert !offset(CMemUnused.next)
	size=uum->size;
	if (size<threshold) {
	  *_uum=uum->next;
	  _ptr=(&hc->heap_hash)(U8 *)+size;
	  uum->next=*_ptr;
	  *_ptr=uum;
	} else {
	  cnt++;
	  _uum=uum;
	}
      }
      threshold<<=1;
    } while (cnt>8 && threshold<=MEM_HEAP_HASH_SIZE);
  }
  return res;
}

U0 MemPagTaskFree(CMemBlk *m,CHeapCtrl *hc)
{//hc must be locked
  Bool old;
  if (m) {
    PUSHFD
    old=!Bts(&(Fs->task_flags),TASKf_BREAK_LOCKED); 
    if (m->mb_signature!=MBS_USED_SIGNATURE_VAL)
      SysBadFree(m);
    else {
      QueRem(m);
      hc->alloced_u8s-=m->pags<<MEM_PAG_BITS;
      MemPagFree(m,NULL);
    }
    if(old)
	  BreakUnlock;
    POPFD
  }
}
