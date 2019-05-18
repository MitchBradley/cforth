# APPPATH is the path to the application code, i.e. this directory
APPPATH=$(TOPDIR)/src/app/esp32

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files that the application uses,
# i.e. the list of files that APPLOADFILE floads.  It's for dependency checking.
APPSRCS = $(wildcard $(APPPATH)/*.fth)

# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

ESP_IDF_REPO = https://github.com/espressif/esp-idf.git
ESP_IDF_VERSION ?= v3.1.1
ESP_IDF_ARCHIVE = esp-idf-$(ESP_IDF_VERSION).zip
ESP_IDF_URL = https://github.com/espressif/esp-idf/releases/download/$(ESP_IDF_VERSION)/$(ESP_IDF_ARCHIVE)

# This file within esp-idf lists the required toolchain versions
TOOLVERSIONS = $(IDF_PATH)/tools/toolchain_versions.mk

EXTRACT_TOOLVERSIONS := grep SUPPORTED_TOOLCHAIN $(IDF_PATH)/make/project.mk \
  | grep := \
  | sed -e s/SUPPORTED/CURRENT/ -e s/VERSIONS/VERSION/ -e s/crosstool-ng-// -e s/DESC/DESC_SHORT/ >$(TOOLVERSIONS)

$(TOOLVERSIONS):
	@echo Getting esp-idf
	(cd $(ESP_IDF_PARENT_PATH) \
	&& wget $(ESP_IDF_URL) \
	&& echo Unzipping esp-idf \
	&& unzip -q $(ESP_IDF_ARCHIVE) \
	&& rm $(ESP_IDF_ARCHIVE) \
	&& python -m pip install --user -r $(IDF_PATH)/requirements.txt \
	&& if [ ! -e $(TOOLVERSIONS) ]; then $(EXTRACT_TOOLVERSIONS); fi \
	)

.PHONY: tv
tv: $(TOOLVERSIONS)

# If the TOOLVERSIONS file is not present, make will trigger the rule to
# make it and then restart so that its information can then be used to
# get the right toolchain
-include $(TOOLVERSIONS)

XTGCC_VERSION = $(CURRENT_TOOLCHAIN_COMMIT_DESC_SHORT)-$(CURRENT_TOOLCHAIN_GCC_VERSION)

XTGCC_ARCHIVE = xtensa-esp32-elf-linux64-$(XTGCC_VERSION).tar.gz
XTGCC_DOWNLOAD = https://dl.espressif.com/dl/$(XTGCC_ARCHIVE)

# Inside XTGCC_PARENT_PATH we have subdirectories for different
# toolchain versions so it is easy to tell if we have the right
# one, and if not, to automatically fetch it
# Example subdirectory name: toolchain-1.22.0-80-g6c4433a-5.2.0/
XTGCC_CONTAINER_PATH ?= $(XTGCC_PARENT_PATH)/toolchain-$(XTGCC_VERSION)

XTGCCPATH ?= $(XTGCC_CONTAINER_PATH)/xtensa-esp32-elf/bin
$(info path $(XTGCCPATH))

$(XTGCCPATH):
	(mkdir -p $(XTGCC_CONTAINER_PATH) \
	&& cd $(XTGCC_CONTAINER_PATH) \
	&& wget $(XTGCC_DOWNLOAD) \
	&& tar xvf $(XTGCC_ARCHIVE) \
	&& rm $(XTGCC_ARCHIVE) \
	)

# Target compiler definitions
CROSS ?= $(XTGCCPATH)/xtensa-esp32-elf-
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


$(PLAT_OBJS): $(XTGCCPATH)
