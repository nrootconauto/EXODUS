//5 has graphics
class CBubble
{
  CBubble *next,*last;
  F64 x,y,dx,dy,radius,t0;
} head;

F64 t0,x,y;
U64 flags;

F64 Windé()
{
  F64 t=ã*(Beat-t0);
  return Arg(Sin(t/8),1.0+Sin(t/4));
}

U0 DrawIt(CTask *,CDC *dc)
{
  CBubble *tmpb;
  F64 é;
  I64 r,x1,y1,z1,x2,y2,z2;

  if (LBts(&flags,0))
    return;

  dc->flags|=DCF_TRANSFORMATION;
  Mat4x4RotX(dc->r,ã/4);

  é=Wrap(ã-Windé);
  Mat4x4RotZ(dc->r,-ã/2+é/10);

  dc->color=BLUE;
  dc->x=x;
  dc->y=y;
  dc->thick=2;
  GrCircle3(dc,0,0,0,10);
  GrLine3(dc,-10,0,0,-30,0,0);

  tmpb=head.last;
  if (tmpb!=&head) {
    dc->color=LTBLUE;
    r=tmpb->radius*Min(1.0,0.25+2*(Beat-tmpb->t0));
    for (é=0;é<2*ã;é+=ã/2) {
      x1=10*Cos(é);y1=10*Sin(é);z1=0;
      DCTransform(dc,&x1,&y1,&z1);

      x2=r*Cos(é);y2=r*Sin(é);z2=0;
      DCTransform(dc,&x2,&y2,&z2);

      GrLine(dc,x1,y1,tmpb->x-x+x2,tmpb->y-y+y2);
    }
    GrCircle(dc,tmpb->x,tmpb->y,r);
    tmpb=tmpb->last;
  }
  while (tmpb!=&head) {
    dc->color=LTBLUE;
    GrCircle(dc,tmpb->x,tmpb->y,tmpb->radius);
    dc->color=LTGRAY;
    GrCircle(dc,tmpb->x+0.65*tmpb->radius*Cos(5*ã/8),
	  tmpb->y-0.65*tmpb->radius*Sin(5*ã/8),1.0+0.2*tmpb->radius);
    tmpb=tmpb->last;
  }
  LBtr(&flags,0);
}

U0 AnimateTask(I64)
{
  CTask *task=Fs->parent_task;
  CBubble *tmpb,*tmpb1;
  F64 t_last=Beat,dt,tSpawn=0,é;

  while (TRUE) {
    dt=Beat-t_last;
    t_last=Beat;

    x+=2*Sin(Beat/3)*dt;
    y+=2*Sin(Beat/2)*dt;

    while (LBts(&flags,0))
      Yield;

    tSpawn+=dt;
    while (tSpawn>1.0) {
      tmpb=MAlloc(sizeof(CBubble));
      tmpb->x=x;
      tmpb->y=y;
      tmpb->dx=0;
      tmpb->dy=0;
      tmpb->radius=Rand*6+4;
      tmpb->t0=Beat;
      QueIns(tmpb,head.last);
      tSpawn-=Rand;
    }

    é=Windé;
    tmpb=head.next;
    while (tmpb!=&head) {
      tmpb1=tmpb->next;

      tmpb->dx+=25*dt*(Rand-0.5);
      tmpb->dy+=25*dt*(Rand-0.5);
      tmpb->x += dt*(20*Cos(é)+tmpb->dx);
      tmpb->y +=-dt*(20*Sin(é)+tmpb->dy);

      if (!(0<=tmpb->x<task->pix_width) ||
	    !(0<=tmpb->y<task->pix_height) ) {
	QueRem(tmpb);
	Free(tmpb);
      }

      tmpb=tmpb1;
    }

    LBtr(&flags,0);
    Sleep(20);
  }
}

U0 Init()
{
  flags=0;
  QueInit(&head);
  t0=Beat;
  x=360; y=52;
}

U0 CleanUp()
{
  QueDel(&head);
}

U0 Song()
{
  CTask *task;
  SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
  Init;
  Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
  Fs->draw_it=&DrawIt;
  Fs->task_end_cb=&SndTaskEndCB;
  MusicSettingsRst;
  music.tempo= 2.480;
  music.stacatto_factor= 0.902;
  try {
    task=PopUpViewPrint("$LK,"Romans,8:28",A="BF:Romans,8:28"$\n");
    TaskWait(task);
    WinHorz(Fs->win_left,TEXT_COLS-10,task);
    WinVert(Fs->win_bottom+3,Fs->win_bottom+15,task);
    while (!ScanKey) {
      Play("5qEE4BeB5D4sBBBB5qD4sB5F4B5FD4G5D4G",
	    "Free\0will...\0\0\0\0\0\0\0\0\0"
	    "I\0\0\0\0fail.\n\0\0\0\0");
      Play("5qEE4BeB5D4sBBBB5qD4sB5F4B5FD4G5D4G",
	    "God\0still...\0\0\0\0\0\0\0\0\0"
	    "I\0\0\0\0hail.\n\0\0\0\0");
      Play("5qD4GeAG5qCetEC4AqBsA5C4A5C4qA",
	    "All\0things\0work\0for\0good...\0"
	    "to\0the\0Lord.\n\0\0\0\0\0\0\0");
      Play("5D4GeAG5qCetEC4AqBsA5C4A5C4qA",
	    "It's\0all\0good...\0\0\0as\0\0sured.\n\0\0\0\0\0\0\0");
    }
  } catch
    PutExcept;
  SettingsPop;
  CleanUp;
}

Song;
