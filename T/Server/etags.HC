U8 *RegisterETag(CServer *srv,U8 *file) {
  CDirEntry dent;
  CHashGeneric *gen;
  U8 *tmp,*h;
  file=ChrootFile(file);
  if(FileFind(file,&dent)) {
    gen=CAlloc(sizeof(CHashGeneric)+StrLen(file)+1,srv->task);
    gen->type=HTT_FRAME_PTR;
    tmp=MStrPrint("%s@%D@%T",file,dent.datetime,dent.datetime);
    h=FNV64Str(tmp);
    gen->str=StrNew(h,srv->task);
    StrCpy(gen+1,file);
    gen->user_data0=dent.datetime;
    gen->user_data1=gen+1;
    HashAdd(gen,srv->task->hash_table);
    Free(h);
    Free(tmp);
    Free(dent.full_name);
    tmp=MStrPrint("%s",gen->str);
  } else
    tmp=NULL;
  Free(file);
  return tmp;
}
Bool ETagChanged(CServer *srv,U8 *etag) {
  CHashGeneric *gen=HashFind(etag,srv->task->hash_table,HTT_FRAME_PTR);
  CDirEntry dent;
  Bool ret=TRUE;
  if(gen) {
    if(!FileFind(gen->user_data1,&dent)) {
      ret=TRUE;
      goto fin;
    }
    Free(dent.full_name);
    ret=dent.datetime>gen->user_data0;
  }
fin:
  if(gen&&ret)
    HashRemDel(gen,srv->task->hash_table);
  return ret;
}