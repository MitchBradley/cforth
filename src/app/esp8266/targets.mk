# APPPATH is the path to the application code, i.e. this directory
APPPATH=$(TOPDIR)/src/app/esp8266

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files that the application uses,
# i.e. the list of files that APPLOADFILE floads.  It's for dependency checking.
APPSRCS = $(wildcard $(APPPATH)/*.fth)

default: nodemcu-fw

# default: app.o

# Makefile fragment for the final target application

# Include files from the SDK
SDK_DIR:=$(NODEMCU_PATH)/sdk/esp_iot_sdk_v$(SDK_VER)
INCS += -I$(TOP_DIR)/sdk-overrides/include -I$(SDK_DIR)/include

INCS += -I$(NODEMCU_PATH)/app/include
INCS += -I$(NODEMCU_PATH)/app/platform
INCS += -I$(NODEMCU_PATH)/app/spiffs
INCS += -I$(NODEMCU_PATH)/app/libc

SRC=$(TOPDIR)/src

# Target compiler definitions
CROSS ?= /Volumes/case-sensitive/esp-open-sdk/xtensa-lx106-elf/bin/xtensa-lx106-elf-
TCC=$(CROSS)gcc
TLD=$(CROSS)ld
TOBJDUMP=$(CROSS)objdump
TOBJCOPY=$(CROSS)objcopy

LIBDIRS=-L$(dir $(shell $(TCC) $(TCFLAGS) -print-libgcc-file-name))

VPATH += $(SRC)/lib
VPATH += $(SRC)/app/esp8266
INCS += -I$(SRC)/app/esp8266

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

tconsoleio.o: vars.h

PLAT_OBJS +=  tconsoleio.o
PLAT_OBJS +=  ttmain.o
PLAT_OBJS +=  tlwip.o
PLAT_OBJS +=  tfileio.o

# Object files for the Forth system and application-specific extensions

FORTH_OBJS = tembed.o textend.o

# Recipe for linking the final image

DICTIONARY=ROM
DICTSIZE=0x4000

app.o: date.o
	@echo Linking $@ ... 
	@$(TLD)  -o $@  -r  $(PLAT_OBJS) $(FORTH_OBJS) date.o

# This rule builds a date stamp object that you can include in the image
# if you wish.

date.o: $(PLAT_OBJS) $(FORTH_OBJS)
	@(echo "`git rev-parse --verify --short HEAD``if git diff-index --exit-code --name-only HEAD >/dev/null; then echo '-dirty'; fi`" || echo UNKNOWN) >version
	@echo 'const char version[] = "'`cat version`'";' >date.c
	@echo 'const char build_date[] = "'`date --utc +%F\ %R`'";' >>date.c
	@cat date.c
	@echo TCC $@
	@$(TCC) -c date.c -o $@

EXTRA_CLEAN += *.elf *.dump *.nm *.img date.c $(FORTH_OBJS) $(PLAT_OBJS)

include $(SRC)/cforth/embed/targets.mk

.PHONY: nodemcu-fw

nodemcu-fw: app.o
	(cd $(NODEMCU_PATH) && sh makeit)

download: nodemcu-fw
	/c/Program\ Files/AutoHotKey/AutoHotKey ~/Desktop/disconn_teraterm.ahk $(COMPORT)
	(cd $(NODEMCU_PATH) && sh loadit COM36)
	/c/Program\ Files/AutoHotKey/AutoHotKey ~/Desktop/connect_teraterm.ahk $(COMPORT)
