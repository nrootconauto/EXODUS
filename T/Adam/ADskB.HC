#help_index "File/Cmd Line (Typically);Cmd Line (Typically)"
public I64 FF(U8 *files_find_mask,U8 *fu_flags=NULL)
{//Files find. List files matching mask.
  I64 cnt=0,fuf_flags=0;
  CDirEntry *tmpde,*tmpde1;
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),"+r+f+F");
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);
  tmpde=tmpde1=FilesFind(files_find_mask,fuf_flags);
  while (tmpde) {
    PutFileLink(tmpde->full_name);
    '\n';
    cnt++;
    tmpde=tmpde->next;
  }
  DirTreeDel(tmpde1);
  return cnt;
}
public I64 Zip(U8 *files_find_mask="*",U8 *fu_flags=NULL)
{//Compress files by moving to .Z filename.
  U8 *st;
  CDirEntry *tmpde,*tmpde1;
  I64 res=0,fuf_flags=0;
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),"+r+f+F+O");
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);
  tmpde=tmpde1=FilesFind(files_find_mask,fuf_flags);
  while (tmpde) {
    if (!IsDotZ(tmpde->full_name)) {
      st=MStrPrint("%s.Z",tmpde->full_name);
      res+=Move(tmpde->full_name,st);
      Free(st);
    }
    tmpde=tmpde->next;
  }
  DirTreeDel(tmpde1);
  return res;
}

public I64 Unzip(U8 *files_find_mask="*.Z",U8 *fu_flags=NULL)
{//Uncompress files by moving to not .Z filename.
//You don't have to do this for normal operation.
  //It automatically unzips ".Z" files.
  U8 *st;
  CDirEntry *tmpde,*tmpde1;
  I64 res=0,fuf_flags=0;
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),"+r+f+F+O");
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);
  tmpde=tmpde1=FilesFind(files_find_mask,fuf_flags);
  while (tmpde) {
    if (IsDotZ(tmpde->full_name)) {
      st=StrNew(tmpde->full_name);
      StrLastRem(st,".");
      res+=Move(tmpde->full_name,st);
      Free(st);
    }
    tmpde=tmpde->next;
  }
  DirTreeDel(tmpde1);
  return res;
}
