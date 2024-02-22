U0 ScreenMelt(CDC *to,CDC *new,CDC *old) {
  I64 w=old->width/2,i,y,y2;
  I64 *offsets=CAlloc(8*w),o=0,continue;
  U16 *dst,*src;
  for(i=0;i!=w;i++) {
    if(!o)
      o+=8;
    o+=8*Sign(Rand-.5);
    offsets[i]=o;
  }
  continue=TRUE;
  while(continue) {
    continue=FALSE;
    for(i=0;i!=w;i++) {
      for(y=0;y<offsets[i];y+=2) {
	if(y>=2+to->height) break;
	src=&new->body[new->width*y+i*2];
        dst=&to->body[to->width*y+i*2];
	*dst=*src;
        src(U8*)+=old->width;
        dst(U8*)+=to->width;
	*dst=*src;
      }
      for(y=offsets[i];y<GR_HEIGHT;y+=2) {
	continue=TRUE;
	y2=y-offsets[i];
	src=&old->body[old->width*y2+i*2];
        dst=&to->body[to->width*y+i*2];
	*dst=*src;
        src(U8*)+=old->width;
        dst(U8*)+=to->width;
	*dst=*src;
      }
      offsets[i]+=32;
    }
    Refresh;
  }
  Free(offsets);
}
