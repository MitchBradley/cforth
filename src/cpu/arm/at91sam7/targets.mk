SRC =../..

# This file is included from objs/tester/Makefile

STAGE:=sh $(TOPDIR)/common/stage.sh

EXTRA_CLEAN=*.elf *.dump *.nm vl3 capture *.img date.c

EXTRAFILES += $(BUILDDIR)/c/forth/Makefile

SUBDIRS=../tester/c/forth

VPATH = $(SRC)/tester/c $(SRC)/common
INCS = -I. -I$(SRC)/tester/c -I$(SRC)/tester/c/forth -I$(SRC)/common

# Add these to include ARM FFT routine in the tester build
# VPATH += $(SRC)/arm
# INCS += -I$(SRC)/arm
include $(SRC)/common/compiler.mk
include $(SRC)/common/common.mk

# TCFLAGS += -mcpu=arm7tdmi -DNANOFORTH
TCFLAGS += -mcpu=arm7tdmi

DUMPFLAGS = --disassemble-all -z -x

TESTER_IO = start.o clocks.o serialio.o ticks.o miscio.o flash.o atmelio.o printfraction.o

# TESTER_APP = main.o jtag.o armjtag.o at91sam7jtag.o ports.o serialtoflash.o
TESTER_APP = main.o jtag.o ports.o serialtoflash.o bintones.o bintonestab.o capture.o

TESTER_OBJS = $(TESTER_IO) $(TESTER_APP)

textend.o: textend.c
	$(TCC) $(TCFLAGS) -c $< -o $@

FORTH_OBJS = ../tester/c/forth/embed.o textend.o
# FORTH_OBJS += fft.o

RAMBASE = 0x200000
SERIAL_LOADER_OFFSET = 0x1000

atmelio.o: config.h

FORCE:

../tester/c/forth/embed.o: FORCE
	$(MAKE) -C ../tester/c/forth

BOOTBASE = 0x000000
RAMBASE  = 0x200000

testerfw.elf: $(TESTER_OBJS) $(FORTH_OBJS)
	@echo Linking $@ ... 
	$(TLD) -N  -o $@  $(TLFLAGS) -Ttext $(BOOTBASE) -Tbss $(RAMBASE) \
	    $(TESTER_OBJS) $(FORTH_OBJS) \
	    $(LIBDIRS) -lgcc -lc
	@$(ARCH)/bin/arm-linux-objdump $(DUMPFLAGS) $@ >$(@:.elf=.dump)
	@nm -n $@ >$(@:.elf=.nm)

start.o: regs.h

%.img: %.elf
	@$(ARCH)/bin/arm-linux-objcopy -O binary $< $@
	date  "+%F %H:%M" >>$@
	- $(STAGE) $@
	@ls -l $@

.PHONY: date.o

date.o:
	echo 'const char version[] = "'`cat version`'" ;' >date.c
	echo 'const char build_date[] = "'`date  --iso-8601=minutes`'" ;' >>date.c
	echo "const unsigned char sw_version[] = {" `cut -d . --output-delimiter=, -f 1,2 version` "};" >>date.c
	$(TCC) -c date.c -o $@

include $(TOPDIR)/common/release.mk
