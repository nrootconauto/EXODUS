#define WGf_CODE 1
#define WGf_PARA 2
#define WGf_LIST 3
#define WGf_TABLE 4
U0 FileGet(CServer *srv,CDyadStream*stream,CURL *url,CHTTPRequest *req) {
  CConnection *con;
  U8 *link=ChrootFile(url->abs_path);
  U8 *f,*mime,*dot=FileExtDot(link);
  I64 len;
  if(dot&&FileFind(link,,FUF_Z_OR_NOT_Z)){
    if(!StrICmp(dot,".GIF")||!StrICmp(dot,".GIF.Z")) mime="image/gif";
    else if(!StrICmp(dot,".JPEG")||!StrICmp(dot,".JPEG.Z")) mime="image/jpeg";
    else if(!StrICmp(dot,".JPG")||!StrICmp(dot,".JPG.Z")) mime="image/jpg";
    else if(!StrICmp(dot,".PNG")||!StrICmp(dot,".PNG.Z"))  mime="image/png";
    else if(!StrICmp(dot,".BMP")||!StrICmp(dot,".BMP.Z"))  mime="image/bmp";
    else if(!StrICmp(dot,".CSS")||!StrICmp(dot,".CSS.Z"))  mime="text/css";
    else if(!StrICmp(dot,".MIN.CSS")||!StrICmp(dot,".MIN.CSS.Z"))  mime="text/css";
    else mime="text/plain";
    f=FileRead(link,&len);
    con=Fs->user_data;
    StrCpy(con->response_mime,mime);
    con->response_code=200;
    WriteNBytes(stream,NULL,f,len);
    con->cache_age=24*60*60*3; //3 days
    Free(f);
  } else {
    R404(stream,&len,url->abs_path);
    con=Fs->user_data;
    StrCpy(con->response_mime,"text/html");
    con->response_code=404;
    R404(stream,NULL,url->abs_path);
  }
en:
  Free(link);
}
class CHTMLPair:CQue {
	U64 tag;
};
CHTMLPair *EnterPair(CHTMLPair *last,CDyadStream *s,I64 *len,U64 tag) {
  CHTMLPair *r=MAlloc(sizeof(CHTMLPair));
  QueInit(r);
  QueIns(r,last);
  r->tag=tag;
  Write(s,len,"<%c>",r->tag);
  return r;
}
CHTMLPair *ClosePair(CHTMLPair *last,CDyadStream *s,I64 *len,I64 cnt=1) {
loop:;
  CHTMLPair *r=last->last;
  if(last->next==last->last)
    return r;
  QueRem(last);
  Free(last);
  Write(s,len,"</%c>",last->tag);
  last=r;
  if(--cnt) goto loop;
  return r;
}
class CHeaderItem:CQue {
	U8 *text;
	I64 depth;
	I64 ident;
};
U8 *MakeIndex(CDyadStream *stream,I64 *len_ptr,CHeaderItem *index) {
  if(!QueCnt(index)) return;
  CHeaderItem *cur;
  CHTMLPair *pairs=MAlloc(sizeof(CHTMLPair)),*cpair=pairs;
  I64 last_idx=0;
  QueInit(pairs);
  WriteLn(stream,len_ptr,"<DIV CLASS=\"paper\"><H3>Table of contents</H3>");
  for(cur=index->next;TRUE;) {
    if(cur->depth>last_idx){
      do
        cpair=EnterPair(cpair,stream,len_ptr,'OL');
      while(++last_idx<cur->depth);
    }
    if(cur->depth<last_idx){
      do
        cpair=ClosePair(cpair,stream,len_ptr);
      while(--last_idx>cur->depth);
    }
    WriteLn(stream,len_ptr,"<LI><A HREF=\"#%d\">%s</A></LI>",cur->ident,cur->text);
    cur=cur->next;
    if(cur==index) goto en;
  }
en:
  while(cpair!=pairs)
    cpair=ClosePair(cpair,stream,len_ptr);
  QueDel(pairs);
  WriteLn(stream,len_ptr,"</DIV>");
}
Bool IsAbsLink(U8 *link) {
//http://
  if(StrFirstOcc(link,":"))
    return  TRUE;
  return FALSE;

}
U8 *StrFirstOccNonEsc(U8 *str,U8 *occ) {
  U8 *ostr=str,*find;
  loop:
  find=StrFirstOcc(str,occ);
  if(find!=ostr&&find&&find[-1]=='!') {
    //Escaped
    str=find+1;
    goto loop;
  }
  if(find&&ostr!=find&&*find=='_'&&find[1]!='_') {
    if(Bt(char_bmp_word,find[-1])) {
      if(find[0]==find[1])
        str=find+2;
      else
        str=find+1;
      goto loop;
    }
  }
  return find;
}
U8 *RemoveEscapedChars(U8 *t1) {
  U8 *t2,*t3;
  //Remove !'s that signify escaped items
  t3=t2=t1;
  for(;*t2;t2++) {
    if(t3!=t2)
      *t3=*t2;
     if(*t2=='!'&&StrOcc("-_/*[}+{|",t2[1]))
       ;
     else
       t3++;
  }
  *t3=0;
  return t1;
}
CHTMLPair *FmtStr(CDyadStream *stream,I64 *len_ptr,CHTMLPair *last,U8 *ln) {
  U8 *ln2=ln,*t1,*t2,*t3;
loop:
  ln2=StrFirstOccNonEsc(ln,"-_/+*[{|");
  if(!ln2) ln2=ln+StrLen(ln);
  Write(stream,len_ptr,"%s",t2=HTMLify(RemoveEscapedChars(t1=StrSlice(ln,ln2))));
  Free(t1),Free(t2);
  switch(*ln2) {  
      break;case '|':
      last=ClosePair(last,stream,len_ptr);
      last=EnterPair(last,stream,len_ptr,'TD');
      break; case '[':
      ln=ln2;
      ln2=StrFirstOccNonEsc(ln+1,"]");
      if(!ln2) {
        ln2=ln;
        Write(stream,len_ptr,"[");
      } else {
        t1=StrSlice(ln+1,ln2);
        t3=StrNew(t1);//Trimming mutates t1
        if(IsImage(Trim(t1))) {
	  WriteLn(stream,len_ptr,"<IMG SRC=\"images/%s\">",Trim(t1));
        } else if(!StrFirstOccNonEsc(t3," ")) {
	  if(IsAbsLink(Trim(t1)))
	    WriteLn(stream,len_ptr,"<A HREF=\"""%s\">%s</A>",Trim(t1),Trim(t1));
	  else
	    WriteLn(stream,len_ptr,"<A HREF=\"""/%s\">%s</A>",Trim(t1),Trim(t1));
        }else {
	  t2=StrFirstOccNonEsc(t3," ");
	  *t2++=0;
	  t2=HTMLify(t2);
	  if(IsAbsLink(Trim(t1)))
	    WriteLn(stream,len_ptr,"<A HREF=\"""%s\">%s</A>",Trim(t1),t2);
	  else
	    WriteLn(stream,len_ptr,"<A HREF=\"""/%s\">%s</A>",Trim(t1),t2);
          Free(t2);
        }
        Free(t1),Free(t3);;
      }
      break;case '*':
      ln=ln2;
      ln2=StrFirstOccNonEsc(ln+1,"*");
      if(!ln2) {
        ln2=ln;
        Write(stream,len_ptr,"*");
      } else {
        Write(stream,len_ptr,"<B>");
        t1=StrSlice(ln+1,ln2);
	last=FmtStr(stream,len_ptr,last,t1);
	Free(t1);
        Write(stream,len_ptr,"</B>");
      }
      break;case '/':
      ln=ln2;
      ln2=StrFirstOccNonEsc(ln+1,"/");
      if(!ln2) {
        ln2=ln;
        Write(stream,len_ptr,"/");
      } else {
        Write(stream,len_ptr,"<I>");
        t1=StrSlice(ln+1,ln2);
	last=FmtStr(stream,len_ptr,last,t1);
	Free(t1);
        Write(stream,len_ptr,"</I>");
      }
      break;case '_':
      ln=ln2;
      ln2=StrFirstOccNonEsc(ln+1,"_");
      if(!ln2) {
        ln2=ln;
        Write(stream,len_ptr,"_");
      } else {
        Write(stream,len_ptr,"<U>");
        t1=StrSlice(ln+1,ln2);
	last=FmtStr(stream,len_ptr,last,t1);
	Free(t1);
        Write(stream,len_ptr,"</U>");
      }
      break;case '-':
      ln=ln2;
      ln2=StrFirstOccNonEsc(ln+1,"-");
      if(!ln2) {
        ln2=ln;
        Write(stream,len_ptr,"-");
      } else {
        Write(stream,len_ptr,"<S>");
        t1=StrSlice(ln+1,ln2);
	last=FmtStr(stream,len_ptr,last,t1);
	Free(t1);
        Write(stream,len_ptr,"</S>");
      }
      break;case '+':
      ln=ln2;
      ln2=StrFirstOccNonEsc(ln+1,"+");
      if(!ln2) {
        ln2=ln;
        Write(stream,len_ptr,"+");
      } else {
        Write(stream,len_ptr,"<MARK>");
        t1=StrSlice(ln+1,ln2);
	last=FmtStr(stream,len_ptr,last,t1);
	Free(t1);
        Write(stream,len_ptr,"</MARK>");
      }
      break;   
  }
  if(*ln2++){
    ln=ln2;
    goto loop;
  }
  return last;
}

I64 FmtText(U8 *ftxt,CDyadStream *stream,CURL *url,Bool cache=FALSE) {
  Bool toc_enable=TRUE;
  U8 *fptr,
        *ln,*oln,*ln2,*t1,*t2,*t3,*cache_blob=NULL,*cache_blob_start=NULL;
  I64 len=0,*len_ptr,flags,i,depth,ident=0,hl_state=0;
  I64 list_depths[0x100],list_depths_i;
  CHTMLPair *markup=MAlloc(sizeof(CHTMLPair)),*last;
  CHeaderItem *headers=MAlloc(sizeof(CHeaderItem)),*cheader,*theader; 
  flags=0;
  len_ptr=&len;
  QueInit(markup);
  QueInit(headers);
loop:
  cheader=headers;
  last=markup;
  QueInit(markup);
  ident=0;
  list_depths_i=0;
  fptr=ftxt;
  if(!len_ptr) { //On second run len_ptr is NULL,but header is already populated
    if(toc_enable) {
      len_ptr=&len;
      MakeIndex(stream,len_ptr,headers);
      len_ptr=NULL;
    }
    cache_blob_start=cache_blob=MAlloc(len+1);
    cache_blob[len]=0;
    FramePtrSet("CACHE_BLOB",&cache_blob);
    if(toc_enable)
      MakeIndex(stream,len_ptr,headers);
    QueDel(headers);
    headers=MAlloc(sizeof(CHTMLPair));
    QueInit(headers);
    cheader=headers;
    hl_state=0;
  }
  while(oln=ln=ReadLine(fptr,&fptr)) {
//Is code if starts with whitespace
    if(StrOcc("\t ",*ln)) {
      if(!LBts(&flags,WGf_CODE)) {
        last=EnterPair(last,stream,len_ptr,'PRE');
        last=EnterPair(last,stream,len_ptr,'CODE');
	hl_state=0;
      }
      HighlightToHtml(stream,len_ptr,ln,&hl_state);
      Write(stream,len_ptr,"\n");
      goto next;
    } else if(LBtr(&flags,WGf_CODE)) {
      EndHighlight(stream,len_ptr,&hl_state);
      last=ClosePair(last,stream,len_ptr);
      last=ClosePair(last,stream,len_ptr);
    }
    if(*ln=='{') {
      ln2=StrFirstOccNonEsc(ln+1,"}");
      if(ln2){
         t1=StrSlice(ln+1,ln2);
	 ln=ln2+1;
         if(!StrCmp(t1,"no-toc")) {
           toc_enable=FALSE;
         }
         Free(t1);
      } else
        ln2=StrLen(ln)+ln;
    }
    if(*ln=='=') {
      last=ClosePair(last,stream,len_ptr);
      for(i=0;ln[i]=='=';i++);
      WriteLn(stream,len_ptr,"<H%d ID=\"%d\">%s</H%d>",i,++ident,t1=HTMLify(ln+i),i);
      if(len_ptr){
        theader=MAlloc(sizeof(CHeaderItem));
        QueInit(theader);
        theader->text=t1;
        theader->depth=i;
        theader->ident=ident;
        QueIns(theader,cheader);
        cheader=theader;
      } else
      goto next_reset;
    }
    if(*ln=='-') {
      for(i=0;ln[i]=='-';i++);
      if(i>=4) {
        last=ClosePair(last,stream,len_ptr);
        WriteLn(stream,len_ptr,"<HR>");
next_reset:
        LBtr(&flags,WGf_CODE);
	LBtr(&flags,WGf_TABLE);
        LBtr(&flags,WGf_PARA);
        goto next;
      }
    }
    if(*ln=='*') {
      for(i=0;ln[i]=='*';i++);
      ln+=i;
      if(list_depths_i)
        depth=list_depths[list_depths_i-1];
      else
        depth=1;
      if(!list_depths_i) {
        last=EnterPair(last,stream,len_ptr,'UL');
        list_depths[list_depths_i++]=i;
      } else if(depth==i) {
//Do nothing
      } else if(depth>i) {
        last=ClosePair(last,stream,len_ptr,depth-i);
        list_depths_i--;
      } else if(depth<i) {
        last=EnterPair(last,stream,len_ptr,'UL');
        list_depths[list_depths_i++]=i;
      } else
        ;
      last=EnterPair(last,stream,len_ptr,'LI');
      LBts(&flags,WGf_LIST);
      goto fmt_line;
    } else if(list_depths_i) {
      last=ClosePair(last,stream,len_ptr,list_depths_i);
      list_depths_i=0;
    }
    if(!Bts(&flags,WGf_PARA))
      last=EnterPair(last,stream,len_ptr,'P');
    if(*ln=='|') {
      if(LBts(&flags,WGf_TABLE)) {
row_start:
        last=EnterPair(last,stream,len_ptr,'TR');
        last=EnterPair(last,stream,len_ptr,'TD');
      } else {
        last=EnterPair(last,stream,len_ptr,'TABLE');
        goto row_start;
      }
    } else if(LBtr(&flags,WGf_TABLE)) {
      last=ClosePair(last,stream,len_ptr);
    }
fmt_line:
    last=FmtStr(stream,len_ptr,last,ln);
    if(LBtr(&flags,WGf_LIST))
      last=ClosePair(last,stream,len_ptr); //Close list item
    else if(Bt(&flags,WGf_TABLE)) {
      last=ClosePair(last,stream,len_ptr); //Close data
      last=ClosePair(last,stream,len_ptr); //Close row
    }
    else if(Bt(&flags,WGf_PARA))
      Write(stream,len_ptr,"<BR>");
next:
  }
finish:
    if(Bt(&flags,WGf_CODE))
      EndHighlight(stream,len_ptr,&hl_state);
    while(markup!=(last=ClosePair(last,stream,len_ptr))) {
    }
    if(len_ptr) {
	len_ptr=NULL;
        goto loop;
    }
    QueDel(markup);
    if(cache)
      ServerCacheAdd(url->abs_path,cache_blob_start,len);
    if(cache_blob_start)
      Free(cache_blob_start);
    FramePtrDel("CACHE_BLOB");
    QueDel(headers);
}
U0 WikiGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
  U8 *path=ChrootFile(url->abs_path),*ftxt,*fptr,
        *ln,*oln,*ln2,*t1,*t2,*t3;
  I64 len=0,*len_ptr=NULL,flags,i,depth,ident=0;
  I64 list_depths[0x100],list_depths_i;
  CHTMLPair *markup=MAlloc(sizeof(CHTMLPair)),*last;
  CConnection *con;
  CHeaderItem *headers=MAlloc(sizeof(CHeaderItem)),*cheader,*theader;
  QueInit(markup);
  QueInit(headers);
  cheader=headers;
  last=markup;
  if(!StrLen(url->abs_path)||!StrCmp(url->abs_path,"/")) {
    path=StrNew(WIKI_ROOT"/WikiHome");
//Copy into URL to "redirect"
    StrCpy(url->abs_path,"/WikiHome");
  }
  if(!FileExtDot(path)) {
    t1=MStrPrint("%s.WIKI",path);
    CatPrint(url->abs_path,".WIKI");
    path=t1;
  }
  if(FileFind(path,,FUF_Z_OR_NOT_Z)&&!IsDir(path)) {
//dummy write an index to compute its length
    con=Fs->user_data;
    StrCpy(con->response_mime,"text/html");
    con->response_code=200;
    WikiHeader(stream,len_ptr,url->abs_path,WHF_CHANGES|WHF_EDIT|WHF_SALT);
    if(ln=ServerCacheGet(url->abs_path)) {
      WriteNBytes(stream,NULL,ln,StrLen(ln));
    } else {
      ftxt=FileRead(path);
      FmtText(ftxt,stream,url,TRUE);
      Free(ftxt);
    }
    WikiFooter(stream,len_ptr,url);
  } else {
    con=Fs->user_data;
    StrCpy(con->response_mime,"text/html");
    con->response_code=200;
    WikiHeader(stream,NULL,"Not found");
    WikiFooter(stream,NULL,url);
  }
}
U0 Post(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,CHashTable *tab) {
	U8 *dot=FileExtDot(url->abs_path);
	if(!StrICmp(url->abs_path,WIKI_EDIT)) {
		EditPost(srv,stream,url,req,tab);
		goto fin;
	} else if(!StrICmp(url->abs_path,WIKI_UPLOAD)) {
		UploadPost(srv,stream,url,req,tab);
		goto fin;
	} else if(!StrICmp(url->abs_path,WIKI_LOGIN2)) {
		LoginPostGet(srv,stream,url,req,tab);
		goto fin;
	} else if(!StrICmp(url->abs_path,WIKI_SIGNUP2)) {
		SignupPostGet(srv,stream,url,req,tab);
		goto fin;
	} else if(!StrICmp(url->abs_path,WIKI_DELETE_ACCOUNT)){
		DeleteSelfPost(srv,stream,url,req,tab);
		goto fin;
	} else if(!StrICmp(url->abs_path,WIKI_LOGOUT)) {
		LogoutPost(srv,stream,url,req,tab);
		goto fin;
	} else if(!StrICmp(url->abs_path,WIKI_ADMIN)) {
		AdminPanelPost(srv,stream,url,req,tab);
		goto fin;
	} else if(!StrICmp(url->abs_path,WIKI_CHANGE_PASS)){
		ChangePassPost(srv,stream,url,req,tab);
		goto fin;
	}
	FileGet(srv,stream,url,req);
fin:
	EndHttpRequest(stream);
}
U0 DeleteGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
  U8 *f=url->abs_path+StrLen(WIKI_DELETE),*chroot,*yes;
  CConnection *con;
  if(!CurrentUserIsAdmin) {
    con=Fs->user_data;
    StrCpy(con->response_mime,"text/html");
    con->response_code=200;
    WikiHeader(stream,NULL,"Need to be an Admin to Delete Files");
    WriteLn(stream,,"<H2>Only Admins can Delete a File!</H2>");
    WriteLn(stream,,"<P>The admin(s) email(s) are %s</P>",WIKI_ADMIN_EMAILS);
    WikiFooter(stream,NULL,url);
    return;
  }
  if(!f) {
    con=Fs->user_data;
    StrCpy(con->response_mime,"text/html");
    con->response_code=200;
    WikiHeader(stream,NULL,"I need a File to Delete");
    WriteLn(stream,,"<H2>Choose a File to Delete from the Edit Menu or Index!</H2>");
    WikiFooter(stream,NULL,url);
    return;
  }
  con=Fs->user_data;
  StrCpy(con->response_mime,"text/html");
  con->response_code=200;
  chroot=ChrootFile(f);
  if(IsDir(chroot)) {
    WikiHeader(stream,NULL,"Not deleting a directory");
    WriteLn(stream,,"<H2>Im not Deleting a Directory,Too Dangerous</H2>",f);
    WriteLn(stream,,"<P>Try deleting files,not directories</P>",f);
    WikiFooter(stream,NULL,url);
    Free(chroot);
    return;
  }
  if(StrFirstOcc(f,"*?")) {
    WikiHeader(stream,NULL,"Not deleting a Wildcard");
    WriteLn(stream,,"<H2>Im not Deleting a Wildcard,Too Dangerous</H2>",f);
    WriteLn(stream,,"<P>Wildcards are too dangerous to deleted</P>",f);
    WikiFooter(stream,NULL,url);
    return;
  }
  if(yes=GetQueryValue(url->query,"yes")) {
    Del(chroot);
    chroot=ChrootFile(f,WIKI_BACKUP);
    DelTree(chroot);
    Free(chroot);
    WikiHeader(stream,NULL,"File Deleted");
    WriteLn(stream,,"<H2>You Deleted %s</H2>",f);
    WikiFooter(stream,NULL,url);
  } else {
    WikiHeader(stream,NULL,"Are You Sure");
    WriteLn(stream,,"<H2>Are You Sure You Want to Delete %s</H2>",f);
    WriteLn(stream,,"<FORM CLASS=\"form-group\" METHOD=\"GET\" ACTION=\"%s\">",url->abs_path);
    WriteLn(stream,,"<FIELDSET CLASS=\"form-group\">");
    WriteLn(stream,,"<LABEL FOR=\"yes\" CLASS=\"paper-radio\"><INPUT TYPE=\"radio\" NAME=\"yes\" ID=\"yes\" VALUE=\"yes\" >");
    WriteLn(stream,,"<SPAN>Yes,I want to delete %s</SPAN></LABEL>",f);
    WriteLn(stream,,"<LABEL FOR=\"no\" CLASS=\"paper-radio\"><INPUT TYPE=\"radio\" NAME=\"no\" ID=\"no\" VALUE=\"no\" CLASS=\"paper-radio\">");
    WriteLn(stream,,"<SPAN>No,I will keep the file</SPAN></LABEL>");
    WriteLn(stream,,"</FIELDSET>");
    WriteLn(stream,,"<INPUTTYPE=\"submit\" VALUE=\"CONFIRM\">");
    WriteLn(stream,,"</FORM>");
    WikiFooter(stream,NULL,url);
  }
}
U0 Get(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req)  {
//Will check for server "MOUNT POINTS" that are defined here
  //This allows us to access WIKI_BACKUP from here
  U8 *dot=FileExtDot(url->abs_path),*np;
  if(!StrNCmp(url->abs_path,WIKI_VIEW_FILE,StrLen(WIKI_VIEW_FILE))) {
    ViewGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrNCmp(url->abs_path,WIKI_DELETE,StrLen(WIKI_DELETE))) {
    DeleteGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrNCmp(url->abs_path,WIKI_BACKUP,StrLen(WIKI_BACKUP))) {
    BackupGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrNCmp(url->abs_path,WIKI_RESTORE,StrLen(WIKI_RESTORE))) {
    RestoreGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrNCmp(url->abs_path,WIKI_CHANGES,StrLen(WIKI_CHANGES))) {
    ChangeLogGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrNCmp(url->abs_path,WIKI_CHANGES_FOR_FILE,StrLen(WIKI_CHANGES_FOR_FILE))) {
    ChangeForFileGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrNCmp(url->abs_path,WIKI_INDEX,StrLen(WIKI_INDEX))) {
    IndexGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrICmp(url->abs_path,WIKI_UPLOAD)) {
    UploadGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrICmp(url->abs_path,WIKI_EDIT)) {
    EditGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrICmp(url->abs_path,WIKI_SEARCH)) {
    FindGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrICmp(url->abs_path,WIKI_LOGIN)) {
    LoginGet(srv,stream,url,req);
    goto fin;
 }
  if(!StrICmp(url->abs_path,WIKI_ACCOUNT)) {
    UserPannelGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrICmp(url->abs_path,WIKI_SALT)) {
    SaltGet(srv,stream,url,req);
    goto fin;
  }
  if(!StrICmp(url->abs_path,WIKI_UNSALT)) {
    SaltGet(srv,stream,url,req,FALSE);
    goto fin;
  }
  if(!StrICmp(url->abs_path,WIKI_ACCOUNT)) {
    UserPannelGet(srv,stream,url,req);
    goto fin;
  }
  if(!dot) {
    WikiGet(srv,stream,url,req);
    goto fin;
  }        
  if(!StrICmp(dot,".WIKI")) {
    WikiGet(srv,stream,url,req);
    goto fin;
  }
  FileGet(srv,stream,url,req);
fin:
  EndHttpRequest(stream);
}
CServer *srv=CreateServer(WIKI_SERVER_PORT);
srv->get=&Get;
srv->post=&Post;
Serve(srv);
