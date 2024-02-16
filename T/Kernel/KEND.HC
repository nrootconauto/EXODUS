U0 SysGlblsInit() {
	I64 i,j ;
    rev_bits_table=CAlloc(256);
    set_bits_table=CAlloc(256);
    for (i=0;i<256;i++)
      for (j=0;j<8;j++) {
        if (Bt(&i,7-j))	LBts(rev_bits_table+i,j);
        if (Bt(&i,j))	set_bits_table[i]++;
      }
	pow10_I64=CAlloc(sizeof(F64)*(308+308+1));
	for (i=-308;i<309;i++)
		pow10_I64[i+309]=Pow(10.,i);
    text.font=sys_font_std;
    text.aux_font=sys_font_cyrillic;
    text.cols=GR_WIDTH/FONT_WIDTH;
    text.rows=GR_HEIGHT/FONT_HEIGHT;
    text.raw_scrn_image=CAlloc(GR_WIDTH*GR_HEIGHT/8);
    text.border_chars[2] (I64)=0x0908070605040302;
    text.border_chars[10](U32)=0x0D0C0B0A;
    dbg.fun_seg_cache=CAlloc(FUN_SEG_CACHE_SIZE*sizeof(CFunSegCache));
    blkdev.tmp_filename=StrNew("/Tmp.DD.Z",adam_task);
}
SysGlblsInit;
SysDefinesLoad; 
