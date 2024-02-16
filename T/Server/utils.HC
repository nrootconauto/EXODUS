U64 FNV64(U8 *s) {
  U64 hash=0xCBF29CE484222325;
  while (*s) {
    hash*=0x100000001B3;
    hash^=*s++;
  }
  return hash;
}

U8 *FNV64Str(U8 *s) {
  U8 *ret=CAlloc(17);
  U64 res=FNV64(s);
  StrPrintHex(ret,res,16);
  return ret;
}

class CURL {
	U8 *hostname;
	U8 *abs_path;
	U8 *query;
	I64 port;
};
class CHTTPRequest {
	#define HTTP_UNDEF 0
	#define HTTP_GET 1
	#define HTTP_POST 2
	
	I64 method;
};
class CServer {
	CTask *task; 
	I64 port;
	CDyadStream *s_sock;
	U0(*get)(CServer*,CDyadStream*,CURL*,CHTTPRequest*);
	U0(*post)(CServer*,CDyadStream*,CURL*,CHTTPRequest*,CHashTable *);
};
U8 *ReadLine(U8 *t,U8 **en) {
  U8 *r,*e;
  if(!*t) {
    if(en) *en=NULL;
	return NULL;
  }
  if(e=StrFirstOcc(t,"\n")) {
chug:
    r=MAlloc(e-t+1);
    MemCpy(r,t,e-t);
    r[e-t]=0;
  } else {
    e=StrLen(t)+t;
    goto chug;
  }
  if(en) {
    if(*e=='\n')
      *en=e+1;
    else
      *en=e;
  }
  return r;
}
U8 *StrSlice(U8 *ptr,U8 *en) {
  U8 *r=MAlloc(en-ptr+1);
  MemCpy(r,ptr,en-ptr);
  r[en-ptr]=0;
  return r;
}
Bool IsImage(U8 *name) {
  U8 *dot=FileExtDot(name);
  if(dot++) {
    if(!StrICmp(dot,"GIF")) return TRUE;
    if(!StrICmp(dot,"JPEG")) return TRUE;
    if(!StrICmp(dot,"JPG")) return TRUE;
    if(!StrICmp(dot,"PNG")) return TRUE;
    if(!StrICmp(dot,"BMP")) return TRUE;
  }
  return FALSE;
$WW,1$}
Bool IsWiki(U8 *name) {
  U8 *dot=FileExtDot(name);
  if(dot++)
    if(!StrICmp(dot,"WIKI")) return TRUE;
  return FALSE;
}
U8 *HTMLify(U8 *str) {
  U8 *ptr,*r=StrNew(""),*t,*t2;
  for(;*str;){
    ptr=StrFirstOcc(str,"<>;&\"");
    if(!ptr)
      ptr=str+StrLen(str);
    switch(*ptr) {
      start:
        t=MStrPrint("%s%s",r,t2=StrSlice(str,ptr));
        r=t;
        case ';': //?
        t=MStrPrint("%s&#59;",r);
		break;
        case '<':
	  t=MStrPrint("%s&lt",r);
	  break;
        case '>':
	  t=MStrPrint("%s&gt",r);
	  break;
        case '&':
	  t=MStrPrint("%s&amp",r);
	  break;
        case '"':
	  t=MStrPrint("%s&quot",r);
	  break;
		case 0:
		t=StrNew(r);
		break;
      end:
        if(*ptr) ptr++;
        r=t;
    }
    str=ptr;
  }
  return r;
}
U8 *ChrootFile(U8 *fn,U8 *prefix=WIKI_ROOT) {
  U8 *t1,*t2;
  fn=StrNew(fn);
  //Check for "." , ".." and "//"(root dir)
  t1=fn;
  while(t2=StrFirstOcc(t1,"/")) {
    if(!StrNCmp(t2,"/./",3)||!StrCmp(t2,"/.")) { //The regular StrCmp checks for end of string
      StrCpy(t2,t2+2);
    } else if(!StrNCmp(t2,"/../",4)||!StrCmp(t2,"/..")) {  //See above note
      t1=t2;
      if(t2-1<=fn) {
	StrCpy(fn,t2+3); //Include the last '/'
	t1=fn;
      } else {
       t2--; //Ignore current '/'
      while(t2>fn&&*t2!='/')
        t2--;
      StrCpy(t2,t1+3); //Include the last '/'
      t1=t2;
      }
    } else if(!StrNCmp(t2,"//",2)) {
      StrCpy(fn,t2+1);
      t1=fn;
    } else
      t1=t2+1;
  }
  t1=fn;
  if(*fn=='/') fn++;
  U8 *virt=MStrPrint("%s/%s",prefix,fn);
  U8 *abs=FileNameAbs(virt),*abs2=FileNameAbs(prefix);
  if(!StrNCmp(abs,abs2,StrLen(abs2))) {
    goto fin;
  }
  if(StrLastOcc(fn,"/")) {
    Free(virt);
    virt=MStrPrint("%s/%s",prefix,StrLastOcc(fn,"/")+1);
    goto fin;
  }
  Free(virt);
  virt=MStrPrint("%s/%s",prefix,fn);
fin:
  //t1 has the start of fn
  Free(abs),Free(abs2),Free(t1);
  return virt;
}
extern I64 FmtText(U8 *ftxt,CDyadStream *stream,CURL *url,Bool cache=FALSE);
U8 *DotZify(U8 *t) {
  U8 *r=t;
  I64 len=StrLen(t);
  if(StrOcc(t,'.'))
    if(!(t[len-2]=='.'&&t[len-1]=='Z')) {
      r=MStrPrint("%s.Z",t);
    }
  return r;
}
