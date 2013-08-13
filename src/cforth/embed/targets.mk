# Additional rules for embedded CForth

VPATH += $(SRC)/cforth/embed
INCS += -I$(SRC)/cforth/embed

# Leave some room at the top of RAM for the C stack and for executing
# RAM-resident binary code like serial_to_flash.  serial_to_flash needs
# 1K of code space, so we reserve 4K for code + stack just to be safe.
TCFLAGS += -g $(OPTIMIZE) $(CONFIG) -DMAXDICT=$(DICTSIZE)
TCFLAGS += -DTARGET

ifeq (y, $(shell $(TCC) -xc -c -fno-stack-protector /dev/null -o /dev/null 2>/dev/null && echo y))
  TCFLAGS += -fno-stack-protector
endif

# Common objects compiled for the target instruction set
TBASEOBJS=tforth.o tcompiler.o tsyscall.o tfloatops.o tlineedit.o

ifeq ($(DICTIONARY),ROM)
  DICTOBJ=rodict.o
else
  DICTOBJ=rwdict.o
endif

# Objects specific to the target environment
EMBEDOBJS=startapp.o tconsio.o mallocembed.o $(DICTOBJ)

HELPERS += makebi forthbi
ARTIFACTS += $(TBASEOBJS) $(EMBEDOBJS)

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

# tembed.o is an object file that can be linked into an application
# to provide a Forth interpreter for that application.  It requires
# only minimal C library support; basically just memory allocation,
# putchar/getchar, and simple string routines like strcpy().

tembed.o: $(TBASEOBJS) $(EMBEDOBJS)
	$(TLD) -r -o $@ $(TBASEOBJS) $(EMBEDOBJS)

# startapp.o provides entry points for the enclosing application to
# call into the Forth application

startapp.o: startapp.c $(INCLUDE)
	$(TCC) $(TCFLAGS) -c $<

# The following object modules contains a binary image of
# a Forth dictionary.  It is used as a component of tembed.o and
# forthbi, so that those programs do not need to perform file
# I/O operations in order to get their initial Forth dictionary.

builtin.o: builtin.c $(INCLUDE) dict.h dicthdr.h
	$(TCC) $(TCFLAGS) -c $<

rwdict.o: rwdict.c $(INCLUDE) dict.h dicthdr.h userarea.h
	$(TCC) $(TCFLAGS) -c $<

rodict.o: rodict.c $(INCLUDE) dict.h dicthdr.h userarea.h
	$(TCC) $(TCFLAGS) -c $<

*.o: targets.mk
*.o: $(INCLUDE)

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

# tconsio.o is a simplified Forth I/O module that supports only console I/O
# (i.e. getchar() and putchar()).

tconsio.o: consio.c $(INCLUDE)
	$(TCC) $(TCFLAGS) -c $<  -o $@

tlineedit.o: lineedit.c $(INCLUDE)
	$(TCC) $(TCFLAGS) -c $<  -o $@

# tforth.o implements the Forth virtual machine and the core primitives.
# It corresponds roughly to the set of Forth words that would typically
# be implemented in assembly language in a machine-specific Forth
# implementation

tforth.o: forth.c $(INCLUDE)
	$(TCC) $(TCFLAGS) -c $< -o $@

# compiler.o implements low-level support routines that are used by
# the Forth interpreter/incremental compiler

tcompiler.o: compiler.c $(INCLUDE)
	$(TCC) $(TCFLAGS) -c $< -o $@

# dictfile.o implements file I/O routines specifically for the purpose
# of reading and writing Forth dictionary images to and from files.

# io.o implements general-purpose Forth I/O primitives for both console
# and file I/O.  It is used in the compilation tools but not in the
# embeddable version (tembed.o).

# The next few object files implement miscellaneous primitives;

tsyscall.o: generic/syscall.c $(FINC)
	$(TCC) $(TCFLAGS) -c $< -o $@

tfloatops.o: floatops.c $(FINC) prims.h
	$(TCC) $(TCFLAGS) -c $< -o $@

textend.o: textend.c $(FINC)
	$(TCC) $(TCFLAGS) -c $< -o $@

EXTRA_CLEAN += tembed.o
