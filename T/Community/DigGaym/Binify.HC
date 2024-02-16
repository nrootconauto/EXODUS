class CBinBlob:CQue {
  I64 sz,w,h;
  U8 *data,*name;
};
U0 BinifyPx()
{
  //
  // Chunks have this format
  //  
  // U8 name[];
  // I64 w,h;
  // U8 data[w*h]
  U8 *ln,n1[STR_LEN],n2[STR_LEN],*poo,*ptr,*ptr2;
  U8 byte;
  CHashGeneric *gen;
  I64 cnt,total=0,cnts2;
  CBinBlob *chunks=CAlloc(sizeof CBinBlob),*cchunk;
  QueInit(chunks);
  CDirEntry *ents=FilesFind("Px/*.HC",FUF_RECURSE|FUF_FLATTEN_TREE),*cur;
  for(cur=ents;cur;cur=cur->next) { 
    if(!IsDir(cur->full_name)) {
      ln=DocLineRead(cur->full_name,1);
      if(StrMatch("#include \"PxBlot\"",ln)) {
        Free(ln);
        cchunk=CAlloc(sizeof CBinBlob);
        ln=DocLineRead(cur->full_name,2);
        poo=n1;
        ptr=StrScan(ln,"U8 %s[%d]%s{",&poo,&cchunk->sz,&poo);
        cchunk->data=MAlloc(cchunk->sz);
        for(cnt=0;cnt!=cchunk->sz;cnt++) {
          cchunk->data[cnt]=Str2I64(ptr,10,&ptr);
          if(*ptr==',')
            ptr++;
        }
        Free(ln);
        ln=DocLineRead(cur->full_name,3);
        poo=n1;
        ptr=StrScan(ln,"PxData %s={%d,%d",&poo,&cchunk->w,&cchunk->h);
        cchunk->name=StrNew(n1);
        QueInit(cchunk);
        QueIns(cchunk,chunks->last);
        total+=2*sizeof(I64)+StrLen(cchunk->name)+1+cchunk->sz;
      }
      Free(ln);
    }
  }
  DirEntryDel(ents);
  ptr=MAlloc(total);
  ptr2=ptr;
  cnt=0;
  for(cchunk=chunks->next;cchunk!=chunks;cchunk=cchunk->next) {
    StrCpy(ptr2,cchunk->name);
    poo=MStrPrint("%s:IDX",cchunk->name);
    FramePtrAdd(poo,cnt++);
    Free(poo);
    ptr2+=StrLen(ptr2)+1;
    ptr2(I64*)[0]=cchunk->w;
    ptr2(I64*)[1]=cchunk->h;
    ptr2+=16;
    if(ptr+total<ptr2) throw('binify');
    MemCpy(ptr2,cchunk->data,cchunk->sz);
    ptr2+=cchunk->sz;
    Free(cchunk->name);
    Free(cchunk->data);

  }
  if(ptr+total!=ptr2) throw('binify');
  QueDel(chunks);
  FileWrite("PX.BIN",ptr,total);
  Free(ptr);
}
class CBinBlob2:CQue {
  I64 sz,w,h;
  U8 *name;
  I16 *px_data;
  U8 *flags_data;
  U8 *types_data;
  U8 *hp_data;
  I64 spawner_cnt;
  CD2I32 *spawner_data;
  I64 spawn_x,spawn_y;
};

U0 BinifyLevels() {
  // Has format
  // U8 name[]
  // I64 sz;
  // I16 px_indexes[]
  // U8 flag[]
  // U8 types[]
  // U8 hp[]
  // I64 spawner_cnt
  // CD2I32 spawner_data
  // I64 w,h;
  // I64 spawn_x
  // I64 spawn_y;
  //
  U8 *name,byte,*ln,*ptr,n1[STR_LEN],*poo,*ptr2;
  I64 x,y,dim,cnt,total=0;
  CDirEntry *ents=FilesFind("Levels/*.HC",FUF_RECURSE|FUF_FLATTEN_TREE),*cur;
  CHashGeneric *gen;
  CBinBlob2 *head=CAlloc(sizeof CBinBlob2),*cur_chunk;
  QueInit(head);
  for(cur=ents;cur;cur=cur->next) {
    if(!IsDir(cur->full_name)) {
      ln=DocLineRead(cur->full_name,3);
      if(StrMatch("#include \"Map\"",ln)) {
        Free(ln);
        ln=DocLineRead(cur->full_name,4);
        poo=n1;
        ptr=StrScan(ln,"PxData *%s[%d]={",&poo,&dim);
        cur_chunk=CAlloc(sizeof CBinBlob2);
        cur_chunk->sz=dim;
        cur_chunk->px_data=MAlloc(sizeof(U16)*dim);
        for(cnt=0;cnt!=dim;cnt++) {
          if(*ptr=='0') {
            cur_chunk->px_data[cnt]=-1;
            ptr++;
          } else if(*ptr=='&') {
            ptr++;
            poo=n1;
            while(Bt(char_bmp_alpha_numeric,*ptr))
              *poo++=*ptr++; 
            *poo=0;
            ptr2=MStrPrint("%s:IDX",n1);
            cur_chunk->px_data[cnt]=FramePtr(ptr2);           
            Free(ptr2);
          } else{
            "%d,%c\n",dim,*ptr;
            throw('Inv');
          }
          if(*ptr==',') ptr++;
        }
        Free(ln);
        ln=DocLineRead(cur->full_name,5);
        cur_chunk->flags_data=MAlloc(dim);
        ptr=StrFirstOcc(ln,"{")+1;
        for(cnt=0;cnt!=dim;cnt++) {
          cur_chunk->flags_data[cnt]=Str2I64(ptr,10,&ptr);
          if(*ptr==',') ptr++;
        }
        Free(ln); 
        ln=DocLineRead(cur->full_name,6); 
        cur_chunk->types_data=MAlloc(dim);
        ptr=StrFirstOcc(ln,"{")+1;
        for(cnt=0;cnt!=dim;cnt++) {
          cur_chunk->types_data[cnt]=Str2I64(ptr,10,&ptr);
          if(*ptr==',') ptr++;
        }
        Free(ln);
        ln=DocLineRead(cur->full_name,7); 
        cur_chunk->hp_data=MAlloc(dim);
        ptr=StrFirstOcc(ln,"{")+1;
        for(cnt=0;cnt!=dim;cnt++) {
          cur_chunk->hp_data[cnt]=Str2I64(ptr,10,&ptr);
          if(*ptr==',') ptr++;
        }
        Free(ln);
        ln=DocLineRead(cur->full_name,8); 
        poo=n1;
        ptr=StrScan(ln,"CD2I32 %s[%d]={",&poo,&dim);
        cur_chunk->spawner_cnt=dim;
        cur_chunk->spawner_data=MAlloc(dim*sizeof(CD2I32));
        for(cnt=0;cnt!=dim;cnt++) {
          ptr=StrScan(ptr,"{%d,%d}",&x,&y);
          cur_chunk->spawner_data[cnt].x=x;
          cur_chunk->spawner_data[cnt].y=y;
          if(*ptr==',') ptr++;
        }
        Free(ln);
        ln=DocLineRead(cur->full_name,9);
        poo=n1;
        StrScan(ln,"MapTemplate %s={%d,%d",&poo,&x,&y);
        cur_chunk->w=x,cur_chunk->h=y;
        cur_chunk->name=StrNew(n1);
        ptr=StrMatch("}};",ln);
        while(*ptr!='{') ptr--;
        StrScan(ptr,"{%d,%d}",&x,&y);
        QueInit(cur_chunk);
        QueIns(cur_chunk,head->last);
        cur_chunk->spawn_x=x;
        cur_chunk->spawn_y=y;
        //tiles are 2 bytes,hp+flags+types(2+1+1+1)
        total+=StrLen(cur_chunk->name)+1+cur_chunk->sz*(2+1+1+1)+8+8+8+8+8+8+dim*sizeof(CD2I32);
      }
      Free(ln);
    }
  }
  DirEntryDel(ents);
  ptr2=ptr=MAlloc(total);
  for(cur_chunk=head->next;cur_chunk!=head;cur_chunk=cur_chunk->next) {
    if(ptr2>total+ptr) throw('onion');
    StrCpy(ptr2,cur_chunk->name);
    ptr2+=StrLen(cur_chunk->name)+1;
    *ptr2(I64*)++=dim=cur_chunk->sz;
    MemCpy(ptr2,cur_chunk->px_data,2*dim);
    ptr2+=2*dim;
    MemCpy(ptr2,cur_chunk->flags_data,dim);
    ptr2+=dim;
    MemCpy(ptr2,cur_chunk->types_data,dim);
    ptr2+=dim;
    MemCpy(ptr2,cur_chunk->hp_data,dim);
    ptr2+=dim;
    *ptr2(I64*)++=dim=cur_chunk->spawner_cnt;
    MemCpy(ptr2,cur_chunk->spawner_data,dim*sizeof(CD2I32));
    ptr2+=dim*sizeof(CD2I32);
    *ptr2(I64*)++=cur_chunk->w;
    *ptr2(I64*)++=cur_chunk->h;
    *ptr2(I64*)++=cur_chunk->spawn_x;
    *ptr2(I64*)++=cur_chunk->spawn_y;
    "WROTE %s,%d\n",cur_chunk->name,dim;
  }
  FileWrite("LEVELS.BIN",ptr,total);
  Free(ptr);
}
U0 Binify() {
  BinifyPx;
  BinifyLevels;
} 