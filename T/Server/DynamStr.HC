U8 *DynamStrPrint(CTask *task,U8 *str,U8 *fmt,...) {
  U8 *fmted=StrPrintJoin(NULL,fmt,argc,argv),*t;
  I64 len=StrLen(fmted);
  if(MSize(str)>=StrLen(str)+len+1) {
    CatPrint(str,fmted);
  } else {
    t=MAlloc(len+StrLen(str),task);
    t[0]=0;
    CatPrint(t,"%s%s",str,fmted);
    Free(str);
    str=t;
  }
  Free(fmted);
  return str;
}