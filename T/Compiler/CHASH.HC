U0 HashDel(CHashSrcSym *tmph)
{   //Free a std TempleOS system hash entry.
    if (!tmph) return;
    if (!(tmph->type&HTT_DICT_WORD))
        Free(tmph->str);
    if (tmph->type & HTG_SRC_SYM) {
        Free(tmph->src_link);
        Free(tmph->idx);
        Free(tmph->import_name);
        LinkedLstDel(tmph->ie_lst);
        if (tmph->type & (HTT_FUN | HTT_EXPORT_SYS_SYM))
            Free(tmph->dbg_info);
        if (tmph->type & (HTT_FUN | HTT_CLASS))
//Assumes code not on heap, so doesn't Free.
            //$LK,"ClassMemberLstDel",A="MN:ClassMemberLstDel"$() is an import to the Kernel module
            ;//ClassMemberLstDel(tmph);
        else if (tmph->type&HTT_DEFINE_STR)
            Free(tmph(CHashDefineStr *)->data);
        else if (tmph->type & HTT_GLBL_VAR) {
            if (!(tmph(CHashGlblVar *)->flags&GVF_ALIAS))
                Free(tmph(CHashGlblVar *)->data_addr);
            LinkedLstDel(tmph(CHashGlblVar *)->dim.next);
            if (tmph(CHashGlblVar *)->fun_ptr)
                HashDel(tmph(CHashGlblVar *)->fun_ptr
                        -tmph(CHashGlblVar *)->fun_ptr->ptr_stars_cnt);
        }
    } else if (tmph->type & HTT_FILE)
        Free(tmph(CHashGeneric *)->user_data0);
    Free(tmph);
}
_extern _HASH_ADD_AFTER U0 HashAddAfter(CHash *tmph,
        CHash *pred,CHashTable *table); //Add hash entry after entry.
_extern _HASH_STR I64 HashStr(U8 *st); //Hash a string.
_extern _HASH_FIND CHash *HashFind(U8 *needle_str,CHashTable *haystack_table,
                                   I64 mask,I64 instance=1);//Find string in hash table.
_extern _HASH_SINGLE_TABLE_FIND CHash *HashSingleTableFind(U8 *needle_str,
        CHashTable *haystack_table,
        I64 mask,I64 instance=1);//Find string in single hash table.
_extern _HASH_BUCKET_FIND CHash **HashBucketFind(U8 *needle_str,
        CHashTable *haystack_table); //Find hash bucket.
_extern _HASH_ADD U0 HashAdd(CHash *tmph,
                             CHashTable *table); //Add entry to hash table.
_extern _HASH_REM_DEL Bool HashRemDel(CHash *tmph,CHashTable *table,
                                      I64 instance=1);//Remove hash entry and del. Instance must match.

U0 HashSrcFileSet(CCmpCtrl *cc,CHashSrcSym *h,I64 line_num_offset=0)
{   //Set $LK,"CHashSrcSym",A="MN:CHashSrcSym"$ link and help_index by cur cc pos.
    CLexFile *tmpf=cc->lex_include_stk;
    I64 line_num=tmpf->line_num+line_num_offset;
    if (line_num<1) line_num=1;
    Free(h->src_link);
    h->src_link=MStrPrint("FL:%s,%d",tmpf->full_name,line_num);
    if (Bt(&cc->opts,OPTf_KEEP_PRIVATE))
        h->type|=HTF_PRIVATE;
    Free(h->idx);
    if (cc->cur_help_idx && *cc->cur_help_idx)
        h->idx=StrNew(cc->cur_help_idx);
    else
        h->idx=NULL;
}
I64 HashTypeNum(CHash *tmph)
{   //Return bit num of hash type, limited to just types.
    if (tmph)
        return Bsf(tmph->type&HTG_TYPE_MASK);
    else
        return -1;
}

I64 HashVal(CHash *tmph)
{   //Returns most likely desired value.
    switch (HashTypeNum(tmph)) {
    case HTt_EXPORT_SYS_SYM:
        return tmph(CHashExport *)->val;
    case HTt_IMPORT_SYS_SYM:
        return tmph(CHashImport *)->module_base;
    case HTt_DEFINE_STR:
    case HTt_CLASS:
    case HTt_INTERNAL_TYPE:
    case HTt_WORD:
    case HTt_DICT_WORD:
    case HTt_OPCODE:
    case HTt_HELP_FILE:
        return tmph;
    case HTt_GLBL_VAR:
        if (tmph(CHashGlblVar *)->flags&GVF_EXTERN)
            return &tmph(CHashGlblVar *)->data_addr;
        else
            return tmph(CHashGlblVar *)->data_addr;
    case HTt_FUN:
        if (Bt(&tmph(CHashFun *)->flags,Cf_EXTERN))
            return tmph;
        else
            return tmph(CHashFun *)->exe_addr;
    case HTt_REG:
        return tmph(CHashReg *)->reg_num|tmph(CHashReg *)->reg_type<<8;
    case HTt_KEYWORD:
    case HTt_ASM_KEYWORD:
    case HTt_MODULE:
    case HTt_FILE:
    case HTt_FRAME_PTR:
        return tmph(CHashGeneric *)->user_data0;

    case -1:		//nobound switch
    case HTt_TYPES_NUM: //nobound switch
    default:
        return 0;
    }
}
CHashTable *HashTableNew(I64 size,CTask *t=NULL)
{   //New hash table, power-of-two in size.
    CHashTable *table;
    table=CAlloc(sizeof(CHashTable),t);
    table->body=CAlloc(size<<3,t);
    table->mask=size-1;
    return table;
}

U0 HashTableDel(CHashTable *table)
{   //Free std system hash table, calling $LK,"HashDel",A="MN:HashDel"$() on entries.
    I64 i;
    CHashSrcSym *tmph,*tmph1;
    if (!table) return;
    for (i=0; i<=table->mask; i++) {
        tmph=table->body[i];
        while (tmph) {
            tmph1=tmph->next;
            HashDel(tmph);
            tmph=tmph1;
        }
    }
    Free(table->body);
    Free(table);
}

I64 HashTablePurge(CHashTable *table)
{   //Eliminate ExportSysSyms that have been usurped.
    I64 i,res=0;
    CHashSrcSym *tmph,*tmph1,*tmph2;
    Bool old;
    if (!table) return 0;
    old=!Bts(&(Fs->task_flags),TASKf_BREAK_LOCKED);
    for (i=0; i<=table->mask; i++) {
        tmph=table->body[i];
        while (tmph) {
            tmph1=tmph->next; //We delete only older ones
            if (tmph->type&(HTT_FUN|HTT_GLBL_VAR)) {
                tmph2=tmph->next; //Older always later in chain
                while (tmph2) {
                    if ((tmph2->type&HTT_EXPORT_SYS_SYM ||
                            tmph2->type&HTG_TYPE_MASK==HTT_INVALID) &&
                            !StrCmp(tmph2->str,tmph->str)) {
                        if (tmph2->type&HTG_TYPE_MASK==HTT_INVALID)
                            tmph2->type=HTT_KEYWORD;//Won't delete HTT_INVALID
                        HashRemDel(tmph2,table);
                        res++;
                        break;
                    }
                    tmph2=tmph2->next;
                }
            }
            tmph=tmph1;
        }
    }
    if(old)
		BreakUnlock;
    return res;
}

CHashGeneric *HashGenericAdd(U8 *name,I64 type,
                             I64 u0=0,I64 u1=0,I64 u2=0,CTask *task=NULL)
{   //Add any type to task hash_table, 3 user_data values.
    if (!task) task=Fs;
    CHashGeneric *res=CAlloc(sizeof(CHashGeneric),task);
    res->type=type;
    res->user_data0=u0;
    res->user_data1=u1;
    res->user_data2=u2;
    res->str=StrNew(name,task);
    HashAdd(res,task->hash_table);
    return res;
}

U0 HashSrcFileSet(CCmpCtrl *cc,CHashSrcSym *h,I64 line_num_offset=0)
{   //Set $LK,"CHashSrcSym",A="MN:CHashSrcSym"$ link and help_index by cur cc pos.
    CLexFile *tmpf=cc->lex_include_stk;
    I64 line_num=tmpf->line_num+line_num_offset;
    if (line_num<1) line_num=1;
    Free(h->src_link);
    h->src_link=MStrPrint("FL:%s,%d",tmpf->full_name,line_num);
    if (Bt(&cc->opts,OPTf_KEEP_PRIVATE))
        h->type|=HTF_PRIVATE;
    Free(h->idx);
    if (cc->cur_help_idx && *cc->cur_help_idx)
        h->idx=StrNew(cc->cur_help_idx);
    else
        h->idx=NULL;
}

CHashGeneric *HashPublic(U8 *st,I64 mask,Bool val=TRUE)
{   //Mark a hash entry as public and $LK,"HashSrcFileSet",A="MN:HashSrcFileSet"$().
    CHashGeneric *res;
    if (res=HashFind(st,Fs->hash_table,mask)) {
        if (val)
            res->type|=HTF_PUBLIC;
        else
            res->type&=~HTF_PUBLIC;
        if (res->type&HTG_SRC_SYM)
            HashSrcFileSet(Fs->last_cc,res);
        return res;
    } else
        return NULL;
}

I64 HashLstAdd(U8 *lst,I64 type,CHashTable *table)
{   //Add a list to a hash table.
    I64 i=0;
    CHashGeneric *tmph;
    if (lst) {
        while (*lst) {
            if (*lst=='@')
                lst++;
            else
                i++;
            tmph=CAlloc(sizeof(CHashGeneric));
            tmph->user_data0=i-1;
            tmph->str=StrNew(lst);
            tmph->type=type;
            HashAdd(tmph,table);
            while (*lst++);
        }
    }
    return i;
}

I64 HashDefineLstAdd(U8 *dname,I64 type,CHashTable *table)
{   //Add define list to a hash table. See $LK,"::/Adam/DolDoc/DocInit.HC",A="FF:::/Adam/DolDoc/DocInit.HC,HashDefineLstAdd"$.
    CHashDefineStr *tmph;
    if (tmph=HashFind(dname,Fs->hash_table,HTT_DEFINE_STR))
        return HashLstAdd(tmph->data,type,table);
    else
        return 0;
}

I64 FramePtr(U8 *name,CTask *task=NULL)
{   //Find entry in task->hash_table, Return user_data.
    CHashGeneric *tmph;
    if(!task) task=Fs;
    if (tmph=HashFind(name,task->hash_table,HTT_FRAME_PTR))
        return tmph->user_data0;
    else
        return 0;
}

CHashGeneric *FramePtrAdd(U8 *name,I64 val=0,CTask *task=NULL)
{   //Add named value to task->hash_table.
    return HashGenericAdd(name,HTT_FRAME_PTR,val,0,0,task);
}

I64 FramePtrSet(U8 *name,I64 val,CTask *t=NULL)
{   //Find hash entry in task->hash_table. Change user_data0.
    CHashGeneric *tmph;
    I64 ret;
    if(!t) t=Fs;
    if (tmph=HashFind(name,t->hash_table,HTT_FRAME_PTR)) {
        ret=val,SwapI64(&tmph->user_data0,&ret);
        return ret;
    } else
        return 0;
}

I64 FramePtrDel(U8 *name,CTask *t=NULL)
{   //Remove entry and delete.
    CHashGeneric *tmph;
    I64 res=0;
    if(!t) t=Fs;
    if (tmph=HashFind(name,t->hash_table,HTT_FRAME_PTR)) {
        res=tmph->user_data0;
        HashRemDel(tmph,t->hash_table);
    }
    return res;
}
/**
 * $AN,"Debug Info Format",A="DbgFormat"$
 * Has format 
 * IF($AN,"HTT_FUN",A="DbgFun"$)
 *     FUNC_NAME(U8[])
 *     FUNC_FILE(U8[])
 *     FUNC_HELP_IDX(U8[])
 *     U32 s,e;
 *     U32 line_offsets[]
 *     U32 stk_size
 *     U32 var_cnt
 *          $AN,"Variable Format",A="DbgVar"$
 *          VAR_NAME(U8[])
 *          VAR_TYPE(U8[])
 *          U32 reg
 *          U32 offset
 *          U32 star_cnt
 *          U32 total_dim //I64 array[3][4] would have total_dim of 12
 *
 * IF($AN,"HTT_GLBL_VAR",A="DbgGlbl"$)
 *     VAR_NAME(U8[])
 *     VAR_FILE(U8[])
 *     VAR_HELP_IDX(U8[])
 *     I64 ln
 * 
 * IF($AN,"HTT_HELP_FILE",A="DbgHelp"$)
 *     POINTS_TO_FILE(U8[])
 *     HELP_IDX(U8[])
 *
 * IF($AN,"HTT_EXPORT_SYS_SYM",A="DbgSym"$)
 *     NAME(U8[])
 *     FILE(U8[])
 *     LINE(I32)
 * ...
 */
/**
 * $BK,1$NOTE 1:$BK,0$
 *  In /PUBLIC.HC we have the public symbols we want
 *  If we find an extern version of the function we are documenting
 *    Use that things FUNC_HELP_IDX
 *  Sys
 */
I64 __DbgInfoWrite(CHashTable *h,U8 *to) {
  I64 i,ln,size=0,min,max;
  CHashSrcSym *tmph;
  CHashFun *pub_tmph;
  CHashClass *tmpc;
  CMemberLst *fun_mem;
  CDbgInfo *dbg_info;
  U32 start_ptr,cnt;
  U8 *src_link,buffer[1024],*bptr=&buffer;
  for (i=0;i<=h->mask;i++) {
    for(tmph=h->body[i];tmph;tmph=tmph->next)
      if(tmph->type&HTT_EXPORT_SYS_SYM&&tmph->src_link) {
        //See $LK,"HTT_EXPORT_SYS_SYM entry in debug info",A="FA:CHASH.HC,DbgSym"$
        if(to) (to+size)(I64*)[0]=HTT_EXPORT_SYS_SYM;
        size+=sizeof(I64);
//Name
        if(to) StrCpy(to+size,tmph->str);
        size+=StrLen(tmph->str)+1;
        bptr=buffer;
        StrScan(tmph->src_link,"FL:%s,%d",&bptr,&ln);
//Filename
        if(to) StrCpy(to+size,buffer);
        size+=StrLen(buffer)+1;
//Line number
        if(to) (to+size)(U32*)[0]=ln;
        size+=4;
      } else if (tmph->src_link && !(tmph->type & (HTF_IMPORT|HTF_PRIVATE)) && (dbg_info=tmph->dbg_info)) {
        if((tmph->type&HTT_FUN)&&!(tmph(CHashFun*)->flags&(1<<Cf_EXTERN))) {
          //See $LK,"HTT_FUN entry in debug info",A="FA:CHASH.HC,DbgFun"$
	  if(to) (to+size)(I64*)[0]=tmph->type&(HTT_FUN|HTF_PUBLIC);
	  size+=sizeof(I64);
	  bptr=buffer;
	  StrScan(tmph->src_link,"FL:%s,%d",&bptr,&ln);
	  if(to) StrCpy(to+size,tmph->str);
	  size+=StrLen(tmph->str)+1;
	  if(to) StrCpy(to+size,buffer);
	  size+=StrLen(buffer)+1;
//Heres the deal,at the end of the compile,I have a PUBLIC.HC where all the #help_indexes are
	  //because this is the last file,I will use the most recent version of the symbol's help idx
	  pub_tmph=HashFind(tmph->str,h,HTF_PUBLIC);
	  if(pub_tmph) {
	    if(pub_tmph->idx&&pub_tmph->type&HTF_PUBLIC) {
	      if(to) StrCpy(to+size,pub_tmph->idx);
	      size+=StrLen(pub_tmph->idx)+1;
	      goto wrote_help_idx;
	    }
	  }
	  if(tmph->idx) {
	    if(to) StrCpy(to+size,tmph->idx);
	    size+=StrLen(tmph->idx)+1;
	  } else {
	    if(to) StrCpy(to+size,"");
	    size+=StrLen("")+1;
	  }
wrote_help_idx:
//Keep track of the line offsets
	  min=dbg_info->min_line;
	  max=dbg_info->max_line;
	  if(to) (to+size)(U32*)[0]=min;
	  if(to) (to+size)(U32*)[1]=max;
	  size+=2*sizeof(U32);
	  max-=min;
	  min-=min;
	  start_ptr=dbg_info->body[0];
	  for(ln=0;ln<=max+1;ln++) {
	    if(to) (to+size)(U32*)[0]=dbg_info->body[ln]-start_ptr;
	    size+=4;
	  }
	  if(to) (to+size)(U32*)[0]=tmph(CHashFun*)->size;
	  size+=4;
	  fun_mem=tmph(CHashFun*)->member_lst_and_root;
	  for(cnt=0;fun_mem;fun_mem=fun_mem->next)
	    cnt++;
	  if(to) (to+size)(U32*)[0]=cnt;
	  size+=4;
//Here we iterate through the variables and and see if they are in registers or not
//Also keep track of array dims
 //See $LK,"Var format",A="FA:CHASH.HC,DbgVar"$
	  fun_mem=tmph(CHashFun*)->member_lst_and_root;
	  for(;fun_mem;fun_mem=fun_mem->next) {
	    if(to) StrCpy(to+size,fun_mem->str);
	    size+=StrLen(fun_mem->str)+1;
	    tmpc=fun_mem->member_class;
	    tmpc-=tmpc->ptr_stars_cnt;
	    if(tmpc->str) {
	      if(to) StrCpy(to+size,tmpc->str);
	      size+=StrLen(tmpc->str)+1;
	    } else {
	      if(to) to[size]=0;
	      size++;
	    }
	    if(to) (to+size)(U32*)[0]=fun_mem->reg;
	    size+=4;
	    if(to) (to+size)(U32*)[0]=fun_mem->offset;
	    size+=4;
	    if(to) (to+size)(U32*)[0]=fun_mem->member_class->ptr_stars_cnt;
	    size+=4;
	    if(to) (to+size)(U32*)[0]=fun_mem->dim.total_cnt;
	    size+=4;
	  }
        }
      } else if(tmph->type&HTT_HELP_FILE){
        //See $LK,"HTT_HELP_FILE entry in debug info",A="FA:CHASH.HC,DbgHelp"$
        if(to) (to+size)(I64*)[0]=HTT_HELP_FILE;
        size+=sizeof(I64);
//Name
        if(to) StrCpy(to+size,tmph->str);
        size+=StrLen(tmph->str)+1;
//Index
        if(to) StrCpy(to+size,tmph->idx);
        size+=StrLen(tmph->idx)+1;
      } else if(tmph->type&HTT_GLBL_VAR&&!(tmph(CHashGlblVar*)->flags&(GVF_ALIAS|GVF_EXTERN))) {
        //See $LK,"HTT_GLBL_VAR entry in debug info",A="FA:CHASH.HC,DbgGlbl"$
        if(to) (to+size)(I64*)[0]=HTT_GLBL_VAR;
        size+=sizeof(I64);
        bptr=buffer;
        StrScan(tmph->src_link,"FL:%s,%d",&bptr,&ln);
//Symbol Name
        if(to) StrCpy(to+size,tmph->str);
        size+=StrLen(tmph->str)+1;
//Filename
        if(to) StrCpy(to+size,buffer);
        size+=StrLen(buffer)+1;
//Heres the deal,at the end of the compile,I have a PUBLIC.HC where all the #help_indexes are
        //because this is the last file,I will use the most recent version of the symbol's help idx
        pub_tmph=HashFind(tmph->str,h,HTF_PUBLIC);
        if(pub_tmph) {
	  if(pub_tmph->idx&&pub_tmph->str&HTF_PUBLIC) {
	    if(to) StrCpy(to+size,pub_tmph->idx);
	    size+=StrLen(pub_tmph->idx)+1;
	    goto wrote_help_idx2;
	  }
        }
//Help index
        if(tmph->idx) {
	  if(to) StrCpy(to+size,tmph->idx);
	  size+=StrLen(tmph->idx)+1;
        } else {
	  if(to) StrCpy(to+size,"");
	  size+=StrLen("")+1;
        }
wrote_help_idx2:
//Line number
        if(to) to[size](I64)=ln;
        size+=8;
      }
  }
  return size;
}
U0 DbgInfoWrite(CHashTable *h,U8 *name) {
  I64 len=__DbgInfoWrite(h,NULL);
  U8 *buf=MAlloc(len);
  __DbgInfoWrite(h,buf);
  FileWrite(name,buf,len);
  Free(buf);
}
//Mirrors __DebugInfoWriteh
//See $LK,"Debug Info Format",A="FA:CHASH.HC,DbgFormat"$
U0 DbgInfoRead(U8 *name) {
  I64 len,min,max,ln,type;
  CHashSrcSym *tmph;
  CMemberLst *tmpm=NULL,*tmpm2=NULL;
  CDbgInfo *dbg_info;
  CHashClass *tmpc;
  U8 *body=FileRead(name,&len),*ptr=body,*fn,*idx;
  while (ptr<body+len) {
    type=ptr(I64*)[0];
    ptr+=8;
    if(type&HTT_EXPORT_SYS_SYM) {
      //Read the name
      tmph=HashFind(ptr,Fs->hash_table,HTT_EXPORT_SYS_SYM);
      if(!tmph) {
        tmph=CAlloc(sizeof(CHashExport));
        tmph->str=StrNew(ptr);
        tmph->type=HTT_UNIMP_FUN;
      }
      //Filename
      ptr+=StrLen(ptr)+1;
      fn=ptr;
      ptr+=StrLen(ptr)+1;
      Free(tmph->src_link);
      //Line number
      min=*ptr(I32*)++;
      tmph->src_link=MStrPrint("FL:%s,%d",fn,min);
    } else if(type&HTT_GLBL_VAR) {
      //Global name
      tmph=HashFind(ptr,Fs->hash_table,HTT_GLBL_VAR);
      if(!tmph) {
        tmph=CAlloc(sizeof(CHashFun));
        tmph->str=StrNew(ptr);
        tmph->type=HTT_UNIMP_FUN;
      }
      tmph->type|=HTF_RESOLVE;
      //filename
      ptr+=StrLen(ptr)+1;
      fn=ptr;
      ptr+=StrLen(ptr)+1;
      //Help index
      idx=ptr;
      ptr+=StrLen(ptr)+1;
      //Line number
      min=ptr(I64*)[0];
      ptr+=8;
      Free(tmph->idx);
      Free(tmph->src_link);
      tmph->src_link=MStrPrint("FL:%s,%d",fn,min);
      if(StrLen(idx))
        tmph->idx=StrNew(idx);
      else
        tmph->idx=NULL;
    } else if(type&HTT_FUN) {
      //Function na,e
      tmph=HashFind(ptr,Fs->hash_table,HTT_FUN);
      if(!tmph) {
        tmph=CAlloc(sizeof(CHashFun));
        tmph->str=StrNew(ptr);
        tmph->type=HTT_UNIMP_FUN;
      }
      ptr+=StrLen(ptr)+1;
      //Filename
      fn=ptr;
      ptr+=StrLen(ptr)+1;
      //Help index
      idx=ptr;
      ptr+=StrLen(ptr)+1;
      //Min/Max lines
      min=ptr(U32*)[0];
      max=ptr(U32*)[1];
      ptr+=2*sizeof(U32);
      //Read the line offsets and put them in body
      if(tmph&&(tmph->type&HTT_FUN||tmph->type&HTT_UNIMP_FUN)) {
        tmph->type|=type; //type may include HTF_PUBLIC
        Free(tmph->src_link);
        Free(tmph->idx);
        if(StrLen(idx))
	  tmph->idx=StrNew(idx);
        else
	  tmph->idx=NULL;
        tmph->src_link=MStrPrint("FL:%s,%d",fn,min);
        tmph->dbg_info=CAlloc(sizeof(CDbgInfo)+sizeof(U32)*(max-min+1));
        tmph->dbg_info->min_line=min;
        tmph->dbg_info->max_line=max;
        for(ln=min;ln<=max+1;ln++) {
	  tmph->dbg_info->body[ln-min]=tmph(CHashFun*)->exe_addr(U8*)+ptr(U32*)[ln-min];
        }
      }
      ptr+=sizeof(U32)*(max-min+1+1);
      if(tmph) tmph(CHashFun*)->size=ptr(I32*)[0];
      ptr+=sizeof(U32);
//Read the variables,see $LK,"Variable format",A="FA:CHASH.HC,DbgVar"$
      max=ptr(U32*)[0];
      ptr+=sizeof(U32);
      tmpm=NULL;
      for(min=0;min!=max;min++) {
        tmpm2=tmpm;
        if(tmph) tmpm=CAlloc(sizeof(CMemberLst));
        if(tmpm2) tmpm2->next=tmpm;
        if(tmph) tmpm->str=StrNew(ptr);
        ptr+=StrLen(ptr)+1;
        tmpc=HashFind(ptr,Fs->hash_table,HTT_CLASS|HTT_INTERNAL_TYPE);
        if(tmph) tmpm->member_class=tmpc;
        ptr+=StrLen(ptr)+1;
//If we couldn't find a class,continue
        if(!tmpc) {
	  if(tmpm) Free(tmpm->str);
	  Free(tmpm);
	  if(tmpm2) tmpm2->next=NULL;
	  tmpm=tmpm2;
	  ptr+=16;
	  goto next;
        } 
        if(tmph) tmpm->reg=ptr(U32*)[0];
        ptr+=4;
        if(tmph) tmpm->offset=ptr(I32*)[0];
        ptr+=4;
        if(tmpm) tmpm->member_class+=ptr(U32*)[0]; //In TempleOS,the next class is a "pointer star"
        ptr+=4;
        if(tmpm) tmpm->dim.total_cnt=tmpm->dim.cnt=ptr(U32*)[0];
        ptr+=4;
next:;
      }
      if(tmph) {
        tmpm=tmph(CHashFun*)->member_lst_and_root;
        for(;tmpm&&tmpm->next;tmpm=tmpm->next);
        if(tmpm)
	  tmpm->next=tmpm2;
        else
	  tmph(CHashFun*)->member_lst_and_root=tmpm2;
      }
    } else if(type&HTT_HELP_FILE) {
//Read the help index file
      tmph=CAlloc(sizeof(CHashSrcSym));
      tmph->type=HTF_PUBLIC|HTT_HELP_FILE;
      tmph->str=StrNew(ptr);
      ptr+=StrLen(ptr)+1;
//Read the help index
      tmph->idx=StrNew(ptr);
      ptr+=StrLen(ptr)+1;
      HashAdd(tmph,Fs->hash_table);
    }
  }
  Free(body);
}

