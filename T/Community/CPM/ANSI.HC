U8 ansi_colors[16]={
  BLACK,
  RED,
  GREEN,
  YELLOW,
  BLUE,
  PURPLE,
  CYAN,
  WHITE,
  LTGRAY,
  LTRED,
  LTGREEN,
  YELLOW,
  LTBLUE,
  LTPURPLE,
  LTCYAN,
  WHITE
};
class CANSITerm {
  I64 state;
  I64 escape_buf_idx;
  I64 cx,cy;
  U8 default_cp,cur_cp;
  Bool awaiting;
  U8 escape_buf[STR_LEN];
  U8 text[TEXT_ROWS-1][TEXT_COLS];
  U8 text_attrs[TEXT_ROWS-1][TEXT_COLS];
} Term;
MemSet(&Term,0,sizeof CANSITerm);
Term.cur_cp=Term.default_cp=BLACK<<4|WHITE;
MemSetU8(Term.text,' ',TEXT_COLS*(TEXT_ROWS-1));
MemSetU8(Term.text_attrs,Term.default_cp,TEXT_COLS*(TEXT_ROWS-1));
U0 DrawTerm(CTask *task,CDC *dc) {
  I64 x,y,attr;
  for(x=0;x!=TEXT_COLS;x++) {
    for(y=0;y!=TEXT_ROWS-1;y++) {
      //See TextBase layer in Help index
      attr=Term.text[y][x]|(Term.text_attrs[y][x]>>4)<<12|(Term.text_attrs[y][x]&0xf)<<8;
      if(x==Term.cx&&y==Term.cy)
        attr|=1<<29;
      TextChar(task,FALSE,x,y,attr);
    }
  }
}
U0 TermPrint(U8 *str) {
  I64 dist,dist2;
  loop2:;
  if(Term.awaiting&&*str) {
    while(*str&&!Bt(char_bmp_alpha,*str))
      Term.escape_buf[Term.escape_buf_idx++]=*str++;
    if(*str) {
      Term.escape_buf[Term.escape_buf_idx++]=*str;
      Term.escape_buf[Term.escape_buf_idx++]=0;
    }
    Term.cy=MinI64(MaxI64(Term.cy,0),TEXT_ROWS-1);
    Term.cx=MinI64(MaxI64(Term.cx,0),TEXT_COLS);
    switch(*str) {
      case 0:break;
      start:
      case 'A':
      dist=Str2I64(Term.escape_buf+1);
      dist=MaxI64(dist,1);
      Term.cy=MaxI64(Term.cy-dist,0);
      break;
      case 'B':
      dist=Str2I64(Term.escape_buf+1);
      dist=MaxI64(dist,1);
      Term.cy=MinI64(Term.cy+dist,TEXT_ROWS-1-1);
      break;
      case 'C':
      dist=Str2I64(Term.escape_buf+1);
      dist=MaxI64(dist,1);
      Term.cx=MinI64(Term.cx+dist,TEXT_COLS-1);
      break;
      case 'D':
      dist=Str2I64(Term.escape_buf+1);
      dist=MaxI64(dist,1);
      Term.cx=MaxI64(Term.cx-dist,0);
      break;
      case 'E':
      dist=Str2I64(Term.escape_buf+1);
      dist=MaxI64(dist,1);
      Term.cy=MinI64(Term.cy+(dist-1),TEXT_ROWS-1-1);
      Term.cx=0;
      break;
      case 'F':
      dist=Str2I64(Term.escape_buf+1);
      dist=MaxI64(dist,1);
      Term.cy=MaxI64(Term.cy-(dist-1),0);
      Term.cx=0;
      break;
      case 'K':
      MemSetU8(&Term.text[Term.cy][Term.cx],' ',TEXT_COLS-Term.cx);
      MemSetU8(&Term.text_attrs[Term.cy][Term.cx],Term.default_cp,TEXT_COLS-Term.cx);
      break;
      case 'J':
      dist=Str2I64(Term.escape_buf+1);
      switch(dist) {
        case 3:
        MemSetU8(&Term.text,' ',TEXT_COLS*(TEXT_ROWS-1));
        MemSetU8(&Term.text_attrs,Term.default_cp,TEXT_COLS*(TEXT_ROWS-1));
        Term.cy=Term.cx=0;
        break;
      }
      Term.awaiting=FALSE;
      Term.escape_buf_idx=0;
      break;
      case 'H':
      StrScan(Term.escape_buf+1,"%d;%dH",&dist,&dist2);
      Term.cy=MinI64(dist-1,TEXT_ROWS-1),Term.cx=MinI64(dist2-1,TEXT_COLS);
      break;
      case 'm':
      dist=Str2I64(Term.escape_buf+1);
      switch(dist) {
        case 0:
        Term.cur_cp=Term.default_cp;
        break;
        case 30...37:
        Term.cur_cp&=0xf;
        Term.cur_cp|=(dist-30)<<4;
        break;
        case 40...47:
        Term.cur_cp&=0xf0;
        Term.cur_cp|=dist-40;
        break;
      }
      end:
      Term.awaiting=FALSE;
      Term.escape_buf_idx=0;
      break;
      default:
      //TOSPrint("UNIMP:%c\n",*str);
      Term.awaiting=FALSE;
      Term.escape_buf_idx=0;
    }
    if(*str) str++;
      goto loop2;
  } else {
    while(*str) {
      if(*str==0x1b) {
        Term.awaiting=TRUE;
        str++;
        goto loop2;
      }
      if(*str=='\r') {
        Term.cx=0;
        str++;
        goto loop2;
      }
      //Backsapce
      if(*str==127||*str==8) {
        Term.text[Term.cy][Term.cx]=' ';
        Term.cx=MaxI64(Term.cx-1,0);
        str++;
        goto loop2;
      }
      if(*str=='\n') {
        Term.cx=0;
        Term.cy++;
      }
      if(Term.cx>=TEXT_COLS) {
        Term.cx=0;
        Term.cy++;
      }
      if(Term.cy>=TEXT_ROWS-1) {
        scroll_down:
        Term.cy=1;
        for(;Term.cy<TEXT_ROWS-1;Term.cy++) {
          MemCpy(
            &Term.text[Term.cy-1],
            &Term.text[Term.cy],
            TEXT_COLS
          );
          MemCpy(
            &Term.text_attrs[Term.cy-1],
            &Term.text_attrs[Term.cy],
            TEXT_COLS
          );
        }
        MemSetU8(&Term.text[Term.cy-1],' ',TEXT_COLS);
        MemSetU8(&Term.text_attrs[Term.cy-1],Term.default_cp,TEXT_COLS);
        Term.cy--;
      }
      Term.text_attrs[Term.cy][Term.cx]=Term.cur_cp;
      if(!Bt(char_bmp_white_space,*str)||*str==' ')
        Term.text[Term.cy][Term.cx++]=*str;
      else
        Term.text[Term.cy][Term.cx++]=' ';
      str++;
    }
  }
}
U8 *TermGetStr() {
  U8 buffer[0x100],buffer2[0x100];
  I64 bpos=0,blen=0,kc,sc;
  buffer[0]=0;
loop2:;
  ScanKey(&kc,&sc);
  switch(kc&0xff) {
    case CH_BACKSPACE:
    sc=SC_BACKSPACE;
    case 0: Sleep(10);
      switch(sc&0xff) { 
        case SC_CURSOR_LEFT:
	  if(bpos)
	    TermPrint("\x1b[1D");
	  bpos=MaxI64(bpos-1,0);
	  break;
        case SC_CURSOR_RIGHT:
          if(blen) {
            if(bpos!=MinI64(bpos+1,blen))
              TermPrint("\x1b[1C");
	    bpos=MinI64(bpos+1,blen);
          }
	  break;
        case SC_BACKSPACE:
	  if(bpos) {
	    TermPrint("\x1b[1D");
	    StrCpy(&buffer[--bpos],&buffer[bpos]);
	    buffer[blen--]=0;
	    TermPrint(&buffer[bpos]);
	    TermPrint(" ");
            if(StrLen(&buffer[bpos])+1)
              StrPrint(buffer2,"\x1b[%dD",StrLen(&buffer[bpos])+1);
            TermPrint(buffer2);
	  }
	  break;
      }
      break;
    case CH_ESC:
    case '\n':
      return StrNew(buffer);
    default:
      MemCpy(buffer2,buffer,bpos);
      buffer2[bpos]=kc&0xff;
      StrCpy(buffer2+bpos+1,buffer+bpos);
      StrCpy(buffer,buffer2);
      TermPrint(buffer+bpos);
      bpos++,blen++;
      buffer[blen]=0;
//We will be at the end of the buffer,so go backwards
      if(blen-bpos) {
        StrPrint(buffer2,"\x1b[%dD",blen-bpos);
        TermPrint(buffer2);
      }
  }
  goto loop2;
}
WinBorder(0);
WinMax;
Fs->draw_it=&DrawTerm;
