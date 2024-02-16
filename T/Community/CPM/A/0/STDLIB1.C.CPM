/*
	STDLIB1.C -- for BDS C v1.6 --  1/86
	Copyright (c) 1982, 1986 by BD Software, Inc.

	The files STDLIB1.C, STDLIB2.C and STDLIB3.C contain the source
	listings for all functions present in the DEFF.CRL library object
 	file. (Note: DEFF2.CRL contains the .CSM-coded portions of the
	library.)

	STDLIB1.C contains the new K&R standard buffered file I/O functions:

	fopen	fclose	fflush
	fgetc	fputc	getw	putw	ungetc
	fread	fwrite	fgets	fputs
	feof	ferror	clearerr
*/

#include <stdio.h>


/*
	fopen(filename, mode)

	The "mode" parameter may be:
	"r" or "rb" 	read, read binary
	"w" or "wb"	write, write binary
	"a" or "ab"	append, append binary
	(If no "b" is appended, text mode assumed by default)
*/

char *fopen(name,mode)
char *mode, *name;
{
    int i;
    FILE *fp;

    if ((fp = alloc(sizeof(*fp))) == NULL)
	return NULL;
    fp->_nextp = fp->_buff;
    fp->_nleft = (NSECTS * SECSIZ);
    fp->_flags = _WRITE;

    switch(*mode){
	case 'r':
		if ((fp->_fd = open(name, 0)) == ERROR)
			goto error;
		fp->_nleft = 0;
		fp->_flags = _READ;
		break;
	case 'a':
		if ((fp->_fd = open(name, 2)) == ERROR)
			goto create;
		if (!cfsize(fp->_fd))	/* if empty file, just like 'w' */
			break;
		if (seek(fp->_fd, -1, 2) == ERROR ||
		    read(fp->_fd, fp->_buff, 1) < 1)
		{
			close(fp->_fd);
			goto error;
		}
		if (mode[1] != 'b')
		   for (i=0; i<SECSIZ; i++)
			if (fp->_buff[i] == CPMEOF)
			{
				seek(fp->_fd, -1, 1);
				fp->_nextp += i;
				fp->_nleft -= i;
				break;
			}
		break;
	case 'w':;
   create:	if ((fp->_fd = creat(name)) == ERROR)
			goto error;
		break;
	default:
		goto error;			/* illegal mode */
    }

    if (mode[1] != 'b')			/* text mode by default */
	fp->_flags |= _TEXT;
    return fp;

 error:
    free(fp);
    return NULL;
}


int fclose(fp)
FILE *fp;
{
	if (fp <= 4)
		return OK;
	if (fp->_flags & _WRITE)
	{
		if (fp->_flags & _TEXT)
			fputc(CPMEOF, fp);
		if (fflush(fp) == ERROR)
			return ERROR;
	}
	free(fp);
	return close(fp->_fd);
}


int fflush(fp)
FILE *fp;
{
	int i; char *p;

	if (fp <= 4)
		return OK;
	if (!(fp->_flags & _WRITE))
		return ERROR;

	if (fp->_nleft == (NSECTS * SECSIZ))
		return OK;

	i = NSECTS - (fp->_nleft / SECSIZ);
	if (write(fp->_fd, fp->_buff, i) != i)
	{
		fp->_flags |= _ERR;
		return ERROR;
	}
	i = (i-1) * SECSIZ;
	if (fp->_nleft % SECSIZ) {
		movmem(fp->_buff + i, fp->_buff, SECSIZ);
		fp->_nleft += i;
		fp->_nextp -= i;
		return seek(fp->_fd, -1, 1);
	 }

	fp->_nleft = (NSECTS * SECSIZ);
	fp->_nextp = fp->_buff;
	return OK;
}

int fgetc(fp)
FILE *fp;
{
	int nsecs;
	char c;

	switch(fp)
	{
		case stdin:	return getchar();
		case stdrdr:	return bdos(3);
	}

top:	if (!fp->_nleft--)		/* if buffer empty, fill it up first */
	{
		if ((fp->_flags & _EOF) ||
		   (nsecs = read(fp->_fd, fp->_buff, NSECTS)) <= 0)
		{
		  eof:	fp->_nleft = 0;
			fp->_flags |= _EOF;
			return EOF;
		}
		fp->_nleft = nsecs * SECSIZ - 1;
		fp->_nextp = fp->_buff;
	}
	c = *fp -> _nextp++;
	if (fp->_flags & _TEXT)
		if (c == CPMEOF)
			goto eof;
		else if (c == '\r')
			goto top;	/* Ignore CR's in text files */
	return c;
}

 
int fputc(c,fp)
char c;
FILE *fp;
{
	switch (fp)
	 {
		case stdout: return putchar(c);	/* std output */
		case stdlst: return bdos(5,c);	/* list dev.  */
		case stdpun: return bdos(4,c);	/* to punch   */
		case stderr: if (c == '\n')
				bdos(2,'\r');
			     return bdos(2,c);
		case stdin: return ERROR;
	 }

	if (!(fp->_flags & _TEXT))	/* If binary mode, just write it */
		return _putc(c, fp);

	if (c == '\r')		/* Else must be Text mode: */
		return c;		/*Ignore CR's */

	if (c != '\n')			/* If not newline, just write it */
		return _putc(c,fp);

	if (_putc('\r',fp) == ERROR)	/* Write CR-LF combination */
		return ERROR;	
	return _putc('\n',fp);	
}

_putc(c,fp)
FILE *fp;
{
	if (fp->_flags & _ERR)
		return ERROR;

	if (!fp->_nleft--)		/*   if buffer full, flush it 	*/
	 {
		if ((write(fp->_fd, fp->_buff, NSECTS)) != NSECTS)
		{
			fp->_flags |= _ERR;
			return ERROR;
		}
		fp->_nleft = (NSECTS * SECSIZ - 1);
		fp->_nextp = fp->_buff;
	 }

	return *fp->_nextp++ = c;
}
	

int ungetc(c, fp)
FILE *fp;
char c;
{
	if (fp == stdin) return ungetch(c);
	if ((fp < 7) || fp -> _nleft == (NSECTS * SECSIZ))
		return ERROR;
	*--fp -> _nextp = c;
	fp -> _nleft++;
	return OK;
}

int getw(fp)
FILE *fp;
{
	int a,b;	
	if (((a = fgetc(fp)) >= 0) && ((b = fgetc(fp)) >=0))
			return (b << 8) + a;
	return ERROR;
}

int putw(w,fp)
unsigned w;
FILE *fp;
{
	if ((fputc(w & 0xff, fp) >=0 ) && (fputc(w / 256,fp) >= 0))
				return w;
	return ERROR;
}

int fread(buf, size, count, fp)
char *buf;
unsigned size, count;
FILE *fp;
{
	int n_read, n_togo, cnt, i;

	n_togo = size * count;
	n_read = 0;
	if (fp->_flags & _EOF)
		return NULL;

	while (n_togo)
	{
		cnt = (n_togo <= fp->_nleft) ? n_togo : fp->_nleft;
		movmem(fp->_nextp, buf, cnt);
		fp->_nextp += cnt;
		buf += cnt;
		fp->_nleft -= cnt;
		n_togo -= cnt;
		n_read += cnt;
		if (n_togo)
		{
			if ((cnt = read(fp->_fd, fp->_buff, NSECTS)) <=0)
			{
				fp->_flags |= _EOF;
				goto text_test;
			}
			fp->_nleft = cnt * SECSIZ;
			fp->_nextp = fp->_buff;
		}
	}
 text_test:
	if (fp->_flags & _TEXT)
	{
		i = min(n_read, SECSIZ);
		while (i--)
			if (*(buf-i) == CPMEOF)		   
			{
				fp->_flags |= _EOF;
				return (n_read - i);
			}
	}
	return (n_read/size);
}

int fwrite(buf, size, count, fp)
char *buf;
unsigned size, count;
FILE *fp;
{
	int n_done, n_togo, cnt;

	n_togo = size * count;
	n_done = 0;

	if (fp->_flags & _ERR)
		return NULL;

	while (n_togo)
	{
		cnt = (n_togo <= fp->_nleft) ? n_togo : fp->_nleft;
		movmem(buf, fp->_nextp, cnt);
		fp->_nextp += cnt;
		buf += cnt;
		fp->_nleft -= cnt;
		n_togo -= cnt;
		n_done += cnt;
		if (n_togo)
		{
			if ((cnt = write(fp->_fd, fp->_buff, NSECTS)) <= 0)
			{
				fp->_flags |= _ERR;
				return ERROR;
			}
			fp->_nleft = (NSECTS * SECSIZ);
			fp->_nextp = fp->_buff;
		}
	}
	return (n_done/size);
}


/* Get a line of text from a buffered input file: */ 

char *fgets(s,n,fp)
char *s;
int n;
FILE *fp;
{
	int c;
	char *cs;
	
	cs = s;
	while (--n > 0)
	{
		if ((c = fgetc(fp)) == EOF)
		{
			*cs = '\0';
			return (cs == s) ? NULL : s;
		}
		if ((*cs++ = c) == '\n') break;
	}
	*cs = '\0';
	return s;
}


/* Write a line of text out to a buffered file: */

fputs(s,fp)
char *s;
FILE *fp;
{
	char c;
	while (c = *s++) {
		if (fputc(c,fp) == ERROR)
			return ERROR;
	}
	return OK;
}

VOID clearerr(fp)
FILE *fp;
{
	fp->_flags &= (~_ERR);
}

int feof(fp)
FILE *fp;
{
	return fp->_flags & _EOF;
}

int ferror(fp)
FILE *fp;
{
	return fp->_flags & _ERR;
}
