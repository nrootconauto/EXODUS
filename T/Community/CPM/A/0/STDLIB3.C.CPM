/*
	STDLIB3.C -- for BDS C v1.6 --  1/86
	Copyright (c) 1982, 1986 by BD Software, Inc.

	The files STDLIB1.C, STDLIB2.C and STDLIB3.C contain the source
	listings for all functions present in the DEFF.CRL library object
 	file. (Note: DEFF2.CRL contains the .CSM-coded portions of the
	library.)

	STDLIB3.C contains mainly string, character, and storage allocation
	functions:

	strcat	strcmp	strcpy	strlen
	isalpha	isupper	islower	isdigit	isspace	toupper	tolower
	atoi
	qsort
	initw	initb	initptr	getval
	alloc	free
	swapin
	abs	max	min
*/


#include <stdio.h>

#define MAX_QSORT_WIDTH	513	/* Largest sized object "qsort" can sort  */

/*
	String functions:
*/

char *strcat(s1,s2)
char *s1, *s2;
{
	char *temp; temp=s1;
	while(*s1) s1++;
	do *s1++ = *s2; while (*s2++);
	return temp;
}


int strcmp(s1, s2)
char *s1, *s2;
{
	while (*s1 == *s2++)
		if (*s1++ == '\0')
			return 0;
	return (*s1 - *--s2);
}


char *strcpy(s1,s2)
char *s1, *s2;
{
	char *temp; temp=s1;
	while (*s1++ = *s2++);
	return temp;
}


int strlen(s)
char *s;
{
	int len;
	len=0;
	while (*s++) len++;
	return len;
}


/*
	Character diddling functions:
*/

int isalpha(c)
char c;
{
	return isupper(c) || islower(c);
}


int isupper(c)
char c;
{
	return c>='A' && c<='Z';
}


int islower(c)
char c;
{
	return c>='a' && c<='z';
}


int isdigit(c)
char c;
{
	return c>='0' && c<='9';
}


int isspace(c)
char c;
{
	return c==' ' || c=='\t' || c=='\n';
}


char toupper(c)
char c;
{
	return islower(c) ? c-32 : c;
}


char tolower(c)
char c;
{
	return isupper(c) ? c+32 : c;
}


int atoi(n)
char *n;
{
	int val; 
	char c;
	int sign;
	val=0;
	sign=1;
	while ((c = *n) == '\t' || c== ' ') ++n;
	if (c== '-') {sign = -1; n++;}
	while (  isdigit(c = *n++)) val = val * 10 + c - '0';
	return sign*val;
}

/*
	Generalized Sort function:
*/

qsort(base, nel, width, compar)
char *base; int (*compar)();
unsigned width,nel;
{	int i, j;
	unsigned gap, ngap, t1;
	int jd, t2;

	t1 = nel * width;
	for (ngap = nel / 2; ngap > 0; ngap /= 2) {
	   gap = ngap * width;
	   t2 = gap + width;
	   jd = base + gap;
	   for (i = t2; i <= t1; i += width)
	      for (j =  i - t2; j >= 0; j -= gap) {
		if ((*compar)(base+j, jd+j) <=0) break;
			 _swp(width, base+j, jd+j);
	      }
	}
}

_swp(w,a,b)
char *a,*b;
unsigned w;
{
	char swapbuf[MAX_QSORT_WIDTH];
	movmem(a,swapbuf,w);
	movmem(b,a,w);
	movmem(swapbuf,b,w);
}


/*
 	Initialization functions
*/


initw(int_ptr,string)
int *int_ptr;
char *string;
{
	int n;
	while ((n = getval(&string)) != -32760)
		*int_ptr++ = n;
}

initb(char_ptr, string)
char *char_ptr, *string;
{
	int n;
	while ((n = getval(&string)) != -32760) *char_ptr++ = n;
}

initptr(str_ptr, first_arg)
char **str_ptr, **first_arg;
{
	char **arg_ptr;

	for (arg_ptr = &first_arg; *arg_ptr; arg_ptr++)
		*str_ptr++ = *arg_ptr;
}


int getval(strptr)
char **strptr;
{
	int n;
	if (!**strptr) return -32760;
	n = atoi(*strptr);
	while (**strptr && *(*strptr)++ != ',');
	return n;
}


/*
	Storage allocation functions:
*/

char *alloc(nbytes)
unsigned nbytes;
{
	struct _header *p, *q, *cp;
	int nunits; 
	nunits = 1 + (nbytes + (sizeof (_base) - 1)) / sizeof (_base);
	if ((q = _allocp) == NULL) {
		_base._ptr = _allocp = q = &_base;
		_base._size = 0;
	 }
	for (p = q -> _ptr; ; q = p, p = p -> _ptr) {
		if (p -> _size >= nunits) {
			_allocp = q;
			if (p -> _size == nunits)
				_allocp->_ptr = p->_ptr;
			else {
				q = _allocp->_ptr = p + nunits;
				q->_ptr = p->_ptr;
				q->_size = p->_size - nunits;
				p -> _size = nunits;
			 }
			return p + 1;
		 }
		if (p == _allocp) {
			if ((cp = sbrk(nunits *	 sizeof (_base))) == ERROR)
				return NULL;
			cp -> _size = nunits; 
			free(cp+1);	/* remember: pointer arithmetic! */
			p = _allocp;
		}
	 }
}


free(ap)
struct _header *ap;
{
	struct _header *p, *q;

	p = ap - 1;	/* No need for the cast when "ap" is a struct ptr */

	for (q = &_base; q->_ptr != &_base; q = q -> _ptr)
		if (p > q && p < q -> _ptr)
			break;

	if (p + p -> _size == q -> _ptr) {
		p -> _size += q -> _ptr -> _size;
		p -> _ptr = q -> _ptr -> _ptr;
	 }
	else p -> _ptr = q -> _ptr;

	if (q + q -> _size == p) {
		q -> _size += p -> _size;
		q -> _ptr = p -> _ptr;
	 }
	else q -> _ptr = p;

	_allocp = q;
}


/* Load a disk file into memory (typically an overlay segment): */

swapin(name,addr)
char *name;
{
	int fd;
	if (( fd = open(name,0)) == ERROR)
		return ERROR;

	if ((read(fd,addr,512)) < 0) {
		close(fd);
		return ERROR;
	}

	bdos(26, 0x80);	/* reset DMA address for benefit of certain systems */

	close(fd);
	return OK;
}


/*
	Now some really hairy functions to wrap things up:
*/

int abs(n)
{
	return (n<0) ? -n : n;
}

int max(a,b)
{
	return (a > b) ? a : b;
}

int min(a,b)
{
	return (a <= b) ? a : b;
}

