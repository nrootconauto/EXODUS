U0 WinDerivedValsUpdate(CTask *task)
{//Those things calculated from other variables.
  if (!task) task=Fs;
  Bool old;
  //Assert: This is called with TASKf_TASK_LOCK set
  PUSHFD
  old=!Bts(&(Fs->task_flags),TASKf_BREAK_LOCKED); 
  task->win_width =task->win_right-task->win_left+1;
  task->win_height=task->win_bottom-task->win_top+1;
  task->pix_left	=FONT_WIDTH*task->win_left;
  task->pix_right	=FONT_WIDTH*(task->win_right+1)-1;
  task->pix_width	=task->pix_right-task->pix_left+1;
  task->pix_top		=FONT_HEIGHT*task->win_top;
  task->pix_bottom	=FONT_HEIGHT*(task->win_bottom+1)-1;
  task->pix_height	=task->pix_bottom-task->pix_top+1;
  if(old)
	BreakUnlock;
  POPFD
}

Bool WinInside(I64 x,I64 y,CTask *task=NULL,I64 border=0)
{//Is pixel (x,y) inside task's win? Border to FONT_WIDTH.
  if (!task) task=Fs;
  if (TaskValidate(task) && Bt(&task->display_flags,DISPLAYf_SHOW)) {
    if (Bt(&task->display_flags,DISPLAYf_NO_BORDER))
      border=0;
    if (task->pix_left-border<=x<=task->pix_right+border &&
	  task->pix_top-border<=y<=task->pix_bottom+border)
      return TRUE;
  }
  return FALSE;
}
