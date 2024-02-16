U0 IrcChannelAdd(U8 *name)
{
    IrcChannel *channel = CAlloc(sizeof(IrcChannel));
    channel->name = StrNew(name);
    channel->topic = CAlloc(2048);
    channel->users = CAlloc(sizeof(IrcUser));
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
    IrcChannel *prev = channel->prev;
    IrcChannel *next = channel->next;
    prev->next = next;
    next->prev = prev;
    //free ircuser list
    Free(channel->name);
    Free(channel);
    ircd_chans_total--;
}

IrcChannel *IrcGetChanByName(U8 *channame)
{
    IrcChannel *channel = channel_head;
    while (channel)
    {
        if (!StrCmp(channel->name, channame)) return channel;
        channel = channel->next;
    }
    return NULL;
}

U0 IrcChannelUserAdd(IrcChannel *channel, IrcClient *client, U64 flags=NULL)
{
    IrcUser *user = CAlloc(sizeof(IrcUser));
    IrcUser *users = channel->users;
    while (users->next)
    {
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
    while (users)
    {
        if (users->client==client)
        {
            prev=users->prev;
            next=users->next;
            if(prev) prev->next = next;
            if(next) next->prev = prev;
            Free(users);
            return;
        }
        users = users->next;
    }
}

U0 IrcChannelTopic(U8 *channame, IrcClient *client, U8 *topic)
{
    U8 *buf = CAlloc(2048);
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
                        DyadWrite(users->client->s,buf,StrLen(buf));
                        users = users->next;
                    }
                }
                else
                {
                    StrPrint(buf, ":%s 482 %s %s :You do not have access to change the topic on this channel\r\n",
                             ircd_hostname, client->username, channame);
                    DyadWrite(client->s,buf,StrLen(buf));
                }
                Free(buf);
                return;
            }
            user = user->next;
        }
    }
    Free(buf);
}

U0 IrcChannelJoin(U8 *channame, IrcClient *client)
{
    U64 flags = NULL;
    if (channame[0]==':') channame++;  // Fix for Revolution IRC client?
    IrcChannel *channel = IrcGetChanByName(channame);
    if (!channel)
    {
        IrcChannelAdd(channame);
        channel = IrcGetChanByName(channame);
        flags = IRCD_USERMODE_q;
    }
    if (channel)
    {
        IrcChannelUserAdd(channel, client, flags);
        IrcClientJoin(channame, client);
    }
}

U0 IrcChannelKick(U8 *channame, IrcClient *client, U8 *nick, U8 *reason=NULL)
{
    U8 *buf = CAlloc(2048);
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
                        DyadWrite(users->client->s,buf,StrLen(buf));
                        users = users->next;
                    }
                    IrcChannelUserDel(channel, kick_client);
                }
                else
                {
                    StrPrint(buf, ":%s 482 %s %s :You must be a channel half-operator\r\n",
                             ircd_hostname, client->username, channame);
                    DyadWrite(client->s,buf,StrLen(buf));
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
    U8 *buf = CAlloc(2048);
    IrcChannel *channel = IrcGetChanByName(channame);
    IrcClient *mode_client = NULL;
    IrcUser *user;
    IrcUser *users;
    if (nick)
    {   // Set user mode
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
                                DyadWrite(users->client->s,buf,StrLen(buf));
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
                                DyadWrite(client->s,buf,StrLen(buf));
                                break;
                            case IRCD_USERMODE_o:
                                StrPrint(buf, ":%s 482 %s %s :You must have channel op access or above to set channel mode #\r\n",
                                         ircd_hostname, client->username, channame);
                                buf[StrLen(buf)-3] = mode[1];
                                DyadWrite(client->s,buf,StrLen(buf));
                                break;
                            case IRCD_USERMODE_q:
                                StrPrint(buf, ":%s 482 %s %s :You must be the channel owner to set channel mode #\r\n",
                                         ircd_hostname, client->username, channame);
                                buf[StrLen(buf)-3] = mode[1];
                                DyadWrite(client->s,buf,StrLen(buf));
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
    {   // TODO: Set channel mode
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