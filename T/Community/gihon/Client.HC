#define IRCD_USERMODE_v 0x1
#define IRCD_USERMODE_h 0x2
#define IRCD_USERMODE_o 0x4
#define IRCD_USERMODE_a 0x8
#define IRCD_USERMODE_q 0x10

I64 registry_tmp;


class IrcClient
{
IrcClient *prev;
IrcClient *next;
I64 s;
U8 *nick;
U8 *username;
U8 *realname;
U8 *server;
U8 *host;
U32 ip;
U8 *vhost;
CFifoI64 *msgs;
I64 idle;
I64 limit;
CTask *task;
CDate last_connect;
Bool disconnected,pad[7];
I64 caps;
U8 *account; //See Accounts.HC
U8 password[STR_LEN];
//See IRCD_CAP_MESSAGE_TAGS and IrcGetClientMsgs
//If the client says +icon='poop.png',send +icon='poop.png' to clients with IRCD_CAP_MESSAGE_TAGS
U8 *client_tags; 
I64 missed_pings;
};

class IrcUser
{
IrcUser *prev;
IrcUser *next;
IrcClient *client;
U64 flags;
};

class IrcChannel
{
IrcChannel *prev;
IrcChannel *next;
U8 *name;
U8 *topic;
IrcUser *users;
CFifoI64 *backlog;
I64 msg_cnt; //Used for msg_id
};

extern U0 IrcParseCommand(IrcClient *client, U8 *str);
extern U0 IrcChannelsQuit(IrcClient *client, U8 *msg=NULL);

IrcClient *client_head = CAlloc(sizeof(IrcClient),gihon_task);
IrcChannel *channel_head = CAlloc(sizeof(IrcChannel),gihon_task);

U0 IrcClientAdd(IrcClient *client)
{
  IrcClient *clients = client_head;
  while (clients->next)
    {
    clients = clients->next;
  }
  client->prev = clients;
  clients->next = client;
  ircd_clients_total++;
}
#include "Account.HC";
U0 IrcClientDel(IrcClient *client)
{
  IrcChannelsQuit(client);
  IrcClientAccountLogout(client);
  U8 *tmp;
  CTask *task = client->task;
  IrcClient *prev = client->prev;
  IrcClient *next = client->next;
  if(prev) prev->next = next;
  if(next) next->prev = prev;
  if (task && task != Fs)
    Kill(task,FALSE);
  close(client->s);
  while(FifoI64Rem(client->msgs,&tmp))
    Free(tmp);
  FifoI64Del(client->msgs); //TODO Free
  Free(client);
  ircd_clients_total--;
}

IrcClient *IrcGetClientByNick(U8 *nick)
{
  IrcClient *client = client_head->next;
  while (client)
    {
    if (client->nick&&!StrCmp(client->nick, nick)) return client;
    client = client->next;
  }
  return NULL;
}

U0 IrcClientSetNick(IrcClient *client, U8 *nick)
{
  I64 i;
  U8 *buf = CAlloc(4096);
  IrcClient *chk_client = client_head->next;

  // check if in use, owned, forbidden, etc..
  while (chk_client)
    {
    if (chk_client->nick&&!StrICmp(chk_client->nick, nick))
      {
      StrPrint(buf, ":%s 433 %s %s :Nickname is already in use.\r\n", ircd_hostname, client->username,
	    nick);
      GihonFifoIns(client->msgs, StrNew(buf));
      Free(buf);
      return;
    }
    chk_client = chk_client->next;
  }
  for (i=0; i<service_cnt; i++)
    {
    if (service_nick[i]&&!StrICmp(service_nick[i], nick))
      {
      StrPrint(buf, ":%s 432 %s %s :Invalid nickname: Reserved for Services\r\n", ircd_hostname, client->username,
	    nick);
      GihonFifoIns(client->msgs, StrNew(buf));
      Free(buf);
      return;
    }
  }

  Free(client->nick);
  client->nick = StrNew(nick,gihon_task);
  Free(buf);
}


#include "Account.HC";
U0 IrcClientSetUser(IrcClient *client, U8 *username, U8 *host, U8 *server, U8 *realname)
{
// check user params
  U8 *tmp,*tmp2;
  CIrcAccount *acnt;
  client->username = StrNew(username,gihon_task);
  client->host = StrNew(host,gihon_task);
  client->realname = StrNew(realname,gihon_task);
  client->server = StrNew(server,gihon_task);

  acnt=IrcAccountLogin(client,realname,client->password);

  if(!acnt) {
     tmp=MStrPrint("%s 433 * %s :Invalid login.\r\n",ircd_hostname,username);
     send(client->s,tmp,StrLen(tmp),0);
     client->disconnected=TRUE;
  } else 
     client->account=acnt;

}

U0 IrcClientMotd(IrcClient *client)
{
  I64 i;
  U8 *buf = CAlloc(4096);
  StrPrint(buf, ":%s 375 %s :-\r\n", ircd_hostname, client->username);
  GihonFifoIns(client->msgs, StrNew(buf));
  for (i=0; i<motd_line_cnt; i++)
    {
    StrPrint(buf, ":%s 372 %s :%s\r\n", ircd_hostname, client->username, motd_lines[i]);
    GihonFifoIns(client->msgs, StrNew(buf));
  }
  StrPrint(buf, ":%s 376 %s :>\r\n", ircd_hostname, client->username);
  GihonFifoIns(client->msgs, StrNew(buf));
  Free(buf);
}

U0 IrcClientNotice(IrcClient *client, U8 *msg)
{
  U8 *buf = CAlloc(4096);
  StrPrint(buf, ":%s NOTICE Auth :%s\r\n", ircd_hostname, msg);
  GihonFifoIns(client->msgs, StrNew(buf));
  Free(buf);
}

U0 IrcClientJoin(U8 *dst, IrcClient *tx_client)
{
  U8 *buf = CAlloc(4096);
  IrcClient *rx_client = client_head->next;
  IrcChannel *rx_channel = channel_head->next;
  IrcUser *rx_user;
  while (rx_channel)
    {
    if (!StrCmp(rx_channel->name, dst))
      { //PRIVMSG to channel
      rx_user = rx_channel->users->next;
      while (rx_user)
        {
        rx_client = rx_user->client;
	StrCpy(buf,"");
        if(rx_client->caps&IRCD_CAP_SERVER_TIME) {
	  IrcPrintDateTag(buf);
	  CatPrint(buf," ");
	}
        CatPrint(buf, ":%s!%s@%s JOIN :%s\r\n", tx_client->nick, tx_client->username,
	      tx_client->host, dst);
        GihonFifoIns(rx_client->msgs, StrNew(buf));
        rx_user = rx_user->next;
      }
      return;
    }
    rx_channel = rx_channel->next;
  }
  Free(buf);
}

U0 IrcClientNames(IrcClient *client, U8 *dst)
{
  U8 *buf = CAlloc(4096);
  U8 *mode = CAlloc(16);
  IrcChannel *channel = channel_head->next;
  IrcUser *user;
  StrPrint(buf, ":%s 353 %s = %s :", ircd_hostname, client->username, dst);
  while (channel)
    {
    if (!StrCmp(channel->name, dst))
      {
      user = channel->users->next;
      while (user)
        {
        StrPrint(mode, "");
        if (user->flags & IRCD_USERMODE_q) StrPrint(mode, "@");
        if (user->flags & IRCD_USERMODE_o) StrPrint(mode, "@");
        if (user->flags & IRCD_USERMODE_h) StrPrint(mode, "\%");
        if (user->flags & IRCD_USERMODE_v) StrPrint(mode, "+");
        StrPrint(buf+StrLen(buf), "%s%s ", mode, user->client->nick);
        user = user->next;
      }
      StrPrint(buf+StrLen(buf), "\r\n");
      GihonFifoIns(client->msgs, StrNew(buf));
      StrPrint(buf, ":%s 366 %s %s :End of /NAMES list.\r\n", ircd_hostname, client->username, dst);
      GihonFifoIns(client->msgs, StrNew(buf));
      Free(mode);
      Free(buf);
      return;
    }
    channel = channel->next;
  }
  Free(mode);
  Free(buf);
}

U0 IrcClientTopic(IrcClient *client, U8 *dst)
{
  U8 *buf = CAlloc(4096);
  IrcChannel *channel = channel_head->next;
  while (channel)
    {
    if (!StrCmp(channel->name, dst))
      {
      if (StrLen(channel->topic))
        {
        StrPrint(buf, ":%s 332 %s %s :%s\r\n", ircd_hostname, client->username, dst, channel->topic);
        GihonFifoIns(client->msgs, StrNew(buf));
      }
      Free(buf);
      return;
    }
    channel = channel->next;
  }
  Free(buf);
}

U0 IrcClientPart(U8 *dst, IrcClient *tx_client, U8 *msg=NULL)
{
  U8 *buf = CAlloc(4096);
  IrcClient *rx_client = client_head->next;
  IrcChannel *rx_channel = channel_head->next;
  IrcUser *rx_user;
  while (rx_channel)
    {
    if (!StrCmp(rx_channel->name, dst))
      { //PRIVMSG to channel
      rx_user = rx_channel->users->next;
      while (rx_user)
        {
        rx_client = rx_user->client;
        if (msg)
	  {
	  StrPrint(buf, ":%s!%s@%s PART %s :%s\r\n", tx_client->nick, tx_client->username,
	        tx_client->host, dst, msg);
        }
        else
	  {
	  StrPrint(buf, ":%s!%s@%s PART %s\r\n", tx_client->nick, tx_client->username,
	        tx_client->host, dst);
        }
        GihonFifoIns(rx_client->msgs, StrNew(buf));
        rx_user = rx_user->next;
      }
      return;
    }
    rx_channel = rx_channel->next;
  }
  Free(buf);
}

U0 IrcClientPing(IrcClient *client, U8 *msg)
{
  U8 *buf = CAlloc(4096);
  StrPrint(buf, ":%s PONG %s :%s\r\n", ircd_hostname, ircd_hostname, msg);
  GihonFifoIns(client->msgs, StrNew(buf));
  Free(buf);
}

//Used for TAGMSG and PRIVMSG
U0 IrcClient_SendOut(IrcClient *tx_client, U8* type="PRIVMSG",U8 *dst, U8 *msg)
{
  U8 *buf = CAlloc(4096) ,*tmp;
  CFifoI64 *new_fifo;
  Bool wants_space;
  IrcClient *rx_client = client_head->next;
  while (rx_client)
    {
    if (!StrCmp(rx_client->nick, dst))
      { //PRIVMSG to nick
      StrCpy(buf,"");
      wants_space=FALSE;
      if(rx_client->caps&IRCD_CAP_SERVER_TIME) {
        wants_space=TRUE;
        IrcPrintDateTag(buf);
      }
      if(rx_client->caps&IRCD_CAP_MESSAGE_TAGS&&tx_client->client_tags)  {
        wants_space=TRUE;
//Make a new argument(;)
        if(*buf)  CatPrint(buf,";");
        CatPrint(buf,"%s",tx_client->client_tags);
      }
      if(wants_space) CatPrint(buf," ");
      if(!StrICmp(type,"TAGMSG")) //Don't include ':'
        CatPrint(buf, ":%s!%s@%s %s %s\r\n", tx_client->nick, tx_client->username,
	      tx_client->host, type, dst);
      else 
        CatPrint(buf, ":%s!%s@%s %s %s :%s\r\n", tx_client->nick, tx_client->username,
	      tx_client->host, type, dst, msg);
      GihonFifoIns(rx_client->msgs, StrNew(buf));
      Free(buf);
      return;
    }
    rx_client = rx_client->next;
  }
  IrcChannel *rx_channel = channel_head->next;
  IrcUser *rx_user;
  while (rx_channel)
    {
    if (!StrCmp(rx_channel->name, dst))
      { //PRIVMSG to channel
      rx_user = rx_channel->users->next;
      IrcPrintDateTag(buf);
      CatPrint(buf," %s:%s",tx_client->nick,msg);
      if(!GihonFifoIns(rx_channel->backlog,tmp=StrNew(buf,gihon_task))) {
        new_fifo=FifoI64New(BACKLOG_FIFO_SZ,gihon_task);
        GihonFifoIns(new_fifo,tmp);
        while(FifoI64Rem(rx_channel->backlog,&tmp)) {
	  if(!GihonFifoIns(new_fifo,tmp))
	    Free(tmp);
        }
        FifoI64Del(rx_channel->backlog);
        rx_channel->backlog=new_fifo;
      }
      while (rx_user)
        {
        rx_client = rx_user->client;
        if (rx_client!=tx_client)
	  {
	  StrCpy(buf,"");
	  wants_space=FALSE;
	  if(rx_client->caps&IRCD_CAP_SERVER_TIME) {
	    wants_space=TRUE;
	    IrcPrintDateTag(buf);
	  }
	  if(rx_client->caps&IRCD_CAP_MESSAGE_TAGS&&tx_client->client_tags)  {
	    wants_space=TRUE;
//Make a new argument(;)
	    if(*buf)  CatPrint(buf,";");
	    CatPrint(buf,"%s",tx_client->client_tags);
	  }
	  if(wants_space) CatPrint(buf," ");
	  if(!StrICmp(type,"TAGMSG")) //Don't include ':'
	    CatPrint(buf, ":%s!%s@%s %s %s\r\n", tx_client->nick, tx_client->username,
		  tx_client->host, type, dst);
	  else 
	    CatPrint(buf, ":%s!%s@%s %s %s :%s\r\n", tx_client->nick, tx_client->username,
		  tx_client->host, type, dst, msg);
	  GihonFifoIns(rx_client->msgs, StrNew(buf));
        }
        rx_user = rx_user->next;
      }
      Free(buf);
      return;
    }
    rx_channel = rx_channel->next;
  }
  Free(buf);
}
U0 IrcClientPrivMsg(IrcClient *tx_client,U8 *dst, U8 *msg) {
  return IrcClient_SendOut(tx_client,"PRIVMSG",dst,msg);
}
U0 IrcClientTagMsg(IrcClient *tx_client, U8 *dst) {
  return IrcClient_SendOut(tx_client,"TAGMSG",dst,"");
}

U0 IrcClientQuit(U8 *dst, IrcClient *tx_client, U8 *msg=NULL)
{
  U8 *buf = CAlloc(4096);
  IrcClient *rx_client = client_head->next;
  IrcChannel *rx_channel = channel_head->next;
  IrcUser *rx_user;
  while (rx_channel)
    {
    if (rx_channel->name&&!StrCmp(rx_channel->name, dst))
      { //PRIVMSG to channel
      rx_user = rx_channel->users->next;
      while (rx_user)
        {
        rx_client = rx_user->client;
        if (msg)
	  {
	  StrPrint(buf, ":%s!%s@%s QUIT :%s\r\n", tx_client->nick, tx_client->username,
	        tx_client->host, msg);
        }
        else
	  {
	  StrPrint(buf, ":%s!%s@%s QUIT\r\n", tx_client->nick, tx_client->username,
	        tx_client->host);
        }
        GihonFifoIns(rx_client->msgs, StrNew(buf));
        rx_user = rx_user->next;
      }
      return;
    }
    rx_channel = rx_channel->next;
  }
  Free(buf);
}

U0 IrcClientWho(IrcClient *client, U8 *dst)
{
  U8 *buf = CAlloc(4096);
  IrcChannel *channel = channel_head->next;
  IrcUser *user;
  while (channel)
    {
    if (!StrCmp(channel->name, dst))
      {
      user = channel->users->next;
      while (user)
        {
        StrPrint(buf, ":%s 352 %s %s %s %s * %s H :0 %s\r\n", ircd_hostname, client->username, dst,
	      user->client->username, user->client->host, user->client->nick,
	      user->client->realname);
        GihonFifoIns(client->msgs, StrNew(buf));
        user = user->next;
      }
      StrPrint(buf, ":%s 315 %s %s :End of /WHO list.\r\n", ircd_hostname, client->username, dst);
      GihonFifoIns(client->msgs, StrNew(buf));
      Free(buf);
      return;
    }
    channel = channel->next;
  }
  Free(buf);
}
I64 RecieveLn(IrcClient *client,U8 *buf,I64 max,I64) {
  I64 idx=0;
  I64 s = client->s;
  idx=recvLine(s,buf,max,0);
  return idx;
}
U0 IrcClientRxHandler(I64 s)
{
  IrcClient *client = CAlloc(sizeof(IrcClient),gihon_task);
  client->task = Fs;
  client->s = s;
  client->ip = 0;
  client->limit = IRCD_LIMIT_MAX;
  client->nick=StrNew("anon",gihon_task);
  client->msgs = FifoI64New(IRCD_TXFIFO_SIZE,gihon_task);
  client->idle = cnts.jiffies;
  IrcClientAdd(client);

//Allow client to connect first
  IrcClientNotice(client, "Welcome to Gihon IRC Server!");
  IrcClientNotice(client, "This server is running Gihon, an IRCd for TempleOS");
  I64 err = NULL;
  U8 *rxbuf = CAlloc(IRCD_RXBUF_SIZE);
  while (err > -1 && !client->disconnected)
    {
    err = RecieveLn(client, rxbuf, IRCD_RXBUF_SIZE, 0);
//AdamLog(rxbuf);
    //AdamLog("\n");
    client->limit--;
    if (client->limit)
      {
      StrUtil(rxbuf,SUF_REM_LEADING|SUF_REM_TRAILING);
      IrcParseCommand(client, rxbuf);
    }
    else
      {
      err = -1;
    }
    Sleep(10);
  }
  client->disconnected = TRUE;
  Free(rxbuf);
  IrcClientDel(client);
}

U0 IrcClientTxHandler()
{
  I64 sec = NULL;
  CDateStruct ds;
  U8 *buf = CAlloc(4096);
  I64 msg = NULL;
  IrcClient *client;
  while (1)
    {
st_disconnect:
    client = client_head->next;
    while (client)
      {
      if (client->disconnected)
        {
discon:
	client->disconnected = TRUE;
      }
      client = client->next;
    }

    if (sec != ds.sec)
      {
      client = client_head->next;
      while (client)
        {
        client->limit = Min(IRCD_LIMIT_MAX, client->limit+1);
        client = client->next;
      }
      sec = ds.sec;
    }

    client = client_head->next;
    while (client)
      {

      if (client->idle+IRCD_PING_INTERVAL <= cnts.jiffies)
        {
        StrPrint(buf, "PING :%s\r\n", ircd_hostname);
        GihonFifoIns(client->msgs, StrNew(buf));
	if(client->missed_pings>=3)
	  client->disconnected = TRUE;
        client->missed_pings++;
	client->idle = IRCD_PING_INTERVAL + cnts.jiffies;
      }
      while (FifoI64Cnt(client->msgs))
        {
        FifoI64Rem(client->msgs, &msg);
        send(client->s, msg, StrLen(msg),0);
        Free(msg);
      }
      client = client->next;
    }
    Date2Struct(&ds, Now);
    Sleep(10);
  }
}
