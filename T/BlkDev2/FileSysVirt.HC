U0 VirtInit(CDrv *dv)
{
  Bool unlock;
  try {
    unlock=DrvLock(dv);
     dv->fs_type=FSt_VIRT;
    if (unlock)
      DrvUnlock(dv);
  } catch
    if (unlock)
      DrvUnlock(dv);
}

Bool VirtFileFind(CDrv *dv,U8 *cur_dir,U8 *name,
	CDirEntry *_res,I64 fuf_flags=0)
{//$LK,"FUF_JUST_DIRS",A="MN:FUF_JUST_DIRS"$, $LK,"FUF_JUST_FILES",A="MN:FUF_JUST_FILES"$
  CDirEntry *buf,*buf2,*ptr;
  U8 dname[CDIR_FILENAME_LEN];
  I64 ch;
  Bool res=FALSE,unlock;
  U8 *vfs_pwd,*at;
  if (fuf_flags&~FUG_FILE_FIND)
    throw('FUF');
  MemSet(_res,0,sizeof(CDirEntry));
  DrvChk(dv);
  if (dv->fs_type!=FSt_VIRT)
    PrintErr("Not Virt Drv\n");
  else if (!CFileNameTo(dname,name))
    PrintErr("Invalid FileName: \"%s\".\n",name);
  else
    try {
      unlock=DrvLock(dv);
      VFsSetDrv(dv->drv_let);
      VFsSetPwd(cur_dir);
      at=name;
      if(VFsFExists(at)) {
        StrCpy(_res->name,name);
        res=TRUE;
        if(VFsIsDir(at))
          _res->attr|=RS_ATTR_DIR;
        if(IsDotZ(at))
          _res->attr|=RS_ATTR_COMPRESSED;
        if(fuf_flags&FUF_JUST_DIRS&&!VFsIsDir(at))
          res=FALSE;
        if(fuf_flags&FUF_JUST_FILES&&VFsIsDir(at))
          res=FALSE;
        _res->size=VFsFSize(at);
        _res->datetime=Unix2CDate(FUnixTime(at));
      }
      if (unlock)
	DrvUnlock(dv);
    } catch
      if (unlock)
	DrvUnlock(dv);
  return res;
}

U8 *VirtFileRead(CDrv *dv,U8 *cur_dir,U8 *filename,I64 *_size,I64 *_attr)
{
  U8 *buf=NULL;
  CDirEntry de;
  I64 c,blk_cnt,cur_dir_clus;
  U8 *old;
  DrvChk(dv);
  *_size=0;
  *_attr=0;
  if (dv->fs_type!=FSt_VIRT)
    PrintErr("Not Virt Drv\n");
  else
    try {
      DrvLock(dv);
      if (VirtFileFind(dv,cur_dir,filename,&de,FUF_JUST_FILES)) {
	blk_cnt=(de.size+BLK_SIZE-1)>>BLK_SIZE_BITS;
        VFsSetDrv(dv->drv_let);
	VFsSetPwd(cur_dir);
	buf=VFsFRead(de.name,&de.size);
	*_size=de.size;
	*_attr=FileAttr(de.name,de.attr);
      }
      DrvUnlock(dv);
    } catch
      DrvUnlock(dv);
  return buf;
}

Bool VirtCd(U8 *name,U8 *cur_dir)
{
  CDirEntry de;
  if (Fs->cur_dv->fs_type!=FSt_VIRT)
    PrintErr("Not Virt Drv\n");
  else if (VirtFileFind(Fs->cur_dv,cur_dir,name,&de,FUF_JUST_DIRS))
    return TRUE;
  else
    PrintErr("File not found: \"%s\".\n",name);
  return FALSE;
}

I64 VirtFilesDel(CDrv *dv,U8 *cur_dir,U8 *files_find_mask,I64 fuf_flags,
		     Bool del_dir,Bool print_msg)
{
  CDirEntry buf,*ptr=&buf;
  I64 i=0,res=0,ch,j=0,n=BLK_SIZE/CDIR_SIZE,cur_dir_clus;
  U8 **dirs;
  Bool unlock_break;
  try {
    unlock_break=BreakLock;
    DrvLock(dv);
    VFsSetDrv(dv->drv_let);
    VFsSetPwd(cur_dir);
    dirs=VFsDir;
    for(i=0;dirs[i];i++) {
	  VirtFileFind(dv,cur_dir,dirs[i],ptr,);
          VFsSetDrv(dv->drv_let);
	  VFsSetPwd(cur_dir);
	  if((del_dir||!VFsIsDir(dirs[i]))&&dirs[i][0]!='.'&&
	    FilesFindMatch(ptr->name,files_find_mask,fuf_flags)) {
	    if (print_msg)
	      "Del %s\n",ptr->name;
	    res++;
        VFsDel(dirs[i]);
	  }
      Free(dirs[i]);
    }
    Free(dirs);
    DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  } catch {
    DrvUnlock(dv);
    if (unlock_break)
      BreakUnlock;
  }
  return res;
}

I64 VirtFileWrite(CDrv *dv,U8 *cur_dir,U8 *name,U8 *buf,I64 size,
	CDate cdt,I64 attr)
{
  CDirEntry de;
  I64 c=0,blk_cnt;
  MemSet(&de,0,sizeof(CDirEntry));
  if (size<0) size=0;
  if (dv->fs_type!=FSt_VIRT)
    PrintErr("Not Virt Drv\n");
  else if (!CFileNameTo(de.name,name))
    PrintErr("Invalid FileName: \"%s\".\n",name);
  else {
    VirtFilesDel(dv,cur_dir,de.name,0,FALSE,FALSE);
    VFsSetDrv(dv->drv_let);
    VFsSetPwd(cur_dir);
    c=VFsFWrite(name,buf,size);
  }
  return c;
}

CDirEntry *VirtFilesFind(U8 *files_find_mask,I64 fuf_flags,
	CDirEntry *parent=NULL)
{
  CDrv *dv=Fs->cur_dv;
  CDirEntry *buf,*buf2,*ptr,*res=NULL,*tmpde;
  I64 i;
  U8 **dirs;
  if (fuf_flags&~FUG_FILES_FIND)
    throw('FUF');
  try {
    DrvLock(dv);
    VFsSetDrv(dv->drv_let);
    VFsSetPwd(Fs->cur_dir);
    dirs=VFsDir;
    for (i=0;dirs[i];i++) {
      tmpde=CAlloc(sizeof(CDirEntry));
      VirtFileFind(Fs->cur_dv,Fs->cur_dir,dirs[i],tmpde,0);
      tmpde->parent=parent;
      if (Bt(&fuf_flags,FUf_RECURSE) && tmpde->attr&RS_ATTR_DIR &&
	    *tmpde->name!='.') {
        tmpde->next=res;
        res=tmpde;
        tmpde->full_name=DirNameAbs(tmpde->name);
        DrvUnlock(dv);
        if (Cd(tmpde->name)) {
	  tmpde->sub=VirtFilesFind(files_find_mask,fuf_flags,tmpde);
	  Cd("..");
        }
        DrvLock(dv);
      } else {
        tmpde->full_name=FileNameAbs(tmpde->name);
        if ((tmpde->attr&RS_ATTR_DIR ||
	      !Bt(&fuf_flags,FUf_JUST_DIRS)) &&
	      !(Bt(&fuf_flags,FUf_RECURSE) && *tmpde->name=='.' &&
	      tmpde->attr&RS_ATTR_DIR) &&
	      FilesFindMatch(tmpde->full_name,files_find_mask,fuf_flags)) {
	  tmpde->next=res;
	  res=tmpde;
        } else
	  DirEntryDel(tmpde);
      }
      Free(dirs[i]);
    }
    Free(dirs);
    DrvUnlock(dv);
  } catch
    DrvUnlock(dv);
  return res;
}

Bool VirtMkDir(CDrv *dv,U8 *cur_dir,U8 *name,I64 entry_cnt)
{//entry_cnt is for preallocating dir blks.
  I64	c;
#assert CDIR_SIZE==64
  Bool unlock_break;
  try {
    unlock_break=BreakLock;
    VFsSetDrv(dv->drv_let);
    VFsSetPwd(cur_dir);
    VFsDirMk(name);
    if (unlock_break)
      BreakUnlock;
  } catch
    if (unlock_break)
      BreakUnlock;
  return TRUE;
}
