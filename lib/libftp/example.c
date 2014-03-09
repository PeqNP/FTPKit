/* example toy application for ftplib 

   args are: hostname, login, passwd, cddir, lsdir (both possibly as empty
   strings ""), long?

   ./example myftpserver mylogin mypassd "" "" 0
   ./example myftpserver mylogin mypasswd "mydir" "subdir" 1

*/

#include <stdio.h>
#include <stdlib.h>
#include "ftplib.h"

int error(char *msg)
{
  fprintf(stderr, "%s\n", msg);
  exit(1);
}

int process_entry(char *ent, unsigned len)
{
  printf("%s\n", ent);
  return 0;
}

int main(int argc, char **argv)
{
  /* this enables printing of sent FTP commands */
  ftp_debug=1;
  /* and this printing of status responses */
  ftp_verbose=1;

  /* check number of arguments */
  if (argc!=7) error("Usage: example myftpserver mylogin mypasswd mydir subdir long?");

  /* open the FTP connection */
  if (ftp_open(argv[1], argv[2], argv[3])) error("ftp_open");

  /* perform cd only if a non empty string was given */
  if (strlen(argv[4])) ftp_cd(argv[4]);

  /* perform the directory listing */
  ftp_ls(atoi(argv[6]), argv[5], process_entry);

  /* the end */
  ftp_close();
}
