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
PLAT_OBJS +=  tesp_spi.o

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
PREFIX += BP=$(realpath /c/Users/wmb/Documents/svn/openfirmware)

include $(SRC)/cforth/embed/targets.mk

.PHONY: nodemcu-fw

NODEMCU_REPO ?= https://github.com/nodemcu/nodemcu-firmware.git
NODEMCU_COMMIT ?= 7b83bbb
$(NODEMCU_PATH):
	(cd $(NODEMCU_PARENT_PATH) \
	&& git clone $(NODEMCU_REPO) \
	&& cd $(abspath $(NODEMCU_PATH)) \
	&& git branch cforth $(NODEMCU_COMMIT) \
	&& git checkout cforth \
	&& git apply $(abspath $(APPPATH))/*.patch \
	)

$(NODEMCU_PATH)/sdk: $(NODEMCU_PATH)
	cd $(NODEMCU_PATH) && make --no-print-directory sdk_patched

$(PLAT_OBJS): $(NODEMCU_PATH)/sdk

nodemcu-fw: app.o
	(cd $(NODEMCU_PATH) && PATH=${PATH}:$(XTGCCPATH) make --no-print-directory)

LOADCMD=tools/esptool.py --port $(COMPORT) -b 115200 write_flash -fm=dio -fs=32m 0x00000 bin/0x00000.bin 0x10000 bin/0x10000.bin

download: nodemcu-fw
	(cd $(NODEMCU_PATH) && $(LOADCMD))


# wmbdownload automatically disconnects the terminal emulator while downloading
# It is used on Windows host systems with TeraTerm as the terminal emulator.
# It further requires the "AutoHotkey" program, which is a scripting language
# that is good at sending events to Windows programs.

SCRIPTPATH=/c/Users/wmb/Desktop/
AHKPATH=/c/Program\ Files/AutoHotKey/
wmbdownload: nodemcu-fw
	$(AHKPATH)AutoHotKey $(SCRIPTPATH)disconn_teraterm.ahk $(COMPORT)
	(cd $(NODEMCU_PATH) && $(LOADCMD))
	$(AHKPATH)AutoHotKey $(SCRIPTPATH)connect_teraterm.ahk $(COMPORT)
