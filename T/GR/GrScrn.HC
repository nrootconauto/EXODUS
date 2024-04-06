#help_index "Graphics/Scrn"

U0 GrUpdateTaskODEs(CTask *task)
{
  sys_task_being_scrn_updated=task;
  try
    ODEsUpdate(task);
  catch {
    LBts(&task->win_inhibit,WIf_SELF_ODE);
    "Exception in WinMgr: Update Task ODEs\n";
    PutExcept;
    Sleep(3000);
  }
  sys_task_being_scrn_updated=NULL;
}

U0 GrUpdateTaskWin(CTask *task)
{ //Draw a win.  Only Core0 tasks have a win.
  CDC *dc;
  CD3I64 saved_scroll;
  sys_task_being_scrn_updated=task;
  try {
    if (!Bt(&task->display_flags,DISPLAYf_NO_BORDER))
      TextBorder(Fs,task->win_left,task->win_right,task->win_top,
	    task->win_bottom,task->border_attr,task==sys_focus_task);
    TextRect(task->win_left,task->win_right,
	  task->win_top,task->win_bottom,task->text_attr<<8);
    if (task==sys_winmgr_task) {
      if (gr.fp_wall_paper)
	(*gr.fp_wall_paper)(task);
    } else if (!(task->win_inhibit&WIF_SELF_DOC))
      DocUpdateTaskDocs(task);
    if (TaskValidate(task)) {
      if (task->draw_it) {
	dc=DCAlias(gr.dc2,task);
    (*task->draw_it)(task,dc);
	DCDel(dc);
      }
      if (TaskValidate(task)) {
	WinScrollNull(task,&saved_scroll);
	DrawCtrls(task);
	WinScrollRestore(task,&saved_scroll);
      }
    }
  } catch {
    if (task!=Fs && TaskValidate(task)) {
      LBtr(&task->display_flags,DISPLAYf_SHOW);
      "Exception in WinMgr: Update Task Win\n";
      PutExcept;
      Sleep(3000);
    }
  }
  sys_task_being_scrn_updated=NULL;
}

U0 GrUpdateTasks()
{//Only called by WinMgr
  I64 i;
  CTask *task,*task1;
  try {
    winmgr.ode_time=0;
    WinZBufUpdate;
    task1=task=sys_winmgr_task;
    do { //Loop through Core0 tasks.
      if (!TaskValidate(task)) break;
      if (Bt(&task->display_flags,DISPLAYf_SHOW) &&
	    Bt(gr.win_uncovered_bitmap,task->win_z_num))
	GrUpdateTaskWin(task);
      if (!TaskValidate(task)) break;
      task=task->next_task;
    } while (task!=task1);

    for (i=0;i<mp_cnt;i++) { //Loop through all cores.
      task1=task=cpu_structs[i].seth_task;
      do {
	if (!TaskValidate(task)) break;
	GrUpdateTaskODEs(task);
	if (!TaskValidate(task)) break;
	task=task->next_task;
      } while (task!=task1);
    }
  } catch {
    PutExcept(FALSE);
    //Dbg("Exception in WinMgr"); TODO RESTORE
  }
  winmgr.last_ode_time=winmgr.ode_time;
  ode_alloced_factor=LowPass1(0.1,ode_alloced_factor,
	Clamp(Gs->idle_factor-0.1,0.2,0.8),1/winmgr.fps);
  sys_task_being_scrn_updated=NULL;
}

U0 GrFixZoomScale()
{
  gr.scrn_zoom=ClampI64(gr.scrn_zoom,1,GR_SCRN_ZOOM_MAX);
  if (gr.scrn_zoom==1) {
    gr.sx=0;
    gr.sy=0;
  } else {
    gr.sx=ClampI64(gr.sx,0,GR_WIDTH-GR_WIDTH/gr.scrn_zoom)&~7;
    gr.sy=ClampI64(gr.sy,0,GR_HEIGHT-GR_HEIGHT/gr.scrn_zoom);
  }
}

public U0 GrScaleZoom(F64 scale)
{//Multiply zoom factor larger or smaller.
  F64 s=gr.scrn_zoom;
  gr.scrn_zoom=gr.scrn_zoom*scale;
  GrFixZoomScale;
  s/=gr.scrn_zoom;
  ms.scale.x*=s;
  ms.scale.y*=s;
  ms.scale.z*=s;
  gr.sx=ms.pos.x;
  gr.sy=ms.pos.y;
  ms.offset.z=ms.pos.z-(ms.pos.z-ms.offset.z)*s;
  GrFixZoomScale;
  ms.offset.x=gr.sx;
  ms.offset.y=gr.sy;
}

U0 GrZoomInScrn()
{
  GrFixZoomScale;
  I64 k,l,span,j,y;
  U8 *src,*src_cap,*dst,*ndst;
  dst=gr.zoomed_dc->body;
  span=gr.zoomed_dc->width/gr.scrn_zoom;
  for(y=0;y!=gr.zoomed_dc->height/gr.scrn_zoom;y++) {
    src=gr.dc2->body+gr.sx+(gr.sy+y)*gr.dc2->width_internal;  
    src_cap=src+span;
//We fill 1 row then we multiply that row,gr.scrn_zoom times
    //This will make our "pixels" sqaure
    while(src!=src_cap) {
      for(k=0;k!=gr.scrn_zoom;k++)
        *dst++=*src;
      src++;
    }
    dst-=span*gr.scrn_zoom;
    //Repeat the zoomed rows as they are the same
    for(l=1;l<gr.scrn_zoom;l++) {
      ndst=dst+gr.zoomed_dc->width_internal;
      MemCpy(ndst,dst,gr.zoomed_dc->width_internal);
      dst=ndst;
    }
    dst=ndst+gr.zoomed_dc->width_internal;
  }
}

U0 GrUpdateTextBG()
{
  I64 reg RSI *dst=gr.dc2->body,reg R13 c,row,col,
	num_rows=TEXT_ROWS,num_cols=TEXT_COLS,i,j,cur_ch,
	reg R12 w1=gr.dc2->width_internal,w2=-7*w1+8,w3=7*w1,w4=0;
  U32 *src=gr.text_base;
  Bool blink_flag=Blink;
  U8 *dst2=dst;

  if (gr.pan_text_x||gr.hide_col) {
    gr.pan_text_x=ClampI64(gr.pan_text_x,-7,7);
    j=AbsI64(gr.pan_text_x)/FONT_WIDTH+1;
    num_cols-=j;
    if (gr.pan_text_x<0) {
      src+=j;
      i=FONT_WIDTH*j+gr.pan_text_x;
    } else
      i=gr.pan_text_x;
    dst2=dst(U8 *)+i;
    w4=j;
    w3+=j*FONT_WIDTH;

    j*=FONT_WIDTH;
    dst(U8 *)=gr.dc2->body;
    for (row=num_rows*FONT_HEIGHT;row--;) {
      for (col=i;col--;)
	*dst(U8 *)++=0;
      dst(U8 *)+=w1-i-j;
      for (col=j;col--;)
	*dst(U8 *)++=0;
    }
  }
  dst=dst2;

  if (gr.pan_text_y||gr.hide_row) {
    gr.pan_text_y=ClampI64(gr.pan_text_y,-7,7);
    j=AbsI64(gr.pan_text_y)/FONT_HEIGHT+1;
    num_rows-=j;
    if (gr.pan_text_y<0) {
      src+=w1/FONT_WIDTH*j;
      i=w1*(FONT_HEIGHT*j+gr.pan_text_y);
    } else
      i=w1*gr.pan_text_y;
    dst2=dst(U8 *)+i;

    j*=w1*FONT_HEIGHT;
    dst(U8 *)=gr.dc2->body;
    for (row=i;row--;)
      *dst(U8 *)++=0;
    dst(U8 *)=gr.dc2->body+TEXT_ROWS*TEXT_COLS*FONT_HEIGHT*FONT_WIDTH-j;
    for (row=j;row--;)
      *dst(U8 *)++=0;
  }
  dst=dst2;

  for (row=num_rows;row--;) {
    for (col=num_cols;col--;) {
      cur_ch=*src++;
      if (cur_ch & (ATTRF_SEL|ATTRF_INVERT|ATTRF_BLINK)) {
	if (cur_ch & ATTRF_SEL)
	  cur_ch.u8[1]=cur_ch.u8[1]^0xFF;
	if (cur_ch & ATTRF_INVERT)
	  cur_ch.u8[1]=cur_ch.u8[1]<<4+cur_ch.u8[1]>>4;
	if (cur_ch & ATTRF_BLINK && blink_flag)
	  cur_ch.u8[1]=cur_ch.u8[1]<<4+cur_ch.u8[1]>>4;
      }
      c=gr.to_8_colors[cur_ch.u8[1]>>4];
      MOV	U64 [RSI],R13
      ADD	RSI,R12
      MOV	U64 [RSI],R13
      ADD	RSI,R12
      MOV	U64 [RSI],R13
      ADD	RSI,R12
      MOV	U64 [RSI],R13
      ADD	RSI,R12
      MOV	U64 [RSI],R13
      ADD	RSI,R12
      MOV	U64 [RSI],R13
      ADD	RSI,R12
      MOV	U64 [RSI],R13
      ADD	RSI,R12
      MOV	U64 [RSI],R13
      dst(U8 *)+=w2;
    }
    src+=w4;
    dst(U8 *)+=w3;
  }
}

U0 GrUpdateTextFG()
{//See $LK,"TextBase Layer",A="HI:TextBase Layer"$.
  U32 *src=gr.text_base;
  I64 i,j,cur_ch,*dst=gr.dc2->body,
	w1=gr.dc2->width_internal,w2=7*w1,w4=0,
	num_rows=TEXT_ROWS,num_cols=TEXT_COLS,row,col;
  U8 *dst_start=gr.dc2->body,*dst_end=dst_start+w1*gr.dc2->height-7*w1-8;
  Bool blink_flag=Blink;

  if (gr.pan_text_x||gr.hide_col) {
    gr.pan_text_x=ClampI64(gr.pan_text_x,-7,7);
    j=AbsI64(gr.pan_text_x)/FONT_WIDTH+1;
    num_cols-=j;
    if (gr.pan_text_x<0) {
      src+=j;
      dst(U8 *)+=FONT_WIDTH*j;
    }
    w4=j;
    w2+=j*FONT_WIDTH;
  }

  if (gr.pan_text_y||gr.hide_row) {
    gr.pan_text_y=ClampI64(gr.pan_text_y,-7,7);
    j=AbsI64(gr.pan_text_y)/FONT_HEIGHT+1;
    num_rows-=j;
    if (gr.pan_text_y<0) {
      src+=w1/FONT_WIDTH*j;
      dst(U8 *)+=w1*FONT_HEIGHT*j;
    }
  }

  for (row=num_rows;row--;) {
    for (col=num_cols;col--;) {
      cur_ch=*src++;
      if (cur_ch & (ATTRF_UNDERLINE|ATTRF_SEL|ATTRF_INVERT|ATTRF_BLINK)) {
	if (cur_ch & ATTRF_SEL)
	  cur_ch.u8[1]=cur_ch.u8[1]^0xFF;
	if (cur_ch & ATTRF_INVERT)
	  cur_ch.u8[1]=cur_ch.u8[1]<<4+cur_ch.u8[1]>>4;
	if (cur_ch & ATTRF_BLINK && blink_flag)
	  cur_ch.u8[1]=cur_ch.u8[1]<<4+cur_ch.u8[1]>>4;
      }
      if (i=cur_ch.u16[1]&0x3FF+gr.pan_text_x+gr.pan_text_y<<5) {
	j=i&0x1F;
	if (j&0x10) j|=~0x1F;
	i>>=5;
	if (i&0x10) i|=~0x1F;
	i=w1*i+j;
	if (dst_start<=dst(U8 *)+i<dst_end)
	  GrRopEquU8NoClipping(cur_ch&(ATTRF_UNDERLINE+0xFFF),dst(U8 *)+i,w1);
      } else
	GrRopEquU8NoClipping(cur_ch&(ATTRF_UNDERLINE+0xFFF),dst,w1);
      dst(U8 *)+=8;
    }
    src+=w4;
    dst(U8 *)+=w2;
  }
}

U0 DCBlotColor8(CDC *dc,CDC *img)
{
  U8 reg RSI *src=img->body;
  U8 reg RDI *dst=dc->body;
  I64 reg R10 w=dc->width/8; //Should be factor of 8
  I64 l=dc->height;
  while(l--) {
    src=img->body+l*img->width_internal;
    dst=dc->body+l*dc->width_internal;
    asm {
      MOV RCX,R10
      MOV RBX,0xF0F0F0F0f0f0f0f
@@loop:
      LODSQ
      MOV RDX,RAX
      SHR RAX,4
      AND U64 [RDI],RAX
      NOT RAX
      AND RDX,RAX
      AND RDX,RBX
      OR U64 [RDI],RDX
      ADD RDI,8
      LOOP @@loop
    };
  }
}
U0 GrUpdateTextModeText()
{
  U32 *src=gr.text_base;
  I64 cur_ch,i=TEXT_COLS*TEXT_ROWS;
  U16 *dst=text.vga_text_alias,*dst2=gr.vga_text_cache;
  Bool blink_flag=Blink;
  if (LBtr(&sys_semas[SEMA_FLUSH_VGA_IMAGE],0)) {
    while (i--) {
      cur_ch=*src++;
      if (cur_ch & ATTRF_SEL)
	cur_ch.u8[1]=cur_ch.u8[1]^0xFF;
      if (cur_ch & ATTRF_INVERT)
	cur_ch.u8[1]=cur_ch.u8[1]<<4+cur_ch.u8[1]>>4;
      if (cur_ch & ATTRF_BLINK)
	if (blink_flag)
	  cur_ch.u8[1]=cur_ch.u8[1]<<4+cur_ch.u8[1]>>4;
      *dst++=*dst2++=cur_ch&0x7FFF;
    }
  } else {
    while (i--) {
      cur_ch=*src++;
      if (cur_ch & ATTRF_SEL)
	cur_ch.u8[1]=cur_ch.u8[1]^0xFF;
      if (cur_ch & ATTRF_INVERT)
	cur_ch.u8[1]=cur_ch.u8[1]<<4+cur_ch.u8[1]>>4;
      if (cur_ch & ATTRF_BLINK)
	if (blink_flag)
	  cur_ch.u8[1]=cur_ch.u8[1]<<4+cur_ch.u8[1]>>4;
      cur_ch&=0x7FFF;
      if (*dst2!=cur_ch)
	*dst++=*dst2++=cur_ch;
      else {
	dst++;
	dst2++;
      }
    }
  }
}

U0 GrUpdateVGAGraphics()
{//Update Graphic Card
}
U8 *_screen=NULL;
U0 ScaleMouseCords(I64 *x,I64 *y) {
  I64 x2=*x,y2=*y;
  x2=(ToF64(x2)/640*640.);
  y2=(ToF64(y2)/480*480.);
  x2=ClampI64(x2,0,640);
  y2=ClampI64(y2,0,480);
  *x=x2;
  *y=y2;
}
I64 scrn_lock=0;
U0 GrUpdateScrn()
{//Called by the Window Manager $LK,"HERE",A="FF:::/Adam/WinMgr.HC,GrUpdateScrn"$, 30 times a second.
  I64 idx;
  CDC *dc;
  while(LBts(&scrn_lock,0))
	Yield;
  DCFill(gr.dc2,BLACK);
  GrUpdateTextBG;
  GrUpdateTextFG;
  DCBlotColor8(gr.dc2,gr.dc);
  GrUpdateTasks;
    
  dc=DCAlias(gr.dc2,Fs);
  dc->flags|=DCF_ON_TOP;
  if (gr.fp_final_scrn_update)
    (*gr.fp_final_scrn_update)(dc);
  DCDel(dc);
  if(gr.scrn_zoom==1) {
    dc=gr.dc2;
  } else {
    GrZoomInScrn;
    dc=gr.zoomed_dc;
  }
  DrawWindowUpdate(dc->body);
  LBtr(&scrn_lock,0);
}
