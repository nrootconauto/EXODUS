class CFileListEnt:CQue {
  U8 *filename;
  I64 hits;
};
//Be sure to delete the ques  FileListEntDel
CFileListEnt *FindIndexedStr(U8 *str) {
  CQue *ret=MAlloc(sizeof CQue);
  CDirEntry *first,*cur;
  I64 cnt;
  U8 *text,*ptr;
  CFileListEnt *fle;
  QueInit(ret);
  if(!StrLen(str)) return ret;
  first=FilesFind(WIKI_ROOT"/*.WIKI");
  for(cur=first;cur;cur=cur->next) {
    ptr=text=FileRead(cur->full_name);
    cnt=0;
    while(ptr=StrIMatch(str,ptr)) {
      cnt++;
      ptr+=StrLen(str);
    }
    if(cnt) {
      fle=MAlloc(sizeof CFileListEnt);
      QueInit(fle);
      fle->hits=cnt;
      fle->filename=StrNew(cur->full_name);
      QueIns(fle,ret->last);
    }
    Free(text);
  }
  DirTreeDel(first);
  return ret;
}
I64 FindResultSort(I64 a,I64 b) {
    return StrCmp(a,b); //TODO TODO sort by relevance
}
U0 FindGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
  CConnection *con;
  U8 **sorted,*ftxt,*ptr,*ln_txt,*search_for=GetQueryValue(url->query,"s"),*h,*title,*dot;
  title=MStrPrint("FIND:%s",search_for);
  I64 len=0,*len_ptr=&len,mat,fcnt,f,trim;
  ptr=FileNameAbs(WIKI_ROOT);
  trim=StrLen(ptr);
  Free(ptr);
  CFifoI64 *matches=FifoI64New(0x80);
  CDirEntry c_ent;
  CFileListEnt *head,*ent;
loop:
  WikiHeader(stream,len_ptr,title,0);
  WriteLn(stream,len_ptr,"<FORM CLASS=\"form-group\" ACTION=\""WIKI_SEARCH"\">");
  WriteLn(stream,len_ptr,"<LABEL FOR=\"s\">SEARCH:</LABEL>");
  WriteLn(stream,len_ptr,"<INPUT NAME=\"s\" ID=\"s\">");
  WriteLn(stream,len_ptr,"<INPUT TYPE=\"Submit\" VALUE=\"Submit\">");
  WriteLn(stream,len_ptr,"</FORM>");
  if(search_for) {
    StrUtil(search_for,SUF_REM_LEADING|SUF_REM_TRAILING);
    head=FindIndexedStr(search_for);
    if(head)
      for(ent=head->next;ent!=head;ent=ent->next) {
        ftxt=FileRead(ent->filename);
        if(StrIMatch(search_for,ftxt)) {
	  FifoI64Ins(matches,StrNew(ent->filename));
        }
      }
    QueDel(head);
  }
  sorted=MAlloc(FifoI64Cnt(matches)*sizeof(U8 **));
  fcnt=FifoI64Cnt(matches);
  while(mat=FifoI64Cnt(matches)) {
    FifoI64Rem(matches,&sorted[mat-1]);
  }
  QSortI64(sorted,fcnt,&FindResultSort);
  for(f=0;f!=fcnt;f++) {
    FileFind(sorted[f],&c_ent);
    ptr=StrNew(c_ent.full_name+trim);
    c_ent.full_name=ptr;
    WriteLn(stream,len_ptr,"<ARITCLE CLASS=\"article\">",c_ent.full_name);
    WriteLn(stream,len_ptr,"<H4 CLASS=\"article-title\"><A HREF=\"%s\">%s</A></H4>",c_ent.full_name,c_ent.full_name);    
    WriteLn(stream,len_ptr,"<P CLASS=\"article-meta\">Last edited at %D(%T).</P>",c_ent.full_name,c_ent.datetime);
    WriteLn(stream,len_ptr,"<P>");
    ptr=ftxt=FileRead(sorted[f]);
    for(mat=0;(ln_txt=ReadLine(ptr,&ptr));) {
      if(mat<5&&StrIMatch(search_for,ln_txt)) {
        h=HTMLify(ln_txt);
        WriteLn(stream,len_ptr,"%s<BR>",h);
        mat++;
      }
    }
    Free(ftxt);
    WriteLn(stream,len_ptr,"</P>");
    WriteLn(stream,len_ptr,"</ARITCLE>");
   //Here we cap the number of matches to save time/bandwidth
   if(mat>5) break;
  }
  WikiFooter(stream,len_ptr,url);
  if(len_ptr) {
  con=Fs->user_data;
  StrCpy(con->response_mime,"text/html");
  con->response_code=200;
    len_ptr=NULL;
    goto loop;
  }
  Free(search_for);
  FifoI64Del(matches);
}