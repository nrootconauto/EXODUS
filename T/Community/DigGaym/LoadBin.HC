#include "Binify";
U0 LoadBin() {
  U8 *ptr,*ptr2,*name,*data,*fmted;
  I64 sz,w,h,cnt,x,y,sz2;
  PxData **pdata;
  CD2I32 *spawners;
  U8 *types,*hp,*flags;
  if(!FileFind("PX.BIN")||!FileFind("LEVELS.BIN"))
    Binify;
  ptr=FileRead("PX.BIN",&sz);
  cnt=0;
  for(ptr2=ptr;ptr2<ptr+sz;) {
    name=ptr2;
    ptr2+=StrLen(name)+1;
    w=*ptr2(I64*)++;
    h=*ptr2(I64*)++;
    data=MAlloc(w*h);
    MemCpy(data,ptr2,w*h);
    ptr2+=w*h;
    ExePrint("PxData %s={%d,%d,%d};;\n",name,w,h,data);
    fmted=MStrPrint("PX_AT-%d",cnt++);
    FramePtrAdd(fmted,ExePrint("&%s;\n",name));
    Free(fmted);
  }
  Free(ptr); 
  FramePtrAdd("PX_AT--1",0);
  ptr2=ptr=FileRead("LEVELS.BIN",&sz2);
  for(;ptr2<ptr+sz2;) {
    name=ptr2;
    ptr2+=StrLen(name)+1;
    sz=*ptr2(I64*)++;
    data=MAlloc(sizeof(PxData*)*sz);
    pdata=data;
    for(cnt=0;cnt!=sz;cnt++) {
      fmted=MStrPrint("PX_AT-%d",*ptr2(I16*)++);
      *pdata++=FramePtr(fmted);
      Free(fmted);
    }
    ExePrint("PxData **%sPx=%d;;\n",name,data);
    flags=data=MAlloc(sz);
    MemCpy(data,ptr2,sz);
    ptr2+=sz;
    ExePrint("U8 *%sFlags=%d;;\n",name,data);
    types=data=MAlloc(sz);
    MemCpy(data,ptr2,sz);
    ptr2+=sz;
    ExePrint("U8 *%sTypes=%d;;\n",name,data);
    hp=data=MAlloc(sz);
    MemCpy(data,ptr2,sz);
    ptr2+=sz;
    ExePrint("U8 *%sHP=%d;;\n",name,data);
    cnt=*ptr2(I64*)++;
    data=spawners=MAlloc(cnt*sizeof(CD2I32));
    MemCpy(spawners,ptr2,cnt*sizeof(CD2I32));
    ptr2+=cnt*sizeof(CD2I32);
    ExePrint("CD2I32 *%sSpawners=%d;;\n",name,data);
    w=*ptr2(I64*)++;
    h=*ptr2(I64*)++;
    x=*ptr2(I64*)++;
    y=*ptr2(I64*)++;
    ExePrint("MapTemplate %s={%d,%d,%sPx,%sFlags,%sTypes,%sHP,%d,%sSpawners,{%d,%d}};;\n",name,w,h,name,name,name,name,cnt,name,x,y);
  }
  Free(ptr);
}
LoadBin;