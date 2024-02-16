CHeapCtrl *cache_heap=Fs->data_heap;
CQue *server_cache=CAlloc(sizeof CQue);
QueInit(server_cache);
I64 server_cache_lock=0,server_cache_lock_cnt=0;
CTask *server_cache_task=NULL;
#define HTT_CACHE 1
#define MAX_CACHE_SIZE 256
class CServerCache:CQue {
  U8 fn[STR_LEN];
  CDate time;
  I64 len;
  U8 body[0];
};
U0 ServerCacheLock() {
  while(LBts(&server_cache_lock,0)) {
    if(server_cache_task==Fs)
      break;
    ServerYield;
  }
  server_cache_task=Fs;
  server_cache_lock_cnt++;
}
U0 ServerCacheUnlock() {
  if(!--server_cache_lock_cnt) {
    server_cache_task=NULL;
    LBtr(&server_cache_lock,0);
  }
}
U0 ReleaseCache() {
  if(Bt(&server_cache_lock,0)) {
    if(server_cache_task==Fs) {
      server_cache_lock_cnt=0;
      server_cache_task=NULL;
      LBtr(&server_cache_lock,0);
    }
  }
}
U0 ServerCacheRem(U8 *fn) {
  CServerCache *cur;
  ServerCacheLock;
  for(cur=server_cache->next;cur!=server_cache;cur=cur->next) {
     if(!StrCmp(fn,cur->fn)) {
       QueRem(cur);
       Free(cur);
       ServerCacheUnlock;
       return ;
     }
  }
  ServerCacheUnlock;
}
U0 ServerCacheAdd(U8 *fn,U8 *text,I64 len) {
  CServerCache *new=MAlloc(sizeof(CServerCache)+len+1,cache_heap),*rem;
  StrCpy(new->fn,fn);
  MemCpy(&new->body,text,len);
  new->body[len]=0;
  new->time=Now;
  new->len=len;
  ServerCacheLock;
  ServerCacheRem(fn);
  if(QueCnt(server_cache)>MAX_CACHE_SIZE) {
    rem=QueRem(server_cache->next);
    Free(rem);
  }
  QueIns(new,server_cache->last);
  ServerCacheUnlock;
}
U8 *ServerCacheGet(U8 *fn) {
  CDirEntry ent;
  CServerCache *cur;
  U8 *ret=NULL,*fn2=NULL;
  ServerCacheLock;
  for(cur=server_cache->next;cur!=server_cache;cur=cur->next) {
    if(!StrCmp(fn,cur->fn)) {
      fn2=ChrootFile(fn);
      if(FileFind(fn2,&ent)) {
        if(ent.datetime>cur->time)
	  goto exit;
        ret=MAlloc(cur->len+1);
        ret[cur->len]=0;
        MemCpy(ret,cur->body,cur->len);
      }
      break;
    }
  }
exit:
  Free(fn2);
  ServerCacheUnlock;
  return ret;
}