U0 ConvertEscaped(CDoc *input) {  
  Bool in_single=FALSE,in_multi=FALSE,in_doc_ent=FALSE;
  DocTop(input);
  I64 ch,twice;
  while((ch=EdCurU8(input))!=-1) {
    switch(ch) {
      case '/':
        EdCursorRight(input);
        if((ch=EdCurU8(input))=='/') {
	  in_single=TRUE;
        } else if(ch=='*') {
	  in_multi=TRUE;
        }
        break;
      case '*':
        if(in_multi) {
	  EdCursorRight(input);
	  if((ch=EdCurU8(input))=='/') {
	    in_single=FALSE,in_multi=FALSE;
	  }
        }
        break;
      case '\n':
        in_single=FALSE;
        break;
    }
    if(in_single||in_multi) {
      if(EdCurU8(input)=='\\') {
        EdCursorRight(input);
        if(EdCurU8(input)=='d') {
//Check if looks like a link with 2 uppercase chartactors
	  if(!in_doc_ent) {
	    for(twice=0;twice!=2;twice++) {
	      EdCursorRight(input);
	      if(!Bt(char_bmp_alpha,ch=EdCurU8(input))) {
	        goto next;
	      } else if(ToUpper(ch)!=ch)
	        goto next;
	    }
	    EdCursorLeft(input);
	    EdCursorLeft(input);
	    in_doc_ent=TRUE;
	  } else
	    in_doc_ent=FALSE;
//\$$LK[here]
	  EdCursorLeft(input);
	  EdCharDel(input);
	  EdCharDel(input);
	  EdCharIns('\d',0,input);
        }
      }
    }
    EdCursorRight(input);
next:;
  }
}

U0 ConvertFiles(U8 *mask="*.HC;*.HC.Z;*.HH;*.HH.Z") {
  CDirEntry *dirents=FilesFind(mask,FUF_JUST_FILES|FUF_FLATTEN_TREE|FUF_RECURSE),*cur;
  CDoc *doc;
  for(cur=dirents;cur;cur=cur->next) {
    doc=DocRead(cur->full_name,DOCF_PLAIN_TEXT);
    ConvertEscaped(doc);
    DocWrite(doc);
    DocDel(doc);
  }  
  DirEntryDel(dirents);
}
Cd("T:/");
ConvertFiles;