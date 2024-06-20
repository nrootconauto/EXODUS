U0 DumpOnDead() {
  I64 sz;
  U8 *dump=DocSave(DocPut,&sz);
  U8 *par_dump=MAlloc(sz,Fs->parent_task);
  MemCpy(par_dump,dump,sz);
  FramePtrAdd("PIPE",par_dump,Fs->parent_task);
  Free(dump);
  Exit;
}
U8 *Pipe(U8 *str) {
  CTask *child=Spawn(&UserCmdLine,NULL,NULL,,Fs);
  BirthWait(&child);
  XTalk(child,"Fs->task_end_cb=&DumpOnDead;\n%s;\nExit;\n",str);
  DeathWait(&child);
  return FramePtr("PIPE");
}
"======[DUMP]======\n%s\n",Pipe("Dir;");