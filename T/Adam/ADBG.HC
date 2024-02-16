#help_index "Debugging/Dump"
Bool ClassRep2(CDoc *doc,U8 *_d,U8 *class_name=lastclass,
	I64 depth,I64 max_depth,Bool dynamic,I64 types=HTT_CLASS,I64 offset=0,Bool include_regs=FALSE)
{//See $LK,"::/Demo/LastClass.HC"$.
  I64 i,j,stars,*ptr;
  CMemberLst *ml;
  CDocEntry *doc_e;
  Bool unlock;
  CHashClass *tmpc,*tmpc2;
  if (depth>=max_depth) return TRUE;
  if (!(tmpc=HashFind(class_name,Fs->hash_table,types))) {
    DocPrint(doc,"Class Not Found.\n");
    return FALSE;
  }
  if (tmpc->base_class && !ClassRep2(doc,_d,tmpc->base_class->str,
        depth,max_depth,dynamic,types,offset))
    return FALSE;
  unlock=DocLock(doc);
  DocPrint(doc,"Class:\"%s\"\n",class_name);
  ml=tmpc->member_lst_and_root;
  while (ml) {
    tmpc2=ml->member_class;
    ptr=_d(U8 *)+ml->offset;
    //GP Registers range from 0-15
    if(0<=ml->reg<=0xf)
      DocPrint(doc,"%08Z ",ml->reg,"ST_U64_REGS");
    else
      DocPrint(doc,"%08X ",ptr(U8 *)+offset);
    stars=tmpc2->ptr_stars_cnt;
    tmpc2=OptClassFwd(tmpc2);
    tmpc2-=tmpc2->ptr_stars_cnt;
    if (tmpc2->type & HTT_INTERNAL_TYPE) {
      DocPrint(doc,"$$GREEN$$%-20ts:$$FG$$",ml->str);
      //ml->reg is lesser or equal to 0xf as there are 16 gp registers including 0
      if(!__IsValidPtr(ptr)||(0<=ml->reg<=0xf&&!include_regs)) { //if is a register and we dont want registers
        "(Unreadable)\n";
      } else if (stars==1 && (tmpc2->raw_type==RT_I8 || tmpc2->raw_type==RT_U8)) {
        ptr=*ptr;
        if (1) {
	  if (dynamic) {
	    doc_e=DocPrint(doc,"$$DA-TRM-P+RD,LEN=64,A=\"%%40ts\"$$\n");
	    doc_e->data=ptr;
	    DocDataFmt(doc,doc_e);
	  } else if(__IsValidPtr(ptr))
	    DocPrint(doc,"%40ts\n",ptr);
	  else
	    DocPrint(doc,"%40X\n",ptr);

        }
      } else if (!stars) {
        j=MinI64(ml->dim.total_cnt,32);
        if (tmpc2->raw_type==RT_I8 || tmpc2->raw_type==RT_U8) {
	  if (j==1) {
	    if (dynamic) {
	      doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,RT=U8,A=\"%%c\"$$\n");
	      doc_e->data=ptr;
	    } else
	      DocPrint(doc,"%c\n",*ptr(U8 *));
	  } else {
	    if (dynamic) {
	      doc_e=DocPrint(doc,"$$DA-TRM-P+RD,LEN=64,A=\"%%40ts\"$$\n");
	      doc_e->data=ptr;
	      DocDataFmt(doc,doc_e);
	    } else if(__IsValidPtr(ptr))
	      DocPrint(doc,"%40ts\n",ptr);
	    else
	      DocPrint(doc,"%40X\n",ptr);
	  }
        }
        for (i=0;i<j;i++) {
	  if(__IsValidPtr(ptr))
	    switch (tmpc2->raw_type) {
	      case RT_I0:
	      case RT_U0:
	        break;
	      case RT_I8:
	        if (dynamic) {
		  doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,RT=I8,A=\"%%02X\"$$ ");
		  doc_e->data=ptr(I8 *)++;
	        } else
		  DocPrint(doc,"%02X ",*ptr(I8 *)++);
	        break;
	      case RT_U8:
	        if (dynamic) {
		  doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,RT=U8,A=\"%%02X\"$$ ");
		  doc_e->data=ptr(U8 *)++;
	        } else
		  DocPrint(doc,"%02X ",*ptr(U8 *)++);
	        break;
	      case RT_I16:
	        if (dynamic) {
		  doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,RT=I16,A=\"%%04X\"$$ ");
		  doc_e->data=ptr(I16 *)++;
	        } else
		  DocPrint(doc,"%04X ",*ptr(I16 *)++);
	        break;
	      case RT_U16:
	        if (dynamic) {
		  doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,RT=U16,A=\"%%04X\"$$ ");
		  doc_e->data=ptr(U16 *)++;
	        } else
		  DocPrint(doc,"%04X ",*ptr(U16 *)++);
	        break;
	      case RT_I32:
	        if (dynamic) {
		  doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,RT=I32,A=\"%%08X\"$$ ");
		  doc_e->data=ptr(I32 *)++;
	        } else
		  DocPrint(doc,"%08X ",*ptr(I32 *)++);
	        break;
	      case RT_U32:
	        if (dynamic) {
		  doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,RT=U32,A=\"%%08X\"$$ ");
		  doc_e->data=ptr(U32 *)++;
	        } else
		  DocPrint(doc,"%08X ",*ptr(U32 *)++);
	        break;
	      case RT_U64:
	        if (dynamic) {
		  doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,RT=U64,A=\"%%08X\"$$ ");
		  doc_e->data=ptr(U64 *)++;
	        } else
		  DocPrint(doc,"%08X ",*ptr(U64 *)++);
	        break;
	      case RT_F64:
	        if (dynamic) {
		  doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,RT=F64,A=\"%%16g\"$$ ");
		  doc_e->data=ptr(F64 *)++;
	        } else
		  DocPrint(doc,"%16g ",*ptr(I64 *)++);
	        break;
	      default:
	        if (dynamic) {
		  doc_e=DocPrint(doc,"$$DA-TRM+RD+UD,A=\"%%016X\"$$ ");
		  doc_e->data=ptr(I64 *)++;
	        } else
		  DocPrint(doc,"%016X ",*ptr(I64 *)++);
	    }
	  if (dynamic)
	    DocDataFmt(doc,doc_e);
        }
        if (j<ml->dim.total_cnt)
	  DocPrint(doc,"...");
      } else
        DocPrint(doc,"%016X",*ptr);
      DocPrint(doc,"\n");
    } else {
      if (depth<2) {
        if (stars==1 && !0)
	  DocPrint(doc,"%-20ts:%016X\n",ml->str,*ptr);
        else {
	  DocPrint(doc,"$$TR,\"%s\"$$\n",ml->str);
	  DocPrint(doc,"$$ID,2$$");
	  if (!stars)
	    ClassRep2(doc,ptr,tmpc2->str,depth+1,max_depth,dynamic);
	  else if (stars==1)
	    ClassRep2(doc,*ptr,tmpc2->str,depth+1,max_depth,dynamic);
	  DocPrint(doc,"$$ID,-2$$");
        }
      } else
        DocPrint(doc,"%-20ts\n",ml->str);
    }
    ml=ml->next;
  }
  if (unlock)
    DocUnlock(doc);
  return TRUE;
}

public U0 ClassRep(U8 *_d,U8 *class_name=lastclass,
	I64 max_depth=2,Bool fun=FALSE,I64 offset=0,Bool include_regs=FALSE)
{//Displays members of a record by using the compiler's info.
  CDoc *doc;
  if (0)
    doc=DocNew;
  else {
    DocMax;
    doc=DocPut;
  }
  if (fun)
    ClassRep2(doc,_d,class_name,0,max_depth,FALSE,HTT_FUN,offset,include_regs);
  else
    ClassRep2(doc,_d,class_name,0,max_depth,FALSE,HTT_CLASS,offset,include_regs);
  DocPrint(doc,"\n");
  DocRecalc(doc);
  if (0) {
    DocDump(doc,100000);
    DocDel(doc);
  }
}

public U0 ClassRepD(U8 *_d,U8 *class_name=lastclass,
	I64 max_depth=2,Bool fun=FALSE,I64 offset=0)
{//Dynamic ClassRep. Uses hex_ed widgit for live changes.
  CDoc *doc;
  if (0)
    doc=DocNew;
  else {
    DocMax;
    doc=DocPut;
  }
  if (fun)
    ClassRep2(doc,_d,class_name,0,max_depth,TRUE,HTT_FUN,offset);
  else
    ClassRep2(doc,_d,class_name,0,max_depth,TRUE,HTT_CLASS,offset);
  DocPrint(doc,"\n");
  DocRecalc(doc);
}
I64 *TaskRegAddr(CTask *task,I64 reg_num)
{
  switch (reg_num) {
    case REG_RAX: return &task->rax;
    case REG_RCX: return &task->rcx;
    case REG_RDX: return &task->rdx;
    case REG_RBX: return &task->rbx;
    case REG_RSP: return &task->rsp;
    case REG_RBP: return &task->rbp;
    case REG_RSI: return &task->rsi;
    case REG_RDI: return &task->rdi;
    case 8 : return &task->r8;
    case 9 : return &task->r9;
    case 10: return &task->r10;
    case 11: return &task->r11;
    case 12: return &task->r12;
    case 13: return &task->r13;
    case 14: return &task->r14;
    case 15: return &task->r15;
  }
  return NULL;
}

U0 UpdateRegVarImg(CHashFun *tmpf,U8 *_b,CTask *task)
{
  CMemberLst *ml;
  CHashClass *tmpc;
  ml=tmpf->member_lst_and_root;
  while (ml) {
    if (ml->reg&0xf==ml->reg) {//Changed as we may have REG_UNDEF
      tmpc=OptClassFwd(ml->member_class);
      MemCpy(_b+ml->offset,TaskRegAddr(task,ml->reg),tmpc->size);
    }
    ml=ml->next;
  }
}
public U0 FunRep(U8 *st,U8 *rbp=NULL,I64 max_depth=2,CTask *task=NULL,Bool include_regs=FALSE)
{//Shows names and vals of a fun's local vars using compiler's info.
  I64 size;
  U8 *img;
  CHashFun *tmpf=HashFind(st,Fs->hash_table,HTT_FUN);
  CMemberLst *tmpm;
  if (tmpf) {
    if (rbp) {
      if (task) {
//tmpf->size is negative.It's the bottom
	//of the fun local var space relative to RBP .
	size=tmpf->arg_cnt*8-tmpf->size+16;

	img=MAlloc(size);
	MemCpy(img,rbp+tmpf->size,size);
	UpdateRegVarImg(tmpf,img-tmpf->size,task);
	ClassRep(img-tmpf->size,st,max_depth,TRUE,rbp-img+tmpf->size,include_regs);
	Free(img);
      } else
	ClassRep(rbp,st,max_depth,TRUE);
    } else {
      tmpm=tmpf->member_lst_and_root;
      while (tmpm) {
	if (0<=tmpm->reg<REG_REGS_NUM)
	  "%08Z %s\n",tmpm->reg,"ST_U64_REGS",tmpm->str;
	else
	  "%08tX %s\n",tmpm->offset,tmpm->str;
	tmpm=tmpm->next;
      }
      "%08tX Stk Size\n",tmpf->size;
    }
  }
}

#help_index "Debugging/Unassemble"
public U0 Uf(U8 *st)
{//Unassembles a named fun
  I64 i;
  CHashSrcSym *tmpf;
  CDbgInfo *dbg_info;
  if (tmpf=HashFind(st,Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM)) {
    if (tmpf->type&HTT_FUN)
      FunRep(st);
    if (dbg_info=tmpf->dbg_info) {
      i=dbg_info->body[dbg_info->max_line+1-dbg_info->min_line]
	    -dbg_info->body[0];
      Un(dbg_info->body[0],i);
      "Code Size:%04X\n",i;
    } else
      U(HashVal(tmpf));
  }
}
#help_index ""
