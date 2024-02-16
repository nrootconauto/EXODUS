U8 **ParseMotd(U8 *str, I64 *argc)
{
    I64 _argc = 0;
    U8 **_argv = NULL;
    U8 **_tmp = CAlloc(sizeof(U64) * StrLen(str));
    I64 i = 0;
    I64 s = 0;
    I64 len;
    while (i < StrLen(str) + 1)
    {
        switch (str[i])
        {
        case 0:
        case '\n':
            len = (str + i)-(str + s - 1);
            if (len - 1)
            {
                _tmp[_argc] = CAlloc(len);
                MemCpy(_tmp[_argc], str + s, len-1);
                _argc++;
            }
            s = i + 1;
            break;
        default:
            break;
        }
        i++;
    }
    *argc = _argc;
    _argv = CAlloc(sizeof(U64) * _argc);
    MemCpy(_argv, _tmp, sizeof(U64) * _argc);
    Free(_tmp);
    Free(str);
    return _argv;
}

I64 motd_line_cnt;
U8 **motd_lines = ParseMotd(FileRead("Motd.TXT"), &motd_line_cnt);