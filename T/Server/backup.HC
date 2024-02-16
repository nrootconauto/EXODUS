//First %s is flags(it may be empty)
//Flags are:
//  S for salted(only admins can edit)
//  s for unsalted(used for unsalting) $BK,1$When we unsalt,where is no text change,so mark it$BK,0$ 
//  c for create
//  b for binary_contents(otherwise contents are reconstructed from diff)
//  r for revert
#define WIKI_BACKUP_HEADER "%s(%s)%s@%D_%T" 
I64 GenerateChangeText(CDiffItem *diff,U8 *to=NULL) {
  I64 len=0,i,items=MSize(diff)/sizeof(CDiffItem);
  for(i=0;i!=items;i++) {
    switch (diff[i].type) {
      case DIFF_SAME:
        break;
      start:
        case DIFF_DELETE:
	  if(to) *to++='-';
	  len++;
	  break;
        case DIFF_INSERT:
	  if(to) *to++='+';
	  len++;
	  break;
      end:
        if(to) StrCpy(to,diff[i].str);
        len+=StrLen(diff[i].str)+1; //+1 for newline
        if(to) to+=StrLen(diff[i].str);
        if(to) *to++='\n';
        break;
      default:
        goto fin;
    }
  }
fin:
  if(to) *to++=0;
  len++;
  return len;
}
I64 TimestampCmp(CDirEntry *a,CDirEntry *b) {
  I64 rev,hr,min,sec;
  CDate date;
  I64 rev2,hr2,min2,sec2;
  CDate date2;
  StrScan(a->name,"%D_%d:%d:%d_%d",&date,&hr,&min,&sec,&rev);
  StrScan(b->name,"%D_%d:%d:%d_%d",&date2,&hr2,&min2,&sec2,&rev2);
  if(date!=date2)
    return date-date2;
  if(hr!=hr2)
    return hr-hr2;
  if(min!=min2)
    return min-min2;
  if(sec!=sec2)
    return sec-sec2;
  return rev-rev2;
}
I64 TimestampCmpRev(CDirEntry *a,CDirEntry *b) {
  return -TimestampCmp(a,b);
}
U8 *ReconstructFileText(U8 *file,U8 *backup_name) {
  CDirEntry *root,*cur,**flat;
  I64 len,idx,flen;
  U8 *path=ChrootFile(file,WIKI_BACKUP),*t1,*t2,*t3;
  U8 flags[STR_LEN],*ftxt;
  t1=MStrPrint("%s/*",path);
  root=FilesFind(t1,FUF_JUST_FILES);
  Free(t1);
  len=0;
  for(cur=root;cur;cur=cur->next)
    len++;
  flat=MAlloc(len*sizeof(CDirEntry*));
  len=0;
  for(cur=root;cur;cur=cur->next) {
    t2=cur->name;
    cur->user_data=!StrCmp(backup_name,cur->name);
//Changelog Timestamps have form %D_%T_d with certian charactors replaced
    while(StrFirstOcc(t2,"-"))
      *StrFirstOcc(t2,"-")='/';
    while(StrFirstOcc(t2,"."))
      *StrFirstOcc(t2,".")=':';
    flat[len++]=cur; 
  }
  QSortI64(flat,len,&TimestampCmp);
  ftxt=StrNew("");
  for(idx=0;idx!=len;idx++) {
    t1=FileRead(flat[idx]->full_name,&flen);
//Skip header
    t2=t1+StrLen(t1)+1;
//Skip changelog
    t2=t2+StrLen(t2)+1;
    //See WIKI_BACKUP_HEADER
    *StrFirstOcc(t1,"(")=0;
    if(StrOcc(t1,'b')) {
      Free(ftxt);
      ftxt=MAlloc(flen-(t2-t1));
      MemCpy(ftxt,t2,flen-(t2-t1));
    } else {
      ApplyDiff(NULL,ftxt,t2,&flen);
      t3=MAlloc(flen+1);
      ApplyDiff(t3,ftxt,t2,NULL);
      t3[flen]=0;
      Free(ftxt);
      ftxt=t3;
    }
    Free(t1);
    if(flat[idx]->user_data)
      break;
  }
  DirEntryDel(root);
  Free(flat);
  Free(path);
  return ftxt;
}
U0 BackupFile(U8 *file,U8 *ntxt,I64 nlen,U8 *user,U8 *flags=NULL,U8 *change_log_txt="") {
  if(!user) user=GetCurrentUserName;
  if(!flags) flags="";
  U8 *cnam1=ChrootFile(file),*fmted=NULL,*cnam2=NULL,*clone=StrNew(file),*otxt,
        *dpath,*dnam,*timestamp,*ftxt,*opath,*timestamp2,*t1,*t2; //Timestamp includes user who last edited the file
  I64 len,len2,len3;
  Bool is_create=StrOcc(flags,'c');
  CDirEntry dent,*ents,*cent;
  CDate time;
  CDiffItem *diff;
  if(FileFind(cnam1)) {
    otxt=FileRead(cnam1,&len);
ent:
    opath=StrLastOcc(clone,"/");
    if(opath)
      cnam2=opath+1;
    else
      opath=clone;
    if(FileFind(cnam1,&dent))
      time=dent.datetime,Free(dent.full_name);
    else
      time=Now;
//t1 is flags
    if(flags)
      t1=StrNew(flags);
    else
      t1=StrNew("");
    if(FileIsSalted(file)&&!StrOcc(flags,'s')) { //s is explict un-salt
      t1=DynamStrPrint(Fs,t1,"%sS",t1);
    }
    if(StrLen(otxt)!=len||IsImage(file))
      t1=DynamStrPrint(Fs,t1,"%sb",t1); //If has a NUL terminator,use a 
    timestamp=MStrPrint(WIKI_BACKUP_HEADER,t1,clone,user,Now,Now);
    t1;
    timestamp2=MStrPrint("%D_%T",time,time);
    while(StrFirstOcc(timestamp2,"/"))
      *StrFirstOcc(timestamp2,"/")='-';
    while(StrFirstOcc(timestamp2,":"))
      *StrFirstOcc(timestamp2,":")='.';
    if(opath) {
//If we have multiple files with the same timestamp,add a unique number at the end
      t1=MStrPrint("%s/%s*",clone,timestamp2);
      t2=ChrootFile(t1,WIKI_BACKUP);
      ents=FilesFind(t2);
      len=0;
      for(cent=ents;cent;cent=cent->next)
        len++;
      DirEntryDel(ents);
      Free(t1),Free(t2);
      if(!len)
        fmted=MStrPrint("%s/%s_0",clone,timestamp2);
      else
	fmted=MStrPrint("%s/%s_%d",clone,timestamp2,len);
      cnam2=ChrootFile(fmted,WIKI_BACKUP);
      dnam=cnam2;
      Free(clone);
      clone=StrNew(cnam2);
      opath=StrLastOcc(clone,"/");
      *opath=0;
      DirMk(clone);
    }
    t1=StrLastOcc(cnam1,".");
    if(t1)
      if(!StrICmp(t1,".WIKI")){
	if(is_create)
	  diff=Diff(ntxt,"");
	else
          diff=Diff(ntxt,otxt);
        len3=GenerateChangeText(diff,NULL); //len3 includes NULL terminator
        len2=StrLen(timestamp);
	
        if(StrOcc(flags,'r')) { //If is a revision,have the "changelog" be a string pointing to our revision
          len3=StrLen(change_log_txt)+1;
        } if(StrOcc(flags,'b')){
          //ntxt is already good,set len3 to 1 to signify 1NULL byte for changelog
          len3=1;
        } else
          ntxt=SaveDiff(diff,&nlen);
        ftxt=MAlloc(len2+1+nlen+len3);
        StrCpy(ftxt,timestamp);
        //
	// r's "Changelog "is actually a pointer to the file we reverted
	// b's are binaries and have no change line
        if(!StrFirstOcc(flags,"rb"))
          GenerateChangeText(diff,ftxt+len2+1);
        else if(StrOcc(flags,'r')) {
	  StrCpy(ftxt+len2+1,change_log_txt);
        } else if(StrOcc(flags,'b')) {
	  StrCpy(ftxt+len2+1,"");
        }
        if(StrOcc(flags,'b'))
          MemCpy(ftxt+len2+len3+1,ntxt,nlen);
        else {
	  MemCpy(ftxt+len2+len3+1,ntxt,nlen);
	  Free(ntxt); //Was Alloc'ed from  save diff
        }
        FileWrite(dnam,ftxt,len2+1+nlen+len3);
        DiffItemsDel(diff);
        goto pass;
      }
    len2=StrLen(timestamp);
    ftxt=MAlloc(len2+1+nlen);
    StrCpy(ftxt,timestamp);
    MemCpy(ftxt+len2+1,ntxt,nlen);
    FileWrite(dnam,ftxt,len2+1+nlen);
pass:
    Free(otxt);
    Free(ftxt);
    Free(timestamp);
    Free(timestamp2);
    Free(fmted);
    Free(clone);
  } else if(StrOcc(flags,'c')) {  //Check for creation
    len=0;
    otxt=StrNew("");
//Make a dummy file to write into
    FileWrite(cnam1,"",0);
    goto ent;
  }
  Free(cnam1);
}

U0 SaltFile(U8 *file,Bool on=TRUE) {
  if(!CurrentUserIsAdmin) return;
  I64 l;
  U8 *chrooted=ChrootFile(file),*name=GetCurrentUserName;
  if(!FileFind(chrooted)) {
    Free(file);
    Free(name);
    return;
  }
  U8 *oftxt=FileRead(chrooted,&l);
  if(on)
    BackupFile(file,oftxt,l,name,"S");
  else
    BackupFile(file,oftxt,l,name,"s"); //Tells the thing there is no text changes,ONLY an unsalt
  Free(oftxt),Free(chrooted),Free(name);
}

CDirEntry *GetFileRevisions(U8 *name) {
  CDirEntry *ents;
  U8 *clone=StrNew(name),*mask,*cnam=ChrootFile(name,WIKI_BACKUP),
        *l=StrLastOcc(cnam,"/"),*od=DirCur;
  *l=0;
  Cd(cnam);
  Cd(l+1);
  ents=FilesFind("*",FUF_JUST_FILES);
  Cd(od);
  Free(od);
  Free(clone);
  return ents;
}
I64 DateSort(CDirEntry *a,CDirEntry *b) {
  return b->datetime-a->datetime;
}
U0 DeleteUserEdits(U8 *user) {
  U8 *path=MStrPrint("%s/*",WIKI_BACKUP),*ftxt,name[STR_LEN],flags[STR_LEN],filename[STR_LEN]
        ,*t1,*t2,*t3,*fp;
  I64 len=0,i,deleted=0,flen;
  CDirEntry *root=FilesFind(path,FUF_RECURSE|FUF_FLATTEN_TREE|FUF_JUST_FILES),*cur;
  CDirEntry **sorted;
  CDate dummy;
  CHashTable *restored=HashTableNew(0x10);
  CHashGeneric *hash;
  for(cur=root;cur;cur=cur->next)
    len++;
  sorted=MAlloc(len*sizeof(CDirEntry*));
  len=0;
  for(cur=root;cur;cur=cur->next) {
    sorted[len++]=cur;
  }
  QSortI64(sorted,len,&TimestampCmpRev);
  for(i=0;i!=len;i++)
    if(FileFind(sorted[i]->full_name)) {
      ftxt=FileRead(sorted[i]->full_name,&flen);
      t1=name,t2=filename,fp=flags;
      StrScan(ftxt,WIKI_BACKUP_HEADER,&fp,&t2,&t1,&dummy,&dummy);
      if(!HashFind(filename,restored,HTT_FRAME_PTR)) {
	 t3=ChrootFile(filename);
//
// Here's the deal,i have sorted the files by timestamp
// So the first file $BK,1$filename$BK,0$ is the most recent,if it does not belong to
// the user,it will be skipped as there is no need to delete the user's edit 
// as it isnt the head.
//
// If the most recent(HEAD) file belongs to the user,we will not mark it,and the
// next most recent file will a canidate for restoration
//
	if(!StrCmp(user,name)) { //if user is name,skip the marking as good
	  if(StrOcc(flags,'c')) {
	    //If the user created the only revision of the file,just delete the file
	    Del(t3);
	    Free(t3);
	    t3=ChrootFile(filename,WIKI_BACKUP);
	    //No need to keep the backups
	    DelTree(t3);
	  }
	  goto next;
	}
        if(StrOcc(flags,'b')&&StrCmp(name,user)) {
	  t2=ftxt+StrLen(ftxt)+1; //Skip timestamp
	  t2=t2+StrLen(t2)+1; //Change-log text
	  BackupFile(filename,t2,flen-(t2-ftxt),NULL,"r",sorted[i]->name);
	  FileWrite(t3,t2,flen-(t2-ftxt));
mark:
//Not restored yet
	  hash=CAlloc(sizeof(CHashGeneric));
	  hash->type=HTT_FRAME_PTR;
	  hash->str=StrNew(filename);
	  HashAdd(hash,restored);
        } else if(StrCmp(name,user)) {
	  Free(ftxt);
	  ftxt=ReconstructFileText(filename,sorted[i]->name);
	  BackupFile(filename,ftxt,StrLen(ftxt),NULL,"r",sorted[i]->name);
	  FileWrite(t3,ftxt,StrLen(ftxt));
	  goto mark;
        }
next:
        Free(t3);
      }
      Free(ftxt);
    }
  Free(sorted);
  DirEntryDel(root);
}
U0 GenerateChangeLog(CDyadStream *s,U8 *name) {
  CDirEntry *ents=GetFileRevisions(name),*cur,**sorted,*root_abs;
  I64 i,len;
  U8 *link,*link2,*ftxt,*ptr,*ln,*h,*t1,flags[STR_LEN],
        fname[STR_LEN],user[STR_LEN],*fp,*np,*dp;
  CDate date,time;
  WriteLn(s,NULL,"<H1>Revisions of \"%s\"</H1>",name);
  WriteLn(s,NULL,"<OL>");
  for(cur=ents;cur;cur=cur->next)
    len++;
  sorted=MAlloc(sizeof(CDirEntry*)*len);
  len=0;
  for(cur=ents;cur;cur=cur->next) {
    sorted[len++]=cur;
  }
  QSortI64(sorted,len,&DateSort);
  for(i=0;i!=len;i++) {
    root_abs=FileNameAbs(WIKI_BACKUP);
    link=EncodeQueryValue(sorted[i]->full_name+StrLen(root_abs));
    ptr=ftxt=FileRead(sorted[i]->full_name);
    dp=flags;
    np=user;
    fp=fname;
    StrScan(ftxt,WIKI_BACKUP_HEADER,&dp,&fp,&np,&date,&time);
    WriteLn(s,NULL,
      "<DIV CLASS=\"paper\"><H2><A HREF=\""WIKI_CHANGES_FOR_FILE"?FILE=%s\">%s</A>(%s)</SPAN></H2>",
      link,
      sorted[i]->full_name+StrLen(root_abs),
      t1=HTMLify(user)
    );
    Free(t1);
    if(StrFirstOcc(flags,"sS")){ //These are for salt/unsalt(meaning there is no text changes)
      if(StrOcc(flags,'s')) {
        WriteLn(s,NULL,"<H3>Was unsalted here!</H3>");
      } else if(StrOcc(flags,'S')) {
        WriteLn(s,NULL,"<H3>Was Salted here!</H3>");
      }
      goto fin;
    }
    if(StrOcc(flags,'c')){
      WriteLn(s,NULL,"<H3>File was Created Here!</H3>");
      goto fin;
    }
    if(StrOcc(flags,'r')){
      ptr+=StrLen(ptr)+1; //Skip Timestamp
      WriteLn(s,NULL,"<H3>File was Reverted from &quot%s&quot Here!</H3>",ptr);
      goto fin;
    }
    if(t1=StrLastOcc(fname,".")) {
      if(!StrICmp(t1,".WIKI")) {
        //HEADER\0
        //changelog\0
        //Bits
        ptr+=StrLen(ptr)+1; //Skip Timestamp
        WriteLn(s,NULL,"<PRE>");
        h=HTMLify(ptr);
        WriteLn(s,NULL,"%s",h);
        Free(h);
        WriteLn(s,NULL,"</PRE>");
        goto fin;
      }
    }
    if(IsImage(fname)) {
      WriteLn(s,NULL,"<IMG SRC=\""WIKI_BACKUP"%s/%s\">",name,sorted[i]->name);
    } else {
      WriteLn(s,NULL,"<A HREF=\""WIKI_BACKUP"%s/%s\">%D(%T)</A>",name,sorted[i]->name,date,time);
    }
fin:
    WriteLn(s,NULL,"</DIV>");
    Free(ftxt);
    Free(root_abs);
  }
  WriteLn(s,NULL,"</OL>");
  Free(sorted);
  DirEntryDel(ents);
}
U0 ChangeLogGet(CServer *s,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
  U8 *f=GetQueryValue(url->query,"FILE"),*header=MStrPrint("Changelog for %s",f);
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
  WikiHeader(stream,NULL,header,FALSE); 
  GenerateChangeLog(stream,f);
  WikiFooter(stream,NULL,url);
  Free(header);
  Free(f);
}
U0 RestoreGet(CServer *s,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
//Checks if not logged in
  I64 len;
  U8 *f=GetQueryValue(url->query,"FILE"),*lasts,*chrooted,*ftxt,*chrooted2,*oftxt;
  if(!UserPrivCheck(s,stream,url,req,f)) return;
  if(!f) return;
  CConnection *con=Fs->user_data;
  StrCpy(con->response_mime,"text/html");
  con->response_code=200;
  lasts=StrLastOcc(f,"/");
  if(!lasts) {
err:
    R404(stream,NULL,f);
    Free(f);
    return;
  }
  chrooted=ChrootFile(f,WIKI_BACKUP);
  *lasts++=0;
  if(!FileFind(chrooted)) {
    goto err;
  }
  chrooted2=ChrootFile(f,WIKI_ROOT);
  oftxt=ftxt=FileRead(chrooted,&len);
  ftxt+=StrLen(ftxt)+1; //Skip timestamp
  if(StrOcc(chrooted2,'.')) {
    if(StrICmp(StrLastOcc(chrooted2,"."),".WIKI")) {
      FileWrite(chrooted2,ftxt,StrLen(ftxt));
      goto fin;
    }
  }
  Free(oftxt);
  oftxt=ftxt=ReconstructFileText(f,lasts);
  BackupFile(f,oftxt,StrLen(oftxt),NULL,"r",lasts);
  FileWrite(chrooted2,ftxt,StrLen(ftxt));
fin:
  Free(oftxt);
  WikiHeader(stream,NULL,"File reverted",0);
  WriteLn(stream,NULL,"<H1>Reverted &quot%s&quot</H1>",chrooted);
  WikiFooter(stream,NULL,url);
  Free(f);
  Free(chrooted2);
}
U0 ChangeForFileGet(CServer *s,CDyadStream *stream,CURL *url,CHTTPRequest *req) {
  U8 *f=GetQueryValue(url->query,"FILE"),*header,*chrooted,*ftxt,*oftxt,*ln,*ptr,*h,*enc,*body,*bits;
  if(!f) return ;
  CDate date,time;
  U8 fn[STR_LEN],name[STR_LEN],*fp,*np,flags[STR_LEN],*dp;
  chrooted=ChrootFile(f,WIKI_BACKUP);
  CDirEntry dent;
  if(!FileFind(chrooted,&dent)) {
    R404(stream,NULL,url->abs_path);
    return;
  }
  oftxt=ftxt=FileRead(chrooted);
  header=MStrPrint("Changes for %s(revision %s)",f,ftxt);
//HTTPheader stuff
  CConnection *con=Fs->user_data;
  con->response_code=200;
  StrCpy(con->response_mime,"text/html");
//
  WikiHeader(stream,NULL,header,FALSE);
  fp=fn;
  np=name;
  dp=flags;
  StrScan(ftxt,WIKI_BACKUP_HEADER,&dp,&fp,&np,&date,&time);
//HEADER\0
  //changelog\0
  //Bits
  //Skip header to changelog
  ftxt+=StrLen(ftxt)+1;
  body=ftxt;
  if(StrFirstOcc(flags,"sS")){ //These are for salt/unsalt(meaning there is no text changes)
    if(StrOcc(flags,'s')) {
      WriteLn(stream,NULL,"<H1>Was unsalted here!</H1>");
    } else if(StrOcc(flags,'S')) {
      WriteLn(stream,NULL,"<H1>Was Salted here!</H1>");
    }
    goto fin;
  }
  if(dp=StrLastOcc(fn,".")) {
    if(!StrICmp(dp,".WIKI")) {
      WriteLn(stream,NULL,"<H1>Full-text</H1><P>");
      bits=ReconstructFileText(fn,dent.name);
      FmtText(bits,stream,url);
      Free(bits);
      if(!StrOcc(flags,'r')){
        WriteLn(stream,NULL,"<H1>Changes</H1><PRE><CODE>");
//If ends in .WIKI,it includes a de-facto changelog
        ptr=body;
        while(ln=ReadLine(ptr,&ptr)) {
	  h=HTMLify(ln);
	  WriteLn(stream,NULL,"%s",h);
	  Free(ln),Free(h);
        }
        WriteLn(stream,NULL,"</CODE></PRE>");
        goto fin;
      } else {
        WriteLn(stream,NULL,"<H1>Was Reverted from &quot%s&quot here!</H1>",body);    
      }
    }
  }
//If doesnt end in .WIKI,we will have links to the raw files for inspection
  //  or <IMG>s if they are images 
  if(IsImage(name)) {
    WriteLn(stream,NULL,"<H1>Image</H1>");
    WriteLn(stream,NULL,"<IMG SRC=\"%s\">",chrooted);
  } else {
    WriteLn(stream,NULL,"<H1>File</H1>");
    WriteLn(stream,NULL,"<A HREF=\"%s\">%s(%D %T)</A>",chrooted,f,date,time);
  }
fin:
  Free(oftxt);
  WriteLn(stream,NULL,"<A HREF=\""WIKI_RESTORE"?FILE=%s\" CLASS=\"form-group\">Restore</A>",enc=EncodeQueryValue(f));
  WikiFooter(stream,NULL,url);
  Free(chrooted);
  Free(header);
  Free(dent.full_name);
}

Bool FileIsSalted(U8 *file) {
  U8 *chrooted=ChrootFile(file,WIKI_BACKUP),*otxt=NULL,flags[STR_LEN],
        name[STR_LEN],user[STR_LEN],*f,*u,*n,*t1;
  Bool ret=FALSE;
  CDirEntry *root,*cur,**sorted;
  CDate dummy;
  I64 len=0;
  t1=MStrPrint("%s/*",chrooted);
  root=FilesFind(t1,FUF_FLATTEN_TREE|FUF_JUST_FILES);
  for(cur=root;cur;cur=cur->next)
    len++;
  sorted=MAlloc(len*sizeof(CDirEntry*));
  len=0;
  for(cur=root;cur;cur=cur->next) {
    sorted[len++]=cur;
  }
  QSortI64(sorted,len,&DateSort);
  Free(t1);
  if(len) {
    otxt=FileRead(sorted[0]->full_name);
    f=flags;
    u=user;
    n=name;
    StrCpy(name,"");
    StrCpy(user,"");
    StrCpy(flags,"");
    StrScan(otxt,WIKI_BACKUP_HEADER,&f,&n,&u,&dummy,&dummy);
    ret=ToBool(StrOcc(flags,'S'));
  }
  DirEntryDel(root);
  Free(otxt);
  Free(chrooted);
  return ret;
}

U0 BackupGet(CServer *srv,CDyadStream*stream,CURL *url,CHTTPRequest *req) {
  U8 *link=url->abs_path;
  if(StrNCmp(link,WIKI_BACKUP,StrLen(WIKI_BACKUP)))
    goto _404;
  U8 *ftxt,*fn,*n,*u,*mime,*dot,*of,fname[STR_LEN],user[STR_LEN],flags[STR_LEN];
  CDate dummy;
  I64 len;
  CConnection *con;
  if(FileFind(link,,FUF_Z_OR_NOT_Z)){
//See WIKI_BACKUP_HEADER
    of=ftxt=FileRead(link,&len);
    fn=flags;
    n=fname;
    u=user;
    StrScan(ftxt,WIKI_BACKUP_HEADER,&fn,&n,&u,&dummy,&dummy);
    dot=StrLastOcc(fname,".");
    if(dot) {
      if(!StrICmp(dot,".GIF")||!StrICmp(dot,".GIF.Z")) mime="image/gif";
      else if(!StrICmp(dot,".JPEG")||!StrICmp(dot,".JPEG.Z")) mime="image/jpeg";
      else if(!StrICmp(dot,".JPG")||!StrICmp(dot,".JPG.Z")) mime="image/jpg";
      else if(!StrICmp(dot,".PNG")||!StrICmp(dot,".PNG.Z"))  mime="image/png";
      else if(!StrICmp(dot,".BMP")||!StrICmp(dot,".BMP.Z"))  mime="image/bmp";
      else if(!StrICmp(dot,".CSS")||!StrICmp(dot,".CSS.Z"))  mime="text/css";
      else if(!StrICmp(dot,".MIN.CSS")||!StrICmp(dot,".MIN.CSS.Z"))  mime="text/css";
      else mime="text/plain";
    } else 
      mime="text/plain";
    ftxt+=StrLen(ftxt)+1;
//Trim off header
    len-=ftxt-of;
    con=Fs->user_data;
    StrCpy(con->response_mime,mime);
    con->response_code=200;
    WriteNBytes(stream,NULL,ftxt,len);
    Free(of);
  } else {
_404:
    R404(stream,&len,url->abs_path);
    con=Fs->user_data;
    StrCpy(con->response_mime,"text/html");
    con->response_code=404;
    R404(stream,NULL,url->abs_path);
  }
en:
}
