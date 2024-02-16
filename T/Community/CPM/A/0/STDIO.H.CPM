/* stdio.h 	for BDS C v1.6  2/85 */

#define BDSC

#define NULL 0		/* null pointer */
#define EOF -1		/* Physical EOF returned by low level I/O functions */
#define ERROR -1	/* General "on error" return value */
#define OK 0		/* General purpose "no error" return value */
#define JBUFSIZE 6	/* Length of setjump/longjump buffer	*/
#define CPMEOF 0x1a	/* CP/M End-of-text-file marker (sometimes!)  */
#define SECSIZ 128	/* Sector size for CP/M read/write calls */
#define TRUE 1		/* logical true constant */
#define FALSE 0		/* logical false constant */
#define MAXLINE	150	/* For compatibility */
#define VOID		/* for functions that don't return anything */

#define NSECTS 8	/* Number of sectors to buffer up in ram */

struct _buf {
	int _fd;
	int _nleft;
	char *_nextp;
	char _buff[NSECTS * SECSIZ];
	char _flags;
};

#define FILE struct _buf	/* Poor man's "typedef" */

#define _READ 1		/* only one of these two may be active at a time */
#define _WRITE 2

#define _EOF 4		/* EOF has occurred on input */
#define _TEXT 8		/* convert ^Z to EOF on input, write ^Z on output */
#define _ERR 16		/* error occurred writing data out to a file */

#define stdin 0
#define stdout 1
#define stdlst 2
#define stdrdr 3
#define stdpun 3
#define stderr 4

#define getc fgetc
#define putc fputc

struct _header  {		/* Alloc/Free object structure */
	struct _header *_ptr;
	unsigned _size;
 };

struct _header  _base;		/* declare this external data to  */
struct _header *_allocp;	/* be used by alloc() and free()  */

