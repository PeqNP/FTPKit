/*
 * Copyright (c) 1985, 1989 Regents of the University of California.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* 
 * From: @(#)ftp.c	5.38 (Berkeley) 4/22/91
 */
char ftp_rcsid[] = 
  "$Id: ftp.c,v 1.25 1999/12/13 20:33:20 dholland Exp $";

#include <sys/param.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/file.h>

#include <netinet/in.h>
#include <netinet/ip.h>
#include <arpa/ftp.h>
#include <arpa/inet.h>
#include <arpa/telnet.h>

#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <netdb.h>
#include <pwd.h>
#include <stdarg.h>

#include "ftp_var.h"
#include "version.h"

int data = -1;

static struct sockaddr_in hisctladdr;
static struct sockaddr_in data_addr;
static struct sockaddr_in myctladdr;
static sigjmp_buf recvabort;
static sigjmp_buf sendabort;
static int ptabflg = 0;
static int abrtflag = 0;

void lostpeer(int);
extern int connected;

extern int ftp_passive;
extern int ftp_verbose;
extern int ftp_sendport;
extern int ftp_debug;

static int initconn(void);
static void ptransfer(const char *direction, long bytes, 
		      const struct timeval *t0, 
		      const struct timeval *t1);
static void tvsub(struct timeval *tdiff, 
		  const struct timeval *t1, 
		  const struct timeval *t0);
static void abort_remote(FILE *din);

FILE *cin, *cout;
static FILE *dataconn(const char *);

char *
hookup(char *host, int port)
{
	register struct hostent *hp = 0;
	int s, tos;
	socklen_t len;
	static char hostnamebuf[256];

	memset(&hisctladdr, 0, sizeof(hisctladdr));
	if (inet_aton(host, &hisctladdr.sin_addr)) {
		hisctladdr.sin_family = AF_INET;
		strncpy(hostnamebuf, host, sizeof(hostnamebuf));
		hostnamebuf[sizeof(hostnamebuf)-1]=0;
	} 
	else {
		hp = gethostbyname(host);
		if (hp == NULL) {
			fprintf(stderr, "ftp: %s: ", host);
			herror((char *)NULL);
			code = -1;
			return((char *) 0);
		}
		hisctladdr.sin_family = hp->h_addrtype;
		if (hp->h_length > (int)sizeof(hisctladdr.sin_addr)) {
			hp->h_length = sizeof(hisctladdr.sin_addr);
		}
		memcpy(&hisctladdr.sin_addr, hp->h_addr_list[0], hp->h_length);
		(void) strncpy(hostnamebuf, hp->h_name, sizeof(hostnamebuf));
		hostnamebuf[sizeof(hostnamebuf)-1] = 0;
	}
	hostname = hostnamebuf;
	s = socket(hisctladdr.sin_family, SOCK_STREAM, 0);
	if (s < 0) {
		perror("ftp: socket");
		code = -1;
		return (0);
	}
	hisctladdr.sin_port = port;
	while (connect(s, (struct sockaddr *)&hisctladdr, sizeof (hisctladdr)) < 0) {
		if (hp && hp->h_addr_list[1]) {
			int oerrno = errno;

			fprintf(stderr, "ftp: connect to address %s: ",
				inet_ntoa(hisctladdr.sin_addr));
			errno = oerrno;
			perror((char *) 0);
			hp->h_addr_list++;
			memcpy(&hisctladdr.sin_addr, hp->h_addr_list[0], 
			       hp->h_length);
			fprintf(stdout, "Trying %s...\n",
				inet_ntoa(hisctladdr.sin_addr));
			(void) close(s);
			s = socket(hisctladdr.sin_family, SOCK_STREAM, 0);
			if (s < 0) {
				perror("ftp: socket");
				code = -1;
				return (0);
			}
			continue;
		}
		perror("ftp: connect");
		code = -1;
		goto bad;
	}
	len = sizeof (myctladdr);
	if (getsockname(s, (struct sockaddr *)&myctladdr, &len) < 0) {
		perror("ftp: getsockname");
		code = -1;
		goto bad;
	}
#ifdef IP_TOS
	tos = IPTOS_LOWDELAY;
	if (setsockopt(s, IPPROTO_IP, IP_TOS, (char *)&tos, sizeof(int)) < 0)
		perror("ftp: setsockopt TOS (ignored)");
#endif
	cin = fdopen(s, "r");
	cout = fdopen(s, "w");
	if (cin == NULL || cout == NULL) {
		fprintf(stderr, "ftp: fdopen failed.\n");
		if (cin)
			(void) fclose(cin);
		if (cout)
			(void) fclose(cout);
		code = -1;
		goto bad;
	}
	if (ftp_verbose)
		printf("Connected to %s.\n", hostname);
	if (getreply(0) > 2) { 	/* read startup message from server */
		if (cin)
			(void) fclose(cin);
		if (cout)
			(void) fclose(cout);
		code = -1;
		goto bad;
	}
#ifdef SO_OOBINLINE
	{
	int on = 1;

	if (setsockopt(s, SOL_SOCKET, SO_OOBINLINE, (char *)&on, sizeof(on))
		< 0 && ftp_debug) {
			perror("ftp: setsockopt");
		}
	}
#endif /* SO_OOBINLINE */

	return (hostname);
bad:
	(void) close(s);
	return ((char *)0);
}

int
dologin(const char *luser, const char *pass)
{
	int n;

	n = command("USER %s", luser);
	if (n == CONTINUE) {
	        n = command("PASS %s", pass);
	}
	if (n == CONTINUE) {
		fprintf(stderr, "Server asked account!!\n");
		return 1;
	}
	if (n != COMPLETE) {
		fprintf(stderr, "Login failed.\n");
		return 1;
	}
	return 0;
}


static void
cmdabort(int ignore)
{
	(void)ignore;

	printf("\n");
	fflush(stdout);
	abrtflag++;
}

int
command(const char *fmt, ...)
{
	va_list ap;
	int r;
	void (*oldintr)(int);

	abrtflag = 0;
	if (ftp_debug) {
		printf("---> ");
		va_start(ap, fmt);
		if (strncmp("PASS ", fmt, 5) == 0)
			printf("PASS XXXX");
		else 
			vfprintf(stdout, fmt, ap);
		va_end(ap);
		printf("\n");
		(void) fflush(stdout);
	}
	if (cout == NULL) {
		perror ("No control connection for command");
		code = -1;
		return (0);
	}
	oldintr = signal(SIGINT, cmdabort);
	va_start(ap, fmt);
	vfprintf(cout, fmt, ap);
	va_end(ap);
	fprintf(cout, "\r\n");
	(void) fflush(cout);
	cpend = 1;
	r = getreply(!strcmp(fmt, "QUIT"));
	if (abrtflag && oldintr != SIG_IGN)
		(*oldintr)(SIGINT);
	(void) signal(SIGINT, oldintr);
	return(r);
}

char reply_string[BUFSIZ];		/* last line of previous reply */
char lreply[BUFSIZ];

#include <ctype.h>

int
getreply(int expecteof)
{
	register int c, n;
	register int dig;
	register char *cp, *lcp;
	int originalcode = 0, continuation = 0;
	void (*oldintr)(int);
	int pflag = 0;
	size_t px = 0;
	size_t psize = sizeof(pasv);

	lcp = lreply;
	oldintr = signal(SIGINT, cmdabort);
	for (;;) {
		dig = n = code = 0;
		cp = reply_string;
		while ((c = getc(cin)) != '\n') {
			if (c == IAC) {     /* handle telnet commands */
				switch (c = getc(cin)) {
				case WILL:
				case WONT:
					c = getc(cin);
					fprintf(cout, "%c%c%c", IAC, DONT, c);
					(void) fflush(cout);
					break;
				case DO:
				case DONT:
					c = getc(cin);
					fprintf(cout, "%c%c%c", IAC, WONT, c);
					(void) fflush(cout);
					break;
				default:
					break;
				}
				continue;
			}
			dig++;
			if (c == EOF) {
				if (expecteof) {
					(void) signal(SIGINT,oldintr);
					code = 221;
					return (0);
				}
				lostpeer(0);
				if (ftp_verbose) {
					printf("421 Service not available, remote server has closed connection\n");
					(void) fflush(stdout);
				}
				code = 421;
				return(4);
			}
			if (c != '\r' && (ftp_verbose > 0 ||
			    (ftp_verbose > -1 && n == '5' && dig > 4))) {
				(void) putchar(c);
				
			}
			if (dig < 4 && isdigit(c))
				code = code * 10 + (c - '0');
			if (!pflag && code == 227)
				pflag = 1;
			if (dig > 4 && pflag == 1 && isdigit(c))
				pflag = 2;
			if (pflag == 2) {
				if (c != '\r' && c != ')') {
					if (px < psize-1) pasv[px++] = c;
				}
				else {
					pasv[px] = '\0';
					pflag = 3;
				}
			}
			if (dig == 4 && c == '-') {
				if (continuation)
					code = 0;
				continuation++;
			}
			if (n == 0)
				n = c;

			if (c != '\r' && (lcp - lreply < BUFSIZ -1)) *lcp++ =c;
			if (cp < &reply_string[sizeof(reply_string) - 1])
				*cp++ = c;
		}
		if (lcp - lreply < BUFSIZ -1) *lcp++ = c;
		if (ftp_verbose > 0 || (ftp_verbose > -1 && n == '5')) {
			(void) putchar(c);
			(void) fflush (stdout);
		}
		if (continuation && code != originalcode) {
			if (originalcode == 0)
				originalcode = code;
			continue;
		}
		*cp = '\0'; *lcp = '\0';
		if (n != '1')
			cpend = 0;
		(void) signal(SIGINT,oldintr);
		if (code == 421 || originalcode == 421)
			lostpeer(0);
		if (abrtflag && oldintr != cmdabort && oldintr != SIG_IGN)
			(*oldintr)(SIGINT);
		return (n - '0');
	}
}

static int
empty(fd_set *mask, int hifd, int sec)
{
	struct timeval t;

	t.tv_sec = (long) sec;
	t.tv_usec = 0;
	return(select(hifd+1, mask, (fd_set *) 0, (fd_set *) 0, &t));
}

static void
abortsend(int ignore)
{
	(void)ignore;

	mflag = 0;
	abrtflag = 0;
	printf("\nsend aborted\nwaiting for remote to finish abort\n");
	(void) fflush(stdout);
	siglongjmp(sendabort, 1);
}


struct	types {
	const char *t_name;
	const char *t_mode;
	int t_type;
	const char *t_arg;
} types[] = {
	{ "ascii",	"A",	TYPE_A,	NULL },
	{ "binary",	"I",	TYPE_I,	NULL },
	{ "image",	"I",	TYPE_I,	NULL },
	{ "ebcdic",	"E",	TYPE_E,	NULL },
	{ "tenex",	"L",	TYPE_L,	bytename },
	{ NULL, NULL, 0, NULL }
};

void
changetype(int newtype, int show)
{
	register struct types *p;
	int comret, oldverbose = ftp_verbose;

	if (newtype == 0)
		newtype = TYPE_I;
	if (newtype == curtype)
		return;
	if (ftp_debug == 0 && show == 0)
		ftp_verbose = 0;
	for (p = types; p->t_name; p++)
		if (newtype == p->t_type)
			break;
	if (p->t_name == 0) {
		printf("ftp: internal error: unknown type %d\n", newtype);
		return;
	}
	if (newtype == TYPE_L && bytename[0] != '\0')
		comret = command("TYPE %s %s", p->t_mode, bytename);
	else
		comret = command("TYPE %s", p->t_mode);
	if (comret == COMPLETE)
		curtype = newtype;
	ftp_verbose = oldverbose;
}


/* in recvrequest and sendrequest, we allocate the buffer just on the
   first call, or reallocate it when it's too small (save time plus
   dont need to bother freeing it on exit) */

#define MALLOC_BUF \
	if (!buf) {					\
		buf = malloc(bufsize);			\
		if (!buf) { return(1); }	        \
		cur_bufsize = bufsize;			\
	}						\
	if (bufsize > cur_bufsize) {			\
		free(buf);				\
		buf = malloc(bufsize);			\
		if (!buf) { return(1); }	        \
		cur_bufsize = bufsize;			\
	}


int
sendrequest(const char *cmd, char *remote, int (*in_fct)(char*,unsigned),
	    unsigned bufsize, off_t restart_point)
{
	struct timeval start, stop;
	register int c, d;
	FILE *volatile dout = 0;
	void (*volatile oldintr)(int);
	volatile long bytes = 0;

	static char *buf = NULL;
	static unsigned cur_bufsize;
	char *bufp;
	int l, cpt;

	MALLOC_BUF;

	if (curtype != type)
		changetype(type, 0);
	oldintr = NULL;
	if (sigsetjmp(sendabort, 1)) {
		while (cpend) {
			(void) getreply(0);
		}
		if (data >= 0) {
			(void) close(data);
			data = -1;
		}
		if (oldintr)
			(void) signal(SIGINT,oldintr);
		code = -1;
		return 1;
	}
	oldintr = signal(SIGINT, abortsend);

	if (initconn()) {
		(void) signal(SIGINT, oldintr);
		code = -1;
		return 1;
	}
	if (sigsetjmp(sendabort, 1))
		goto abort;

	if (restart_point)
		if (command("REST %ld", (long) restart_point) != CONTINUE) {
			return 1;
		}
	
	if (command("%s %s", cmd, remote) != PRELIM) {
		(void) signal(SIGINT, oldintr);
		return 1;
	}
	
	dout = dataconn("w");
	if (dout == NULL)
		goto abort;
	(void) gettimeofday(&start, (struct timezone *)0);
	switch (curtype) {

	case TYPE_I:
	case TYPE_L:
		errno = d = 0;
		while ((c = (*in_fct)(buf, bufsize)) > 0) {
			bytes += c;
			for (bufp = buf; c > 0; c -= d, bufp += d)
				if ((d = write(fileno(dout), bufp, c)) <= 0)
					break;
		}
		if (c < 0)
			fprintf(stderr, "%s\n", strerror(errno));
		if (d < 0) {
			if (errno != EPIPE) 
				perror("netout");
			bytes = -1;
		}
		break;

	case TYPE_A:
		while ((l=(*in_fct)(buf, bufsize))) {
			for (cpt=0; cpt<l; cpt++) {
				c = buf[cpt];
				if (c == '\n') {
					if (ferror(dout))
						break;
					(void) putc('\r', dout);
					bytes++;
				}
				(void) putc(c, dout);
				bytes++;
			}
		}
		if (ferror(dout)) {
			if (errno != EPIPE)
				perror("netout");
			bytes = -1;
		}
		break;
	}
	(void) gettimeofday(&stop, (struct timezone *)0);
	(void) fclose(dout);
	/* closes data as well, so discard it */
	data = -1;
	(void) getreply(0);
	(void) signal(SIGINT, oldintr);
	if (bytes > 0)
		ptransfer("sent", bytes, &start, &stop);
	return (bytes<0);
abort:
	(void) gettimeofday(&stop, (struct timezone *)0);
	(void) signal(SIGINT, oldintr);
	if (!cpend) {
		code = -1;
		return 1;
	}
	if (dout) {
		(void) fclose(dout);
	}
	if (data >= 0) {
		/* if it just got closed with dout, again won't hurt */
		(void) close(data);
		data = -1;
	}
	(void) getreply(0);
	code = -1;
	if (bytes > 0)
		ptransfer("sent", bytes, &start, &stop);
	return 1;
}

static void
abortrecv(int ignore)
{
	(void)ignore;

	mflag = 0;
	abrtflag = 0;
	printf("\nreceive aborted\nwaiting for remote to finish abort\n");
	(void) fflush(stdout);
	siglongjmp(recvabort, 1);
}


int
recvrequest(const char *cmd, char *remote, int (*out_fct)(char*,unsigned),
	    unsigned bufsize, off_t restart_point)
{
	FILE *volatile din = 0;
	void (*volatile oldintp)(int);
	void (*volatile oldintr)(int);
	volatile int is_retr, tcrflag, bare_lfs = 0;
	volatile long bytes = 0;
	register int c;
	struct timeval start, stop;

	static char *buf = NULL;
	static unsigned cur_bufsize;
	static unsigned cpt = 0;

	MALLOC_BUF;

	is_retr = strcmp(cmd, "RETR") == 0;
	oldintr = NULL;
	oldintp = NULL;
	tcrflag = !crflag && is_retr;
	if (sigsetjmp(recvabort, 1)) {
		while (cpend) {
			(void) getreply(0);
		}
		if (data >= 0) {
			(void) close(data);
			data = -1;
		}
		if (oldintr)
			(void) signal(SIGINT, oldintr);
		code = -1;
		return 1;
	}
	oldintr = signal(SIGINT, abortrecv);

	if (!is_retr) {
		if (curtype != TYPE_A)
			changetype(TYPE_A, 0);
	} 
	else if (curtype != type) {
		changetype(type, 0);
	}
	if (initconn()) {
		(void) signal(SIGINT, oldintr);
		code = -1;
		return 1;
	}
	if (sigsetjmp(recvabort, 1))
		goto abort;
	if (is_retr && restart_point &&
	    command("REST %ld", (long) restart_point) != CONTINUE) {
		return 1;
	}
	if (remote) {
		if (command("%s %s", cmd, remote) != PRELIM) {
			(void) signal(SIGINT, oldintr);
			return 1;
		}
	} 
	else {
		if (command("%s", cmd) != PRELIM) {
			(void) signal(SIGINT, oldintr);
			return 1;
		}
	}
	din = dataconn("r");
	if (din == NULL)
		goto abort;

	(void) gettimeofday(&start, (struct timezone *)0);

	switch (curtype) {

	case TYPE_I:
	case TYPE_L:
		errno = 0;
		while ((c = read(fileno(din), buf, bufsize)) > 0) {
			if ((*out_fct)(buf,c)) goto abort;
			bytes += c;
		}
		if (c < 0) {
			if (errno != EPIPE)
				perror("netin");
			bytes = -1;
		}
		break;

	case TYPE_A:
		while ((c = getc(din)) != EOF) {
			if (c == '\n')
				bare_lfs++;
			while (c == '\r') {
				bytes++;
				if ((c = getc(din)) != '\n' || tcrflag) {
					if (c == '\0') {
						bytes++;
						goto contin2;
					}
					if (c == EOF)
						goto contin2;
				}
			}
			if (cpt == bufsize || c == '\n') {
				buf[cpt] = 0;
				if ((*out_fct)(buf, cpt)) goto abort;
				cpt = 0;
			} else buf[cpt++]=c;
			bytes++;
	contin2:	;
		}
break2:
		if (bare_lfs) {
			printf("WARNING! %d bare linefeeds received in ASCII mode\n", bare_lfs);
			printf("File may not have transferred correctly.\n");
		}
		if (ferror(din)) {
			if (errno != EPIPE)
				perror("netin");
			bytes = -1;
		}
		break;
	}
	(void) signal(SIGINT, oldintr);
	if (oldintp)
		(void) signal(SIGPIPE, oldintp);
	(void) gettimeofday(&stop, (struct timezone *)0);
	(void) fclose(din);
	/* closes data as well, so discard it */
	data = -1;
	(void) getreply(0);
	if (bytes > 0 && is_retr)
		ptransfer("received", bytes, &start, &stop);
	return (bytes<0);
abort:

/* abort using RFC959 recommended IP,SYNC sequence  */

	(void) gettimeofday(&stop, (struct timezone *)0);
	if (oldintp)
		(void) signal(SIGPIPE, oldintp);
	(void) signal(SIGINT, SIG_IGN);
	if (!cpend) {
		code = -1;
		(void) signal(SIGINT, oldintr);
		return 1;
	}

	abort_remote(din);
	code = -1;
	if (din) {
		(void) fclose(din);
	}
	if (data >= 0) {
		/* if it just got closed with din, again won't hurt */
		(void) close(data);
		data = -1;
	}
	if (bytes > 0)
		ptransfer("received", bytes, &start, &stop);
	(void) signal(SIGINT, oldintr);
	return 1;
}

/*
 * Need to start a listen on the data channel before we send the command,
 * otherwise the server's connect may fail.
 */
static int
initconn(void)
{
	register char *p, *a;
	int result, tmpno = 0;
	socklen_t len;
	int on = 1;
	int tos;
	u_long a1,a2,a3,a4,p1,p2;

	if (ftp_passive) {
		data = socket(AF_INET, SOCK_STREAM, 0);
		if (data < 0) {
			perror("ftp: socket");
			return(1);
		}
		if (options & SO_DEBUG &&
		    setsockopt(data, SOL_SOCKET, SO_DEBUG, (char *)&on,
			       sizeof (on)) < 0)
			perror("ftp: setsockopt (ignored)");
		if (command("PASV") != COMPLETE) {
			printf("Passive mode refused.\n");
			return(1);
		}

		/*
		 * What we've got at this point is a string of comma separated
		 * one-byte unsigned integer values, separated by commas.
		 * The first four are the an IP address. The fifth is the MSB
		 * of the port number, the sixth is the LSB. From that we'll
		 * prepare a sockaddr_in.
		 */

		if (sscanf(pasv,"%ld,%ld,%ld,%ld,%ld,%ld",
			   &a1,&a2,&a3,&a4,&p1,&p2)
		    != 6) 
		{
			printf("Passive mode address scan failure. Shouldn't happen!\n");
			return(1);
		}

		data_addr.sin_family = AF_INET;
		data_addr.sin_addr.s_addr = htonl((a1 << 24) | (a2 << 16) |
						  (a3 << 8) | a4);
		data_addr.sin_port = htons((p1 << 8) | p2);

		if (connect(data, (struct sockaddr *) &data_addr,
		    sizeof(data_addr))<0) {
			perror("ftp: connect");
			return(1);
		}
#ifdef IP_TOS
		tos = IPTOS_THROUGHPUT;
		if (setsockopt(data, IPPROTO_IP, IP_TOS, (char *)&tos,
		    sizeof(tos)) < 0)
			perror("ftp: setsockopt TOS (ignored)");
#endif
		return(0);
	}
noport:
	data_addr = myctladdr;
	if (ftp_sendport)
		data_addr.sin_port = 0;	/* let system pick one */ 
	if (data != -1)
		(void) close(data);
	data = socket(AF_INET, SOCK_STREAM, 0);
	if (data < 0) {
		perror("ftp: socket");
		if (tmpno)
			ftp_sendport = 1;
		return (1);
	}
	if (!ftp_sendport)
		if (setsockopt(data, SOL_SOCKET, SO_REUSEADDR, (char *)&on, sizeof (on)) < 0) {
			perror("ftp: setsockopt (reuse address)");
			goto bad;
		}
	if (bind(data, (struct sockaddr *)&data_addr, sizeof (data_addr)) < 0) {
		perror("ftp: bind");
		goto bad;
	}
	if (options & SO_DEBUG &&
	    setsockopt(data, SOL_SOCKET, SO_DEBUG, (char *)&on, sizeof (on)) < 0)
		perror("ftp: setsockopt (ignored)");
	len = sizeof (data_addr);
	if (getsockname(data, (struct sockaddr *)&data_addr, &len) < 0) {
		perror("ftp: getsockname");
		goto bad;
	}
	if (listen(data, 1) < 0)
		perror("ftp: listen");
	if (ftp_sendport) {
		a = (char *)&data_addr.sin_addr;
		p = (char *)&data_addr.sin_port;
#define	UC(b)	(((int)b)&0xff)
		result =
		    command("PORT %d,%d,%d,%d,%d,%d",
		      UC(a[0]), UC(a[1]), UC(a[2]), UC(a[3]),
		      UC(p[0]), UC(p[1]));
		if (result == ERROR && ftp_sendport == -1) {
			ftp_sendport = 0;
			tmpno = 1;
			goto noport;
		}
		return (result != COMPLETE);
	}
	if (tmpno)
		ftp_sendport = 1;
#ifdef IP_TOS
	on = IPTOS_THROUGHPUT;
	if (setsockopt(data, IPPROTO_IP, IP_TOS, (char *)&on, sizeof(int)) < 0)
		perror("ftp: setsockopt TOS (ignored)");
#endif
	return (0);
bad:
	(void) close(data), data = -1;
	if (tmpno)
		ftp_sendport = 1;
	return (1);
}

static FILE *
dataconn(const char *lmode)
{
	struct sockaddr_in from;
	int s, tos;
	socklen_t fromlen = sizeof(from);

        if (ftp_passive)
            return (fdopen(data, lmode));

	s = accept(data, (struct sockaddr *) &from, &fromlen);
	if (s < 0) {
		perror("ftp: accept");
		(void) close(data), data = -1;
		return (NULL);
	}
	(void) close(data);
	data = s;
#ifdef IP_TOS
	tos = IPTOS_THROUGHPUT;
	if (setsockopt(s, IPPROTO_IP, IP_TOS, (char *)&tos, sizeof(int)) < 0)
		perror("ftp: setsockopt TOS (ignored)");
#endif
	return (fdopen(data, lmode));
}

static void
ptransfer(const char *direction, long bytes, 
	  const struct timeval *t0, 
	  const struct timeval *t1)
{
	struct timeval td;
	float s, bs;

	if (ftp_verbose) {
		tvsub(&td, t1, t0);
		s = td.tv_sec + (td.tv_usec / 1000000.);
#define	nz(x)	((x) == 0 ? 1 : (x))
		bs = bytes / nz(s);
		printf("%ld bytes %s in %.3g secs (%.2g Kbytes/sec)\n",
		    bytes, direction, s, bs / 1024.0);
	}
}

static void
tvsub(struct timeval *tdiff, 
      const struct timeval *t1, 
      const struct timeval *t0)
{

	tdiff->tv_sec = t1->tv_sec - t0->tv_sec;
	tdiff->tv_usec = t1->tv_usec - t0->tv_usec;
	if (tdiff->tv_usec < 0)
		tdiff->tv_sec--, tdiff->tv_usec += 1000000;
}

void
reset(void)
{
	fd_set mask;
	int nfnd = 1;

	FD_ZERO(&mask);
	while (nfnd > 0) {
		FD_SET(fileno(cin), &mask);
		if ((nfnd = empty(&mask, fileno(cin), 0)) < 0) {
			perror("reset");
			code = -1;
			lostpeer(0);
		}
		else if (nfnd) {
			(void) getreply(0);
		}
	}
}

static void
abort_remote(FILE *din)
{
	char buf[BUFSIZ];
	int nfnd, hifd;
	fd_set mask;

	/*
	 * send IAC in urgent mode instead of DM because 4.3BSD places oob mark
	 * after urgent byte rather than before as is protocol now
	 */
	snprintf(buf, sizeof(buf), "%c%c%c", IAC, IP, IAC);
	if (send(fileno(cout), buf, 3, MSG_OOB) != 3)
		perror("abort");
	fprintf(cout,"%cABOR\r\n", DM);
	(void) fflush(cout);
	FD_ZERO(&mask);
	FD_SET(fileno(cin), &mask);
	hifd = fileno(cin);
	if (din) { 
		FD_SET(fileno(din), &mask);
		if (hifd < fileno(din)) hifd = fileno(din);
	}
	if ((nfnd = empty(&mask, hifd, 10)) <= 0) {
		if (nfnd < 0) {
			perror("abort");
		}
		if (ptabflg)
			code = -1;
		lostpeer(0);
	}
	if (din && FD_ISSET(fileno(din), &mask)) {
		while (read(fileno(din), buf, BUFSIZ) > 0)
			/* LOOP */;
	}
	if (getreply(0) == ERROR && code == 552) {
		/* 552 needed for nic style abort */
		(void) getreply(0);
	}
	(void) getreply(0);
}
