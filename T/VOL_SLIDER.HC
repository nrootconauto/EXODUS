
//It's a volume slider that will run in the WallPaper.HC.Z
U0 DrawVolumeSlider(CDC *dc , CCtrl *vol) {
  CD3I32 triangle[4];
  I64 intified=GetVolume*100,width=vol->right-vol->left;
  F64 slope=ToF64(vol->bottom-vol->top)/width;
  dc->color=BLUE;
  GrRect(dc,vol->left,vol->top,width,vol->bottom-vol->top);
//Draw green triangle of the volume
  dc->color=GREEN;
  triangle[0].x=vol->left;
  triangle[0].y=vol->bottom;
  triangle[1].x=vol->left+width*GetVolume;
  triangle[1].y=vol->bottom-width*GetVolume*slope;
  triangle[2].x=triangle[1].x;
  triangle[2].y=vol->bottom;
  GrFillPoly3(dc,3,triangle);
//
  dc->color=YELLOW;
  I64 voli=intified;
  GrPrint(dc,vol->left,vol->top,"VOLUME:%d%%",voli);
}
U0 VolumeSliderScroll(CCtrl *c,I64 delta) {
  c->state(F64)+=delta/100.;
  c->state(F64)=Clamp(c->state(F64),0,1.0);
  SetVolume(c->state(F64));
}

U0 VolumeSliderLeftClick(CCtrl *c,I64 x,I64 y,Bool down) {
  x-=c->left;
  c->state(F64)=Round(100*x/ToF64(c->right-c->left))/100.;
  c->state(F64)=Clamp(c->state(F64),0,1.0);
  SetVolume(c->state(F64));
}

U0 AddVolumeSlider(CTask *to) {
  CCtrl *vol=CAlloc(sizeof CCtrl);
  vol->state(F64)=1.0;
  vol->flags=CTRLF_SHOW|CTRLF_CAPTURE_LEFT_MS;
  vol->left=vol->top=0;
  vol->type=CTRLT_GENERIC;
  vol->right=FONT_WIDTH*16+vol->left;
  vol->bottom=FONT_HEIGHT+vol->top;
  vol->draw_it=&DrawVolumeSlider;
  vol->win_task=to;
  vol->wheel_chg=&VolumeSliderScroll;
  vol->left_click=&VolumeSliderLeftClick;
  QueIns(vol,to->last_ctrl);
  TaskDerivedValsUpdate(to);
}
