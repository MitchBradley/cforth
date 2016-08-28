# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
ifneq "$(findstring arm,$(shell uname -m))" ""
include $(SRC)/cpu/host/compiler.mk
else
include $(SRC)/cpu/arm/compiler.mk
endif

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk
include $(SRC)/cforth/embed/targets.mk

DUMPFLAGS = --disassemble -z -x -s

VPATH += $(SRC)/cpu/arm $(SRC)/lib
VPATH += $(SRC)/platform/arm-mmp2 
INCS += -I$(SRC)/platform/arm-mmp2 

# Platform-specific object files for low-level startup and platform I/O

PLAT_OBJS = tstart.o mallocembed.o

# Object files for the Forth system and application-specific extensions

FORTH_OBJS = ttmain.o tembed.o textend.o tconsoleio.o

# Recipe for linking the final image

# On XO-1.75, a masked-ROM loader copies CForth from SPI FLASH into SRAM
DICTIONARY=RAM

DICTSIZE=0xe000

RAMBASE = 0xd1000000
RAMTOP  = 0xd1020000

TSFLAGS += -DRAMTOP=${RAMTOP}

LIBGCC= -lgcc

app.elf: $(PLAT_OBJS) $(FORTH_OBJS)
	@echo Linking $@ ... 
	$(TLD) -N  -o $@  $(TLFLAGS) -Ttext $(RAMBASE) \
	    $(PLAT_OBJS) $(FORTH_OBJS) \
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
