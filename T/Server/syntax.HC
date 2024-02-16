#define SYN_TK_STR		"HL_STR"
#define SYN_TK_NUM		"HL_NUM"
#define SYN_TK_MACRO	"HL_MAC"
#define SYN_TK_CLASS	"HL_CLASS"
#define SYN_TK_FUN	"HL_FUN"
#define SYN_TK_COMMENT	"HL_COMMENT"
#define SYN_TK_KEYWORD	"HL_KW"
#define SYN_TK_VAR	"HL_VAR"
#define SYN_TK_OPCODE	"HL_OPC"
#define HLS_COMMENT 1
U0 HighlightToHtml(CDyadStream *s,I64 len,U8 *src,I64 *state) {
  CHash *h;
  U8 *osrc=src;
//First charactor is a ';' so we Lex an item to load the buffer into cctrl->cur_buf_ptr
  U8 *t1=MAlloc(StrLen(src)+1+1),*t2,*t3=t1;
  *t3++=';';
  osrc=t1;
  StrCpy(t3,src);
  src=osrc+1; //See above note regarding first  ';'
  if(*state&HLS_COMMENT) {
    if(t2=StrMatch("*/",osrc)) {
//Eariler if we ecountered a "/*" ,we set the HLS_COMMENT in state,and 
      // we have an unterminated <SPAN>
      *state&=~HLS_COMMENT;
      t3=StrSlice(osrc,t1=t2+2);
      t2=HTMLify(t3);
      Write(s,len,"%s</SPAN>",t2);
      Free(t3);
      Free(t2);
      src=t1;
    } else{
      Write(s,len,"%s",src);
      Free(osrc);
      return ;
    }
  }
  try {
    CCmpCtrl *cctrl=CmpCtrlNew(src,CCF_NO_DEFINES|CCF_DONT_FREE_BUF,"WikiParser");   
loop:
    src=t3=t2=cctrl->cur_buf_ptr;
    while(Bt(char_bmp_white_space,*t2)||*t2=='#') {
      t2++;
    }
    if(t3!=t2) {
      t1=HTMLify(t3=StrSlice(t3,t2));
      Write(s,len,"%s",t1);
      Free(t1);
    }
    if(!StrNCmp(t2,"//",2)) {
      Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_COMMENT,t2=HTMLify(t2));
      Free(t2);
    } else if(!StrNCmp("/*",t2,2)) {
      if(t1=StrMatch("*/",t2+2)) {
        cctrl->cur_buf_ptr=t1+2;
	t1=StrSlice(t2,t1+2);
	Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_COMMENT,t2=HTMLify(t1));
	Free(t1),Free(t2);
	goto loop;
      } else {
        Write(s,len,"<SPAN CLASS=\"%s\">%s",SYN_TK_COMMENT,t2=HTMLify(t2));
        *state|=HLS_COMMENT;
        Free(t2);
        goto fin;
      }
    }
    cctrl->cur_buf_ptr=t2;
    if(Lex(cctrl)) {
      switch(cctrl->token) {
        start:
	  t3=cctrl->cur_buf_ptr;
//Check if last_U16 is NULL to see if we are at the end of the file
	  if(cctrl->flags&CCF_USE_LAST_U16&&cctrl->last_U16) {
	    t3--;
	  }
	  case TK_IDENT:
	    t1=HTMLify(t3=StrSlice(t2,t3));
	    h=HashFind(cctrl->cur_str,adam_task->hash_table,
		HTT_KEYWORD|HTT_FUN|HTT_GLBL_VAR|HTT_CLASS|HTT_DEFINE_STR|
		HTT_OPCODE|HTT_ASM_KEYWORD
	    );
	    if(h) {
	      if(h->type&(HTT_KEYWORD|HTT_ASM_KEYWORD)) {
	        Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_KEYWORD,t1);
	      } else if(h->type&HTT_CLASS) {
	        Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_CLASS,t1);
	      } else if(h->type&HTT_FUN) {
	        Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_FUN,t1);
	      } else if(h->type&HTT_DEFINE_STR) {
	        Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_MACRO,t1);
	      } else if(h->type&HTT_OPCODE) {
	        Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_OPCODE,t1);
	      } else if(h->type&HTT_GLBL_VAR) {
	        Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_VAR,t1);
	      }
	    } else 
	      Write(s,len,"%s",t1);
	    Free(t1),Free(t3);
	    break;case  TK_STR:
	    t1=HTMLify(t3=StrSlice(t2,t3));
	    Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_STR,t1);
	    Free(t1),Free(t3);

	    break;case  TK_I64:
num:
	    t1=HTMLify(t3=StrSlice(t2,t3));
	    Write(s,len,"<SPAN CLASS=\"%s\">%s</SPAN>",SYN_TK_NUM,t1);
	    Free(t3),Free(t1);
	    break;case  TK_CHAR_CONST:
	    Write(s,len,"<SPAN CLASS=\"%s\">'%c'</SPAN>",SYN_TK_STR,cctrl->cur_i64);
	    break;case TK_F64: goto num;
	    break;case TK_IF:
	    Write(s,len,"<SPAN CLASS=\"%s\">if</SPAN>",SYN_TK_KEYWORD);
	    break;case TK_IFDEF:Write(s,len,"<SPAN CLASS=\"%s\">ifdef</SPAN>",SYN_TK_KEYWORD);
	    break;case TK_IFNDEF:Write(s,len,"<SPAN CLASS=\"%s\">ifndef</SPAN>",SYN_TK_KEYWORD);
	    break;case TK_IFAOT:Write(s,len,"<SPAN CLASS=\"%s\">ifaot</SPAN>",SYN_TK_KEYWORD);
	    break;case TK_IFJIT:Write(s,len,"<SPAN CLASS=\"%s\">ifjit</SPAN>",SYN_TK_KEYWORD);
	    break;case TK_ENDIF:Write(s,len,"<SPAN CLASS=\"%s\">endif</SPAN>",SYN_TK_KEYWORD);
	    break;case TK_ELSE:Write(s,len,"<SPAN CLASS=\"%s\">else</SPAN>",SYN_TK_KEYWORD);
	    break;default:
slice:
	    t1=HTMLify(t3=StrSlice(t2,t3));
	    Write(s,len,"%s",t1);
	    Free(t1),Free(t3);
        end:
//Check if last_U16 is NULL to see if we are at the end of the file
	  if(cctrl->flags&CCF_USE_LAST_U16&&cctrl->last_U16) {
	    cctrl->flags&=~CCF_USE_LAST_U16;
	    cctrl->cur_buf_ptr--;
	  }
      }
      cctrl->flags|=CCF_NO_DEFINES;
      goto loop;
    } else  {
fin:
    }
  } catch {
	//Src was set at the start of the loop with the first orignal buf pos
     Write(s,len,"%s",src);
     Fs->catch_except=TRUE;
  }
  CmpCtrlDel(cctrl);
  Free(osrc);
}
U0 EndHighlight(CDyadStream *s,I64 len,I64 *state) {
  if(*state&HLS_COMMENT) {
    Write(s,len,"</SPAN>");
  }
}
