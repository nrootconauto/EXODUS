#ifndef IRCD_MESSAGE_TAG_HH
#define IRCD_MESSAGE_TAG_HH
U8 *IrcParseMessageTag(U8 *str,U8 *who) {
  if(*str!='@') return NULL;
  I64 wl=StrLen(who);
  U8 *ret=MAlloc(4096),*into;
  str++;
  while(*str) {
    if(!StrNICmp(who,str,wl)) {
      str+=wl;
      if(*str==' '||*str==';') {
//Empty value
	Free(ret);
	return StrNew("");
      } else if(*str=='=') {
//Gxt a value
	str++;
	into=ret;
	while(*str!=' '&&*str&&*str!=';') {
	  switch(*str) {
	    case '\\':
	      str++;
	      switch(*str) {
	        start:
		case ':':
		  *into++=';';
		  break;
		  case 's':
		    *into++=' ';
		    break;
		  case '\\':
		    *into++='\\';
		    break;
		  case 'r':
		    *into++='\r';
		    break;
		  case 'n':
		    *into++='\n';
		    break;
		end:
		  str++;
		  break;
	        default:
	          *into++=*str++;
	      }
	    break;
	   default:
	     *into++=*str++;
	  }
        }
	*into++=0;
	return ret;
      }
    } else {
        while(*str&&*str!=';')
	  str++;
	if(*str==';')
	  str++;
      }
  }
 Free(ret);
  return NULL;
}
U8 *IrcGetClientMsgs(U8 *str) {
  U8 *ret=CAlloc(StrLen(str)+1),*ptr=ret;
  U8*st;
  Bool first=TRUE;
  if(*str!='@') return ret;
  str++;
  while(*str&&*str!=' ') {
    for(st=str;*str&&*str!=' '&&*str!=';';str++)
      ;
    if(*str==';')
      str++;
    if(*st=='+') {
      if(first) {
        first=FALSE;
      } else
        *ptr++=';';
      while(*st!=';'&&*st!=' '&&*st)
        *ptr++=*st++;
    }
  }
  return ret;
}
/*
"%s\n",GetClientMsgs("@+typing=paused;poo=123;+msgid=123;+poop=yummy ");
"%s\n",ParseMessageTag("@aaa=bbb;ccc;example.com/ddd=eee","aaa");
"%s\n",ParseMessageTag("@aaa=bbb;ccc;example.com/ddd=eee","example.com/ddd");
"%x\n",ParseMessageTag("@aaa=bbb;ccc;example.com/ddd=eee","ccc");*/
#endif