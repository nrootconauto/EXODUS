U0 IrcPrintDateTag(U8 *buf,CDate when=0) {
  if(!when) when=Now;
  CDateStruct ds;
  Date2Struct(&ds,when);
  StrPrint(buf,"@time=%d-%d-%dT%d:%d:%d.%dZ",ds.year,ds.mon,ds.day_of_mon,
	ds.hour,ds.min,ds.sec,ds.sec100
	);
}

U0 IrcChannelAdd(U8 *name)
{
  IrcChannel *channel = CAlloc(sizeof(IrcChannel),gihon_task);
  channel->name = StrNew(name,gihon_task);
  channel->topic = CAlloc(4096,gihon_task);
  channel->users = CAlloc(sizeof(IrcUser),gihon_task);
  channel->backlog=FifoI64New(BACKLOG_FIFO_SZ,gihon_task);
  IrcChannel *channels = channel_head;
  while (channels->next)
  {
    channels = channels->next;
  }
  channel->prev = channels;
  channels->next = channel;
  ircd_chans_total++;
}

U0 IrcChannelDel(IrcChannel *channel)
{
  U8 *msg;
  IrcChannel *prev = channel->prev;
  IrcChannel *next = channel->next;
  if(prev) prev->next = next;
  if(next) next->prev = prev;
  while(FifoI64Rem(channel->backlog,&msg))
    Free(msg);
  FifoI64Del(channel->backlog);
  Free(channel->name);
  Free(channel);
  ircd_chans_total--;
}

U0 IrcList(IrcClient *client) {
  IrcChannel *channel = channel_head;
  IrcUser *u;
  U8 buf[4096];
  I64 users;
  GihonFifoIns(client->msgs, MStrPrint(":%s 321 %s Channel :Users  Name\n",ircd_hostname,client->nick));
  while (channel)
    {
    if (channel->name) {
      u=channel->users;
      users=0;
      while(u&&(u=u->next)) 
	users++;
      StrPrint(buf,":%s 322 %s %s %d :'%s'\n",ircd_hostname,client->nick,channel->name,users,channel->topic);
      GihonFifoIns(client->msgs, StrNew(buf));
    }
    channel = channel->next;
  }  
  GihonFifoIns(client->msgs, MStrPrint(":%s 323 %s :End of /LIST\n",ircd_hostname,client->nick));
}

IrcChannel *IrcGetChanByName(U8 *channame)
{
  IrcChannel *channel = channel_head;
  while (channel)
    {
    if (channel->name&&!StrCmp(channel->name, channame)) return channel;
    channel = channel->next;
  }
  return NULL;
}

U0 IrcChannelUserAdd(IrcChannel *channel, IrcClient *client, U64 flags=NULL)
{
  IrcUser *user = CAlloc(sizeof(IrcUser),gihon_task);
  IrcUser *users = channel->users;
  while (users->next)
    {
    if (users->client == client)
      return ; //Already on channel
    users = users->next;
  }
  user->client = client;
  user->flags = flags;
  user->prev = users;
  users->next = user;
}

U0 IrcChannelUserDel(IrcChannel *channel, IrcClient *client)
{
  IrcUser *users = channel->users->next;
  IrcUser *prev = NULL;
  IrcUser *next = NULL;
re_enter:
  while (users)
    {
    if (users->client==client)
      {
      prev=users->prev;
      next=users->next;
      if(prev) prev->next = next;
      if(next) next->prev = prev;
      Free(users);
      users=next;
//Maybe there are multiple references to a user in a channel
      goto re_enter;
    }
    users = users->next;
  }
}

U0 IrcChannelTopic(U8 *channame, IrcClient *client, U8 *topic)
{
  U8 *buf = CAlloc(4096);
  IrcChannel *channel = IrcGetChanByName(channame);
  IrcUser *user;
  IrcUser *users;
  if (channel)
    {
    user = channel->users->next;
    while (user)
      {
      if (user->client==client)
        {
        if (user->flags >= IRCD_USERMODE_o)
	  {
	  StrPrint(channel->topic, topic);
	  users = channel->users->next;
	  while (users)
	    {
	    StrPrint(buf, ":%s!%s@%s TOPIC %s :%s\r\n", client->nick, client->username,
		  client->host, channame, channel->topic);
	    GihonFifoIns(users->client->msgs, StrNew(buf));
	    users = users->next;
	  }
        }
        else
	  {
	  StrPrint(buf, ":%s 482 %s %s :You do not have access to change the topic on this channel\r\n",
	        ircd_hostname, client->username, channame);
	  GihonFifoIns(client->msgs, StrNew(buf));
        }
        Free(buf);
        return;
      }
      user = user->next;
    }
  }
  Free(buf);
}

#include "MessageTag.HC";
CDate IrcPrsTimeTag(U8 *str,CDateStruct *ds=NULL) {
  U8 *buf=IrcParseMessageTag(str,"time");
  CDateStruct _ds;
  if(!ds) ds=&_ds;
  MemSet(ds,0,sizeof CDateStruct);
  if(!buf) return 0;
  I64 yr,mon,day,hr,mn,sc,s100;
  StrScan(buf,"%d-%d-%dT%d:%d:%d.%dZ",&yr,&mon,&day,
        &hr,&mn,&sc,&s100
        );
  ds->year=yr;
  ds->mon=mon;
  ds->day_of_mon=day;
  ds->hour=hr;
  ds->min=mn;
  ds->sec=sc;
  ds->sec100=s100;
  Free(buf);
  return Struct2Date(ds);
}
I64 DateCmp(CDate a,CDate b) {
  if(a.date>b.date) return 1;
  if(a.date<b.date) return -1;
  if(a.time>b.time) return 1;
  if(a.time<b.time) return -1;
  return 0;
}
U0 IrcBacklog(IrcClient *to,U8 *name) {
  IrcChannel *channel = channel_head->next;
  CFifoI64 *shalow;
  U8 *tmp,buf[4096],who[4096],msg[4096],time_tag[4096];
  U8 *msg_ptr=msg,*who_ptr=who,*time_tag_ptr=time_tag;
  while(channel) {
    if(channel->name&&!StrCmp(channel->name,name)) {
      shalow=MAllocIdent(channel->backlog);
      while(FifoI64Rem(shalow,&tmp)) {
        StrScan(tmp,"%s %s:%s",&time_tag_ptr,&who_ptr,&msg_ptr);
        "%T,%T\n",to->last_connect,IrcPrsTimeTag(time_tag);
        "%D,%D\n",to->last_connect,IrcPrsTimeTag(time_tag);
        if(to->last_connect<=IrcPrsTimeTag(time_tag)) {
	  if(to->caps&IRCD_CAP_SERVER_TIME) {
	    StrPrint(buf, "%s :%s!%s@%s PRIVMSG %s :%s\r\n", time_tag, who, to->username,to->host, name, msg);
	  } else 
	    StrPrint(buf, ":%s!%s@%s PRIVMSG %s :%s\r\n", who, to->username,to->host, name, msg);
          GihonFifoIns(to->msgs, StrNew(buf));
        }
      }
      Free(shalow);
      break;
    }
    channel=channel->next;
  }
}


U0 IrcChannelJoin(U8 *_channame, IrcClient *client)
{
  U64 flags  = IRCD_USERMODE_q;
  IrcChannel *channel;
  U8 *orig = StrNew(_channame),*channame,*time_code;
  _channame = orig;
  while (*_channame) {
    channame = _channame;
    if (StrFirstOcc(channame,",")) {
      _channame=StrFirstOcc(channame,",")+1;
      _channame[-1]=0;
    } else
      _channame += StrLen(_channame);
    if (channame[0]==':') channame++;  // Fix for Revolution IRC client?
    channel = IrcGetChanByName(channame);
    if (!channel)
      {
        IrcChannelAdd(channame);
        channel = IrcGetChanByName(channame);
    }
    if (channel)
      {
      IrcChannelUserAdd(channel, client, flags);
      IrcClientJoin(channame, client);
      IrcBacklog(client,channame);

    }
  }
  Free(orig);
}

U0 IrcChannelKick(U8 *channame, IrcClient *client, U8 *nick, U8 *reason=NULL)
{
  U8 *buf = CAlloc(4096);
  IrcChannel *channel = IrcGetChanByName(channame);
  IrcClient *kick_client = IrcGetClientByNick(nick);
  IrcUser *user;
  IrcUser *users;
  if (channel && kick_client)
    {
    user = channel->users->next;
    while (user)
      {
      if (user->client==client)
        {
        if (user->flags >= IRCD_USERMODE_h)
	  {
	  users = channel->users->next;
	  while (users)
	    {
	    StrPrint(buf, ":%s!%s@%s KICK %s %s :%s\r\n", client->nick, client->username,
		  client->host, channame, nick, reason);
	    GihonFifoIns(users->client->msgs, StrNew(buf));
	    users = users->next;
	  }
	  IrcChannelUserDel(channel, kick_client);
        }
        else
	  {
	  StrPrint(buf, ":%s 482 %s %s :You must be a channel half-operator\r\n",
	        ircd_hostname, client->username, channame);
	  GihonFifoIns(client->msgs, StrNew(buf));
        }
        Free(buf);
        return;
      }
      user = user->next;
    }
  }
  Free(buf);
}

U0 IrcChannelMode(U8 *channame, IrcClient *client, U8 *mode, U8 *nick=NULL)
{
  U64 res = 0;
  Bool set = FALSE;
  U8 *buf = CAlloc(4096);
  IrcChannel *channel = IrcGetChanByName(channame);
  IrcClient *mode_client = NULL;
  IrcUser *user;
  IrcUser *users;
  if (nick)
    { // Set user mode
    mode_client = IrcGetClientByNick(nick);
    if (!mode_client)
      {
// nick does not exist?
      Free(buf);
      return;
    }
    else
      {
      user = channel->users->next;
      while (user)
        {
        if (user->client==client)
	  {
	  if ((!StrCmp("-v", mode) || !StrCmp("+v", mode)))
	    {
	    set = TRUE;
	    if (user->flags < IRCD_USERMODE_h)
	      {
	      res = IRCD_USERMODE_h;
	    }
	  }
	  if ((!StrCmp("-h", mode) || !StrCmp("+h", mode)))
	    {
	    set = TRUE;
	    if (user->flags < IRCD_USERMODE_o)
	      {
	      res = IRCD_USERMODE_o;
	    }
	  }
	  if ((!StrCmp("-o", mode) || !StrCmp("+o", mode)))
	    {
	    set = TRUE;
	    if (user->flags < IRCD_USERMODE_q)
	      {
	      res = IRCD_USERMODE_q;
	    }
	  }

	  if (set)
	    {
	    if (!res)
	      {
	      users = channel->users->next;
	      while (users)
	        {
	        if (users->client==mode_client)
		  {
		  if (mode[0]=='-')
		    {
		    if (user->flags > users->flags)
		      {
		      users->flags = NULL;
		    }
		  }
		  if (mode[0]=='+')
		    {
		    switch (mode[1])
		      {
		      case 'v':
		        users->flags = Max(users->flags, IRCD_USERMODE_v);
		        break;
		      case 'h':
		        users->flags = Max(users->flags, IRCD_USERMODE_h);
		        break;
		      case 'o':
		        users->flags = Max(users->flags, IRCD_USERMODE_o);
		        break;
		      default:
		        break;
		    }
		  }
	        }
	        StrPrint(buf, ":%s!%s@%s MODE %s %s %s\r\n", client->nick, client->username,
		      client->host, channame, mode, nick);
	        GihonFifoIns(users->client->msgs, StrNew(buf));
	        users = users->next;
	      }
	    }
	    else
	      {
	      switch (res)
	        {
	        case IRCD_USERMODE_h:
		  StrPrint(buf, ":%s 482 %s %s :You must have channel halfop access or above to set channel mode #\r\n",
		        ircd_hostname, client->username, channame);
		  buf[StrLen(buf)-3] = mode[1];
		  GihonFifoIns(client->msgs, StrNew(buf));
		  break;
	        case IRCD_USERMODE_o:
		  StrPrint(buf, ":%s 482 %s %s :You must have channel op access or above to set channel mode #\r\n",
		        ircd_hostname, client->username, channame);
		  buf[StrLen(buf)-3] = mode[1];
		  GihonFifoIns(client->msgs, StrNew(buf));
		  break;
	        case IRCD_USERMODE_q:
		  StrPrint(buf, ":%s 482 %s %s :You must be the channel owner to set channel mode #\r\n",
		        ircd_hostname, client->username, channame);
		  buf[StrLen(buf)-3] = mode[1];
		  GihonFifoIns(client->msgs, StrNew(buf));
		  break;
	        default:
		  break;
	      }
	    }
	  }
	  Free(buf);
	  return;
        }
        user = user->next;
      }
    }
  }
  else
    { // TODO: Set channel mode
    if (channel)
      {

    }

  }
  Free(buf);
}

U0 IrcChannelPart(U8 *channame, IrcClient *client, U8 *msg=NULL)
{
  IrcChannel *channel = IrcGetChanByName(channame);
  if (channel)
    {
    IrcChannelUserDel(channel, client);
    IrcClientPart(channame, client, msg);
  }
}

U0 IrcChannelsQuit(IrcClient *client, U8 *msg=NULL)
{
  IrcChannel *channel = channel_head->next;
  while (channel)
    {
    IrcChannelUserDel(channel, client);
    IrcClientQuit(channel->name, client, msg);
    channel = channel->next;
  }
}
