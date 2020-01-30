# Makefile fragment for the final target application
# Based on src/app/arm-xo-cl4/targets.mk

SRC=$(TOPDIR)/src

# Target compiler definitions
CROSS ?= arm-none-eabi-
CPU_VARIANT=-marm -mcpu=strongarm110
include $(SRC)/cpu/arm/compiler.mk

VPATH += $(SRC)/cpu/arm $(SRC)/lib
VPATH += $(SRC)/platform/arm-ariel
VPATH += $(SRC)/platform/arm-xo-1.75
INCS += -I$(SRC)/platform/arm-ariel

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk
include $(SRC)/cforth/embed/targets.mk

TCFLAGS += -fno-pie

DUMPFLAGS = --disassemble -z -x -s

# Platform-specific object files for low-level startup and platform I/O

PLAT_OBJS = tstart.o mallocembed.o

# Object files for the Forth system and application-specific extensions

# FORTH_OBJS = tmain.o embed.o textend.o  spiread.o consoleio.o
FORTH_OBJS = ttmain.o tembed.o textend.o  tspiread-simpler.o tconsoleio.o tinflate.o

SHIM_OBJS = tshimmain.o tspiread.o

SHIM_CFLAGS += -DCFORTHSIZE=$(shell stat -c%s cforth.img)
SHIM_CFLAGS += -DRAMBASE=$(RAMBASE)
SHIM_CFLAGS += -DSHIMBASE=$(SHIMBASE)

tshimmain.o: shimmain.c cforth.img
	@echo TCC $<
	@$(TCC) $(INCS) $(DEFS) $(TCFLAGS) $(TCPPFLAGS) $(SHIM_CFLAGS) -c $< -o $@

# Recipe for linking the final image

# On MMP3, a masked-ROM loader copies CForth from SPI FLASH into SRAM
DICTIONARY=RAM

DICTSIZE=0xf000

RAMBASE  = 0xd1000000
IRQSTACKSIZE = 0x100
RAMTOP   = 0xd101f000
SHIMBASE = 0xd1019000

TSFLAGS += -DRAMTOP=${RAMTOP}
TSFLAGS += -DIRQSTACKSIZE=${IRQSTACKSIZE}

LIBGCC= -lgcc

version:
	git log -1 --format=format:"%H" >>$@ 2>/dev/null || echo UNKNOWN >>$@
	pwd
	echo VPATH = ${VPATH}

cforth.elf: version $(PLAT_OBJS) $(FORTH_OBJS)
	@echo 'const char version[] = "'`cat version`'" ;' >date.c
	@echo 'const char build_date[] = "'`date --utc +%F\ %R`'" ;' >>date.c
	@$(TCC) -c date.c
	@echo Linking $@ ...
	@$(TLD) -N  -o $@  $(TLFLAGS) -Ttext $(RAMBASE) \
	    $(PLAT_OBJS) $(FORTH_OBJS) date.o \
	    $(LIBDIRS) $(LIBGCC)
	@$(TOBJDUMP) $(DUMPFLAGS) $@ >$(@:.elf=.dump)
	@if egrep -q '^\S{8}:\s\S{4}\s' $(@:.elf=.dump); then echo 'PJ1 has no Thumb support. Wrong libgcc?'; rm $@; exit 1; fi
	@nm -n $@ >$(@:.elf=.nm)

shim.elf: $(PLAT_OBJS) $(SHIM_OBJS)
	@echo Linking $@ ...
	@$(TLD) -N  -o $@  $(TLFLAGS) -Ttext $(SHIMBASE) \
	    $(PLAT_OBJS) $(SHIM_OBJS) \
	    $(LIBDIRS) $(LIBGCC)
	@$(TOBJDUMP) $(DUMPFLAGS) $@ >$(@:.elf=.dump)
	@nm -n $@ >$(@:.elf=.nm)


# This rule extracts the executable bits from an ELF file, yielding raw binary.

%.img: %.elf
	@$(TOBJCOPY) -O binary $< $@
	@date  "+%F %H:%M" >>$@
	@ls -l $@

EXTRA_CLEAN += *.elf *.dump *.nm *.img date.c $(FORTH_OBJS) $(PLAT_OBJS) $(SHIM_OBJS) date.o version
