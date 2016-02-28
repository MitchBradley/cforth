# Builds CForth for ESP8266

TOPDIR=../..

# CONFIG += -DBITS32 -DT16
CONFIG += -DBITS32

CFLAGS += -m32

CC := gcc

# GCCPATH := /Volumes/case-sensitive/esp-open-sdk/
GCCPATH := C:/
CROSS ?= $(GCCPATH)xtensa-lx106-elf/bin/xtensa-lx106-elf-
#BASE = /Users/wmb/
BASE = /c/Users/wmb/Documents/Archive/from-MacBookPro/

NODEMCU ?= $(BASE)github/nodemcu-firmware
INCS += -I$(NODEMCU)/app/include
INCS += -I$(NODEMCU)/app/platform
INCS += -I$(NODEMCU)/app/spiffs
INCS += -I$(NODEMCU)/app/libc

ESPSDK ?= $(NODEMCU)/sdk
INCS += -I$(ESPSDK)/esp_iot_sdk_v1.4.0/include

include $(TOPDIR)/src/app/esp8266/targets.mk
