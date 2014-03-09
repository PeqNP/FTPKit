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
 *
 *	from: @(#)ftp_var.h	5.9 (Berkeley) 6/1/90
 *	$Id: ftp_var.h,v 1.12 1999/10/02 18:39:17 dholland Exp $
 */

/*
 * FTP global variables.
 */

#include <setjmp.h>
#include <sys/param.h>

/*
 * Tick counter step size.
 */
#define TICKBYTES     10240

#ifndef Extern
#define Extern extern
#endif


/*
 * Options and other state info.
 */
Extern int	traceflag;	/* trace packets exchanged */
Extern int	hash;		/* print # for each buffer transferred */
Extern int	connected;	/* connected to server */
Extern int	ntflag;		/* use ntin ntout tables for name xlation */
Extern int	mapflag;	/* use mapin mapout templates on file names */
Extern int	code;		/* return/reply code for ftp command */
Extern int	crflag;		/* if 1, strip car. rets. on ascii gets */
Extern char     pasv[64];       /* passive port for proxy data connection */
Extern char	*altarg;	/* argv[1] with no shell-like preprocessing  */
Extern char	ntin[17];	/* input translation table */
Extern char	ntout[17];	/* output translation table */
Extern char	mapin[MAXPATHLEN];	/* input map template */
Extern char	mapout[MAXPATHLEN];	/* output map template */
Extern char	typename[32];		/* name of file transfer type */
Extern int	type;			/* requested file transfer type */
Extern int	curtype;		/* current file transfer type */
Extern char	structname[32];		/* name of file transfer structure */
Extern int	mode;			/* file transfer mode */
Extern char	bytename[32];		/* local byte size in ascii */

Extern char	*hostname;	/* name of host connected to */
Extern int	unix_server;	/* server is unix, can use binary for ascii */

Extern int	ftp_port;	/* htons'd port number for ftp service */

Extern sigjmp_buf toplevel;	/* non-local goto stuff for cmd scanner */

Extern int	cpend;		/* flag: if != 0, then pending server reply */
Extern int	mflag;		/* flag: if != 0, then active multi command */

Extern int	options;	/* used during socket creation */

char *hookup(char *host, int port);
int dologin(const char *luser, const char* passwd);
int command(const char *fmt, ...);

int sendrequest(const char *cmd, char *remote, int (*fct)(char*,unsigned),
		 unsigned, off_t);

int recvrequest(const char *cmd, char *remote, int (*fct)(char*,unsigned),
		 unsigned, off_t);

int getreply(int expecteof);
void changetype(int newtype, int show);
