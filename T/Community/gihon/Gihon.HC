#exe {Cd(__DIR__);};;
#ifdef __AIWNIOS__
#include "CrossNetShims/Aiwnios2";
#else
#ifdef __EXODUS
#include "CrossNetShims/EXODUS";
#endif
#endif
#exe {Cd(__DIR__);};;
#define IRCD_LIMIT_MAX      20
#define IRCD_PING_INTERVAL  60000
#define IRCD_PORT           6667
#define IRCD_RXBUF_SIZE     4096
#define IRCD_TXBUF_SIZE     4096
#define IRCD_TXFIFO_SIZE    0x200
#define BACKLOG_FIFO_SZ (IRCD_TXFIFO_SIZE/2) //MUST REVERSE ROOM FOR JOIN MESSAGES(so use smaller size)

U8 *ircd_hostname = "irc.gihon.local";		
I64 ircd_chans_total = 0;
I64 ircd_clients_total = 0;

CTask *gihon_task=Fs;

#define IRCD_CAP_SERVER_TIME 1
#define IRCD_CAP_MESSAGE_TAGS (1<<1)
#define IRCD_CAP_TYPING (1<<2)
extern U0 IrcPrintDateTag(U8 *buf,CDate when=0);
//This accounts for Free-ing strings from the overflow of the fifo
U0 GihonFifoIns(CFifoI64 *fifo,U8 *s) {
  U8 *new_s=StrNew(s,gihon_task),*tmp;
  if(FifoI64Cnt(fifo)==fifo->mask) {
   FifoI64Rem(fifo,&tmp);
   Free(tmp);
  }
  FifoI64Ins(fifo,new_s);
  Free(s);
}


#include "Motd";
#include "Service";
#include "Arg";
#include "Client";
#include "Channel";
#include "Command";


I64 Gihon()
{
  I64 sock = socket(AF_INET,SOCK_STREAM);
  IrcClient *iclient;
  IrcChannel *ichannel;
  if (sock < 0)
    return -1;
  sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_port = htons(IRCD_PORT);
  addr.sin_addr.s_addr = 0;
  addrinfo* res, *curr;
  getaddrinfo("0.0.0.0", NULL, NULL, &res);
  for(curr=res;curr;curr=curr->ai_next) { 
    if (curr->ai_family == AF_INET && (curr->ai_socktype == 0 || curr->ai_socktype == SOCK_STREAM)) {
      MemCpy(&addr.sin_zero,&curr->ai_addr(sockaddr_in*)->sin_zero,8);
      addr.sin_addr.s_addr = (curr->ai_addr(sockaddr_in*))->sin_addr.s_addr;
      break;
    }
  }
  freeaddrinfo(res);
  bind(sock,&addr,sizeof(sockaddr_in));
  listen(sock,10);
  Spawn(&IrcClientTxHandler,, "Gihon ClientTxHandler",,Fs);
//Flush previous keys
  FlushMsgs; 
  "Press a key to stop serving\n";
  while (!ScanKey)
    {
    I64 client = accept(sock,NULL,0);
    if(client!=-1)
      Spawn(&IrcClientRxHandler, client, "Gihon ClientRxHandler",,Fs);
    Sleep(10);
  }
  while(iclient=client_head->next)
    IrcClientDel(iclient);
  while(ichannel=channel_head->next)
    IrcChannelDel(ichannel);
  Free(client_head);
  Free(channel_head);
  close(sock);
//  Exit;
}
Gihon;
