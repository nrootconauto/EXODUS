#define IRCD_CMD_ADMIN  0
#define IRCD_CMD_AWAY   1
#define IRCD_CMD_CNOTICE        2
#define IRCD_CMD_CPRIVMSG       3
#define IRCD_CMD_CONNECT        4
#define IRCD_CMD_DIE    5
#define IRCD_CMD_ENCAP  6
#define IRCD_CMD_ERROR  7
#define IRCD_CMD_HELP   8
#define IRCD_CMD_INFO   9
#define IRCD_CMD_INVITE 10
#define IRCD_CMD_ISON   11
#define IRCD_CMD_JOIN   12
#define IRCD_CMD_KICK   13
#define IRCD_CMD_KILL   14
#define IRCD_CMD_KNOCK  15
#define IRCD_CMD_LINKS  16
#define IRCD_CMD_LIST   17
#define IRCD_CMD_LUSERS 18
#define IRCD_CMD_MODE   19
#define IRCD_CMD_MOTD   20
#define IRCD_CMD_NAMES  21
#define IRCD_CMD_NAMESX 22
#define IRCD_CMD_NICK   23
#define IRCD_CMD_NOTICE 24
#define IRCD_CMD_OPER   25
#define IRCD_CMD_PART   26
#define IRCD_CMD_PASS   27
#define IRCD_CMD_PING   28
#define IRCD_CMD_PONG   29
#define IRCD_CMD_PRIVMSG        30
#define IRCD_CMD_QUIT   31
#define IRCD_CMD_REHASH 32
#define IRCD_CMD_RESTART        33
#define IRCD_CMD_RULES  34
#define IRCD_CMD_SERVER 35
#define IRCD_CMD_SERVICE        36
#define IRCD_CMD_SERVLIST       37
#define IRCD_CMD_SQUERY 38
#define IRCD_CMD_SQUIT  39
#define IRCD_CMD_SETNAME        40
#define IRCD_CMD_SILENCE        41
#define IRCD_CMD_STATS  42
#define IRCD_CMD_SUMMON 43
#define IRCD_CMD_TIME   44
#define IRCD_CMD_TOPIC  45
#define IRCD_CMD_TRACE  46
#define IRCD_CMD_UHNAMES        47
#define IRCD_CMD_USER   48
#define IRCD_CMD_USERHOST       49
#define IRCD_CMD_USERIP 50
#define IRCD_CMD_USERS  51
#define IRCD_CMD_VERSION        52
#define IRCD_CMD_WALLOPS        53
#define IRCD_CMD_WATCH  54
#define IRCD_CMD_WHO    55
#define IRCD_CMD_WHOIS  56
#define IRCD_CMD_WHOWAS 57

#define IRCD_CMDS_MAX    58

U8 **ircd_commands = CAlloc(sizeof(U64) * IRCD_CMDS_MAX);

ircd_commands[IRCD_CMD_ADMIN] = "ADMIN";
ircd_commands[IRCD_CMD_AWAY] = "AWAY";
ircd_commands[IRCD_CMD_CNOTICE] = "CNOTICE";
ircd_commands[IRCD_CMD_CPRIVMSG] = "CPRIVMSG";
ircd_commands[IRCD_CMD_CONNECT] = "CONNECT";
ircd_commands[IRCD_CMD_DIE] = "DIE";
ircd_commands[IRCD_CMD_ENCAP] = "ENCAP";
ircd_commands[IRCD_CMD_ERROR] = "ERROR";
ircd_commands[IRCD_CMD_HELP] = "HELP";
ircd_commands[IRCD_CMD_INFO] = "INFO";
ircd_commands[IRCD_CMD_INVITE] = "INVITE";
ircd_commands[IRCD_CMD_ISON] = "ISON";
ircd_commands[IRCD_CMD_JOIN] = "JOIN";
ircd_commands[IRCD_CMD_KICK] = "KICK";
ircd_commands[IRCD_CMD_KILL] = "KILL";
ircd_commands[IRCD_CMD_KNOCK] = "KNOCK";
ircd_commands[IRCD_CMD_LINKS] = "LINKS";
ircd_commands[IRCD_CMD_LIST] = "LIST";
ircd_commands[IRCD_CMD_LUSERS] = "LUSERS";
ircd_commands[IRCD_CMD_MODE] = "MODE";
ircd_commands[IRCD_CMD_MOTD] = "MOTD";
ircd_commands[IRCD_CMD_NAMES] = "NAMES";
ircd_commands[IRCD_CMD_NAMESX] = "NAMESX";
ircd_commands[IRCD_CMD_NICK] = "NICK";
ircd_commands[IRCD_CMD_NOTICE] = "NOTICE";
ircd_commands[IRCD_CMD_OPER] = "OPER";
ircd_commands[IRCD_CMD_PART] = "PART";
ircd_commands[IRCD_CMD_PASS] = "PASS";
ircd_commands[IRCD_CMD_PING] = "PING";
ircd_commands[IRCD_CMD_PONG] = "PONG";
ircd_commands[IRCD_CMD_PRIVMSG] = "PRIVMSG";
ircd_commands[IRCD_CMD_QUIT] = "QUIT";
ircd_commands[IRCD_CMD_REHASH] = "REHASH";
ircd_commands[IRCD_CMD_RESTART] = "RESTART";
ircd_commands[IRCD_CMD_RULES] = "RULES";
ircd_commands[IRCD_CMD_SERVER] = "SERVER";
ircd_commands[IRCD_CMD_SERVICE] = "SERVICE";
ircd_commands[IRCD_CMD_SERVLIST] = "SERVLIST";
ircd_commands[IRCD_CMD_SQUERY] = "SQUERY";
ircd_commands[IRCD_CMD_SQUIT] = "SQUIT";
ircd_commands[IRCD_CMD_SETNAME] = "SETNAME";
ircd_commands[IRCD_CMD_SILENCE] = "SILENCE";
ircd_commands[IRCD_CMD_STATS] = "STATS";
ircd_commands[IRCD_CMD_SUMMON] = "SUMMON";
ircd_commands[IRCD_CMD_TIME] = "TIME";
ircd_commands[IRCD_CMD_TOPIC] = "TOPIC";
ircd_commands[IRCD_CMD_TRACE] = "TRACE";
ircd_commands[IRCD_CMD_UHNAMES] = "UHNAMES";
ircd_commands[IRCD_CMD_USER] = "USER";
ircd_commands[IRCD_CMD_USERHOST] = "USERHOST";
ircd_commands[IRCD_CMD_USERIP] = "USERIP";
ircd_commands[IRCD_CMD_USERS] = "USERS";
ircd_commands[IRCD_CMD_VERSION] = "VERSION";
ircd_commands[IRCD_CMD_WALLOPS] = "WALLOPS";
ircd_commands[IRCD_CMD_WATCH] = "WATCH";
ircd_commands[IRCD_CMD_WHO] = "WHO";
ircd_commands[IRCD_CMD_WHOIS] = "WHOIS";
ircd_commands[IRCD_CMD_WHOWAS] = "WHOWAS";

I64 IrcMatchCommand(U8 *str)
{
    I64 i;
    for (i=0; i<IRCD_CMDS_MAX; i++)
    {
        if (!StrICmp(str, ircd_commands[i])) return i;
    }
    return -1;
}

U0 IrcParseCommand(IrcClient *client, U8 *str)
{
    U8 **argv;
    I64 argc = NULL;
    I64 cmd = -1;
    argv = ParseArgs(str, &argc);
    if (argc)
    {
        cmd = IrcMatchCommand(argv[0]);
        switch (cmd)
        {
        case IRCD_CMD_JOIN:
            if (argc==2)
            {
                IrcChannelJoin(argv[1], client);
                				IrcClientTopic(client, argv[1]);
                IrcClientNames(client, argv[1]);
            }
            break;
        case IRCD_CMD_KICK:
            if (argc>3)
            {
                IrcChannelKick(argv[1], client, argv[2], StrFirstOcc(str, ":")+1);
            }
            else
            {
                IrcChannelKick(argv[1], client, argv[2], argv[2]);
            }
            break;
        case IRCD_CMD_MODE:
            if (argc==3)
            {
                IrcChannelMode(argv[1], client, argv[2]);
            }
            if (argc==4)
            {
                IrcChannelMode(argv[1], client, argv[2], argv[3]);
            }
            break;
        case IRCD_CMD_NICK:
            if (argc==2)
            {
                IrcClientSetNick(client, argv[1]);
            }
            break;
        case IRCD_CMD_PART:
            if (argc==2)
            {
                IrcChannelPart(argv[1], client);
            }

            if (argc>2)
            {
                IrcChannelPart(argv[1], client, StrFirstOcc(str, ":")+1);
            }
            break;
        case IRCD_CMD_PING:
            if (argc==2)
            {
                IrcClientPing(client, argv[1]);
            }
            break;
        case IRCD_CMD_PRIVMSG:
            if (argc>2)
            {
		TOSPrint("LOOK:%s,%p\n",client->nick,client->s);
                IrcClientPrivMsg(client, argv[1], StrFirstOcc(str, ":")+1);
            }
            break;
        case IRCD_CMD_QUIT:
            if (argc==1)
            {
                IrcChannelsQuit(client);
            }
            if (argc>1)
            {
                IrcChannelsQuit(client, StrFirstOcc(str, ":")+1);
            }
            break;
        case IRCD_CMD_TOPIC:
            if (argc>2)
            {
                IrcChannelTopic(argv[1], client, StrFirstOcc(str, ":")+1);
            }
            break;
        case IRCD_CMD_USER:
            if (argc>4)
            {
                IrcClientSetUser(client, argv[1], argv[2], argv[3], StrFirstOcc(str, ":")+1); // for now
                IrcClientMotd(client);
            }
            break;
        case IRCD_CMD_WHO:
            if (argc==2)
            {
                IrcClientWho(client, argv[1]);
            }
            break;
        default:
            break;
        }
        FreeArgs(argc, argv);
    }
    client->idle = __GetTicks;
}