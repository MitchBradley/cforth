# Makefile for Forth on a small embedded processor

VPATH += $(SRC)/cforth/embed $(SRC)/cforth
INCS += -I. -I$(SRC)/cforth -I$(SRC)/cforth/embed

# SYSCALL=
SYSCALL=-DNOSYSCALL

# To omit floating point support
FP=
# Use this version if your math library has acosh(), expm1(), log1fp(), etc.
# FP=-DFLOATING -DMOREFP
# Use this version if not
# FP=-DFLOATING

#OPTIMIZE=
OPTIMIZE=-O

RELOCATE=
# RELOCATE=-DRELOCATE

CONFIG= $(INCS) $(FP) $(RELOCATE) $(SYSCALL) -DBITS32 -DT16

CFLAGS= -g $(OPTIMIZE) $(CONFIG)

# Leave some room at the top of RAM for the C stack and for executing
# RAM-resident binary code like serial_to_flash.  serial_to_flash needs
# 1K of code space, so we reserve 4K for code + stack just to be safe.
TCFLAGS += -g $(OPTIMIZE) $(CONFIG) -DMAXDICT=$(DICTSIZE)
TCFLAGS += -DTARGET

ifeq (y, $(shell $(TCC) -xc -c -fno-stack-protector /dev/null -o /dev/null 2>/dev/null && echo y))
  TCFLAGS += -fno-stack-protector
endif

FINC=config.h forth.h vars.h 

INCLUDE=compiler.h $(FINC) prims.h

# Common objects compiled for the target instruction set
TBASEOBJS=tforth.o tcompiler.o tsyscall.o tfloatops.o

# Common objects compiled for the host instruction set
BASEOBJS=forth.o compiler.o syscall.o floatops.o extend.o

ifeq ($(DICTIONARY),ROM)
  DICTOBJ=rodict.o
else
  DICTOBJ=rwdict.o
endif

# Objects specific to the target environment
EMBEDOBJS=startapp.o consio.o mallocembed.o $(DICTOBJ)

# Objects specific to the host environment
HOSTOBJS=main.o io.o nullbi.o dictfile.o mallocl.o 

# Objects comprising the metacompiler (host) application
METAOBJS=meta.o compiler.o io.o dictfile.o mallocl.o

# The following macros are for the "clean" and "tidy" targets

HELPERS=forth.dic kernel.dic meta forth makebi makename forthbi
DERIVED=dict.h dicthdr.h userarea.h init.x prims.h vars.h forth.ip
BACKUPS=*.BAK *.CKP ,* *~
ARTIFACTS = $(BASEOBJS) $(TBASEOBJS) $(METAOBJS) $(EMBEDOBJS) $(HOSTOBJS) \
  $(HELPERS) $(DERIVED) $(BACKUPS) *.core


# forthbi contains the same basic functionality as embed.o, but it
# is linked as a self-contained application that can be executed
# as a user program.  Its primary purpose is for testing during
# the development and refinement of forth.o .  It only works if
# the compilation host and the target have the same instruction set.

forthbi: main.o embed.o mallocl.o
	$(CC) $(CFLAGS) -o $@ main.o embed.o mallocl.o

RAMBASE = 0x200000
TEXTBASE = $(RAMBASE)
TLFLAGS = -static

# embed.o is an object file that can be linked into an application
# to provide a Forth interpreter for that application.  It requires
# only minimal C library support; basically just memory allocation,
# putchar/getchar, and simple string routines like strcpy().

embed.o: $(TBASEOBJS) $(EMBEDOBJS)
	$(TLD) -r -o $@ $(TBASEOBJS) $(EMBEDOBJS)

# startapp.o provides entry points for the enclosing application to
# call into the Forth application

startapp.o: startapp.c $(INCLUDE)
	$(TCC) $(TCFLAGS) -c $<

# The following object modules contains a binary image of
# a Forth dictionary.  It is used as a component of embed.o and
# forthbi, so that those programs do not need to perform file
# I/O operations in order to get their initial Forth dictionary.

builtin.o: builtin.c $(INCLUDE) dict.h dicthdr.h
	$(TCC) $(TCFLAGS) -c $<

rwdict.o: rwdict.c $(INCLUDE) dict.h dicthdr.h userarea.h
	$(TCC) $(TCFLAGS) -c $<

rodict.o: rodict.c $(INCLUDE) dict.h dicthdr.h userarea.h
	$(TCC) $(TCFLAGS) -c $<

*.o: targets.mk

# Memory allocator for the target environment

mallocembed.o: mallocembed.c $(FINC)
	$(TCC) $(TCFLAGS) -c $<

# dict.h and dicthdr.h are automatically-generated "source" files
# containing ASCII representations of binary data.  They are compiled
# to create builtin.o

dict.h dicthdr.h userarea.h: app.dic makebi
	./makebi $<

# makebi is a self-contained application whose only purpose is to
# convert a file containing a binary image of a Forth dictionary
# into an ASCII source file that can be compiled by a C compiler
# into an initialized data area.

makebi: makebi.c
	$(CC) $(CFLAGS) -o makebi $<

# app.dic is a Forth dictionary file that has been extended to include
# application code

app.dic: $(APPPATH)/$(APPLOADFILE) forth forth.dic $(APPSRCS)
	(cd $(APPPATH); $(OBJPATH2)/forth $(OBJPATH2)/forth.dic $(APPLOADFILE); mv $@ $(OBJPATH2))

base_dict.h base_dicthdr.h base_userarea.h: forth.dic makebi
	./makebi $<
	mv dict.h base_dict.h
	mv dicthdr.h base_dicthdr.h
	mv userarea.h base_userarea.h

# forth.dic is a Forth dictionary file that includes basic Forth compilation
# capabilities

FORTHSRCS = ../misc.fth ../compiler.fth ../control.fth ../postpone.fth \
            ../util.fth ../rambuffer.fth ../config.fth ../comment.fth \
            ../case.fth ../th.fth ../format.fth ../words.fth ../dump.fth \
            ../patch.fth ../brackif.fth ../decompm.fth ../decomp.fth \
            ../callfind.fth ../needs.fth ../sift.fth ../stringar.fth \
            ../size.fth ../ccalls.fth ../split.fth ../rstrace.fth aliases.fth

forth.dic: load.fth forth kernel.dic $(FORTHSRCS)
	(cd $(SRC)/cforth/embed; $(OBJPATH)/forth $(OBJPATH)/kernel.dic load.fth; mv $@ $(OBJPATH))

# kernel.dic is a primitive Forth dictionary file with extremely rudimentary
# Forth interpretation capabilities; it is missing a significant number
# of standard capabilities, but is sufficient as a base for the next
# Forth compilation step (that of creating forth.dic).

kernel.dic: interp.fth meta init.x
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

meta.o: meta.c $(INCLUDE)
	$(CC) $(CFLAGS) -c $<

# forth is an application program that runs under an operating system.
# It contains the run-time primitives for the Forth kernel, and also
# complete file I/O capabilities.  It is used in the compilation of extended
# Forth dictionary files (forth.dic and app.dic) and can also be used
# for development testing purposes.  It reads and writes its dictionary
# images to and from ordinary files.

forth: $(BASEOBJS) $(HOSTOBJS)
	$(CC) $(CFLAGS) -o $@ $(HOSTOBJS) $(BASEOBJS)

# main.o is the main() entry point for the self-contained applications above

main.o: main.c $(INCLUDE) 
	$(CC) $(CFLAGS) -c $<

# consio.o is a simplified Forth I/O module that supports only console I/O
# (i.e. getchar() and putchar()).

consio.o: consio.c $(INCLUDE)
	$(TCC) $(TCFLAGS) -c $<

# forth.o implements the Forth virtual machine and the core primitives.
# It corresponds roughly to the set of Forth words that would typically
# be implemented in assembly language in a machine-specific Forth
# implementation

tforth.o: forth.c $(INCLUDE)
	$(TCC) $(TCFLAGS) -c $< -o $@

forth.o: forth.c $(INCLUDE)
	$(CC) $(CFLAGS) -c $<

# compiler.o implements low-level support routines that are used by
# the Forth interpreter/incremental compiler

tcompiler.o: compiler.c $(INCLUDE)
	$(TCC) $(TCFLAGS) -c $< -o $@

compiler.o: compiler.c $(INCLUDE)
	$(CC) $(CFLAGS) -c $<

# dictfile.o implements file I/O routines specifically for the purpose
# of reading and writing Forth dictionary images to and from files.

dictfile.o: dictfile.c forth.h
	$(CC) $(CFLAGS) -c $<

# io.o implements general-purpose Forth I/O primitives for both console
# and file I/O.  It is used in the compilation tools but not in the
# embeddable version (embed.o).

io.o: io.c $(FINC)
	$(CC) $(CFLAGS) -c $<

nullbi.o: nullbi.c $(INCLUDE)
	$(CC) $(CFLAGS) -c $<

mallocl.o: mallocl.c $(FINC)
	$(CC) $(CFLAGS) -c $<

# The next few object files implement miscellaneous primitives;

tsyscall.o: generic/syscall.c $(FINC)
	$(TCC) $(TCFLAGS) -c $< -o $@

syscall.o: syscall.c $(FINC)
	$(CC) $(CFLAGS) -c $<

tfloatops.o: floatops.c $(FINC) prims.h
	$(TCC) $(TCFLAGS) -c $< -o $@

floatops.o: floatops.c $(FINC) prims.h
	$(CC) $(CFLAGS) -c $<

textend.o: textend.c $(FINC)
	$(TCC) $(TCFLAGS) -c $< -o $@

extend.o: extend.c $(FINC)
	$(CC) $(CFLAGS) -c $<

# These files are automatically-generated header files containing
# information extracted from the C source file "forth.c".  They
# are used in the compilation of other object modules.

init.x prims.h vars.h: forth.c
	make makename
	rm -f init.x prims.h vars.h
	cpp -C -DMAKEPRIMS $(CONFIG) $< >forth.ip
	./makename forth.ip

# makename is a self-contained application whose purpose is to
# extract various bits of information from the "forth.c" source
# file and to produce ".h" files that export that information
# to other modules.  That information is basically the list of
# primitive routines and variables and their names (both C
# preprocessor names and Forth word names).  This avoids the
# tedious and error-prone step of keeping forth.c in sync with
# "init.x", "prims.h", and "vars.h" by automatically generating
# those three files.

makename: makename.c
	$(CC) -o makename $<

clean:
	@rm -f $(ARTIFACTS) embed.o app.dic $(EXTRA_CLEAN)

tidy:
	@rm -f $(ARTIFACTS)
