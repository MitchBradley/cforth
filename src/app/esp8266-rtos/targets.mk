CONFIG += -DBITS32
CONFIG += -DFLOATING -DMORE_FP
LIBS += -lm

CFLAGS += -m32

CC := gcc

TCPATH=$(TOPDIR)/src/app/$(APPNAME)

include $(TCPATH)/sdk.mk

# APPPATH is the path to the application code, i.e. this directory
APPPATH ?= $(TOPDIR)/src/app/$(APPNAME)

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE ?= app.fth

ESP32PATH=$(TOPDIR)/src/app/esp32

# APPSRCS is a list of Forth source files that the application uses,
# i.e. the list of files that APPLOADFILE floads.  It's for dependency checking.
APPSRCS += $(wildcard $(APPPATH)/*.fth)
APPSRCS += $(ESP32PATH)/wifi.fth
APPSRCS += $(ESP32PATH)/server.fth

# default: 0x00000.bin 0x10000.bin

# default: app.o

# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
CROSS ?= $(XTGCCPATH)/xtensa-lx106-elf-

TCC=$(CROSS)gcc
TLD=$(CROSS)ld
TOBJDUMP=$(CROSS)objdump
TOBJCOPY=$(CROSS)objcopy

LIBDIRS=-L$(dir $(shell $(TCC) $(TCFLAGS) -print-libgcc-file-name))

VPATH += $(TCPATH)
INCS += -I$(TCPATH)

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk

OPTIMIZE = -O2

TCFLAGS += \
  -g \
  -fno-inline-functions \
  -nostdlib \
  -mlongcalls \
  -DXTENSA

DUMPFLAGS = --disassemble -z -x -s

# Platform-specific object files for low-level startup and platform I/O

ttmain.o: vars.h $(XTGCCPATH)

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

# The rest is the interface to the SDK build system
PROJECT_PATH := $(abspath $(TCPATH)/sdk_src)

IDF_PATHS:=IDF_PATH="$(IDF_PATH)" CFORTH_BUILD_PATH="$(CFORTH_BUILD_PATH)" PATH="$(XTGCCPATH):$(PATH)" PROJECT_PATH="$(PROJECT_PATH)"

# If COMPORT is in the environment, for example
#   COMPORT=COM36 make flash
# then override the CONFIG_ESPTOOLPY_PORT setting in the SDK build scripts,
# otherwise use that setting.
COMPORT ?=
ifneq ($(COMPORT),)
	ESPPORT_OVERRIDE = ESPPORT=$(COMPORT)
endif

MAKECMD = $(IDF_PATHS) $(ESPPORT_OVERRIDE) make --no-print-directory -C $(PROJECT_PATH)

$(APPELF): app.o
	@$(MAKECMD)

flash: $(APPELF)
	@$(MAKECMD) $@

# Passthroughs for some utility commands in the SDK build system
monitor:
	@$(MAKECMD) $@

erase_flash:
	@$(MAKECMD) $@

print_flash_cmd:
	@$(MAKECMD) $@

partition_table:
	@$(MAKECMD) $@

simple_monitor:
	@$(MAKECMD) $@

size:
	@$(MAKECMD) $@

size-components:
	@$(MAKECMD) $@

defconfig:
	@$(MAKECMD) $@

menuconfig:
	@$(MAKECMD) $@

bootloader-flash:
	@$(MAKECMD) $@

app-flash:
	@$(MAKECMD) $@

sdk-clean:
	@$(MAKECMD) clean
