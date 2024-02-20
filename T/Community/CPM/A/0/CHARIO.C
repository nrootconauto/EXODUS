/* CHARIO.C		Character-oriented file I/O

	Written 1980 by Scott W. Layson
	This code is in the public domain.

These routines deal with reading and writing large blocks of
characters, when they do not fit neatly in sectors.  At the moment,
only sequential output is supported; input is fully random. */


#define TRUE (-1)
#define FALSE 0
#define NULL 0


/* i/o buffer */
struct iobuf {
	int fd;
	int isect;			/* currently buffered sector */
	int nextc;			/* index of next char in buffer */
	char buff [128];
	};

/* seek opcodes */
#define ABSOLUTE	0
#define RELATIVE	1

#define INPUT		0
#define OUTPUT		1
#define UPDATE		2


copen (buf, fname)			/* open a file for char input */
	struct iobuf *buf;
	char *fname;
{
	buf->fd = open (fname, INPUT);
	if (buf->fd == -1) return (-1);
	read (buf->fd, &buf->buff, 1);
	buf->isect = 0;
	buf->nextc = 0;
	return (buf);
	}


ccreat (buf, fname)			/* create a file for char output */
	struct iobuf *buf;
	char *fname;
{
	buf->fd = creat (fname);
	if (buf->fd == -1) return (-1);
	buf->isect = 0;
	buf->nextc = 0;
	return (buf);
	}


cclose (buf)				/* close the file assoc. with buf */
	struct iobuf *buf;
{
	close (buf->fd);
	}


cseek (buf, nbytes, code)	/* seek to a character (input only!) */
	struct iobuf *buf;
	unsigned nbytes, code;
{
	int newsect;

	if (buf < 0) return (-1);
	if (code == RELATIVE) nbytes += buf->isect * 128 + buf->nextc;
	newsect = nbytes / 128;
	if (newsect != buf->isect
	    && (seek (buf->fd, newsect, ABSOLUTE) == -1
		   || read (buf->fd, &buf->buff, 1) == -1)) return (-1);
	buf->nextc = nbytes % 128;
	buf->isect = newsect;
	return (nbytes);
	}


cread (buf, dest, nbytes)	/* read some bytes into dest */
	struct iobuf *buf;
	char *dest;
	unsigned nbytes;
{
	int navail, nsects, nleft, nread1, nread2;

	if (buf < 0) return (-1);
	navail = umin (nbytes, 128 - buf->nextc);
	movmem (&buf->buff[buf->nextc], dest, navail);
	nbytes -= navail;
	buf->nextc += navail;
	dest += navail;
	nsects = nbytes / 128;
	if (nsects) {
		nread1 = read (buf->fd, dest, nsects);
		if (nread1 == -1) return (navail);
		buf->isect += nread1;
		if (nread1 < nsects) return (navail + nread1 * 128);
		dest += nread1 * 128;
		}
	else nread1 = 0;
	if (buf->nextc == 128) {
		nread2 = read (buf->fd, &buf->buff, 1);
		if (nread2 == -1) return (navail);
		++(buf->isect);
		buf->nextc = 0;
		if (nread2 < 1) return (navail + nread1 * 128);
		}
	nleft = nbytes % 128;
	movmem (&buf->buff, dest, nleft);
	buf->nextc += nleft;
	return (navail + nbytes);
	}


cwrite (buf, source, nbytes)	/* write some bytes from source */
	struct iobuf *buf;
	char *source;
	unsigned nbytes;
{
	unsigned nleft, nfill, nsects;
	
	if (buf < 0) return (-1);
	if (buf->nextc) {
		nfill = umin (nbytes, 128 - buf->nextc);
		movmem (source, &buf->buff[buf->nextc], nfill);
		buf->nextc += nfill;
		nbytes -= nfill;
		source += nfill;
		}
	if (buf->nextc == 128) {
		++(buf->isect);
		buf->nextc = 0;
		if (write (buf->fd, &buf->buff, 1) < 1) return (-1);
		}
	nsects = nbytes / 128;
	if (nsects  &&  write (buf->fd, source, nsects) < nsects)
		return (-1);
	nbytes %= 128;
	movmem (source + nsects * 128, &buf->buff, nbytes);
	buf->nextc += nbytes;
	return (nsects * 128 + nbytes);
	}


cflush (buf)				/* flush an output buffer */
	struct iobuf *buf;
{
	if (buf->nextc  &&  write (buf->fd, &buf->buff, 1) < 1)
		return (-1);
	return (1);
	}


umin (a, b)				/* unsigned min */
	unsigned a, b;
{
	return ((a < b) ? a : b);
	}


/* End of CHARIO.C  --  Character oriented file I/O */
s)	/* write some bytes from source 