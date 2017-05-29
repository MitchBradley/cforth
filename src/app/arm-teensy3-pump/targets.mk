CONFIG += -DBITS32
# CONFIG += -DFLOATING -DMOREFP

CC:=gcc

# APPPATH is the path to the application code, i.e. this directory
APPPATH=$(TOPDIR)/src/app/arm-teensy3-pump

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files that the application uses,
# i.e. the list of files that APPLOADFILE floads.  It's for dependency checking.
APPSRCS = $(wildcard $(APPPATH)/*.fth)

default: app.o

# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
CROSS?=/c/Arduino/hardware/tools/arm/bin/arm-none-eabi-
CPU_VARIANT=-mthumb -mcpu=cortex-m4
include $(SRC)/cpu/arm/compiler.mk

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk

DICTIONARY=ROM
DICTSIZE=0xc000

CONFIG += -DBITS32
CONFIG += -DFLOATING -DMORE_FP
CFLAGS += -m32
TCFLAGS += -MMD -g -Os -std=c99
#TCFLAGS += -MMD -g -Os -std=c99
TCFLAGS += -DF_CPU=96000000

include $(SRC)/cforth/embed/targets.mk

DUMPFLAGS = --disassemble -z -x -s

VPATH += $(SRC)/cpu/arm $(SRC)/lib
VPATH += $(SRC)/app/arm-teensy3
INCS += -I$(SRC)/app/arm-teensy3

# Platform-specific object files for low-level startup and platform I/O

PLAT_OBJS =  ttmain.o tconsoleio.o mallocembed.o
PLAT_OBJS += ti2c-bitbang.o
PLAT_OBJS += tonewire.o

# Object files for the Forth system and application-specific extensions

FORTH_OBJS = tembed.o textend.o

RAMBASE = 0x1fff8000
RAMTOP  = 0x20008000

TSFLAGS += -DRAMTOP=${RAMTOP}

LIBGCC= -lgcc

ttmain.o: vars.h

app.o: $(PLAT_OBJS) $(FORTH_OBJS)
	@echo Linking $@ ... 
	$(TLD)  -o $@  -r  $(PLAT_OBJS) $(FORTH_OBJS)

app.elf: app.o
	@echo Linking $@ ... 
	$(TLD) -N  -o $@  $(TLFLAGS) -Ttext $(RAMBASE) \
	    start.o app.o \
	    $(LIBDIRS) $(LIBGCC) -lc
	@$(TOBJDUMP) $(DUMPFLAGS) $@ >$(@:.elf=.dump)
	@nm -n $@ >$(@:.elf=.nm)

# This rule extracts the executable bits from an ELF file, yielding raw binary.

%.img: %.elf
	@$(TOBJCOPY) -O binary $< $@
	date  "+%F %H:%M" >>$@
	@ls -l $@

# This rule builds a date stamp object that you can include in the image
# if you wish.

.PHONY: date.o

date.o:
	echo 'const char version[] = "'`cat version`'" ;' >date.c
	echo 'const char build_date[] = "'`date  --iso-8601=minutes`'" ;' >>date.c
	echo "const unsigned char sw_version[] = {" `cut -d . --output-delimiter=, -f 1,2 version` "};" >>date.c
	$(TCC) -c date.c -o $@

EXTRA_CLEAN += *.elf *.dump *.nm *.img date.c $(FORTH_OBJS) $(PLAT_OBJS)
