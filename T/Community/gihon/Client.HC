#define IRCD_USERMODE_v 0x1
#define IRCD_USERMODE_h 0x2
#define IRCD_USERMODE_o 0x4
#define IRCD_USERMODE_a 0x8
#define IRCD_USERMODE_q 0x10
class IrcClient
{
    IrcClient *prev;
    IrcClient *next;
    CDyadStream *s;
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
    Bool disconnected;
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
};

extern U0 IrcParseCommand(IrcClient *client, U8 *str);
extern U0 IrcChannelsQuit(IrcClient *client, U8 *msg=NULL);

IrcClient *client_head = CAlloc(sizeof(IrcClient));
client_head->nick=StrNew("....");
client_head->username=StrNew("....");
client_head->realname=StrNew("....");
client_head->server=StrNew("....");
client_head->host=StrNew("....");
client_head->vhost=StrNew("....");
client_head->msgs=FifoI64New(1);


IrcChannel *channel_head = CAlloc(sizeof(IrcChannel));
channel_head->name=StrNew("#anonchan");
channel_head->topic=StrNew("Talk about cool stuff");
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

U0 IrcClientDel(IrcClient *client)
{
    IrcClient *prev = client->prev;
    IrcClient *next = client->next;
    if(prev) prev->next = next;
    if(next) next->prev = prev;
    Free(client->nick);
    Free(client->username);
    Free(client->realname);
    Free(client->server);
    Free(client->host);
    Free(client->vhost);
    Free(client);
    ircd_clients_total--;
}

IrcClient *IrcGetClientByNick(U8 *nick)
{
    IrcClient *client = client_head->next;
    while (client)
    {
        if (!StrCmp(client->nick, nick)) return client;
        client = client->next;
    }
    return NULL;
}

U0 IrcClientSetNick(IrcClient *client, U8 *nick)
{
    I64 i;
    U8 *buf = CAlloc(2048);
    IrcClient *chk_client = client_head->next;

    // check if in use, owned, forbidden, etc..
    while (chk_client)
    {
        if (!StrICmp(chk_client->nick, nick))
        {
            StrPrint(buf, ":%s 433 %s %s :Nickname is already in use.\r\n", ircd_hostname, client->username,
                     nick);
            DyadWrite(client->s,buf,StrLen(buf));
            Free(buf);
            return;
        }
        chk_client = chk_client->next;
    }
    for (i=0; i<service_cnt; i++)
    {
        if (!StrICmp(service_nick[i], nick))
        {
            StrPrint(buf, ":%s 432 %s %s :Invalid nickname: Reserved for Services\r\n", ircd_hostname, client->username,
                     nick);
            DyadWrite(client->s,buf,StrLen(buf));
            Free(buf);
            return;
        }
    }

    client->nick = StrNew(nick);
    Free(buf);
}

U0 IrcClientSetUser(IrcClient *client, U8 *username, U8 *host, U8 *server, U8 *realname)
{
    // check user params
    client->username = StrNew(username);
    client->host = StrNew(host);
    client->realname = StrNew(realname);
    client->server = StrNew(server);
}

U0 IrcClientMotd(IrcClient *client)
{
    I64 i;
    U8 *buf = CAlloc(2048);
    StrPrint(buf, ":%s 375 %s :-\r\n", ircd_hostname, client->username);
    DyadWrite(client->s,buf,StrLen(buf));
    for (i=0; i<motd_line_cnt; i++)
    {
        StrPrint(buf, ":%s 372 %s :%s\r\n", ircd_hostname, client->username, motd_lines[i]);
        DyadWrite(client->s,buf,StrLen(buf));
    }
    StrPrint(buf, ":%s 376 %s :>\r\n", ircd_hostname, client->username);
    DyadWrite(client->s,buf,StrLen(buf));
    Free(buf);
}

U0 IrcClientNotice(IrcClient *client, U8 *msg)
{
    U8 *buf = CAlloc(2048);
    StrPrint(buf, ":%s NOTICE Auth :%s\r\n", ircd_hostname, msg);
    DyadWrite(client->s,buf,StrLen(buf));
    Free(buf);
}

U0 IrcClientJoin(U8 *dst, IrcClient *tx_client)
{
    U8 *buf = CAlloc(2048);
    IrcClient *rx_client = client_head->next;
    IrcChannel *rx_channel = channel_head->next;
    IrcUser *rx_user;
    while (rx_channel)
    {
        if (!StrCmp(rx_channel->name, dst))
        {   //PRIVMSG to channel
            rx_user = rx_channel->users->next;
            while (rx_user)
            {
                rx_client = rx_user->client;
                StrPrint(buf, ":%s!%s@%s JOIN :%s\r\n", tx_client->nick, tx_client->username,
                         tx_client->host, dst);
                DyadWrite(rx_client->s,buf,StrLen(buf));
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
    U8 *buf = CAlloc(2048);
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
            DyadWrite(client->s,buf,StrLen(buf));
            StrPrint(buf, ":%s 366 %s %s :End of /NAMES list.\r\n", ircd_hostname, client->username, dst);
            DyadWrite(client->s,buf,StrLen(buf));
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
    U8 *buf = CAlloc(2048);
    IrcChannel *channel = channel_head->next;
    while (channel)
    {
        if (!StrCmp(channel->name, dst))
        {
            if (StrLen(channel->topic))
            {
                StrPrint(buf, ":%s 332 %s %s :%s\r\n", ircd_hostname, client->username, dst, channel->topic);
                DyadWrite(client->s,buf,StrLen(buf));
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
    U8 *buf = CAlloc(2048);
    IrcClient *rx_client = client_head->next;
    IrcChannel *rx_channel = channel_head->next;
    IrcUser *rx_user;
    while (rx_channel)
    {
        if (!StrCmp(rx_channel->name, dst))
        {   //PRIVMSG to channel
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
                DyadWrite(rx_client->s,buf,StrLen(buf));
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
    U8 *buf = CAlloc(2048);
    StrPrint(buf, ":%s PONG %s :%s\r\n", ircd_hostname, ircd_hostname, msg);
    DyadWrite(client->s,buf,StrLen(buf));
    Free(buf);
}

U0 IrcClientPrivMsg(IrcClient *tx_client, U8 *dst, U8 *msg)
{
    U8 *buf = CAlloc(2048);
    IrcClient *rx_client = client_head->next;
    while (rx_client)
    {
        if (!StrCmp(rx_client->nick, dst))
        {   //PRIVMSG to nick
            StrPrint(buf, ":%s!%s@%s PRIVMSG %s :%s\r\n", tx_client->nick, tx_client->username,
                     tx_client->host, dst, msg);
            DyadWrite(rx_client->s,buf,StrLen(buf));
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
        {   //PRIVMSG to channel
            rx_user = rx_channel->users->next;
            while (rx_user)
            {
                rx_client = rx_user->client;
                if (!!StrCmp(rx_client->nick, tx_client->nick))
                {
                    StrPrint(buf, ":%s!%s@%s PRIVMSG %s :%s\r\n", tx_client->nick, tx_client->username,
                             tx_client->host, dst, msg);
                    DyadWrite(rx_client->s,buf,StrLen(buf));
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

U0 IrcClientQuit(U8 *dst, IrcClient *tx_client, U8 *msg=NULL)
{
    U8 *buf = CAlloc(2048);
    IrcClient *rx_client = client_head->next;
    IrcChannel *rx_channel = channel_head->next;
    IrcUser *rx_user;
    while (rx_channel) {
        if (!StrCmp(rx_channel->name, dst)) { //PRIVMSG to channel
            rx_user = rx_channel->users->next;
            while (rx_user) {
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
                DyadWrite(rx_client->s,buf,StrLen(buf));
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
    U8 *buf = CAlloc(2048);
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
                DyadWrite(client->s,buf,StrLen(buf));
                user = user->next;
            }
            StrPrint(buf, ":%s 315 %s %s :End of /WHO list.\r\n", ircd_hostname, client->username, dst);
            DyadWrite(client->s,buf,StrLen(buf));
            Free(buf);
            return;
        }
        channel = channel->next;
    }
    Free(buf);
}
U0 IrcClientReadLine(CDyadStream *s,U8 *rxbuf,I64 len,IrcClient *client) {
    rxbuf=StrNew(rxbuf);
    StrUtil(rxbuf,SUF_REM_TRAILING|SUF_REM_LEADING);
    client->limit--;
    if (client->limit) {
        IrcParseCommand(client, rxbuf);
    } else {
        IrcChannelsQuit(client, "Excess flood");
        client->disconnected = TRUE;
	DyadClose(s);
    }
    Free(rxbuf);
}

U0 IrcClientClose(CDyadStream *s,IrcClient *cl) {
  IrcChannelsQuit(cl);
  IrcClientDel(cl);
}
U0 IrcClientHandler(CDyadStream *s,I64 srv)
{
    IrcClient *client = CAlloc(sizeof(IrcClient));
    client->s = s;
    client->ip = DyadGetAddress(s);
    client->limit = IRCD_LIMIT_MAX;
    client->msgs = FifoI64New(IRCD_TXFIFO_SIZE);
    client->idle = cnts.jiffies;
    client->nick=StrNew("....");
    client->username=StrNew("....");
    client->realname=StrNew("....");
    client->server=StrNew("....");
    client->host=StrNew("....");
    client->vhost=StrNew("....");
    client->msgs=FifoI64New(1);
    DyadSetReadCallback(s,DYAD_EVENT_LINE,&IrcClientReadLine,client);
    DyadSetCloseCallback(s,DYAD_EVENT_CLOSE,&IrcClientClose,client);
    IrcClientAdd(client);
    IrcClientNotice(client, "Welcome to Gihon IRC Server!");
    IrcClientNotice(client, "This server is running Gihon, an IRCd for TempleOS");
}
