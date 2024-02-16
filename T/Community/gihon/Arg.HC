U0 FreeArgs(I64 argc, U8 **argv)
{
    I64 i;
    for (i = 0; i < argc; i++)
    {
        Free(argv[i]);
    }
    if (argv)
    {
        Free(argv);
    }
}

U8 **ParseArgs(U8 *str, I64 *argc)
{   // Return argc, argv from str.
    Bool quoted = FALSE;
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
        case ' ':
            if (!quoted)
            {
                len = (str + i)-(str + s - 1);
                if (str[i - 1] == '"')
                {
                    len--;
                }
                if (len - 1)
                {
                    _tmp[_argc] = CAlloc(len);
                    MemCpy(_tmp[_argc], str + s, len-1);
                    _argc++;
                }
                s = i + 1;
            }
            break;
        case '"':
            quoted = !quoted;
            if (quoted)
            {
                s = i + 1;
            }
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
    return _argv;
}