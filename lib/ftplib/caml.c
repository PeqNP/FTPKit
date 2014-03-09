#ifndef NO_CAML
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include "ftplib.h"

extern char version[];


/* setting of global parameters */

CAMLprim value caml_setpassive(value passive)
{
	ftp_passive = Bool_val(passive);
	return Val_unit;
}

CAMLprim value caml_setverbose(value verbose)
{
	ftp_verbose = Bool_val(verbose);
	return Val_unit;
}

CAMLprim value caml_setsafeput(value safeput)
{
	ftp_safeput = Bool_val(safeput);
	return Val_unit;
}

CAMLprim value caml_setsendport(value sendport)
{
	ftp_sendport = Bool_val(sendport);
	return Val_unit;
}

/* return version string */

CAMLprim value caml_version(void)
{
	return (copy_string(version));
}

/* basic API */

CAMLprim value caml_ftp_open(value server, value login, value passwd)
{
	int r = ftp_open(String_val(server), String_val(login),
			 String_val(passwd));
	return (r?Val_false:Val_true);
}

CAMLprim value caml_ftp_close(void)
{
    int r = ftp_close();
    return (r?Val_false:Val_true);
}

CAMLprim value caml_ftp_cd(value directory)
{
    int r = ftp_cd(String_val(directory));
    return (r?Val_false:Val_true);
}

CAMLprim value caml_ftp_delete(value file)
{
    int r = ftp_delete(String_val(file));
    return (r?Val_false:Val_true);
}


static value head;

static int add_one_file(char *file, unsigned unused)
{
    // create a cons cell and a caml string
    value cell = alloc(2,Tag_cons);
    value thisfile = copy_string(file);

    // put the string in the cell, add the cell at head of list
    Field(cell,0) = thisfile;
    Field(cell,1) = head;

    // the new head
    head = cell;
    return 0;
}

CAMLprim value caml_ftp_ls(value long_ls, value name)
{
    head = Val_emptylist;

    // each call to add_one_file adds a cons cell at head of list
    ftp_ls(Bool_val(long_ls), 
	   string_length(name)?String_val(name):NULL,
	   add_one_file);

    return head;
}

CAMLprim value caml_ftp_rename(value oldfile, value newfile)
{
    int r = ftp_rename(String_val(oldfile), String_val(newfile));
    return (r?Val_false:Val_true);
}

CAMLprim value caml_ftp_mkdir(value directory)
{
    int r = ftp_mkdir(String_val(directory));
    return (r?Val_false:Val_true);
}

CAMLprim value caml_ftp_rmdir(value directory)
{
    int r = ftp_rmdir(String_val(directory));
    return (r?Val_false:Val_true);
}


CAMLprim value caml_ftp_put(value rst, value append,
			    value localfile, value remotefile)
{
    int r = ftp_putfile(String_val(localfile), String_val(remotefile),
			Int_val(rst), Bool_val(append));
    return (r?Val_false:Val_true);
}

CAMLprim value caml_ftp_putunique(value localfile, value remotefile)
{
    char filename[100];

    int r = ftp_putfileunique(String_val(localfile), String_val(remotefile),
			      filename, 100);
    return (r?copy_string(""):copy_string(filename));
}

CAMLprim value caml_ftp_get(value rst,value remotefile, value localfile)
{
    int r = ftp_getfile(String_val(remotefile), String_val(localfile), 
			Int_val(rst));
    return (r?Val_false:Val_true);
}


CAMLprim value caml_ftp_sendcommand(value command)
{
    char buf[1024];
    ftp_sendcommand(String_val(command), buf, 1024);
    return(copy_string(buf));
}


/* advanced API: not available so far */


/* low level file transfers */

//static value caml_fct;

/* that doesn't work

static int cb_fct(char* buf, unsigned size)
{
    //value str = alloc_string(size);
    //memcpy(Field(str,1), buf, size);
    //return Int_val(callback(caml_fct, str));

    // pb if zero in the buffer -- this is NOT a string if binary mode
    return Int_val(callback(caml_fct, copy_string(buf)));
}

CAMLprim value caml_ftp_rawget(value remotefile, value fct, value bufsize)
{
    int r;
    
    caml_fct = fct;
    r = ftp_get(String_val(remotefile), cb_fct, Int_val(bufsize), 0);
    return (r?Val_false:Val_true);
}
*/

#endif
