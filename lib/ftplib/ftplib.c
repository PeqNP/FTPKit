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

char copyright[] =
  "@(#) Copyright (c) 1985, 1989 Regents of the University of California.\n"
  "All rights reserved.\n";

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>

#include <arpa/ftp.h>

#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <ctype.h>
#include <netdb.h>
#include <pwd.h>


//
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <assert.h>


extern int ftp_safeput;
extern int ftp_verbose;
extern int ftp_sendport;
extern int ftp_debug;

#define Extern
#include "ftp_var.h"
int traceflag = 0;
const char *home = "/";

extern FILE *cout;
extern int data;

extern char reply_string[];
extern char lreply[];

void intr(int);
void lostpeer(int);
void help(int argc, char *argv[]);

static int
do_init(void)
{
	struct servent *sp;
	int top;

	sp = getservbyname("ftp", "tcp");
	if (sp == 0) {
		fprintf(stderr, "ftp: ftp/tcp: unknown service\n");
		exit(1);
	}
	ftp_port = sp->s_port;

	cpend = 0;	/* no pending replies */
	crflag = 1;	/* strip c.r. on ascii gets */
	ftp_sendport = -1;	/* not using ports */

	top = sigsetjmp(toplevel, 1) == 0;
	if (top) {
		(void) signal(SIGINT, intr);
		(void) signal(SIGPIPE, lostpeer);
	}
	top = 1;
	return 0;
}



int
ftp_open(char *server, char *login, char *passwd)
{
	char *host;
	unsigned short port;
	int overbose;
	char reallogin[255];
	char *gateway;

	do_init();
	if (connected) {
		printf("Already connected to %s, use close first.\n",
			hostname);
		return -1;
	}

	gateway = getenv("FTP_GATEWAY");
	port = ftp_port;

	strcpy(reallogin, login);
	if (gateway) {
	  host = hookup(gateway, port);
	  strcat(reallogin, "@");
	  strncat(reallogin, server, 255-strlen(login)-1);
	}
	else {
	  host = hookup(server, port);
	}
	if (!host) return -1;

	connected = 1;
	/*
	 * Set up defaults for FTP.
	 */
	(void) strcpy(typename, "ascii"), type = TYPE_A;
	curtype = TYPE_A;
	if (dologin(reallogin, passwd)) { ftp_close(); return -1; }

#if defined(__unix__) && CHAR_BIT == 8
/*
 * this ifdef is to keep someone form "porting" this to an incompatible
 * system and not checking this out. This way they have to think about it.
 */
	overbose = ftp_verbose;
	if (ftp_debug == 0)
		ftp_verbose = -1;
	if (command("SYST") == COMPLETE && overbose) {
		register char *cp, c = 0;
		cp = index(reply_string+4, ' ');
		if (cp == NULL)
			cp = index(reply_string+4, '\r');
		if (cp) {
			if (cp[-1] == '.')
				cp--;
			c = *cp;
			*cp = '\0';
		}

	        printf("Remote system type is %s.\n",
			reply_string+4);
		if (cp)
			*cp = c;
	}
	if (!strncmp(reply_string, "215 UNIX Type: L8", 17)) {
		unix_server = 1;
		/*
		 * Set type to 0 (not specified by user),
		 * meaning binary by default, but don't bother
		 * telling server.  We can use binary
		 * for text files unless changed by the user.
		 */
		type = 0;
		(void) strcpy(typename, "binary");
		if (overbose)
		    printf("Using %s mode to transfer files.\n",
			typename);
	} else {
	        unix_server = 0;
		if (overbose && 
		    !strncmp(reply_string, "215 TOPS20", 10))
			printf(
"Remember to set tenex mode when transfering binary files from this machine.\n");
	}
	ftp_verbose = overbose;
#else
#warning "Unix auto-mode code skipped"
#endif /* unix */
	return 0;
}


/* ZZZ */
int
ftp_close(void)
{
	if (!connected)
		return 1;
	(void) command("QUIT");
	if (cout) {
		(void) fclose(cout);
	}
	cout = NULL;
	connected = 0;
	data = -1;
	return 0;
}

int
ftp_cd(char *directory)
{
	int r;

	if (!strcmp("..", directory)) {

	r = command("CDUP");
	if (r == ERROR && code == 500) {
	  if (ftp_verbose)
	    printf("CDUP command not recognized, trying XCUP\n");
	  return command("XCUP") != COMPLETE;
	}
	return r != COMPLETE;
	}

	r = command("CWD %s", directory);
	if (r == ERROR && code == 500) {
		if (ftp_verbose)
			printf("CWD command not recognized, trying XCWD\n");
		return (command("XCWD %s", directory) != COMPLETE);
	}
	return r != COMPLETE;
}

int
ftp_delete(char *file)
{
        return (command("DELE %s", file) != COMPLETE);
}

int
ftp_rename(char *oldname, char *newname)
{
	int r;
	r = command("RNFR %s", oldname);
	if (r != CONTINUE) return 1;
	return (command("RNTO %s", newname) != COMPLETE);
}


int
ftp_mkdir(char *directory)
{
	int r;
	r = command("MKD %s", directory);
	if (r == ERROR && code == 500) {
		if (ftp_verbose)
			printf("MKD command not recognized, trying XMKD\n");
		return (command("XMKD %s", directory) != COMPLETE);
	}
	return r != COMPLETE;
}

int
ftp_rmdir(char *directory)
{
	int r;
	r = command("RMD %s", directory);
	if (r == ERROR && code == 500) {
		if (ftp_verbose)
			printf("RMD command not recognized, trying XRMD\n");
		return (command("XRMD %s", directory) != COMPLETE);
	}
	return r != COMPLETE;
}

int
ftp_ls(int ll, char *pathname, int(*fct)(char*,unsigned))
{
	return recvrequest(ll?"LIST":"NLST", pathname, fct, 80, 0);
}


/* low level file transfer functions */

int
ftp_get(char *pathname, int(*fct)(char*,unsigned), unsigned bufsize, off_t rst)
{
	return recvrequest("RETR", pathname, fct, bufsize, rst);

}

int
ftp_put(char *pathname, int(*fct)(char*,unsigned), unsigned size, off_t rst,
	int append)
{
	char *tmpname = NULL;
	int r;
	char *cmd = (append?"APPE":"STOR");

	if (ftp_safeput) {
		tmpname = malloc(strlen(pathname)+5);
		if (!tmpname) return 1;
		strcpy(tmpname, pathname);
		strcat(tmpname, ".tmp");
	} else
		tmpname = pathname;
	
	r = sendrequest(cmd, tmpname, fct, size, rst);
	if (r || !ftp_safeput) return r;
	r = ftp_rename(tmpname, pathname);
	if (tmpname!=pathname) free(tmpname);
	return r;
}

int
ftp_putunique(char *pathname, char *uname, unsigned usize,
	      int(*fct)(char*,unsigned), unsigned bufsize)
{
	char *b,*e;

	int r = sendrequest("STOU", pathname, fct, bufsize, 0);

	if (uname != NULL && usize > 0) { 
		/* getting the unique name */
		/* this works for wu-ftpd ... */
		b = lreply;
		while (*b != ':' && *b != 0) b++;
		if (b == 0) *uname = 0;
		else {
			e = b++;
			while (*e != ')' && *e != 0) e++; *e = 0;
			strncpy(uname, b, usize);
		}
	}
	return r;
}



/* high level file transfer functions */

FILE *fout, *fin;

static int
write_get_buf(char *buf, unsigned size)
{
	if (write(fileno(fout), buf, size) != size) {
		fprintf(stderr, "Error writing to local file");
		return 1;
	}
	return 0;
}

int
ftp_getfile(char *remote_file, char *local_file, off_t rst)
{
	int r;
	unsigned bufsize;
	char mode[3] = "r+";
	struct stat st;

	if (!rst) strcpy(mode,"w");

	if ((fout=fopen(local_file, mode)) == NULL) {
		fprintf(stderr, "Cannot open local %s\n", local_file);
		return 2;
	}
	
	if (rst) 
		if (fseek(fout, (long) rst, SEEK_SET) < 0) return 3;
	
	if (fstat(fileno(fout), &st) < 0 || st.st_blksize == 0)
		bufsize = BUFSIZ;
	else
		bufsize = st.st_blksize;
	
	r = ftp_get(remote_file, write_get_buf, bufsize, rst);
	fclose(fout);
	return r;
}


static int
read_put_buf(char *buf, unsigned size)
{
	int c = read(fileno(fin), buf, size);
	return c;
}

int
ftp_putfile(char *local_file, char *remote_file, off_t rst, int append)
{
	int r;
	unsigned bufsize;
	struct stat st;

	if ((fin=fopen(local_file, "r")) == NULL) {
		fprintf(stderr, "Cannot open local file %s\n", local_file);
		return 2;
	}
	if (rst) 
		if (fseek(fin, (long) rst, SEEK_SET) < 0) return 3;

	if (fstat(fileno(fin), &st) < 0 || st.st_blksize == 0)
		bufsize = BUFSIZ;
	else
		bufsize = st.st_blksize;

	r = ftp_put(remote_file, read_put_buf, bufsize, rst, append);
	fclose(fin);
	return r;
}

int
ftp_putfileunique(char *local_file, char *remote_file,
		  char *uname, unsigned usize)
{
	int r;
	unsigned bufsize;
	struct stat st;

	if ((fin=fopen(local_file, "r")) == NULL) {
		fprintf(stderr, "Cannot open local file %s\n", local_file);
		return 2;
	}

	if (fstat(fileno(fin), &st) < 0 || st.st_blksize == 0)
		bufsize = BUFSIZ;
	else
		bufsize = st.st_blksize;

	r = ftp_putunique(remote_file, uname, usize, read_put_buf, 
			  bufsize);
	fclose(fin);
	return r;
}



int
ftp_sendcommand(char *cmd, char *buf, unsigned size)
{
	int r = command(cmd);
	memcpy(buf, lreply, MIN(size,BUFSIZ));;
	//       	strncpy(buf, lreply, MIN(size,BUFSIZ));
	return r != COMPLETE;
}


// ---


void
intr(int ignore)
{
	(void)ignore;
	siglongjmp(toplevel, 1);
}

void
lostpeer(int ignore)
{
	(void)ignore;

	if (connected) {
		if (cout != NULL) {
			shutdown(fileno(cout), 1+1);
			fclose(cout);
			cout = NULL;
		}
		if (data >= 0) {
			shutdown(data, 1+1);
			close(data);
			data = -1;
		}
		connected = 0;
	}
}
