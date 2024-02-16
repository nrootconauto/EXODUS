U0 TouchAll() {
  DelTree(WIKI_BACKUP);
  CDirEntry *root=FilesFind(WIKI_ROOT,FUF_RECURSE|FUF_JUST_FILES|FUF_FLATTEN_TREE);
  CDirEntry *cur;
  U8 *to_trim=FileNameAbs(WIKI_ROOT),*ftxt;
  I64 len;
  for(cur=root;cur;cur=cur->next) {
    ftxt=FileRead(cur->full_name,&len);
    BackupFile(cur->full_name+StrLen(to_trim),ftxt,len,"root","c");
    Free(ftxt);
  }
  DirEntryDel(root);
}