

#help_index "DolDoc/Task;StdOut/Task"
extern I64 PopUpTermRight(U8 *header);
I64 TermRightClickLink(CDoc *doc,CDocEntry *doc_e)
{//Called with doc locked, exit unlocked
  Bool send_new_line=FALSE,res=FALSE;
  U8 *st,*st2;
  I64 i;
  CEdFileName fn;
  if (st2=DocEntryLink(doc,doc_e)) {
    if (st=DocLinkFile(st2)) {
      DocUnlock(doc);
      if ((i=PopUpTermRight(st))>=0) {
	DocBottom(doc);
	switch (i) {
	  case RIGHT_INCLUDE:
	    if (FileExtDot(st) && !FilesFindMatch(st,FILEMASK_JIT)) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not .HC File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "#include \"%s\";\n\dPT\d\dFG\d\dBG\d",st;
	    WinZBufUpdate;
	    ExeFile(st,CCF_CMD_LINE);
	    res=TRUE;
	    break;
	  case RIGHT_AINCLUDE:
	    if (FileExtDot(st) && !FilesFindMatch(st,FILEMASK_JIT)) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not .HC File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "Adam(\"#include \\\"%s\\\"\" );\n\dPT\d\dFG\d\dBG\d",st;
	    WinZBufUpdate;
        AdamFile(st,FALSE);
	    res=TRUE;
	    break;
	  case RIGHT_COPY:
	    StrCpy(fn.name,st);
	    if (DocForm(&fn)) {
            res=ToBool(Copy(st,fn.name));
	    } else
	      send_new_line=TRUE;
	    break;
	  case RIGHT_MOVE:
	    StrCpy(fn.name,st);
	    if (DocForm(&fn))
	      res=Move(st,fn.name);
	    else
	      send_new_line=TRUE;
	    break;
	  case RIGHT_DELETE:
	    res=ToBool(Del(st));
	    break;
	  case RIGHT_TYPE:
	    res=Type(st);
	    break;
	  case RIGHT_ED:
	    if (FileExtDot(st) && !FilesFindMatch(st,FILEMASK_DD)) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not DolDoc File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "Ed(\"%s\");\n\dPT\d\dFG\d\dBG\d",st;
	    res=Ed(st);
	    break;
	  case RIGHT_MOUNT:
	    if (FileExtDot(st) && !FilesFindMatch(st,"*.ISO.C")) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not .ISO.C File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "MountFile(\"%s\");\n\dPT\d\dFG\d\dBG\d",st;
	    WinZBufUpdate;
	    MountFile(st);
	    res=TRUE;
	    break;
	  case RIGHT_PLAIN:
	    "Plain(\"%s\");\n\dPT\d\dFG\d\dBG\d",st;
	    res=Plain(st);
	    break;
	  case RIGHT_INFILE:
	    if (FileExtDot(st) && !FilesFindMatch(st,"*.IN*")) {
	      if (!PopUpCancelOk(ST_WARN_ST "Not .IN File\n\n")) {
		send_new_line=TRUE;
		break;
	      }
	    }
	    "InFile(\"%s\");\n\dPT\d\dFG\d\dBG\d",st;
	    WinZBufUpdate;
	    InFile(st);
	    res=TRUE;
	    break;
	}
      } else
	send_new_line=TRUE;
      Free(st);
    } else
      send_new_line=TRUE;
    Free(st2);
  } else
    send_new_line=TRUE;
  DocBottom(doc);
  "\dPT\d\dFG\d\dBG\d";
  if (send_new_line)
    '\n';
  return res;
}

public CDoc *DocBorderNew(CDoc *pdoc)
{//Make new std border doc.
  CDocEntry *doc_e;
  CDoc *bdoc;

  bdoc=DocNew;
  bdoc->flags|=DOCF_BORDER_DOC;
  if (pdoc) {
    DocPrint(bdoc,"\dCM+H+BY+RX+NC,-7,1\d");
    doc_e=DocPrint(bdoc,"\dTX+H+BD+TC,\" \"\d");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdFilterCB;
    doc_e=DocPrint(bdoc,"\dTX+H+BD+TC,\" \"\d");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdOverStrikeCB;
    doc_e=DocPrint(bdoc,"\dTX+H+BD+TC,\" \"\d");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdDollarCB;
    DocPrint(bdoc,"\dCM+H+BY+RX+NC,-18,1\d");
    doc_e=DocPrint(bdoc,"\dTX+BD+TC,\"     \"\d");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdMoreCB;
    doc_e=DocPrint(bdoc,"\dTX+H+BD+TC,\" \"\d");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdDollarTypeCB;
  }
  DocPrint(bdoc,"\dCM+H+TY+NC,0,-1\d");
  doc_e=DocPrint(bdoc,"\dDA+H-TRM-P+BD+RD+CX+IV,LEN=STR_LEN-1,"
	"A=\"%%s...\",SCX=15\d");
  doc_e->data=&(Fs->task_title);
  DocDataFmt(bdoc,doc_e);
  DocPrint(bdoc,"\dCM+H+NC,1,0\d\dTX+H+BD+IV,\"%X\"\d",Fs);
  DocPrint(bdoc,"\dTX+H+RX+BD,\"[X]\"\d");
  DocPrint(bdoc,"\dBK,1\d\dTX+H+LX+BD,\"MENU\"\d\dBK,0\d");
  return bdoc;
}

public U0 DocTermNew()
{//Make into term win task with Put/Display/Border docs.
  CDoc *pdoc=DocNew;
  pdoc->right_click_link=&TermRightClickLink;
  pdoc->max_entries=4096;
  Fs->border_src=BDS_CUR_DRV;
  pdoc->desc='Term';
  Fs->put_doc=Fs->display_doc=pdoc;
  Fs->border_doc=DocBorderNew(pdoc);
  Fs->cur_menu=MenuFile("::/Doc/EdPullDown.DD");
  WinScrollsInit(Fs);
}

#help_index "DolDoc"


I64 PopUpTermRight(U8 *header)
{
  I64 i;
  CDoc *doc=DocNew;
  if (header) DocPrint(doc,"%s",header);
  DocPrint(doc,"\n\n"
	"TXT=%s\nDD =%s\nJIT=%s\nGR =%s"
	"\dCM+LX,1,3 \d\dBT,\"Include           JIT\",LE=RIGHT_INCLUDE\d"
	"\dCM+LX,25,0\d\dBT,\"Adam Include      JIT\",LE=RIGHT_AINCLUDE\d"
	"\dCM+LX,1,3 \d\dBT,\"Copy                 \",LE=RIGHT_COPY\d"
	"\dCM+LX,25,0\d\dBT,\"Move or Rename       \",LE=RIGHT_MOVE\d"
	"\dCM+LX,1,3 \d\dBT,\"Delete               \",LE=RIGHT_DELETE\d"
	"\dCM+LX,25,0\d\dBT,\"Type           TXT;GR\",LE=RIGHT_TYPE\d"
	"\dCM+LX,1,3 \d\dBT,\"DolDoc Edit        DD\",LE=RIGHT_ED\d"
	"\dCM+LX,25,0\d\dBT,\"Mount           ISO.C\",LE=RIGHT_MOUNT\d"
	"\dCM+LX,1,3 \d\dBT,\"Plain Text Edit   TXT\",LE=RIGHT_PLAIN\d"
	"\dCM+LX,25,0\d\dBT,\"Infile             IN\",LE=RIGHT_INFILE\d"
	"\dCM+LX,1,3 \d\dBT,\"Cancel               \",LE=DOCM_CANCEL\d\n",
	FILEMASK_TXT,FILEMASK_DD,FILEMASK_JIT,FILEMASK_GR);
  i=PopUpMenu(doc);
  DocDel(doc);
  return i;
}

I64 EdLeftClickLink(CDoc *doc,CDocEntry *doc_e)
{//Called with doc locked, exit unlocked
  Bool res;
  U8 *st;
  if (st=DocEntryLink(doc,doc_e)) {
    DocUnlock(doc);
    if (doc_e->de_flags & DOCEF_POPUP)
      res=PopUpEd(st);
    else
      res=Ed(st);
    Free(st);
    return res;
  }
}

