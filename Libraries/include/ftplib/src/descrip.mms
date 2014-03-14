.ifdef MMSIA64
SUFFIX = _IA64
CFLAGS = $(CFLAGS)/define=(_LARGEFILE)
.endif
.ifdef MMSALPHA
SUFFIX = _ALPHA
CFLAGS = $(CFLAGS)/define=(_LARGEFILE)
.endif
.ifdef MMSVAX
XFER_VECTOR = ftplib_vector.obj
.endif

TARGETS = ftplib$(SUFFIX).exe qftp$(SUFFIX).exe
SHLINKFLAGS = /SHARE=$(MMS$TARGET)/NOMAP

* : $(TARGETS)
	continue

clean :
	if f$search("ftplib.obj") .nes. "" then delete ftplib.obj;*
	if f$search("ftplib_alpha.obj") .nes. "" then delete ftplib_alpha.obj;*
	if f$search("ftplib.exe") .nes. "" then delete ftplib.exe;*
	if f$search("ftplib_alpha.exe") .nes. "" then delete ftplib_alpha.exe;*
	if f$search("qftp.obj") .nes. "" then delete qftp.obj;*
	if f$search("qftp_alpha.obj") .nes. "" then delete qftp_alpha.obj;*
	if f$search("qftp.exe") .nes. "" then delete qftp.exe;*
	if f$search("qftp_alpha.exe") .nes. "" then delete qftp_alpha.exe;*
	if f$search("ftplib_vector.obj") .nes. "" then delete ftplib_vector.obj;*

ftplib$(SUFFIX).obj : ftplib.c ftplib.h
	$(CC) $(CFLAGS) $<

ftplib$(SUFFIX).exe : ftplib$(SUFFIX).obj $(XFER_VECTOR)
	$(LINK) $(SHLINKFLAGS) ftplib$(SUFFIX).opt/options

qftp$(SUFFIX).exe : qftp$(SUFFIX).obj
	$(LINK) $(LINKFLAGS) qftp$(SUFFIX).opt/options

qftp$(SUFFIX).obj : qftp.c ftplib.h
	$(CC) $(CFLAGS) $<
