U0 GridInit()
{//Init mouse grid struct. See $LK,"::/Demo/Graphics/Grid.HC"$.
  ms_grid.x=ms_grid.y=ms_grid.z=8;
  ms_grid.x_offset=ms_grid.y_offset=ms_grid.z_offset=0;
  ms_grid.x_speed =ms_grid.y_speed =ms_grid.z_speed =1;
  ms_grid.show=ms_grid.snap=ms_grid.coord=FALSE;
}

U0 MsUpdate(I64 x,I64 y,I64 z,Bool l,Bool r)
{
  ms.presnap.x=ToI64(ms.scale.x*x)+ms.offset.x;
  ms.presnap.y=ToI64(ms.scale.y*y)+ms.offset.y;
  ms.presnap.z=ToI64(ms.scale.z*z)+ms.offset.z;
  if (ms_grid.snap) {
    ms.pos.x=Trunc(ms.presnap.x/ms_grid.x)*ms_grid.x+ms_grid.x_offset;
    ms.pos.y=Trunc(ms.presnap.y/ms_grid.y)*ms_grid.y+ms_grid.y_offset;
    ms.pos.z=Trunc(ms.presnap.z/ms_grid.z)*ms_grid.z+ms_grid.z_offset;
  } else {
    ms.pos.x=ms.presnap.x;
    ms.pos.y=ms.presnap.y;
    ms.pos.z=ms.presnap.z;
  }

  ms.pos.x=ClampI64(ms.pos.x,0,GR_WIDTH-1);
  ms.pos.y=ClampI64(ms.pos.y,0,GR_HEIGHT-1);
  ms.pos_text.x=ms.pos.x/FONT_WIDTH;
  if (ms.pos_text.x>=text.cols) {
    ms.pos_text.x=text.cols-1;
    ms.pos.x=text.cols*FONT_WIDTH-1;
  }
  ms.pos_text.y=ms.pos.y/FONT_HEIGHT;
  if (ms.pos_text.y>=text.rows) {
    ms.pos_text.y=text.rows-1;
    ms.pos.y=text.rows*FONT_HEIGHT-1;
  }
  ms.lb=l;
  ms.rb=r;
}

U0 MsSet(I64 x=I64_MAX,I64 y=I64_MAX,I64 z=I64_MAX,I64 l=I64_MAX,I64 r=I64_MAX)
{//Note: Generates a message. See $LK,"MsSet",A="FF:::/Demo/Games/Zing.HC,MsSet"$().
  if (!(0<=x<GR_WIDTH))
    x=ms.pos.x;
  if (!(0<=y<GR_HEIGHT))
    y=ms.pos.y;
  if (z==I64_MAX)
    z=ms.pos.z;

  if (!(FALSE<=l<=TRUE))
    l=ms.lb;
  if (!(FALSE<=r<=TRUE))
    r=ms.rb;

  x=(x-ms.offset.x)/ms.scale.x;
  y=(y-ms.offset.y)/ms.scale.y;
  z=(z-ms.offset.z)/ms.scale.z;
  MsUpdate(x,y,z,l,r);
  MsHardSet(x,y,z,l,r);
}
U0 MsInit()
{
  MemSet(&ms,0,sizeof(CMsStateGlbls));
  MemSet(&ms_last,0,sizeof(CMsStateGlbls));
  ms.offset.x=ms.offset.y=ms.offset.z=0;
  ms.scale.x=ms.scale.y=ms.scale.z=1.0;
  ms.pos_text.x=ms.pos_text.y=ms.pos_text.z=0;
  ms.has_wheel=TRUE;
  ms.show=TRUE;
  ms.speed=0;
  ms.timestamp=cnts.jiffies;
  ms.dbl_time=0.350;
  GridInit;
  MemSet(&ms_hard,0,sizeof(CMsHardStateGlbls));
  ms_hard.installed=1;
  ms_hard.has_wheel=TRUE;
  ms_hard.fifo=FifoU8New(8);
  ms_hard.fifo2=FifoU8New(0x1000);
  ms_hard.scale.x=0.5;
  ms_hard.scale.y=0.5;
  ms_hard.scale.z=1.0;
  ms_hard.prescale.x=GR_WIDTH/ms_hard.scale.x/2.0;
  ms_hard.prescale.y=GR_HEIGHT/ms_hard.scale.y/2.0;
  ms_hard.prescale.z=0/ms_hard.scale.z;
  ms_hard.pos.x=GR_WIDTH>>1;
  ms_hard.pos.y=GR_HEIGHT>>1;
  MemCpy(&ms_hard_last,&ms_hard,sizeof(CMsHardStateGlbls));
}

MsInit;
U0 MsHardSetPre()
{
  I64 old_timestamp=ms_hard_last.timestamp;
  MemCpy(&ms_hard_last,&ms_hard,sizeof(CMsHardStateGlbls));
  ms_hard_last.timestamp=old_timestamp;
}

U0 MsHardSpeedSet()
{
  I64 dd,tmp;
  if ((dd=SqrI64(ms_hard_last.pos.x-ms_hard.pos.x)
	+SqrI64(ms_hard_last.pos.y-ms_hard.pos.y)) &&
	(tmp=ms_hard.timestamp-ms_hard_last.timestamp))
    ms_hard.speed=Sqrt(dd)*cnts.time_stamp_freq/tmp;
  ms_hard_last.timestamp=ms_hard.timestamp;
}

U0 MsHardSetPost()
{
  I64 i;
  ms_hard.pos.x=ms_hard.prescale.x*ms_hard.scale.x*ms_grid.x_speed;
  ms_hard.pos.y=ms_hard.prescale.y*ms_hard.scale.y*ms_grid.y_speed;
  ms_hard.pos.z=ms_hard.prescale.z*ms_hard.scale.z*ms_grid.z_speed;

  i=Trunc(ms.scale.x*ms_hard.pos.x/ms_grid.x)*ms_grid.x+ms.offset.x;
//TODO ms_grid.x_offset?
  if (i<0)
    ms.offset.x-=i;
  else if (i>=GR_WIDTH)
    ms.offset.x+=GR_WIDTH-1-i;

  i=Trunc(ms.scale.y*ms_hard.pos.y/ms_grid.y)*ms_grid.y+ms.offset.y;
  if (i<0)
    ms.offset.y-=i;
  else if (i>=GR_HEIGHT)
    ms.offset.y+=GR_HEIGHT-1-i;
  if (ms_hard.pos.x!=ms_hard_last.pos.x || ms_hard.pos.y!=ms_hard_last.pos.y ||
	ms_hard.pos.z!=ms_hard_last.pos.z) {
    ms_hard.evt=TRUE;
    MsHardSpeedSet;
  } else
    for (i=0;i<5;i++)
      if (ms_hard.bttns[i]!=ms_hard_last.bttns[i]) {
	ms_hard.evt=TRUE;
	break;
      }
}
U0 MsHardSet(I64 x,I64 y,I64 z,I64 l,I64 r)
{
  ms_hard.timestamp=cnts.jiffies;
  MsHardSetPre;
  ms_hard.prescale.x=x/ms_hard.scale.x/ms_grid.x_speed;
  ms_hard.prescale.y=y/ms_hard.scale.y/ms_grid.y_speed;
  ms_hard.prescale.z=z/ms_hard.scale.z/ms_grid.z_speed;
  ms_hard.bttns[0]=l;
  ms_hard.bttns[1]=r;
  MsHardSetPost;
}
I64 ms_mtx=0;
U0 HMSSet4(I64 x,I64 y,I64 z,I64 lr) {
  while(LBts(&ms_mtx,0))
    PAUSE;
  //SetFs(adam_task);
  ScaleMouseCords(&x,&y);
  x=x*ms.scale.x+ms.offset.x;
  y=y*ms.scale.y+ms.offset.y;
  z=z*ms.scale.z+ms.offset.z;
  MsSet(x,y,z,lr>>1,lr&1);
  LBtr(&ms_mtx,0);
 }
SetMSCallback(&HMSSet4);
