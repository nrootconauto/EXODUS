U0SelCopy(CDirEntry *head,U8 *to,I64 argc,U8 **exclude) {
  CDirEntry *c_ent=head;
  U8 *to2,*data;
  I64 i,len;
  if(!FileFind(to))
    DirMk(to);
  while(c_ent) {
    for(i=0;i!=argc;i++) {
      if(!StrCmp(exclude[i],c_ent->full_name))
        goto next;
    }
    if(c_ent->sub){
      SelCopy(c_ent->sub,to2=MStrPrint("%s/%s",to,c_ent->name),argc,exclude);
    } else if(!IsDir(c_ent->full_name)&&c_ent->name[0]!='.') {
      to2=MStrPrint("%s/%s",to,c_ent->name);
      if(FileFind(to2)) {
        "Repeat file %s,Aborting\n",to2;
        throw('Repeat');
      }
      data=FileRead(c_ent->full_name,&len);
      FileWrite(to2,data,len);
      Free(data);
      Free(to2);
    }
    next:
    c_ent=c_ent->next;
  }
}
// This file will find all the files exlcuding some directories
// you dont want,it will then compress them for you after moving
// them to a specified directory
U0 ReleasePackage(U8 *to,...) {
  I64 i;
  CDirEntry *ents;
  U8 **argv2=MAlloc((argc+1)*sizeof(U8*)),*all; //includes directory we are writing to
  for(i=0;i!=argc;i++)
    argv2[i]=FileNameAbs(argv[i]);
  argv2[i]=FileNameAbs(to);
  DelTree(all=MStrPrint("%s/*",to)); //Delete files in dirs
  DelTree(to); //Delete dirs
  Free(all);
  ents=FilesFind("/*",FUF_RECURSE);
  SelCopy(ents,to,argc+1,argv2);
  DirTreeDel(ents);
  for(i=0;i!=argc+1;i++)
    Free(argv2[i]);
  Free(argv2);
}
Cd("T:/");
ReleasePackage("T","Offical","Greek","SmallTalk","TempleOS.ISO");
Cd("/");
Cmp("FULL_PACKAGE.HC","HCRT.DBG.Z","HCRT.BIN");
Exit;
