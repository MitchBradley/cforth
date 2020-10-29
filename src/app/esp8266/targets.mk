# APPPATH is the path to the application code, i.e. this directory
APPPATH ?= $(TOPDIR)/src/app/esp8266

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE ?= app.fth

# APPSRCS is a list of Forth source files that the application uses,
# i.e. the list of files that APPLOADFILE floads.  It's for dependency checking.
APPSRCS += $(wildcard $(APPPATH)/*.fth)

TCPATH=$(TOPDIR)/src/app/esp8266

default: 0x00000.bin 0x10000.bin

# default: app.o

# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
TCC=$(CROSS)gcc
TLD=$(CROSS)ld
TOBJDUMP=$(CROSS)objdump
TOBJCOPY=$(CROSS)objcopy

LIBDIRS=-L$(dir $(shell $(TCC) $(TCFLAGS) -print-libgcc-file-name))

VPATH += $(TCPATH)
INCS += -I$(TCPATH)

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk
include $(TCPATH)/sdk.mk

OPTIMIZE = -O2

TCFLAGS += \
  -g \
  -fno-inline-functions \
  -nostdlib \
  -mlongcalls \
  -mtext-section-literals \
  -DXTENSA

DUMPFLAGS = --disassemble -z -x -s

# Platform-specific object files for low-level startup and platform I/O

tconsoleio.o: vars.h

PLAT_OBJS +=  tconsoleio.o
PLAT_OBJS +=  ttmain.o
PLAT_OBJS +=  tlwip.o
PLAT_OBJS +=  tfileio.o
PLAT_OBJS +=  tesp_spi.o

# Object files for the Forth system and application-specific extensions

FORTH_OBJS = tembed.o textend.o tw5500.o

# Recipe for linking the final image

DICTIONARY=ROM
DICTSIZE=0x4000

app.o: tdate.o
	@echo Linking $@ ... 
	@$(TLD)  -o $@  -r  $(PLAT_OBJS) $(FORTH_OBJS) tdate.o

# This rule builds a date stamp object that you can include in the image
# if you wish.

tdate.o: $(PLAT_OBJS) $(FORTH_OBJS)
	@(echo "`git rev-parse --verify --short HEAD``if git diff-index --exit-code --name-only HEAD >/dev/null; then echo '-dirty'; fi`" || echo UNKNOWN) >version
	@echo 'const char version[] = "'`cat version`'";' >tdate.c
	@echo 'const char build_date[] = "'`date --utc +%F\ %R`'";' >>tdate.c
	@cat tdate.c
	@echo TCC $@
	@$(TCC) -c tdate.c -o $@

EXTRA_CLEAN += *.elf *.dump *.nm *.img tdate.c version
EXTRA_CLEAN += $(FORTH_OBJS) $(PLAT_OBJS)

PREFIX += CBP=$(realpath $(TOPDIR)/src)
PREFIX += BP=$(realpath /c/Users/wmb/Documents/svn/openfirmware)

include $(SRC)/cforth/embed/targets.mk

# include autohotkey.mk

dlonly:
	$(NODEMCU_PARENT_PATH)/nodemcu-firmware/tools/esptool.py --port $(COMPORT) -b 115200 write_flash -fm=dio -fs=32m 0x00000 0x00000.bin 0x10000 0x10000.bin
