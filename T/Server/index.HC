I64 IndexSort(CDirEntry *a,CDirEntry *b) {
	if(IsDir(a->full_name)&&!IsDir(b->full_name)) 
		return -1;
	if(!IsDir(a->full_name)&&IsDir(b->full_name)) 
		return 1;
	return StrCmp(a->name,b->name);
}
U0 WIKI_FILE_UPLOAD_HTML(CDyadStream *stream,CURL *url,U8 *folder="/") {
	U8 *dest_folder=GetQueryValue(url->query,"FOLDER");
	if(!dest_folder) dest_folder=StrNew("/");
	WriteLn(stream,NULL,"<FORM ACTION=\""WIKI_UPLOAD"?FOLDER=%s\" CLASS=\"form-group\" ENCTYPE=\"multipart/form-data\" METHOD=\"POST\">",folder);
	WriteLn(stream,NULL,"<INPUT TYPE=\"file\" NAME=\"UPLOAD\" ID=\"UPLOAD\">");
	WriteLn(stream,NULL,"<INPUT TYPE=\"submit\" NAME=\"SUBMIT\" ID=\"SUBMIT\">");
	WriteLn(stream,NULL,"</FORM>");
}
U0 UploadGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
	CConnection *con=Fs->user_data;
	con->response_code=200;
	StrCpy(con->response_mime,"text/html");
	WikiHeader(stream,NULL,"<H1>Upload a file here:</H1>",FALSE);
	WIKI_FILE_UPLOAD_HTML(stream,url);
	WikiFooter(stream,NULL,url);
}
U0 UploadPost(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req,CHashTable *tab) {
  CHashGeneric *hash=HashFind("UPLOAD",tab,-1);
  if(!UserPrivCheck(srv,stream,url,req,""))
    return;
  U8 *blurb,*where,*where2,*u;
  CConnection *con;
  if(hash) {
    con=Fs->user_data;
    con->response_code=200;
    StrCpy(con->response_mime,"text/html");
    where2=GetQueryValue(url->query,"FOLDER");
    if(!where2) where2=StrNew("/");
    where=MStrPrint("%s/%s",where2,hash->user_data2);
    where2=where;
    where=ChrootFile(where2);
    u=GetCurrentUserName;
    if(!FileFind(where))
      BackupFile(where2,hash->user_data1,hash->user_data0,"c");
    else
      BackupFile(where2,hash->user_data1,hash->user_data0,u);
    FileWrite(where,hash->user_data1,hash->user_data0);
    blurb=MStrPrint("File %s uploaded.",hash->user_data2);
    WikiHeader(stream,NULL,blurb,FALSE);
    WriteLn(stream,NULL,"<H1>File \"%s\" uploaded.</H1>",hash->user_data2);
    WriteLn(stream,NULL,"<P>Size is %d byte(s).</P>",hash->user_data0);
    WikiFooter(stream,NULL,url);
  } else {
fail:
    con=Fs->user_data;
    con->response_code=200;
    StrCpy(con->response_mime,"text/html");
    WikiHeader(stream,NULL,"<H1>Upload a file here:</H1>",FALSE);
    WIKI_FILE_UPLOAD_HTML(stream,url,"/");
    WikiFooter(stream,NULL,url);
  }
}
//
// For non-WIKI files,I will choose to "VIEW" them. This means the server will
// provide a website navbar while also displaying the content
//
U0 ViewGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
  CConnection *con=Fs->user_data;
  StrCpy(con->response_mime,"text/html");
  U8 *path=url->abs_path+StrLen(WIKI_VIEW_FILE),*h;
  if(!path) {
    con->response_code=404;
    R404(stream,NULL,"Supply a File to View.");
    return;
  }
  con->response_code=200;
  h=HTMLify(path);
  WikiHeader(stream,NULL,path,WHF_SALT|WHF_CHANGES);
  WriteLn(stream,NULL,"<H2>Viewing file %s</H2>",h);
  if(IsImage(url->abs_path)) {
    WriteLn(stream,NULL,"<IMG SRC=\"%s\">",path);
  } else {
    WriteLn(stream,NULL,"<A HREF=\"%s\">%s</A>",path,h);
  }
  WikiFooter(stream,NULL,url);  
}
U0 IndexGet(CServer *srv,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
  U8 *index_link=MStrPrint("INDEX:/%s",url->abs_path);
  U8 *dir="/",*rel_dir="/",*chrooted,*t1;
  CDirEntry *ents,*cent,**sorted;
  CConnection *con=Fs->user_data;
  StrCpy(con->response_mime,"text/html");
  con->response_code=200;
  I64 ent_cnt=0,i;
  if(!StrNCmp(WIKI_INDEX,url->abs_path,StrLen(WIKI_INDEX)))
    rel_dir=dir=url->abs_path+StrLen(WIKI_INDEX);
  chrooted=ChrootFile(dir);
  dir=MStrPrint("%s/*",chrooted);
  WikiHeader(stream,NULL,index_link,FALSE);
  ents=FilesFind(dir);
  for(cent=ents;cent;cent=cent->next)
    ent_cnt++;
  sorted=MAlloc(sizeof(CDirEntry*)*ent_cnt);
  for(cent=ents,ent_cnt=0;cent;cent=cent->next)
    sorted[ent_cnt++]=cent;
  QSortI64(sorted,ent_cnt,&IndexSort);
  WriteLn(stream,NULL,"<H1>Upload a new file to %s</H1>",rel_dir);
  StrUtil(rel_dir,SUF_REM_SPACES);
  WIKI_FILE_UPLOAD_HTML(stream,url,rel_dir);
  WriteLn(stream,NULL,"<H1>Make a new page</H1>");
  WriteLn(stream,NULL,"<FORM ACTION=\""WIKI_EDIT"\" CLASS=\"form-group>\">");
  WriteLn(stream,NULL,"<LABELFOR=\"PAGENAME\">New Page:</LABEL>");
  WriteLn(stream,NULL,"<INPUT TYPE=\"TEXT\" NAME=\"PAGENAME\" ID=\"PAGENAME\">");
  WriteLn(stream,NULL,"</FORM>");
  WriteLn(stream,NULL,"<H1>Contents of %s</H1>",rel_dir);
  WriteLn(stream,NULL,"<UL>");
  for(i=0;i!=ent_cnt;i++) {
    t1=MStrPrint("%s/%s",rel_dir,sorted[i]->name);
    if(!StrCmp(".",sorted[i]->name)||!StrCmp("..",sorted[i]->name))
      goto next;
    if(IsDir(sorted[i]->full_name)) {
      WriteLn(stream,NULL,"<LI><A HREF=\""WIKI_INDEX"%s/%s\">%s</A><SPAN CLASS=\"badge secondary\">Folder</SPAN></LI>",rel_dir,sorted[i]->name,sorted[i]->name);
    } else {
      if(IsWiki(t1)) {
        if(FileIsSalted(t1))
	  WriteLn(stream,NULL,"<LI><A HREF=\"%s/%s\">%s</A>(Last edit at %D-%T)<SPAN CLASS=\"badge danger\">Salted</SPAN>",rel_dir,sorted[i]->name,sorted[i]->name,sorted[i]->datetime,sorted[i]->datetime);
        else
	  WriteLn(stream,NULL,"<LI><A HREF=\"%s/%s\">%s</A>(Last edit at %D-%T)",rel_dir,sorted[i]->name,sorted[i]->name,sorted[i]->datetime,sorted[i]->datetime);
      } else {
	//See WIKI_FILE_VIEW(We view images and such,not post a direct link to them)
        if(FileIsSalted(t1))
	  WriteLn(stream,NULL,"<LI><A HREF=\""WIKI_VIEW_FILE"%s/%s\">%s</A>(Last edit at %D-%T)<SPAN CLASS=\"badge danger\">Salted</SPAN>",rel_dir,sorted[i]->name,sorted[i]->name,sorted[i]->datetime,sorted[i]->datetime);
        else
	  WriteLn(stream,NULL,"<LI><A HREF=\""WIKI_VIEW_FILE"%s/%s\">%s</A>(Last edit at %D-%T)",rel_dir,sorted[i]->name,sorted[i]->name,sorted[i]->datetime,sorted[i]->datetime);
	
      }
      WriteLn(stream,NULL,"<SPAN><A HREF=\""WIKI_CHANGES"?FILE=%s/%s\">(Changelog)</A><SPAN>",rel_dir,sorted[i]->name);
      if(CurrentUserIsAdmin)
        WriteLn(stream,NULL,"<SPAN><A HREF=\""WIKI_DELETE"%s/%s\">(Delete)</A><SPAN>",rel_dir,sorted[i]->name);
      WriteLn(stream,NULL,"</LI>");
    }
    Free(t1);
next:
  }
  WriteLn(stream,NULL,"</UL>");
  WikiFooter(stream,NULL,url);
  DirEntryDel(ents);
  Free(sorted);
}
