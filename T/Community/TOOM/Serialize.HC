U8 *UH(U8 *name,U8 *ptr) {
  U8 buf[STR_LEN];
  StrPrint(buf,"Unique.%s",name);
  FramePtrAdd(buf,ptr);
  return ptr;
}
//This can be purged at across levels
U8 *UH2(U8 *name,U8 *ptr) {
  return ptr;
}
U0 PurgeUH2() {
  CHashTable *tab=Fs->hash_table;
  CHashGeneric *tmph,*tmph2;
  I64 bucket;
  for(bucket=0;bucket<=tab->mask;bucket++) {
    for(tmph=tab->body[bucket];tmph;tmph=tmph2) {
	tmph2=tmph->next;
	if(!StrNCmp("Unique2.",tmph->str,8))
	  HashRemDel(tmph,tab);
    }
  }
}