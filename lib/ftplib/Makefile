
# -- parameters

# uncomment this if you don't want caml bindings
NO_CAML      = -DNO_CAML

# where is the caml.h file
CAMLH_DIR = /usr/local/godi/lib/ocaml/std-lib/

# --

CFLAGS = -I $(CAMLH_DIR) $(NO_CAML) -O2 -Wall

CC=gcc


all: libftp.a ftp.cmxa

# C library

libftp.a: ftplib.o ftp.o caml.o
	rm -f libftp.a
	ar q libftp.a ftplib.o ftp.o caml.o

ftp.o ftplib.o: ftp_var.h ftplib.h version.h

caml.o: ftplib.h version.h

# Caml native code library

ftp.cmxa: libftp.a ftp.ml
	ocamlopt -a -cclib libftp.a ftp.ml -o ftp.cmxa

# Caml bytecode library

ftp.cma: libftp.a ftp.ml
	ocamlc -custom -a -cclib libftp.a ftp.ml -o ftp.cma

clean:
	rm -f *.o *.a *.cmo *.cmi *.cmx *.cmxa *.cma


# Caml toplevel with ftplib

ocamlftp: libftp.a ftp.cma
	ocamlmktop -o ocamlftp ftp.cma unix.cma


# example C application

example.o: example.c
	gcc -c example.c

example: libftp.a example.o
	gcc  example.o libftp.a -o example

# example in Caml ?

