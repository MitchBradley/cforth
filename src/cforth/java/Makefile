# Makefile for Forth under Java

VPATH = . ..

ARCH=/usr/local/arm
UTILS=$(ARCH)/arm-linux/bin
TCC=$(UTILS)/gcc -DTARGET
TLD=$(UTILS)/ld
LIBDIRS=-L$(ARCH)/lib/gcc-lib/arm-linux/3.2/
# TCC = arm-linux-gcc
# TLD = arm-linux-ld

# SYSCALL=
SYSCALL=-DNOSYSCALL

# To omit floating point support
FP=
# Use this version if your math library has acosh(), expm1(), log1fp(), etc.
# FP=-DFLOATING -DMOREFP
# Use this version if not
# FP=-DFLOATING

#OPTIMIZE=
#OPTIMIZE=-O

RELOCATE=
# RELOCATE=-DRELOCATE

CONFIG= -I. -I.. $(FP) $(RELOCATE) $(SYSCALL) -DBITS32

CFLAGS= -g $(OPTIMIZE) $(CONFIG)

INCPRIMS= -include vars.h -include prims.h
FINC=config.h forth.h vars.h 

INCLUDE=compiler.h $(FINC) prims.h

# Common objects compiled for the host instruction set
# BASEOBJS=forth.o compiler.o syscall.o floatops.o extend.o
BASEOBJS=forth.o compiler.o syscall.o

# Objects specific to the host environment
HOSTOBJS=main.o io.o nullbi.o dictfile.o mallocl.o 

# Objects comprising the metacompiler (host) application
METAOBJS=meta.o compiler.o io.o dictfile.o mallocl.o

# The following macros are for the "clean" and "tidy" targets

HELPERS=forth.dic kernel.dic meta forth makebi makename forthbi
DERIVED=dict.h dicthdr.h userarea.h init.x prims.h vars.h forth.ip *.j
BACKUPS=*.BAK *.CKP ,* *~
ARTIFACTS = $(BASEOBJS) $(TBASEOBJS) $(METAOBJS) $(EMBEDOBJS) $(HOSTOBJS) \
  $(HELPERS) $(DERIVED) $(BACKUPS) *.java

all: forth.dic cidpforth.java forth.java

RAMBASE = 0x200000
TLFLAGS = -static
LIBDIRS=-L$(ARCH)/lib/gcc-lib/arm-linux/3.2/

# forth.dic is a Forth dictionary file that includes basic Forth compilation
# capabilities

forth.dic: forth kernel.dic load.fth
	./forth kernel.dic load.fth
	-[ `hostname` == 'bdco' ] && cp forth.dic /mnt/bigdell

# kernel.dic is a primitive Forth dictionary file with extremely rudimentary
# Forth interpretation capabilities; it is missing a significant number
# of standard capabilities, but is sufficient as a base for the next
# Forth compilation step (that of creating forth.dic).

kernel.dic: ../interp.fth meta init.x
	./meta $< kernel.dic

# meta is a self-contained program whose only purpose is to create kernel.dic
# using as input the file "../interp.fth", which is written in a severely-
# restricted form of Forth source code .  The use of this self-contained
# auxiliary program "meta" eliminates the need for certain kinds of compilation
# code in the low-level C runtime routines that form the base of the
# Forth execution environment, resulting in a smaller kernel.

meta: $(METAOBJS)
	$(CC) -o $@ $(METAOBJS)

# meta.o is an object module that is a component of "meta"

meta.o: $(INCLUDE) meta.c
	$(CC) $(CFLAGS) $(INCPRIMS) -c meta.c

# forth is an application program that runs under an operating system.
# It contains the run-time primitives for the Forth kernel, and also
# complete file I/O capabilities.  It is used in the compilation of extended
# Forth dictionary files (forth.dic and app.dic) and can also be used
# for development testing purposes.  It reads and writes its dictionary
# images to and from ordinary files.

forth: $(BASEOBJS) $(HOSTOBJS)
	$(CC) $(CFLAGS) -o $@ $(HOSTOBJS) $(BASEOBJS)

# main.o is the main() entry point for the self-contained applications above

%.o: %.c
	$(CC) $(CFLAGS) -c $<

# main.o: $(INCLUDE) main.c
# 	$(CC) $(CFLAGS) -c main.c

forth.o: $(INCLUDE) forth.c
	$(CC) $(CFLAGS) $(INCPRIMS) -c forth.c

# compiler.o implements low-level support routines that are used by
# the Forth interpreter/incremental compiler

compiler.o: $(INCLUDE) compiler.c
	$(CC) $(CFLAGS) $(INCPRIMS) -c compiler.c

# dictfile.o implements file I/O routines specifically for the purpose
# of reading and writing Forth dictionary images to and from files.

dictfile.o: forth.h dictfile.c
	$(CC) $(CFLAGS) -c dictfile.c

# io.o implements general-purpose Forth I/O primitives for both console
# and file I/O.  It is used in the compilation tools but not in the
# embeddable version.

io.o:	$(FINC) io.c
	$(CC) $(CFLAGS) $(INCPRIMS) -c io.c

nullbi.o: $(INCLUDE) nullbi.c
	$(CC) $(CFLAGS) -c nullbi.c

mallocl.o: $(FINC) ../mallocl.c
	$(CC) $(CFLAGS) -c ../mallocl.c

# The next few object files implement miscellaneous primitives;

syscall.o: $(FINC) ../generic/syscall.c
	$(CC) $(CFLAGS) -c ../generic/syscall.c

floatops.o: $(FINC) ../fprims.h prims.h ../floatops.c
	$(CC) $(CFLAGS) -c ../floatops.c

extend.o: $(FINC) ../extend.c
	$(CC) $(CFLAGS) -c ../extend.c

# These files are automatically-generated header files containing
# information extracted from the C source file "forth.c".  They
# are used in the compilation of other object modules.

init.x prims.h vars.h: forth.ip makename
	./makename forth.ip

# forth.ip is the result of preprocessing forth.c with MAKEPRIMS
# defined.  The reason for doing this in a separate step is to
# omit any primitives that are #ifdef'ed out, so that makename
# doesn't see them and try to add them to the enumeration.

forth.ip: forth.c forth.h config.h Makefile
	cpp -C -DMAKEPRIMS $(CONFIG) forth.c >forth.ip

# A .j file is a fragment of Java source code that is created by
# preprocessing a C source file with JAVA defined.  The include
# macros are set up so that the preprocessor is well-formed Java
# code.  Several such fragments are then concatenated to form a
# complete Java source file.  It's done this way because the C source
# code is organized as several separate files, but Java requires the
# entire source code for a given class definition to be in one file.

%.j: %.c $(INCLUDE)
	cpp $(CONFIG) -DJAVA $< | grep -v "^#" >$@

end.j:
	echo "}" >end.j

# Forth application to run on a J2ME mobile phone implementing
# the CIDP profile.

cidpforth.java: cidpstart.j forth.j compiler.j cidpio.j end.j
	cat $^ >$@
	-[ `hostname` == 'bdco' ] && cp $@ /mnt/bigdell

# Forth application to run under J2SE.

forth.java: javastart.j forth.j compiler.j io.j end.j
	cat $^ >$@
	-[ `hostname` == 'bdco' ] && cp $@ /mnt/bigdell

# makename is a self-contained application whose purpose is to
# extract various bits of information from the "forth.c" source
# file and to produce ".h" files that export that information
# to other modules.  That information is basically the list of
# primitive routines and variables and their names (both C
# preprocessor names and Forth word names).  This avoids the
# tedious and error-prone step of keeping forth.c in sync with
# "init.x", "prims.h", and "vars.h" by automatically generating
# those three files.

%: %.c
	$(CC) -o $@ -g $<

clean:
	@rm -f $(ARTIFACTS)

tidy:
	@rm -f $(ARTIFACTS)
