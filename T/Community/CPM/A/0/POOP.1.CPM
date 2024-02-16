#include <STDIO.H>
#include <STDLIB.H>
#define MLN_LEN 80
#define MSCREEN_H 20
#define MLINES 0x200
#define MVIEW_OFF 2
#define MSCROLL_INC 10
int line_ptrs[MLINES];
char *_lines[MLINES];
char fn_name[12];
int bk_num;
int scroll;
int cur_line,cur_col;
int line_count;
int margin;
void ExitSexy() {
	printf("\033[3J\n");
	printf("Have a bodacious day!!!\n");
	printf("/\\      /\\\n");
	printf("||      ||\n");
	printf("|\\      /|\n");
	printf("| ------ |\n");
	printf("| (*) (*)|\n");
	printf("|    ^   |\n");
	printf("| \\___/  |\n");
	printf("| ______ |\n");
	printf("||      ||\n");
	printf("\\/      \\/\n");
	exit();
}
void CursorUp() {
	int l;
	if(!cur_line) {
		cur_col=0;
		return;
	}
	l=strlen(_lines[line_ptrs[--cur_line]]);
	if(l<=cur_col)
	  cur_col=l;
	if(cur_line<scroll)
	  scroll=max(0,cur_line-MSCROLL_INC);
}
void CursorDown() {
	int l;
	if(cur_line>=line_count-1) {
		cur_col=strlen(_lines[line_ptrs[line_count-1]]);
		return;
	}
	l=strlen(_lines[line_ptrs[++cur_line]]);
	if(l<=cur_col)
	  cur_col=l;
	if(cur_line>=MSCREEN_H+scroll)
	   scroll=max(0,cur_line-MSCREEN_H+MSCROLL_INC);
}
void CursorLeft() {
	if(!cur_col) {
		CursorUp();
  cur_col=strlen(_lines[line_ptrs[cur_line]]);
		return;
	}
	--cur_col;
}
void CursorRight() {
	int l;
	l=strlen(_lines[line_ptrs[cur_line]]);
	if(cur_col>=l) {
		CursorDown();
		cur_col=0;
		return;
	}
	++cur_col;
}
void __InsText(text,len) char *text; {
	int i,l;
	char *ln;
	l=strlen(ln=_lines[line_ptrs[cur_line]]);
	for(i=l-cur_col+1;i>=0;i--)
		ln[cur_col+len+i]=ln[cur_col+i];
	movmem(text,&ln[cur_col],len);
	cur_col+=len;
}
int __DelText(len) {
	int i,l;
	char *ln;
	l=strlen(ln=_lines[line_ptrs[cur_line]]);
	cur_col-=len;
	for(i=0;i<l+1-len;i++) {
		ln[cur_col+i]=ln[cur_col+i+1];
	}
}
int HasLine(l) {
  int i;
  for(i=0;i!=line_count;i++)
    if(line_ptrs[i]==l) return 1;
  return 0;
}
void InsLine() {
	/*Swap out tmp with cur_line's value*/
	int i;
	int tmp;
	tmp=line_ptrs[++line_count];
	for(i=line_count;i>cur_line;i--)
		line_ptrs[i]=line_ptrs[i-1];
	_lines[tmp]=alloc(MLN_LEN);
	strcpy(_lines[tmp],"");
	line_ptrs[cur_line+1]=tmp;
}
void MergeNextLine() {
	int i,tmp,did_somthing;
	tmp=line_ptrs[cur_line+1];
	strcat(_lines[line_ptrs[cur_line]],_lines[line_ptrs[cur_line+1]]);
	did_somthing=cur_line+1<line_count-1;
	if(did_somthing)
		free(_lines[line_ptrs[cur_line+1]]);
	for(i=cur_line+1;i<line_count-1;i++) {
		line_ptrs[i]=line_ptrs[i+1];
	}
	/*Swap line with out free'd line*/
	if(did_somthing)
		line_ptrs[i]=tmp;
	if(cur_line==line_count-1) {
		strcpy(_lines[line_ptrs[cur_line]],"");
	}
	if(line_count) {
	  --line_count;
    }
}
void AskSave() {
	printf("Save as: ");
	gets(fn_name);
}
void Save() {
	int i,l;
	FILE *f,*f2;
 char bak_name[8+3+1+1];
	loop:;
	if(fn_name[0]==0) AskSave();
	if(!index(fn_name,".")) {
		inv:
		fn_name[0]=0;
		printf("INVALID FILE NAME\n");
		goto loop;
	}
	if(strlen(fn_name)>11) {
		goto inv;
	}
 for(i=0;fn_name[i]!='.';i++)
   bak_name[i]=fn_name[i];
 sprintf(bak_name+i,".%d",++bk_num);
 f2=fopen(fn_name,"r");
 f=fopen(bak_name,"w");
 while(-1!=(i=fgetc(f2)))
   fputc(i,f);
 fclose(f),fclose(f2);

	f=fopen(fn_name,"w");
	for(i=0;i!=line_count;i++) {
		if(l=strlen(_lines[line_ptrs[i]]))
		  fwrite(_lines[line_ptrs[i]],1,l,f);
		fputc('\r',f);
		fputc('\n',f);
	}
	fclose(f);
}
void Draw(off,sline,eline) {
	int i,i2;
	char linum_b[40];
	for(i=sline;i<eline;i++) {
		if(i>=line_count) break;
		sprintf(linum_b,"%d:",i+1);
		i2=strlen(linum_b);
		for(;i2<margin;i2++)
		  linum_b[i2]=' ';
		linum_b[margin]=0;
		printf("\033[%d;%dH\033[K%s%s",off++,1,linum_b,_lines[line_ptrs[i]]);
   }
   for(;i<eline;i++)
      printf("\033[%d;%dH\033[K",off++,1);
}
void PositionCursor(off) {
	printf("\033[%d;%dH",off+(cur_line-scroll),1+cur_col+margin);
}
char find_buf[MLN_LEN];
int IndexOf(s,ss,off) char *s,*ss; {
  int l;
  l=strlen(ss);
  loop:;
  if(memcmp(&s[off],ss,l)) {
    return off; 
  }
  if(s[off++])
   goto loop;
  return -1;
}
void GotoLine() {
  char buf[MLN_LEN];
  int ln;
  printf("\033[%d;1H\033[KGoto line:",MSCREEN_H+MVIEW_OFF);
  gets(buf);
  
  sscanf(buf,"%d",&ln);
  if(ln>=line_count) ln=line_count-1;
  if(ln<0) ln=0;
  scroll=max(0,ln-MSCROLL_INC);
  cur_line=ln;
  cur_col=0;
}
void Find() {
  char fb2[MLN_LEN];
  int ocol,oline,i,off;

  ocol=cur_col;oline=cur_line;
  printf("\033[%d;1H\033[KFIND(current is %s): ",MVIEW_OFF+MSCREEN_H,
	find_buf);
  gets(fb2);
  if(!fb2[0]) {
  } else {
    strcpy(find_buf,fb2);
  }
  if(-1!=(off=IndexOf(_lines[line_ptrs[cur_line]],find_buf
     ,cur_col))) {
    cur_col=off+strlen(find_buf);
    return;
  }
  for(i=cur_line+1;i<line_count;i++) {
    off=IndexOf(_lines[line_ptrss[i]],find_buf,0);
    if(off!=-1) {
      found:;
      scroll=max(0,i-MSCROLL_INC);
      cur_col=off+strlen(find_buf);
      cur_line=i;
      return;
    }
  }
  for(i=0;i<=cur_line;i++) {
    off=IndexOf(_lines[line_ptrs[i]],find_buf,0);
    if(off!=-1) goto found;
  }
}
void InputLoop() {
	int ch,changed,old_scroll;
	char buf[MLN_LEN];
	Draw(MVIEW_OFF,0,MSCREEN_H);
	loop:;
	if(old_scroll!=scroll)
		Draw(MVIEW_OFF,scroll,scroll+MSCREEN_H);
	old_scroll=scroll;
	PositionCursor(MVIEW_OFF);
	ch=bios(3); /*Dont echo*/
	switch(ch) {
		case '\033':
		/*Listen up,ANSI seqeunces for Up,down,left and right are
		 *
		 * Up \033[A
		 * Down \033[B
		 * Right \033[C
		 * Left \033[D
		 * */
		switch(ch=bios(3)) {
			case '[':
			switch(ch=bios(3)) {
				case 'A': CursorUp(); break;
				case 'B': CursorDown(); break;
				case 'C': CursorRight(); break;
				case 'D': CursorLeft(); break;
			}
		}
		break;
		case 'Q'&0x1f:
		if(changed) {
			Save();
		}
		ExitSexy();
  case 'G'&0x1f:
  GotoLine();
  break;
  case 'F'&0x1f:
		Find();
		break;	
  case 'S'&0x1f:
		CursorDown();
		break;
		case 'W'&0x1f:
		CursorUp();
  	break;
		case 'D'&0x1f:
		CursorRight();
		break;
		case 'A'&0x1f:
		CursorLeft();
		break;
		case 127:
		changed=1;
		if(cur_col) {
			__DelText(1);
			Draw(MVIEW_OFF+(cur_line-scroll),cur_line,cur_line+1);
		} else if(cur_line) {
			cur_col=strlen(_lines[line_ptrs[--cur_line]]);
			MergeNextLine();
		    Draw(MVIEW_OFF+((cur_line)-scroll),cur_line,cur_line+
			    (MSCREEN_H-((cur_line)-scroll)));
		}
		break;
		case '\r':
		case '\n':
		changed=1;
		strcpy(buf,_lines[line_ptrs[cur_line]]+cur_col);
		_lines[line_ptrs[cur_line]][cur_col]=0;
		InsLine();
		_lines[line_ptrs[cur_line+1]][0]=0;
		cur_col=0;
		++cur_line;
		__InsText(buf,strlen(buf));
		cur_col=0;
		Draw(MVIEW_OFF+((cur_line-1)-scroll),cur_line-1,cur_line-1+
			(MSCREEN_H-((cur_line-1)-scroll)));
		break;
		default:
		if(0x1f>=ch) break;
		changed=1;
		__InsText(&ch,1);
		Draw(MVIEW_OFF+(cur_line-scroll),cur_line,cur_line+1);
		break;
	}
	goto loop;
}
void LoadFile(fn) char *fn; {
	int ch;
	int l,c;
	FILE *f;
	l=c=0;
	f=fopen(fn,"r");
	if(!f) return;
	_lines[l]=alloc(MLN_LEN);
	strcpy(_lines[l],"");
	while(-1!=(ch=fgetc(f))) {
		line_ptrs[l]=l;
		if(CPMEOF==ch) break;
		switch(ch) {
			case '\r':
			case '\n':
			c=0;
			if(++l>=MLINES) {
				printf("TOO MANY LINES.\n");
				ExitSexy();
			}
			_lines[l]=alloc(MLN_LEN);
			strcpy(_lines[l],"");
			break;
			default:
			if(c>=MLN_LEN) {
				printf("LINE %d IS TOO LONG.\n",l+1);
				ExitSexy();
			}
			_lines[l][c++]=ch;
			_lines[l][c]=0;
		}
	}
	if(!(line_count=l)) {
		line_count=l=1;
		_lines[0]=alloc(MLN_LEN);
		strcpy(_lines[0],"");
	}
	fclose(f);
}
int main(argc,argv) char **argv; {
 bk_num=0;
	printf("\033[3J\n");
	int i;
	char buf[64];
	find_buf[0]=0;
	sprintf(buf,"%d: ",MLINES+1);
	margin=strlen(buf);
	for(i=0;i!=MLINES;i++)
		line_ptrs[i]=i;
	if(argc>=2) {
		LoadFile(argv[1]);
		strcpy(fn_name,argv[1]);	
	} else if(argc>2) {
		printf("POOP.COM FILE.TXT\n");
		ExitSexy();
	} else {
		strcpy(fn_name,"");
		_lines[0]=alloc(MLN_LEN);
		strcpy(_lines[0],"");
		line_count=1;
	}
	scroll=cur_line=cur_col=0;
	InputLoop();
}
 {
		line_ptrs[l]=l;
		if(CPMEOF==ch) break;
		switch(ch) {
			