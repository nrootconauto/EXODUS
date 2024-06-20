#exe {Cd(__DIR__);};;
#include "Generic.HC";
#include "Set.HC";
class CNetAddr {
  U8 *hostname;
  I64 port;
};
class CExodusSock:CSocket {
  I64 sock_num;
  CI64Set *children;
  I64 read_cnt,write_cnt,hangup_cnt;
  U8 *read_base; //Free this
  U8 *write_ptr,*read_ptr;
};
CTask *net_task=NULL;
CDyadStream *dyad_socks[0x10000];
CExodusSock *exodus_socks[0x10000];
extern CExodusSock *_Socket(CDyadStream *stream);
U0 DyadSocketTaskEnd() {
  DyadShutdown;  
  Exit;
}
U0 DyadSocketTask(I64 s) {
  DyadInit;
  net_task=Fs;
  Fs->task_end_cb=&DyadSocketTaskEnd;
  MemSetI64(dyad_socks,0,0x10000);
  MemSetI64(exodus_socks,0,0x10000);
  while(TRUE) {
    DyadUpdate;
    Sleep(10);
  }
}
I64 FindFreeSock() {
  I64 i=0;
  for(i=0;i!=0x10000;i++)
    if(!dyad_socks[i])
      return i;
  return -1;
}
I64 DyadSockIdx(CDyadStream *s) {
  I64 i=0;
  for(i=0;i!=0x10000;i++) {
    if(dyad_socks[i]==s)
      return i;
  }
  return -1;
}
I64 ExodusGetAddrInfo(U8 *node,U8*ul,addrinfo *hints=NULL,addrinfo **res) {
  sockaddr_in *addr=CAlloc(sizeof sockaddr_in);
  addrinfo *info=CAlloc(sizeof addrinfo);
  CNetAddr *new=CAlloc(sizeof CNetAddr);
  new->hostname=StrNew(node);
  new->port=0;
  info->ai_family=AF_INET;
  info->ai_canonname=StrNew(node);
  info->ai_addr=addr;
  info->ai_socktype=SOCK_STREAM;
  addr->sin_zero[0](U64*)=new;
  *res=info;
  return 0;
}

socket_addr_resolver=CAlloc(sizeof CAddrResolver);
socket_addr_resolver->getaddrinfo=&ExodusGetAddrInfo;
I64 ExodusAccept(CExodusSock *_s,sockaddr *src_addr,I64 addr_len) {
  I64 s=_s->sock_num;
  I64 code;
  CExodusSock *got;
  if(_s->read_cnt) {
    _s->read_cnt--;
    got=_s->children->body[0];
    I64SetRem(_s->children,got);
  } else
    got=-1;
  return got;
}
I64 ExodusClose(CExodusSock *_s) {
  CDyadStream *ds=dyad_socks[_s->sock_num];
  dyad_socks[_s->sock_num]=NULL;
  exodus_socks[_s->sock_num]=NULL;
  DyadEnd(ds);
  Free(_s);
  return 0;
}
I64 ExodusBind(CExodusSock *_s,sockaddr_in *src_addr,I64 addr_len) {
  CNetAddr *from=src_addr->sin_zero[0](U64*);
  DyadListen(dyad_socks[_s->sock_num],htons(src_addr->sin_port),from->hostname);
  return 0;
}
I64 ExodusConnect(CExodusSock *_s,sockaddr_in *src_addr,I64 addr_len) {
  CNetAddr *from=src_addr->sin_zero[0](U64*);
//Use port from src_addr
  DyadConnect(dyad_socks[_s->sock_num],from->hostname,htons(src_addr->sin_port));
  return 0;
}
I64 ExodusListen(CExodusSock *_s,I64 backlog) {
//See NetBind
  return 0;
}
I64 ExodusRecvFrom(CExodusSock *_s,U8 *buf,I64 len,I64 flags,sockaddr *ul,I64 addrlen) {
//TODO wherefrom
ent:;
  I64 s=_s->sock_num;
  I64 buf_len=_s->write_ptr-_s->read_ptr;
  if(!buf_len) {Sleep(4);goto ent;}
  if(buf_len>=len) {
    MemCpy(buf,_s->read_ptr,len);
    _s->read_ptr+=len;
    return len;
  }
  MemCpy(buf,_s->read_ptr,buf_len);
  _s->read_ptr+=buf_len;
  return buf_len;
}
I64 ExodusSendTo(CExodusSock* _s, U8* buf, I64 len, I64 flags, sockaddr* dest_addr, I64 addrlen) {
//TODO whereto
  I64 s=_s->sock_num;
  DyadWrite(dyad_socks[s],buf,len);
  return len;

}
I64 ExodusSockOpt(CExodusSock* _s, I64 level, I64 optname, U8* optval, I64 optlen) {
//Poop taods
}
static U0 DyadReadCallback(CDyadStream *who,U8 *buf,I64 len,U8 *ud) {
  CExodusSock *s=ud;
  I64 buf_len;
  U8 *copy;
  buf_len=s->write_ptr-s->read_base;
  if(!s->read_base) {
    s->read_base=CAlloc(len+32);
    s->read_ptr=s->read_base;
    s->write_ptr=s->read_base;
  } else if(buf_len+len>=MSize(s->read_base)) { 
    buf_len=s->write_ptr-s->read_ptr;
    copy=s->read_base;
    s->read_base=CAlloc(len+32+buf_len);
    MemCpy(s->read_base,s->read_ptr,buf_len);
    Free(copy);
    s->read_ptr=s->read_base;
    s->write_ptr=s->read_base+buf_len;
  }
  MemCpy(s->write_ptr,buf,len);
  s->write_ptr+=len;
}
static U0 DyadAcceptCallback(CDyadStream *new,CExodusSock *s) {
  I64SetAdd(s->children,_Socket(new));
  s->read_cnt++;
}
static U0 DyadCloseCallback(CDyadStream *who,U8 *user_data) {
  I64 idx=DyadSockIdx(who);
  if(idx==-1) return;
  CExodusSock *s=exodus_socks[idx];
  s->hangup_cnt++;  
}
CExodusSock *_Socket(CDyadStream *stream) {
  CExodusSock *ret=CAlloc(sizeof CExodusSock);
  I64 sock=FindFreeSock;
  ret->sock_num=sock;
  ret->accept=&ExodusAccept;
  ret->bind=&ExodusBind;
  ret->close=&ExodusClose;
  ret->connect=&ExodusConnect;
  ret->listen=&ExodusListen;
  ret->recvfrom=&ExodusRecvFrom;
  ret->sendto=&ExodusSendTo;
  ret->setsockopt=&ExodusSockOpt;
  ret->children=I64SetNew;
  DyadSetListenCallback$IV,0$(stream,DYAD_EVENT_ACCEPT,&DyadAcceptCallback,ret);
  DyadSetReadCallback(stream,DYAD_EVENT_DATA,&DyadReadCallback,ret);
  DyadSetCloseCallback(stream,DYAD_EVENT_CLOSE,&DyadCloseCallback,ret);
  dyad_socks[sock]=stream;
  exodus_socks[sock]=ret;
  return ret;
}

U8 *ExodusSocket(U16,U16) {
  if(!net_task) {
    Spawn(&DyadSocketTask,0,"DyadShim",-1,Fs);
    while(!net_task) 
      Yield;
  }  
  return _Socket(DyadNewStream);
}

RegisterSocketClass(AF_INET,SOCK_STREAM,&ExodusSocket);

/*I64 sock=create_connection("aiwnios.com",6667);
sendString(sock,
"NICK asshole\n"
"USER asshole 0 * :asshole\n"
,0);
U8 buf[STR_LEN];
recvLine(sock,buf,STR_LEN,0);
"%s\n",buf;
sendString(sock,
"JOIN #main\n"
,0);
while(recvLine(sock,buf,STR_LEN,0))
  "%s\n",buf;
close(sock);*/