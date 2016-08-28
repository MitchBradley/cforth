# Makefile fragment for CForth to run as an embedded app on a PC motherboard

SRC=$(TOPDIR)/src

include $(SRC)/cpu/host/compiler.mk

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk
include $(SRC)/cforth/embed/targets.mk

DUMPFLAGS = --disassemble -z -x -s

VPATH += $(SRC)/lib
VPATH += $(SRC)/platform/pc
INCS += -I$(SRC)/platform/pc

# Platform-specific object files for low-level startup and platform I/O

PLAT_OBJS = tstart.o ttmain.o tconsoleio.o mallocembed.o


# Object files for the Forth system and application-specific extensions

FORTH_OBJS = tembed.o textend.o


# Recipe for linking the final image

DICTIONARY=ROM

DICTSIZE=0x7000

ROMBASE = 0xffff0000
RAMBASE = 0xfff08000

app.elf: $(PLAT_OBJS) $(FORTH_OBJS)
	@echo Linking $@ ... 
	$(TLD) -N  -o $@  $(TLFLAGS) -Ttext $(ROMBASE) -Tbss $(RAMBASE) \
	    $(PLAT_OBJS) $(FORTH_OBJS) \
	    $(LIBDIRS) -lc
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
