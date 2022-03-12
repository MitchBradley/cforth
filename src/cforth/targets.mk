# Make rules for host CForth

VPATH += $(SRC)/cforth
INCS += -I. -I$(SRC)/cforth

# SYSCALL=
SYSCALL=-DNOSYSCALL

EXTENDSRC ?= $(SRC)/cforth/extend.c

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

CONFIG += $(INCS) $(FP) $(RELOCATE) $(SYSCALL) -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0

CFLAGS += -g $(OPTIMIZE) $(CONFIG)
CFLAGS += -fno-common

FINC=config.h forth.h vars.h 

INCLUDE=compiler.h $(FINC) prims.h

# Common objects compiled for the host instruction set
BASEOBJS=forth.o compiler.o syscall.o floatops.o extend.o

# Objects specific to the host environment
HOSTOBJS += main.o io.o nullbi.o dictfile.o mallocl.o

# You can substitute linenoise.o for linedit.o to get slightly more
# editing functionality, in particular history-across-sessions and
# better handling of long input lines.
HOSTOBJS += lineedit.o
# HOSTOBJS += linenoise.o

ifeq ($(OS),Windows_NT)
  HOSTOBJS += win32-kbd.o
else
  UNAME_S := $(shell uname -s)
  ifeq ($(UNAME_S),Linux)
    HOSTOBJS += linux-kbd.o
  else
    ifeq ($(UNAME_S),Darwin)
      HOSTOBJS += linux-kbd.o
    else
      HOSTOBJS += getc-kbd.o
    endif
  endif
endif

# Objects comprising the metacompiler (host) application
METAOBJS=meta.o compiler.o io.o dictfile.o mallocl.o lineedit.o getc-kbd.o

# The following macros are for the "clean" and "tidy" targets

HELPERS=kernel.dic meta makename meta.exe makename.exe makeccalls
DERIVED=dict.h dicthdr.h userarea.h init.x prims.h vars.h forth.ip ccalls.fth
BACKUPS=*.BAK *.CKP ,* *~
ARTIFACTS = $(BASEOBJS) $(METAOBJS) $(HOSTOBJS) \
  $(HELPERS) $(DERIVED) $(BACKUPS) *.core *.o *.exe *.d tccalls.fth

%.o: %.c $(INCLUDE)

# This forces the creation of prims.h and vars.h
forth.o: prims.h vars.h

# forth.dic is a Forth dictionary file that includes basic Forth compilation
# capabilities

FORTHSRCS = misc.fth compiler.fth control.fth postpone.fth \
            util.fth rambuffer.fth config.fth comment.fth \
            case.fth th.fth format.fth words.fth dump.fth \
            patch.fth brackif.fth decompm.fth decomp2.fth \
            callfind.fth needs.fth sift.fth stringar.fth \
            size.fth ccalls.fth split.fth rstrace.fth

forth.dic: load.fth forth kernel.dic $(FORTHSRCS)
	./forth kernel.dic $(SRC)/cforth/load.fth

# kernel.dic is a primitive Forth dictionary file with extremely rudimentary
# Forth interpretation capabilities; it is missing a significant number
# of standard capabilities, but is sufficient as a base for the next
# Forth compilation step (that of creating forth.dic).

kernel.dic: interp.fth meta init.x
	./meta $< kernel.dic

# meta is a self-contained program whose only purpose is to create kernel.dic
# using as input the file "interp.fth", which is written in a severely-
# restricted form of Forth source code .  The use of this self-contained
# auxiliary program "meta" eliminates the need for certain kinds of compilation
# code in the low-level C runtime routines that form the base of the
# Forth execution environment, resulting in a smaller kernel.

meta: $(METAOBJS)
	@echo CC $<
	@$(CC) $(CFLAGS) -o $@ $(METAOBJS)

# meta.o is an object module that is a component of "meta"

# forth is an application program that runs under an operating system.
# It contains the run-time primitives for the Forth kernel, and also
# complete file I/O capabilities.  It is used in the compilation of extended
# Forth dictionary files (forth.dic and app.dic) and can also be used
# for development testing purposes.  It reads and writes its dictionary
# images to and from ordinary files.

forth: $(BASEOBJS) $(HOSTOBJS)
	@echo MAKING FORTH
	@echo CC $(HOSTOBJS) $(BASEOBJS) $(LIBS) -o $@
	@$(CC) $(CFLAGS) -o $@ $(HOSTOBJS) $(BASEOBJS) $(LIBS)

# main.o is the main() entry point for the self-contained applications above

# forth.o implements the Forth virtual machine and the core primitives.
# It corresponds roughly to the set of Forth words that would typically
# be implemented in assembly language in a machine-specific Forth
# implementation

# compiler.o implements low-level support routines that are used by
# the Forth interpreter/incremental compiler

# dictfile.o implements file I/O routines specifically for the purpose
# of reading and writing Forth dictionary images to and from files.

# io.o implements general-purpose Forth I/O primitives for both console
# and file I/O.  It is used in the compilation tools but not in the
# embeddable version (embed.o).

extend.o ccalls.fth: $(EXTENDSRC) $(FINC) makeccalls
	@echo CC $<
	@$(CC) $(CFLAGS) -c $(EXTENDSRC) -o $@
	@$(CC) $(CFLAGS) -E -C -c $(EXTENDSRC) | ./makeccalls >ccalls.fth

# This rule builds a date stamp object that you can include in the image
# if you wish.

date.o: $(PLAT_OBJS) $(FORTH_OBJS)
	@(echo "`git rev-parse --verify --short HEAD``if git diff-index --exit-code --name-only HEAD >/dev/null; then echo '-dirty'; fi`" || echo UNKNOWN) >version
	@echo 'const char version[] = "'`cat version`'";' >date.c
	@echo 'const char build_date[] = "'`date --utc +%F\ %R`'";' >>date.c
	@cat date.c
	@echo CC $@
	@$(CC) -c date.c -o $@

# These files are automatically-generated header files containing
# information extracted from the C source file "forth.c".  They
# are used in the compilation of other object modules.

init.x prims.h vars.h: forth.c
	@$(MAKE) --no-print-directory makename
	@rm -f init.x prims.h vars.h
	@echo CPP $<
	@$(CPP) -C -DMAKEPRIMS $(CONFIG) $< >forth.ip
	@echo MAKENAME
	@./makename forth.ip

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
	@echo CC $<
	@$(CC) -o makename $<

makeccalls: makeccalls.c
	@echo CC $<
	@$(CC) -o makeccalls $<

# clean::
# 	@rm -f $(ARTIFACTS) forth forth.dic app.dic $(EXTRA_CLEAN)

tidy:
	@rm -f $(ARTIFACTS)
