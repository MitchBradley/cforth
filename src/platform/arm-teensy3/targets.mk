# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
CROSS ?= arm-none-eabi-
CPU_VARIANT=-mthumb -mcpu=cortex-m4
include $(SRC)/cpu/arm/compiler.mk

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk

DEFS += -DF_CPU=48000000 -DUSB_SERIAL -DLAYOUT_US_ENGLISH -D__MK20DX256__ -DARDUINO=105 -DTEENSYDUINO=118

DICTIONARY=ROM
DICTSIZE=0x2000

include $(SRC)/cforth/embed/targets.mk

CFLAGS += -m32 -march=i386

TCFLAGS += -Os

# Omit unreachable functions from output

TCFLAGS += -ffunction-sections -fdata-sections $(DEFS)
TLFLAGS += --gc-sections -Map main.map

# VPATH += $(SRC)/cpu/arm
VPATH += $(SRC)/lib
VPATH += $(SRC)/platform/arm-teensy3

# This directory, including board information
INCS += -I$(SRC)/platform/arm-teensy3


# Platform-specific object files for low-level startup and platform I/O

tconsoleio.o: vars.h

PLAT_OBJS += tmk20dx128.o ttmain.o tconsoleio.o tusb_dev.o tusb_mem.o tusb_desc.o tusb_serial.o tanalog.o tpins_teensy.o teeprom.o mallocembed.o

# Object files for the Forth system and application-specific extensions

FORTH_OBJS = tembed.o textend.o


# Recipe for linking the final image

LDSCRIPT = $(SRC)/platform/arm-teensy3/mk20dx256.ld

app.elf: $(PLAT_OBJS) $(FORTH_OBJS) tdate.o
	@echo Linking $@ ... 
	$(TLD) -o $@  $(TLFLAGS) -T$(LDSCRIPT) \
	   $(PLAT_OBJS) $(FORTH_OBJS) tdate.o \
	   $(LIBDIRS) -lgcc


# This rule extracts the executable bits from an ELF file, yielding a hex file

%.hex: %.elf
	$(CROSS)size $<
	$(TOBJCOPY) -O ihex -R .eeprom $< $@
	@ls -l $@

# This rule loads the hex file to the module
burn: app.hex
	teensy_loader_cli -w -mmcu=mk20dx128 app.hex

# This rule builds a date stamp object that you can include in the image
# if you wish.

tdate.o: $(PLAT_OBJS) $(FORTH_OBJS)
	@(echo "`git rev-parse --verify --short HEAD``if git diff-index --exit-code --name-only HEAD >/dev/null; then echo '-dirty'; fi`" || echo UNKNOWN) >version
	@echo 'const char version[] = "'`cat version`'";' >tdate.c
	@echo 'const char build_date[] = "'`date --utc +%F\ %R`'";' >>tdate.c
	@cat tdate.c
	@echo TCC $@
	@$(TCC) -c tdate.c -o $@

EXTRA_CLEAN += *.map *.elf *.dump *.nm *.hex version tdate.c
EXTRA_CLEAN += $(FORTH_OBJS) $(PLAT_OBJS)
