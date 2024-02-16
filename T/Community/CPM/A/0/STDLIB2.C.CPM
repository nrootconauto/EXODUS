/*
	STDLIB2.C -- for BDS C v1.6 --  1/86
	Copyright (c) 1982, 1986 by BD Software, Inc.

	The files STDLIB1.C, STDLIB2.C and STDLIB3.C contain the source
	listings for all functions present in the DEFF.CRL library object
 	file. (Note: DEFF2.CRL contains the .CSM-coded portions of the
	library.)

	STDLIB2.C contains mainly formatted text I/O functions:

	printf 	fprintf	sprintf	lprintf	_spr
	scanf	fscanf	sscanf	_scn
	getline	puts
	putdec

*/

#include <stdio.h>

#define iseof(x) (x==CPMEOF || x==EOF || x==0)

char toupper(), isdigit();

printf(format)
char *format;
{
	int putchar();
	return _spr(&format, &putchar);
}

int fprintf(fp, format)
char *format;
FILE *fp;
{
	int _fputc();
	return _spr(&format, &_fputc, fp);
}

sprintf(buffer, format)
char *buffer, *format;
{
	int _sspr();
	_spr(&format, &_sspr, &buffer);
	*buffer = '\0';
}

_sspr(c,strptr)
char **strptr;
{
	*(*strptr)++ = c;
}

int lprintf(format)
char *format;
{
	int _fputc();
	return _spr(&format, &_fputc, stdlst);
}

int _fputc(c,fp)
FILE *fp;
{
	if (c == '\n')
		if (fputc('\r', fp) == ERROR)
			return ERROR;
	if (fputc(c, fp) == ERROR)
		return ERROR;
	return OK;
}	

int scanf(format)
char *format;
{
	int getchar(),ungetch();
	return _scn(&format, getchar, ungetch);
}

int fscanf(fp,format)
char *format;
FILE *fp;
{
	int fgetc(),ungetc();
	return _scn(&format, fgetc, ungetc, fp);
}

int sscanf(line,format)
char *line, *format;
{
	int _sgetc(), _sungetc();
	return _scn(&format, &_sgetc, &_sungetc, &line);
}


/*
	Internal routine used by "_spr" to perform ascii-
	to-decimal conversion and update an associated pointer:
*/

int _gv2(sptr)
char **sptr;
{
	int n;
	n = 0;
	while (isdigit(**sptr)) n = 10 * n + *(*sptr)++ - '0';
	return n;
}

char _uspr(string, n, base)
char **string;
unsigned n;
{
	char length;
	if (n<base) {
		*(*string)++ = (n < 10) ? n + '0' : n + 55;
		return 1;
	}
	length = _uspr(string, n/base, base);
	_uspr(string, n%base, base);
	return length + 1;
}


int _bc(c,b)
char c,b;
{
	if (isalpha(c = toupper(c)))
		c -= 55;
	else if (isdigit(c))
		c -= 0x30;
	else
		return ERROR;

	if (c > b-1)
		return ERROR;
	else
		return c;
}

_spr(fmt,putcf,arg1)
int (*putcf)();
char **fmt;
{
	char _uspr(), c, base, *format, ljflag, prefill, *wptr;
	char wbuf[20];	/* 20 is enough for all but %s */
	int length, *args, width, precision;
	format = *fmt++;    /* fmt first points to the format string	*/
	args = fmt;	    /* now fmt points to the first arg value	*/

	while (c = *format++)
	  if (c == '%') {
	    wptr = wbuf;
	    precision = 32767;
	    width = ljflag = 0;
	    prefill = ' ';

	    if (*format == '-') {
		    format++;
		    ljflag=1;
	     }

	    if (*format == '0')	prefill = '0';

	    if (isdigit(*format)) width = _gv2(&format);

	    if (*format == '.') {
		    format++;
		    precision = _gv2(&format);
	     }

	    if (*format == 'l') format++;	/* no longs here */

	    switch(c = *format++) {
		case 'd':  if (*args < 0) {
				*wptr++ = '-';
				*args = -*args;
				width--;
			    }
		case 'u':  base = 10; goto val;
		case 'b':  base = 2; goto val;
		case 'x':  base = 16; goto val;
		case 'o':  base = 8;

		val:       width -= _uspr(&wptr,*args++,base);
			   goto pad;

		case 'c':  *wptr++ = *args++;
			   width--;
			   goto pad;

		pad:	   *wptr = '\0';
			   length = strlen(wptr = wbuf);
		pad7:		/* don't modify the string at wptr */
			   if (!ljflag)
				while (width-- > 0)
				  if ((*putcf)(prefill,arg1) == ERROR)
					return ERROR;;
			   while (length--)
				if ((*putcf)(*wptr++,arg1) == ERROR) 
					return ERROR;
			   if (ljflag)
				while (width-- > 0)
					if ((*putcf)(' ',arg1) == ERROR)
						return ERROR;
			   break;

		case 's':
			   wptr = *args++;
			   length = strlen(wptr);
			   if (precision < length) length=precision;
			   width -= length;
			   goto pad7;

		case NULL:
			   return OK;

		default:   if ((*putcf)(c,arg1) == ERROR) return ERROR;
	     }
	  }
	  else if ((*putcf)(c,arg1) == ERROR) return ERROR;
	return OK;
}

_sgetc(sp)
char **sp;
{
	return *(*sp)++;
}

_sungetc(ch,sp)
char **sp,ch;
{
	--*sp;
}

union {
	char byte;
	int word;
};

int _scn(arglist,get,unget,ioarg)
int (*get)(), (*unget)();
int **arglist;
{
	char assign, c, base, n, *sptr, *format, matchit;
	char shortf;
	int sign, val, width, peek;

	format = *arglist++;	/* format points to the format string */

	n = 0;
	while (1)
	{
	   if (!(c = *format++)) goto alldone;
	   if (isspace(c)) continue;	/* skip white space in format string */
	   if (c!='%') 
	   {
	   	if(_GetNonWh(get,ioarg,&peek)) goto eofdone;
		if(c!=peek) goto undone;
	   }
	   else		/* process conversion */
	   {
		sign = 1; shortf=FALSE;
		if ('*'==*format) {
			format++;
			assign = FALSE;}
		else assign = TRUE;
		if (isdigit(*format)) width = _gv2(&format);
		else width = 32767;
		if ('l'==*format) format++;		/* no longs */
		switch (c=*format++) {
			case 'x': base = 16;	goto doval;
 			case 'o': base = 8;	goto doval;
			case 'b': base = 2;	goto doval;
			case 'h': shortf = TRUE;	/* short is char */
			case 'd':
			case 'u': base = 10;
				doval:
				if (_GetNonWh(get,ioarg,&peek))
					goto eofdone;
				width--;
				if (peek=='-') {
					sign = -1;
					peek=(*get)(ioarg);
					if (!width--)
						continue;
					}
				if ((val=_bc(peek,base)) == ERROR)
					goto undone;
				while (1) {
					peek = (*get)(ioarg);
					if (iseof(peek) || !width--)
						break;
					if (peek=='x' && c=='x')
						continue;
					if ((c = _bc(peek,base)) == 255)
						break;
					val = val * base + c;
				}
				if (assign) {
					val *= sign;
					if (shortf)
						(*arglist++)->byte = val;
					else
						(*arglist++)->word = val;
					n++;}
				if (iseof(peek))
					goto eofdone;
				(*unget)(peek,ioarg);
				continue;

			case 's': 
				if (_GetNonWh(get,ioarg,&peek)) goto eofdone;
				matchit = ('%'==*format) ? ' ' : *format;
				sptr = *arglist;
				while (1) {
					if (isspace(peek))
						break;
					if (peek == matchit) {
						format++;
						break;
					 }
					if (assign) *sptr++ = peek;
					if (!--width)
						break;
					peek=(*get)(ioarg);
					if (iseof(peek))
						break;
				 } 
				if (assign) {
					n++;
					*sptr = '\0';
					arglist++;
				 }
				if (iseof(peek))
					goto eofdone;
				continue;

			case 'c': peek=(*get)(ioarg);
				if (iseof(peek))
					goto eofdone;
				if (assign) {
					(*arglist++)->byte = peek;
					n++;
				}
				continue;

			case '%':	/* allow % to be read with "%%" */
				if (_GetNonWh(get,ioarg,&peek))
					goto eofdone;
				if ('%' != peek)
					goto undone;
				continue;

			default: goto alldone;
		 }
	    }
	}
	eofdone:	(*unget)(CPMEOF,ioarg);
			return n ? n : EOF;
	undone:		(*unget)(peek,ioarg);
	alldone:	return n;
}

int _GetNonWh(get,ioarg,apeek)		/* get next non white character */
int (*get)();					/* return TRUE if EOF */
int *apeek;
{
	int c;
	while (isspace(c = (*get)(ioarg)))
		;
	*apeek = c;
	return iseof(c);
}

getline(s,lim)
char s[];
int lim;
{
	int c,i;
	i=0;
	while (--lim>0) {
		c=getchar();
		if (c==EOF) break;
		if (c==CPMEOF) {
			ungetch(CPMEOF);	/* don't pass ^Z */
			break;
			}
		s[i++] = c;
		if (c == '\n') break;
	}
	s[i] = '\0';
	return i;
}

puts(s)
char *s;
{
	while (*s) putchar(*s++);
}

/* Print out a decimal number: */

putdec(n)
int n;
{
	if (n < 0)
	{
		putchar('-');
		putdec(-n);
		return;
	}
	
	if (n > 9)
		putdec(n/10);

	putchar(n - n/10*10 + '0');
}
