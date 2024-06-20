#ifndef SERVER_H
#define SERVER_H
#define USE_UDP
#ifdef USE_UDP
CUDPAddr *UDPAddrClone(CUDPAddr *a,CTask *mem_task=NULL) {
  CUDPAddr *ret=MAllocIdent(a,mem_task);
  ret->host=StrNew(a->host,mem_task);
  return ret;
}
#endif
/*
   ___           _     _           ___ 
  / _ \_   _ ___| |__ (_)_ __     / _ \
 / /_)/ | | / __| '_ \| | '_ \   / /_)/
/ ___/| |_| \__ \ | | | | | | | / ___/ 
\/     \__,_|___/_| |_|_|_| |_| \/     
                                    
*/
/*
 * Listen up $BK,1$IDs always have bit 0 set(rest of bits are number)$BK,0$ Pointers are always aligned to 8 
 */
#define ID_MASK 0x1ffFF
#define PTR_2_ID_FMT "Id_Ptr.%x"
#define ID_RELOC_FMT "Reloc.%d"

I64 class CHashPair {
  I32 id;
  U32 hash;
};

U8 *UDPAddrToStr(CUDPAddr *a) {
  return MStrPrint("%s:%d\n",a->host,a->port);
}

class CServerThing:CQue {
//len is the size of the self
  U64 rand_seed;
  U32 frame;
#define SRV_THINGF_TO_DELETE 1
  I32 thing_flags;
  I32 id;
  U8 class_name[44];
};



class COutgoing:CQue {
  I64 last_frame; 
  I64 user_data;
  I64 id_cnt;
  CHashPair *valid_ids; 
  union {
    CUDPAddr *to;
    I64 accept;
  };
  I64 read_cnt;
  U8 *read_data;
};

class CServerMsg {
  U64 type;
  U32 len;
#define MESSAGEF_SEND_ACK 1
  U32 msg_flags;
  I64 last_ms;
  U64 msg_hash;
  U0 msg_body[0];
};

I64 HashServerMsg(CServerMsg *msg) {
  I64 hash=5981,old_hash=msg->msg_hash;
  I64 cnt=msg->len;
  msg->msg_hash=0;
  while(--cnt>=0) {
    hash=hash<<5+hash+msg(U8*)[cnt];
  }
  msg->msg_hash=old_hash;
  return hash;
}

Bool ValidateServerMsg(CServerMsg *msg) {
  return msg->msg_hash==HashServerMsg(msg);
}

class CAskThing:CServerMsg {
  I64 id;
};

class CRecieveThings:CServerMsg {
  I64 cnt;
};

class CMessagePass:CServerMsg {
  U8 message_name[32];
  I64 message_sz;
  I32 src_id,dst_id;
  U8 body[0];
};

class CHashesMsg:CServerMsg {
  I64 cnt;
  CHashPair body[0];
};

//These are for SRV_CODE_GET_UPDATES,These are put in an array and send over
//  after being CompressBuf'ed 
class CRecieveThing:CQue {
  I64 id,len;
  Bool remove;
  U8 body[0];
};

//Next things get sent
#define SRV_CODE_SEND_MESSAGE 'Message'
#define SRV_CODE_SEND_HASHES 'Hashes'
#define SRV_CODE_GET_UPDATES 'Updates'
#define SRV_CODE_HELLO 'Hello'
//This is used by MESSAGEF_SEND_ACK
//It will keep firing the message until it recieves an SRC_CODE_ACK
//(Used for ensuring important messages get sent)
#define SRV_CODE_ACK 'Ack' //Sends back hash of message

class CServer {
#define SERV_MODE_SERVER 1
#define SERV_MODE_CLIENT 2
  CTask *mem_task;
  I64 id_num;
  I64 frame_cnt;
  I32 init_ms;
  I32 last_ms;
  I64 last_response;
  CQue things;
//Used in Server mode
  CQue clients;
  union {
    I64 client_sock;
    I64 server_sock;
  };
  CHashTable *hash_table;
union {
  CUDPAddr *write_to;
  I64 write_to_sock;
};
  U0 (*idle)(CServer *);
  CTask *read_task;
  CTask *server_task;
  CServerThing *id_map[0x10000];
  I64 lock;
  I32 mode;
  U8 no_yield;
  U8 pad[2];
};
U0 ServerThingDel(CServer *s,CServerThing *thing) {
  thing->thing_flags|=SRV_THINGF_TO_DELETE;
}
U0 ServerWrite(CServer *s,U8 *buf,I64 len) {
#ifdef USE_UDP
  NetUDPSendTo(s->server_sock,buf,len,s->write_to);
#else
  while(-1==NetPollForWrite(1,&s->write_to_sock))
    Yield;
  NetWrite(s->write_to_sock,buf,len);
#endif
}

#ifdef USE_UDP
COutgoing *UDPAddrToClient(CServer *s,CUDPAddr *a) {
  COutgoing *og,*head=&s->clients;
  for(og=head->next;og!=head;og=og->next) {
    if(s->mode==SERV_MODE_CLIENT)
      return og;
    if(og->to->port==a->port)
      if(!StrCmp(a->host,og->to->host))
        return og;
  }
  og=CAlloc(sizeof(COutgoing),s->mem_task);
  og->to=UDPAddrClone(a);
  QueIns(og,&s->clients);
  return og;
}

U0 UDPReadCallback(CServer *s,U8 *poofer,I64 len,CUDPAddr *addr) {
  COutgoing*og=UDPAddrToClient(s,addr);
  U8 *buf=MAlloc(og->read_cnt+len,s->mem_task);
  while(LBts(&s->lock,0)) {
    if(!TaskValidate(s->mem_task))
      Exit;
    Yield;
  }
  MemCpy(buf+og->read_cnt,poofer,len);
  if(og->read_cnt)
    MemCpy(buf,og->read_data,og->read_cnt);
  Free(og->read_data);
  og->read_data=buf;
  og->read_cnt+=len;
  LBtr(&s->lock,0);
}

#endif

U0 ServerAdjust_tS(CServer *s,I64 ms) {
//TODO adjust init_ms lag compenstation???
  s->init_ms=ms;
  s->last_response=__GetTicks;
}


Bool ServerRead(CServer *s,U8 *to,I64 _len,Bool optional=FALSE,F64 timeout=0.035) {
#ifdef USE_UDP
  F64 to_ts=tS+timeout;
  CUDPAddr *from;
  I64 len;
  U8 *buf,poofer[0x10000];
  COutgoing *og;
  while(TRUE) {
      if(s->write_to) {
        og=UDPAddrToClient(s,s->write_to);
        if(og->read_cnt>=_len) {
          goto fin;
       }
      }
      if(optional)
	return FALSE;
      if(timeout>=0.&&tS>=to_ts)
        return FALSE;
      og=NULL;
      if(!s->no_yield)
        Sleep(1);
    }
fin:
  while(LBts(&s->lock,0))
    ;
  MemCpy(to,og->read_data,_len);

  og->read_cnt-=_len;
  buf=MAlloc(og->read_cnt,s->mem_task);
  MemCpy(buf,og->read_data+_len,og->read_cnt);
  Free(og->read_data);
  og->read_data=buf;
  LBtr(&s->lock,0);

  return TRUE;
#else
  F64 to_ts=tS+timeout;
  if(optional&&-1==NetPollForRead(1,&s->write_to_sock))
    return FALSE;
/*  if(timeout>0) {
    while(-1==NetPollForRead(1,&s->write_to_sock)&&to_ts>tS)
      Yield;
    if(-1!=NetPollForRead(1,&s->write_to_sock))
      goto enter;
    return FALSE;
  }*/
enter:
  while(-1==NetPollForRead(1,&s->write_to_sock))
      Yield;
  NetRead(s->write_to_sock,to,_len);
  return TRUE;
#endif
}


//
// Forwards
// 
extern U0 ServerCleanupDead(CServer *server);
extern U0 _ServerThingDel(CServer *,CServerThing*);
extern Bool UpdateThing(CServer *s,CServerThing *dst,CServerThing *t,I64 sz);
extern I64 HashThing(CServer *s,CServerThing *t);
extern U0 LinkServerThings(CServer *s);
extern I64 ServerPtr2Id(CServer *s,U8 *ptr);
extern U8 *ServerId2Ptr(CServer *s,I64 id);
extern U8 *SerializeThing(CServer *s,CServerThing *t,I64 *sz);
extern CServerThing *UnserializeThing(CServer *s,U8 *buf,I64 sz);
extern Bool AddThingToServer(CServerThing *thing,CServer *server,I64 at=-1);
extern CServerMsg *ServerReadMsg(CServer *s,Bool optional=FALSE);

#define SERVER_DELAY 30
#define SERVER_TICK_TIME (1000/30)
F64 Server_tS(CServer *server) {
  F64 d=ToF64((__GetTicks-server->last_response)+server->init_ms)/JIFFY_FREQ;
  return d;
}

U0 ServerWriteMsg(CServer *s,CServerMsg *m) {
  I64 hash;
  COutgoing *og;
  U8 *unread,*new;
  I64 unread_sz=0;
  CServerMsg *ack;
  m->last_ms=__GetTicks;
  hash=m->msg_hash=HashServerMsg(m);
  ServerWrite(s,m,m->len);
  if(m->msg_flags&MESSAGEF_SEND_ACK) {
    unread=MAlloc(0,s->mem_task);
    do {
      ack=ServerReadMsg(s);
      if(ack&&(ack->type!=SRV_CODE_ACK||ack->msg_hash!=hash)) {
        new=MAlloc(unread_sz+ack->len,s->mem_task);
	MemCpy(new,unread,unread_sz);
	Free(unread);
	MemCpy(new+unread_sz,ack,ack->len);
	unread_sz+=ack->len;
        Free(ack);
	unread=new;
	Sleep(SERVER_DELAY/2);
        ServerWrite(s,m,m->len);
      } else
	break;
    } while(TRUE);
    Free(ack);
//Im making the assumption that all data is read through the above loop as 
//we have yet yo get the ACK request
//
// [old packets]->(SEND MSG HERE)->[non ACK]->[Yay,got an ACK]
//
    while(LBts(&s->lock,0))
      Yield;
    og=UDPAddrToClient(s,s->write_to);
    og->read_data=unread;
    og->read_cnt=unread_sz;
    LBtr(&s->lock,0);
  }
}

//Pseudo random number generator
#define LIN_CONGRUE_A	6364136223846793005
#define LIN_CONGRUE_C	1442695040888963407
I64 ClientPRNGI64(CServerThing *thing) {
  I64 res=thing->rand_seed;
  res=LIN_CONGRUE_A*res^(res&0xFFFFFFFF0000)>>16+LIN_CONGRUE_C;
  thing->rand_seed=res;
  return res;
}

U64 ClientRPNGU64(CServerThing *thing) {
  return ClientPRNGI64(thing);
}

U0 ClientSendHashes(CServer *s) {
  if(s->mode!=SERV_MODE_CLIENT) throw('Server');
  I64 len,cnt=QueCnt(&s->things);
  CServerThing *thing;
  len=sizeof(CHashesMsg)+cnt*sizeof(CHashPair);
  CHashesMsg *msg=CAlloc(len);
  msg->len=len;
  msg->type=SRV_CODE_SEND_HASHES;
  msg->last_ms=__GetTicks;
  msg->cnt=cnt;
  thing=&s->things;
  while(--cnt>=0) {
    thing=thing->next;
    msg->body[cnt].id=thing->id;
    msg->body[cnt].hash=HashThing(s,thing);
  }
  ServerWriteMsg(s,msg);
  Free(msg);  
}

U0 ClientPassMessageImportant(CServer *s,U8 *name,U8 *data,I64 cnt,I64 dst_id=-1,I64 src_id=-1) {
  CMessagePass *msg=CAlloc(sizeof(CMessagePass)+cnt);
  msg->type=SRV_CODE_SEND_MESSAGE;
  msg->len=sizeof(CMessagePass)+cnt;
  StrCpy(msg->message_name,name);
  msg->message_sz=cnt;
  msg->dst_id=dst_id;
  msg->src_id=src_id;
  msg->msg_flags=MESSAGEF_SEND_ACK;
  MemCpy(msg->body,data,cnt);
  ServerWriteMsg(s,msg);
  Free(msg);

}

U0 ClientPassMessage(CServer *s,U8 *name,U8 *data,I64 cnt,I64 dst_id=-1,I64 src_id=-1) {
  CMessagePass *msg=CAlloc(sizeof(CMessagePass)+cnt);
  msg->type=SRV_CODE_SEND_MESSAGE;
  msg->len=sizeof(CMessagePass)+cnt;
  StrCpy(msg->message_name,name);
  msg->message_sz=cnt;
  msg->dst_id=dst_id;
  msg->src_id=src_id;
  MemCpy(msg->body,data,cnt);
  ServerWriteMsg(s,msg);
  Free(msg);
}
U0 ServerPassMessageToClient(CServer *s,U8 *name,U8 *data,I64 cnt,I64 dst_id=-1,I64 src_id=-1) {
  ClientPassMessage(s,name,data,cnt,dst_id,src_id);
}

U0 ServerPassMessageToAllClients(CServer *s,U8 *name,U8 *data,I64 cnt,I64 dst_id=-1,I64 src_id=-1) {
#ifdef USE_UDP
  if(s->mode==SERV_MODE_CLIENT) return;
  CUDPAddr *old=s->write_to;
  COutgoing *cur,*head=&s->clients;
  for(cur=head->next;cur!=head;cur=cur->next) {
    s->write_to=cur->to;
    ServerPassMessageToClient(s,name,data,cnt,dst_id,src_id);
  }
  s->write_to=old;
#else
  if(s->mode==SERV_MODE_CLIENT) return;
  COutgoing *cur,*head=&s->clients;
  I64 old=s->write_to_sock;
  for(cur=head->next;cur!=head;cur=cur->next) {
    s->write_to_sock=cur->accept;
    ServerPassMessageToClient(s,name,data,cnt,dst_id,src_id);
  }
  s->write_to_sock=old;

#endif
}


CServerMsg *ServerReadMsg(CServer *s,Bool optional=FALSE) {
  CServerMsg msg,*buf=NULL;
  if(ServerRead(s,&msg,sizeof(CServerMsg),optional)) {
    if(msg.len>0x10000) goto fail;
    buf=MAlloc(msg.len);
    MemCpy(buf,&msg,sizeof(CServerMsg));
    if(msg.len>sizeof(CServerMsg)) {
      if(!ServerRead(s,buf+1,msg.len-sizeof(CServerMsg))) {
fail:
        Free(buf);
        return NULL;
      }
    }
    if(!ValidateServerMsg(buf))
	goto fail;
    if(s->mode==SERV_MODE_CLIENT)
      ServerAdjust_tS(s,buf->last_ms);
    return buf;
  }
  return NULL;
}

Bool ClientAskForUpdates(CServer *s) {
  if(s->mode!=SERV_MODE_CLIENT) throw('Server');
  ServerCleanupDead(s);
  Bool optional=FALSE,r=FALSE;
  U8 *buf,*obuf;
  I64 cnt,len;
  CServerThing *thing,*old_thing;
  CMessagePass *pass;
  CServerMsg *msg=CAlloc(sizeof(CServerMsg));
  ClientSendHashes(s);
  msg->type=SRV_CODE_GET_UPDATES;
  msg->len=sizeof(CServerMsg);
  msg->last_ms=__GetTicks;
  I64 ms2=__GetTicks;
  ServerWriteMsg(s,msg);
loop:
//will set optional after our first run
  Free(msg);
  if(!(msg=ServerReadMsg(s,optional))) {
    Free(msg);
    return r;
  }
  if(msg->type==SRV_CODE_GET_UPDATES) {
    cnt=msg(CHashesMsg*)->cnt;
    buf=msg(CHashesMsg*)+1;
    while(--cnt>=0) {
      thing=ServerId2Ptr(s,buf(CRecieveThing*)->id);
      if(buf(CRecieveThing*)->remove) {
        if(thing)
          ServerThingDel(s,thing);
      } else {
        old_thing=thing;
        if(thing&&UpdateThing(s,thing,buf(CRecieveThing*)->body,0))
          ; //all is good
        else if(thing=UnserializeThing(s,buf(CRecieveThing*)->body,0)) {
          if(old_thing) ServerThingDel(s,old_thing);
          AddThingToServer(thing,s,thing->id);
        }
      }
      buf+=buf(CRecieveThing*)->len;
    }
    LinkServerThings(s);
  } else if(msg->type==SRV_CODE_SEND_MESSAGE) {
      pass=msg;
        if(HashFind(pass->message_name,Fs->hash_table,HTT_FUN)) {
          CallExtStr(pass->message_name,s,pass);
        }
  } else if(msg->type==SRV_CODE_ACK) {
//Extra
  } else
   DbgPrint("UNKONWN:%c",msg->type);
  r=TRUE;
  optional=TRUE;
  goto loop;
}

U0 ServerKillCb() {
  CServer *s=FramePtr("Server");
  COutgoing *client,*head=&s->clients;
  NetClose(s->server_sock);
  Exit;
}
Bool OutgoingIdHashMatches(CServer *s,COutgoing *out,I64 id) {
  CServerThing *thing=ServerId2Ptr(s,id);
  I64 cnt=out->id_cnt;
  if(!thing) return FALSE;
  U32 hash=HashThing(s,thing)&0xffffFFFF;
  while(--cnt>=0) {
$ER$    if(out->valid_ids[cnt].id==id) {
      if(out->valid_ids[cnt].hash==hash)
        return TRUE;
    }
//valid_ids are sorted
    if(out->valid_ids[cnt].id<id)
      break;
  }
  return FALSE;  
}
Bool OutgoingHasId(COutgoing *out,I64 id) {
  I64 cnt=out->id_cnt;
  while(--cnt>=0) {
    if(out->valid_ids[cnt].id==id) return TRUE;
 }
  return FALSE;
}
Bool ServerHasId(CServer *server,I64 id) {
  if(server->id_map[id>>1])
    return TRUE;
  return FALSE;
}
I64 IdCompare(CHashPair a,CHashPair b) {
  return a.id-b.id;
}
U0 PassMessage(CServer *s,CMessagePass *pass) {
  CHashFun *fun=HashFind(pass->message_name,Fs->hash_table,HTT_FUN);
  if(!fun) return;
  if(fun->arg_cnt!=2) return;
  CallExtStr(pass->message_name,s,pass);
}
COutgoing *CurrentClient() {
  return FramePtr("Server@@Client");
}
class CServerNewPair {
  CNetAddr *addr;
  CTask *mem_task;
  CHashTable *use_htable;
};
#ifdef USE_UDP
U0 UDPOnRecvCbTask(CD3I64 *pair) {  
  U0 (*cb)(CServer *,U8*,I64,CUDPAddr*);
  cb=pair->y;
  CServer *s=pair->z;
  U8 buf[0x10000];
  I64 len;
  CUDPAddr *addr;
  Free(pair);
  while(TRUE) {
//client_sock and server_sock are in a union
    len=NetUDPRecvFrom(s->server_sock,buf,0x10000,&addr);
    Sleep(3);
    if(len!=-1) {
      (*cb)(s,buf,len,addr);
    }
    NetUDPAddrDel(addr);
  }
}
CTask *InstallUDPOnRecvCb(CServer *s,U0(*cb)(CServer *,U8*,I64,CUDPAddr*)) {
  CD3I64 *triple=MAlloc(sizeof CD3I64);
  triple->y=cb;
  triple->z=s;
  s->read_task=Spawn(&UDPOnRecvCbTask,triple,,mp_cnt-1);
}
#endif

U0 ServerCleanupDead(CServer *server) {
  CServerThing *thing,*head=&server->things,*next;
  for(thing=head->next;thing!=head;thing=next) {
    next=thing->next;
    if(thing->thing_flags&SRV_THINGF_TO_DELETE) {
      _ServerThingDel(server,thing);
    }
  }
}

U0 _ServerNew(CServerNewPair *pair) {
  I64 cnt,idx,len;
  U8 *buf,dumb[8],repeat;
  CQue blob_head;
  CServerThing *thing;
  CRecieveThing *recieve;
  CNetAddr *ul;
#ifdef USE_UDP
  CUDPAddr *from_client;
#endif
  CServer *server=CAlloc(sizeof CServer);
  CServerMsg msg;
  CServerMsg *got_msg=NULL;
  CRecieveThings recv_things;
  CHashesMsg *hashes;
  CMessagePass *pass;
  COutgoing *client,*next;
  Fs->task_end_cb=&ServerKillCb;
  Fs->hash_table->next=pair->use_htable;
  server->mem_task=pair->mem_task;
  server->server_task=Fs;
  server->mode=SERV_MODE_SERVER;
  server->frame_cnt=1;
  server->hash_table=HashTableNew(2048);
  QueInit(&server->things);
  QueInit(&server->clients);
#ifdef USE_UDP
  server->server_sock=NetUDPSocketNew;
  InstallUDPOnRecvCb(server,&UDPReadCallback);
#else
  server->server_sock=NetSocketNew;
#endif
  NetBindIn(server->server_sock,pair->addr);
#ifndef USE_UDP
  NetListen(server->server_sock,10);
#endif
  NetAddrDel(pair->addr);
  Free(pair);
  FramePtrAdd("Server",server);
  FramePtrAdd("Server@@Client",NULL);
  while(TRUE) {
    ServerCleanupDead(server);
    FramePtrSet("Server@@Client",NULL);
    LinkServerThings(server);
    if(server->idle)
      (*server->idle)(server);
    Sleep(SERVER_DELAY/2);
    if(1) {
#ifdef USE_UDP
        ServerRead(server,"",0,TRUE); 
#else
      if(-1!=NetPollForRead(1,&server->server_sock)) {
        client=CAlloc(sizeof(COutgoing));
	client->accept=NetAccept(server->server_sock,NULL);
	QueIns(client,&server->clients);
      }
#endif
      do {
      repeat=FALSE;
      for(client=server->clients.next;client!=&server->clients;client=next) {
        server->write_to=client->to;
        next=client->next;
        FramePtrSet("Server@@Client",client);
#ifdef USE_UDP 
        if(0) { //TODO check for hangup
#else
	if(-1!=NetPollForHangup(1,&client->accept)) {
	  NetClose(client->accept);
#endif
	  QueRem(client);
	  Free(client->valid_ids);
	  Free(client);
#ifdef USE_UDP
        } else if(1) {
//TODO something mroe genius
	  server->write_to=client->to;
	  if(!client->read_cnt)
	    goto next_client;
	  Free(got_msg);
	  got_msg=ServerReadMsg(server,TRUE);
#else
        } else if(-1!=NetPollForRead(1,&client->accept)) {
	  server->write_to_sock=client->accept;
	  Free(got_msg);
	  got_msg=ServerReadMsg(server,TRUE);
#endif
	  if(!got_msg) break;
	  if(got_msg->type==SRV_CODE_SEND_MESSAGE) {
	    repeat=TRUE;
	    PassMessage(server,got_msg);
	  } else if(got_msg->type==SRV_CODE_GET_UPDATES) {
	    repeat=TRUE;
	    cnt=0;
	    for(thing=server->things.next;thing!=&server->things;thing=thing->next) {
	      if(!OutgoingIdHashMatches(server,client,thing->id))
	        cnt++;
	    }
	    for(idx=0;idx!=client->id_cnt;idx++) {
	      if(!ServerHasId(server,client->valid_ids[idx].id))
	        cnt++;
	    }
	    recv_things.len=sizeof(CRecieveThings);
	    recv_things.cnt=cnt;
//Will send later
	    QueInit(&blob_head);
	    cnt=0;
	    for(thing=server->things.next;thing!=&server->things;thing=thing->next) {
	      if(!OutgoingIdHashMatches(server,client,thing->id)) {
	        buf=SerializeThing(server,thing,&len);
	        recieve=CAlloc(sizeof(CRecieveThing)+len);
	        recieve->len=sizeof(CRecieveThing)+len;
	        recieve->id=thing->id;
	        MemCpy(recieve->body,buf,len);
	        QueIns(recieve,blob_head.last);
	        Free(buf);
	        cnt+=recieve->len;
	      }
	    }
	    for(idx=0;idx!=client->id_cnt;idx++) {
	      if(!ServerHasId(server,client->valid_ids[idx].id)) {
	        recieve=CAlloc(sizeof(CRecieveThing));
	        recieve->len=sizeof(CRecieveThing);
	        recieve->id=client->valid_ids[idx].id;
	        recieve->remove=TRUE;
	        QueIns(recieve,blob_head.last);
	        cnt+=recieve->len;
	      }
	    }
	    buf=MAlloc(cnt+sizeof(CRecieveThings));
	    recv_things.len+=cnt;
	    recv_things.type=SRV_CODE_GET_UPDATES;
	    MemCpy(buf,&recv_things,sizeof(CRecieveThings));
	    idx=cnt;
	    cnt=0;
	    for(recieve=blob_head.next;recieve!=&blob_head;recieve=recieve->next) {
	      MemCpy(buf+cnt+sizeof(CRecieveThings),recieve,recieve->len);
	      cnt+=recieve->len; 
	    }
	    QueDel(&blob_head);
	    Free(client->valid_ids);
//Send here
	    ServerWriteMsg(server,buf);
	    Free(buf);

	    client->id_cnt=QueCnt(&server->things);
	    client->valid_ids=MAlloc(client->id_cnt*8,server->mem_task);
	    cnt=client->id_cnt;
	    for(thing=server->things.next;thing!=&server->things;thing=thing->next) {
	      client->valid_ids[--cnt].hash=HashThing(server,thing);
	      client->valid_ids[cnt].id=thing->id;
	    }
	    client->last_frame=server->frame_cnt;
	  } else if(got_msg->type==SRV_CODE_HELLO) {
	    repeat=TRUE;
	  } else if(got_msg->type==SRV_CODE_SEND_HASHES) {
	    repeat=TRUE;
	    hashes=got_msg;
	    Free(client->valid_ids);
	    client->id_cnt=hashes->cnt;
	    client->valid_ids=MAlloc(hashes->cnt*sizeof(CHashPair));
	    cnt=hashes->cnt;
	    while(--cnt>=0) {
	      client->valid_ids[cnt]=hashes->body[cnt];
	    }
	  }
          if(got_msg->msg_flags&MESSAGEF_SEND_ACK) {
	    got_msg->msg_flags&=~MESSAGEF_SEND_ACK;
            got_msg->type=SRV_CODE_ACK;
	    got_msg->len=sizeof(CServerMsg);
	    got_msg->last_ms=__GetTicks;
	    ServerWrite(server,got_msg,got_msg->len);
          } 
next_client:;
        }
      }
      } while(repeat);
    }
  }
}

CServer *ClientNew(U8 *host,I64 port) {
  CServerMsg server_msg;
  CServer *server=CAlloc(sizeof CServer);
  server->mem_task=Fs;
  server->mode=SERV_MODE_CLIENT;
  QueInit(&server->things);
  QueInit(&server->clients);
#ifdef USE_UDP
  CUDPAddr *addr;
  server->client_sock=NetUDPSocketNew;
  server->write_to=NetUDPAddrNew(host,port);
  InstallUDPOnRecvCb(server,&UDPReadCallback);
#else
  CNetAddr *addr=NetAddrNew(host,port);
  server->client_sock=NetSocketNew;
  server->write_to_sock=server->client_sock;
  NetConnect(server->client_sock,addr);
  NetAddrDel(addr);
#endif
  server->hash_table=HashTableNew(2048);
  server_msg.len=sizeof(CServerMsg);
  server_msg.type=SRV_CODE_HELLO;
  ServerWriteMsg(server,&server_msg);
  return server;
}

U0 OutgoingDel(COutgoing *og) {
#ifndef USE_UDP
  if(og->accept!=-1)
    NetClose(og->accept);
#endif
  Free(og->valid_ids);
  Free(og->read_data);
  Free(og);  
}

U0 ServerDel(CServer *s) {
  CServerThing *t,*head,*next;
  COutgoing *og;
  Kill(s->read_task,FALSE);
  head=&s->things;
  for(t=head->next;t!=head;t=next) {
    next=t->next;
    _ServerThingDel(s,t);
  }
  Kill(s->server_task);
  head=&s->clients;
  for(og=head->next;og!=head;og=next) {
    next=og->next;
    OutgoingDel(og);
  }
  NetClose(s->server_sock);
  HashTableDel(s->hash_table);
  Free(s);
}



CServer *ServerNew(U8 *host,I64 port) {
  CServerNewPair *pair=CAlloc(sizeof(CServerNewPair));
  pair->use_htable=Fs->hash_table;
  pair->mem_task=Fs;
  pair->addr=NetAddrNew(host,port);
  CTask *t=Spawn(&_ServerNew,pair,,,Fs);
  while(!FramePtr("Server",t)) {
    Sleep(10);
  }
  return FramePtr("Server",t);
}

I64 GetClassMeta(U8 *class_name,U8 *member,U8 *meta_name) {
  CHashClass *cls=HashFind(class_name,Fs->hash_table,HTT_CLASS);
  CMemberLst *mlst;
  CMemberLstMeta *meta;
  if(!cls) return NULL;
  if(mlst=MemberFind(member,cls)) {
     if(meta=MemberMetaFind(meta_name,mlst))
	return meta->user_data;
  }
  return NULL;
}


I64 GetClassMemberValI64(CServerThing *t,U8 *member) {
  CHashClass *cls=HashFind(t->class_name,Fs->hash_table,HTT_CLASS);
  CMemberLst *mlst;
  CMemberLstMeta *meta;
  if(!cls) return NULL;
  if(mlst=MemberFind(member,cls)) {
     switch(mlst->member_class->raw_type) {
       case RT_U8:
         return *(t(U8*)+mlst->offset);
       case RT_U16:
         return (t(U8*)+mlst->offset)(U16*)[0];
       case RT_U32:
         return (t(U8*)+mlst->offset)(U32*)[0];
       case RT_U64:
         return (t(U8*)+mlst->offset)(U64*)[0];
       case RT_I8:
         return *(t(I8*)+mlst->offset);
       case RT_I16:
         return (t(U8*)+mlst->offset)(I16*)[0];
       case RT_I32:
         return (t(U8*)+mlst->offset)(I32*)[0];
       case RT_I64:
         return (t(U8*)+mlst->offset)(I64*)[0];
       case RT_F64:
         return (t(U8*)+mlst->offset)(F64*)[0];
     }
  }
  return NULL;
}

F64 GetClassMemberValF64(CServerThing *t,U8 *member) {
  CHashClass *cls=HashFind(t->class_name,Fs->hash_table,HTT_CLASS);
  CMemberLst *mlst;
  CMemberLstMeta *meta;
  if(mlst=MemberFind(member,cls->member_lst_and_root)) {
     switch(mlst->member_class->raw_type) {
       case RT_U8:
         return *(t(U8*)+mlst->offset);
       case RT_U16:
         return (t(U8*)+mlst->offset)(U16*)[0];
       case RT_U32:
         return (t(U8*)+mlst->offset)(U32*)[0];
       case RT_U64:
         return (t(U8*)+mlst->offset)(U64*)[0];
       case RT_I8:
         return *(t(I8*)+mlst->offset);
       case RT_I16:
         return (t(U8*)+mlst->offset)(I16*)[0];
       case RT_I32:
         return (t(U8*)+mlst->offset)(I32*)[0];
       case RT_I64:
         return (t(U8*)+mlst->offset)(I64*)[0];
       case RT_F64:
         return (t(U8*)+mlst->offset)(F64*)[0];
     }
  }
  return NULL;
}

U0 _ServerThingDel(CServer *s,CServerThing *thing) {
  U8 *buf=MStrPrint(PTR_2_ID_FMT,thing),*del;
  CHash *tmph;
  if(s->id_map[thing->id>>1]==thing)
    s->id_map[thing->id>>1]=NULL;
  if(tmph=HashFind(buf,s->hash_table,HTT_FRAME_PTR))
    HashRemDel(tmph,s->hash_table);
  Free(buf);
  QueRem(thing);
  QueInit(thing);
  if(del=GetClassMemberValI64(thing,"destroy")) {
    if(HashFind(del,Fs->hash_table,HTT_FUN))
      CallExtStr(del,thing);
    else
      Free(thing);
  } else
    Free(thing);
}
Bool AddThingToServer(CServerThing *thing,CServer *server,I64 at=-1) {
  I64 use=(server->id_num+1)&ID_MASK,orig=server->id_num&ID_MASK;
  CHashGeneric *tmph;
  U8 *buf;
  if(at!=-1) {
    use=at>>1;
    goto got_valid;
  }
  while(use!=orig) {
    use=(use+1)&ID_MASK;
    if(!server->id_map[use]) {
got_valid:
      thing->id=(use<<1)|1;
      server->id_num=use;
      server->id_map[use]=thing;
      buf=MStrPrint(PTR_2_ID_FMT,thing);
      if(tmph=HashFind(buf,server->hash_table,HTT_FRAME_PTR))
        HashRemDel(tmph,server->hash_table);
      tmph=CAlloc(sizeof(CHashGeneric),server->mem_task);
      tmph->str=StrNew(buf,server->mem_task);
      tmph->type=HTT_FRAME_PTR;
      tmph->user_data0=thing->id;
      HashAdd(tmph,server->hash_table);
      Free(buf);
      server->id_map[use]=thing;
QueRem(thing);
      QueIns(thing,&server->things);
      return TRUE;
    }
  }
  return FALSE;
}
CServerThing *ConstructServerThing(CTask *mem_task,U8 *class_name,...) {
  I64 idx;
  CHashClass *cls=HashFind(class_name,Fs->hash_table,HTT_CLASS),*ocls=cls;
  CMemberLst *mlst;
  U8 *constructor;
  if(!cls) return NULL;
  CServerThing *t=CAlloc(cls->size,mem_task);
  QueInit(t);
  StrCpy(t->class_name,class_name);
  for(cls=ocls;cls;cls=cls->base_class)
    for(mlst=cls->member_lst_and_root;mlst;mlst=mlst->next) {
      idx=GetClassMeta(class_name,mlst->str,"dft");
      if(idx)
        (t(U8*)+mlst->offset)(I64*)[0]=idx;
    }
  for(idx=0;idx<argc;idx+=2) {
    mlst=MemberFind(argv[idx],cls);
    if(mlst) {
      switch(mlst->member_class->raw_type) {
        case RT_U8:
	  *(t(U8*)+mlst->offset)=argv[idx+1];
	  break;
        case RT_U16:
	  (t(U8*)+mlst->offset)(U16*)[0]=argv[idx+1];
	  break;
        case RT_U32:
	  (t(U8*)+mlst->offset)(U32*)[0]=argv[idx+1];
	  break;
        case RT_U64:
	  (t(U8*)+mlst->offset)(U64*)[0]=argv[idx+1];
	  break;
        case RT_I8:
	  *(t(I8*)+mlst->offset)=argv[idx+1];
	  break;
        case RT_I16:
	  (t(U8*)+mlst->offset)(I16*)[0]=argv[idx+1];
	  break;
        case RT_I32:
	  (t(U8*)+mlst->offset)(I32*)[0]=argv[idx+1];
	  break;
        case RT_I64:
	  (t(U8*)+mlst->offset)(I64*)[0]=argv[idx+1];
	  break;
        case RT_F64:
	  (t(U8*)+mlst->offset)(F64*)[0]=argv(F64*)[idx+1];
	  break;
      }
    }
  }
  if(constructor=GetClassMemberValI64(t,"constructor")) {
    CallExtStr(constructor,t);
  }
  return t;
}
I64 ServerPtr2Id(CServer *s,U8 *ptr) {
  U8 *buf=MStrPrint(PTR_2_ID_FMT,ptr);
  CHashGeneric *tmph=HashFind(buf,s->hash_table,HTT_FRAME_PTR);
  Free(buf);
  if(tmph) {
    return tmph->user_data0;
}
  return -1;
}
U8 *ServerId2Ptr(CServer *s,I64 id) {
  CServerThing *t,*head=&s->things;
//See note after the Pushin P
  if(id>>1>ID_MASK)
    return NULL;
  return s->id_map[id>>1];
} 

U0 LinkServerThing(CServer *s,CServerThing *ret) {
  CHashClass *cls;
  U8 *ptr;
  CMemberLst *mlst;
  if(cls=HashFind(ret->class_name,Fs->hash_table,HTT_CLASS))
    for(;cls;cls=cls->base_class)
      for(mlst=cls->member_lst_and_root;mlst;mlst=mlst->next)
        if(MemberMetaFind("swizzle",mlst)) {
	  if(ptr=ServerId2Ptr(s,(ret(U8*)+mlst->offset)(I64*)[0]))
	    (ret(U8*)+mlst->offset)(U8**)[0]=ptr;
        }
}
U0 LinkServerThings(CServer *s) {
  CServerThing *t;
  for(t=s->things.next;t!=&s->things;t=t->next) {
    LinkServerThing(s,t);
}
}
U0 GenerateThingUpdater(U8 *class_name) {
  CHashClass *cls=HashFind(class_name,Fs->hash_table,HTT_CLASS),*ocls=cls;
  CMemberLst *mlst;
  CMemberLstMeta *meta;
  if(!cls) return;
  StreamPrint("U0 UpdateThing@@%s(CServer *s,%s *dst,%s *buf,I64 sz) {\n",
	class_name,class_name,class_name);  
  for(;cls;cls=cls->base_class)
    for(mlst=cls->member_lst_and_root;mlst;mlst=mlst->next)
      if(MemberMetaFind("swizzle",mlst)) {
        StreamPrint("dst->%s=ServerId2Ptr(s,buf->%s);\n",mlst->str,mlst->str);
      } else if(!mlst->member_class->ptr_stars_cnt) {
	if(mlst->dim.next) {
	  StreamPrint("MemCpy(dst->%s,buf->%s,%d);\n",mlst->str,mlst->str,mlst->dim.total_cnt*mlst->member_class->size);
        } else if(mlst->member_class->raw_type!=RT_U0)
          StreamPrint("dst->%s=buf->%s;\n",mlst->str,mlst->str);
      }
  StreamPrint("}\n");
}
U0 GenerateSerializeThing(U8 *class_name) {
  CHashClass *cls=HashFind(class_name,Fs->hash_table,HTT_CLASS),*ocls=cls;
  CMemberLst *mlst;
  CMemberLstMeta *meta;
  if(!cls) return;
  StreamPrint("U8 *Serialize@@%s(CServer *s,%s *thing,I64 *sz) {\n",
	class_name,class_name);  
  StreamPrint("  %s *buf=CAlloc(%d,s->mem_task);\n",class_name,cls->size);
  StreamPrint("  MemCpy(buf,thing,%d);\n",cls->size);
  for(;cls;cls=cls->base_class)
    for(mlst=cls->member_lst_and_root;mlst;mlst=mlst->next)
      if(MemberMetaFind("swizzle",mlst)) 
        StreamPrint("buf->%s=ServerPtr2Id(s,buf->%s);\n",mlst->str,mlst->str);
      else if(mlst->member_class->ptr_stars_cnt) {
	if(mlst->dim.next) 
          StreamPrint("MemSetU64(buf->%s,NULL,%d);\n",mlst->str,mlst->dim.total_cnt);
	else if(mlst->member_class->raw_type!=RT_U0)
          StreamPrint("buf->%s=NULL;\n",mlst->str);
      } 
        
  StreamPrint("  if(sz) *sz=%d;\n",ocls->size);
  StreamPrint("  return buf;\n");
  StreamPrint("}\n");
}

U0 GenerateUnserializeThing(U8 *class_name) {
  CHashClass *cls=HashFind(class_name,Fs->hash_table,HTT_CLASS),*ocls=cls;
  CMemberLst *mlst;
  CMemberLstMeta *meta;
  if(!cls) return;
  StreamPrint("%s *Unserialize@@%s(CServer *s,%s *thing,I64 *sz) {\n",
	class_name,class_name,class_name);  
  StreamPrint("  %s *buf=ConstructServerThing(s->mem_task,\"%s\"));\n",class_name,cls->str);
  StreamPrint("  UpdateThing(s,buf,thing,sz);\n"); 
  StreamPrint("  return buf;\n");
  StreamPrint("}\n");
}

Bool UpdateThing(CServer *s,CServerThing *dst,CServerThing *t,I64 sz) {
  if(StrCmp(dst->class_name,t->class_name))
    return FALSE;
  U8 *buf=MStrPrint("UpdateThing@@%s",t->class_name);
  CHashFun *fun=HashFind(buf,Fs->hash_table,HTT_FUN);
  if(!fun) {
    ExePrint("#exe {GenerateThingUpdater(\"%s\");;};;",t->class_name);
    fun=HashFind(buf,Fs->hash_table,HTT_FUN);
  }  
  Free(buf);
  if(fun) CallExtStr(fun->str,s,dst,t,sz);
  return TRUE;
}


U8 *SerializeThing(CServer *s,CServerThing *t,I64 *sz) {
  U8 *buf=MStrPrint("Serialize@@%s",t->class_name);
  CHashFun *fun=HashFind(buf,Fs->hash_table,HTT_FUN);
  if(!fun) {
    ExePrint("#exe {GenerateSerializeThing(\"%s\");;};;",t->class_name);
    fun=HashFind(buf,Fs->hash_table,HTT_FUN);
  }  
  Free(buf);
  if(fun) return CallExtStr(fun->str,s,t,sz);
  return NULL;
}
CServerThing *UnserializeThing(CServer *s,CServerThing *t,I64 sz) {
  U8 *buf=MStrPrint("Unserialize@@%s",t->class_name);
  CHashFun *fun=HashFind(buf,Fs->hash_table,HTT_FUN);
  if(!fun) {
    ExePrint("#exe {GenerateUnserializeThing(\"%s\");;};;",t->class_name);
    fun=HashFind(buf,Fs->hash_table,HTT_FUN);
  }  
  Free(buf);
  if(fun) return CallExtStr(fun->str,s,t,sz);
  return NULL;
}

U8 *HashThing(CServer *s,CServerThing *t) {
  U8 *buf=MStrPrint("Hash@@%s",t->class_name);
  CHashFun *fun=HashFind(buf,Fs->hash_table,HTT_FUN);
  if(!fun) {
    ExePrint("#exe {GenerateHashThing(\"%s\");;};;",t->class_name);
    fun=HashFind(buf,Fs->hash_table,HTT_FUN);
  }  
  Free(buf);
  if(fun) return CallExtStr(fun->str,s,t);
  return NULL;
}
U0 _GenerateHashThing(CMemberLst *mlst,U8 *prefix=NULL,CArrayDim *dim=NULL) {
  I64 precision,cnt;
  U8 *buf;
  if(!prefix) {
    prefix=mlst->str;
    if(!dim)
      dim=mlst->dim.next;
  }
  if(dim) {
    for(cnt=0;cnt!=dim->cnt;cnt++) {
      buf=MStrPrint("%s[%d]",prefix,cnt);
      if(dim->next) {
	_GenerateHashThing(mlst,buf,dim->next);
      } else 
	_GenerateHashThing(mlst,buf);
      Free(buf);
    }
  } else {
    if(MemberMetaFind("swizzle",mlst)) {
      StreamPrint("member=ServerPtr2Id(s,t->%s);",prefix);
    } else if(mlst->member_class->ptr_stars_cnt) {
//DONT HASH POINTERS
      StreamPrint("member=0;");
    } else if(mlst->member_class->raw_type==RT_F64) {
//TODO check for precision,1/16. is the dft
      if(precision=MemberMetaData("fixed_prec",mlst)) 
        StreamPrint("member=t->%s*%d;\n",prefix,precision);
      else
        StreamPrint("member=t->%s*16;\n",prefix);
    } else {
      StreamPrint("member=t->%s;\n",prefix);
    }
    StreamPrint("hash=member+(hash<<5+hash);"); //(hash<<5+hash) is hash*32+hash or hash*33
  }
}
U0 GenerateHashThing(U8 *class_name) {
  CHashClass *cls=HashFind(class_name,Fs->hash_table,HTT_CLASS);
  CMemberLst *mlst;
  CMemberLstMeta *meta;
  I64 precision;
  if(!cls) return;
  StreamPrint("I64 Hash@@%s(CServer *s,%s *t) {\n",class_name,class_name);
  StreamPrint("  I64 hash=5968,member;\n");
  for(;cls;cls=cls->base_class) {
//DONT HASH THE THING HEADER
    if(cls==HashFind("CServerThing",Fs->hash_table,HTT_CLASS))
      break;
    for(mlst=cls->member_lst_and_root;mlst;mlst=mlst->next)
      _GenerateHashThing(mlst);
  }
  StreamPrint("return hash;\n");
  StreamPrint("}\n");
}

Bool ThingHasClass(U8 *name,CServerThing *thing) {
  CHashClass *cls=HashFind(thing->class_name,Fs->hash_table,HTT_CLASS);
  while(cls) {
    if(!StrCmp(cls->str,name))
      return TRUE;
    cls=cls->base_class;
  }
  return FALSE;
}

/*
class CMan:CServerThing {
  CMan *self swizzle;
  U8 *poop;
  F64 x,y;
  F64 health;
};
U0 Message_NewMan(CServer *s,CMessagePass *pass) {
  CMan *man=ConstructServerThing(s->mem_task,"CMan","x",35.,"y",50.,"health",100.);
  man->self=man;
  AddThingToServer(man,s);
}
CServer *server=ServerNew("127.0.0.1",8011);
Sleep(100);
CMan *thing;
CServer *client=ClientNew("127.0.0.1",8011);
ClientAskForUpdates(client);
ClientPassMessage(client,"Message_NewMan",NULL,0);
ClientAskForUpdates(client);
"CNT:%d\n",QueCnt(&client->things);
thing=server->things.next;
thing(CMan*)->x=1000;
ClassRep(thing,thing->class_name);
ClientAskForUpdates(client);
ClassRep(thing,thing->class_name);
CServer *client2=ClientNew("127.0.0.1",8011);
ClientAskForUpdates(client2);
ClientAskForUpdates(client);
thing=client2->things.next;
thing->poop=0x321321321;
ClientAskForUpdates(client2);
ClassRep(thing,thing->class_name);
thing=server->things.next;
ClassRep(thing);
"%d\n",ServerPtr2Id(server,thing->self);*/
#endif
