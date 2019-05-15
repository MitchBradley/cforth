# APPPATH is the path to the application code, i.e. this directory
APPPATH=$(TOPDIR)/src/app/esp32

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files that the application uses,
# i.e. the list of files that APPLOADFILE floads.  It's for dependency checking.
APPSRCS = $(wildcard $(APPPATH)/*.fth)

# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
CROSS ?= /Volumes/case-sensitive/esp-open-sdk/xtensa-lx106-elf/bin/xtensa-lx106-elf-
TCC=$(CROSS)gcc
TLD=$(CROSS)ld
TOBJDUMP=$(CROSS)objdump
TOBJCOPY=$(CROSS)objcopy

LIBDIRS=-L$(dir $(shell $(TCC) $(TCFLAGS) -print-libgcc-file-name))

VPATH += $(APPPATH)
VPATH += $(SRC)/cforth
VPATH += $(SRC)/lib
INCS += -I$(APPPATH)

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk

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

ttmain.o: vars.h

PLAT_OBJS +=  ttmain.o
PLAT_OBJS +=  tfileio.o

# Object files for the Forth system and application-specific extensions

FORTH_OBJS = tembed.o textend.o

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

include $(SRC)/cforth/embed/targets.mk

ESP_IDF_REPO ?= https://github.com/espressif/esp-idf.git
$(IDF_PATH):
	(cd $(IDF_PARENT_PATH) \
	&& git clone --recursive $(ESP_IDF_REPO) \
	&& python -m pip install --user -r esp-idf/requirements.txt \
	)

XTGCC_ARCHIVE ?= xtensa-esp32-elf-linux64-1.22.0-73-ge28a011-5.2.0.tar.gz
XTGCC_DOWNLOAD ?= https://dl.espressif.com/dl/$(XTGCC_ARCHIVE)
$(XTGCCPATH):
	(cd $(XTGCC_PARENT_PATH) \
	&& wget $(XTGCC_DOWNLOAD) \
	&& tar xvf $(XTGCC_ARCHIVE) \
	&& rm $(XTGCC_ARCHIVE) \
	)

$(PLAT_OBJS): $(IDF_PATH) $(XTGCCPATH)
