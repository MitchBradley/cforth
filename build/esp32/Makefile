# Builds CForth for ESP8266

default: forth.elf

TOPDIR=../..

CONFIG += -DBITS32
CONFIG += -DFLOATING -DMORE_FP

CFLAGS += -m32

CC := gcc

# Change these to reflect the locations of external stuff on your system,
# either here or on the command line
XTGCCPATH ?= /c/msys32/opt/xtensa-esp32-elf/bin/
CROSS ?= $(XTGCCPATH)xtensa-esp32-elf-

# ESP32 SDK
IDF_PATH ?= $(TOPDIR)/../esp-idf

COMPORT ?= COM27

include $(TOPDIR)/src/app/esp32/targets.mk

forth.elf: app.o
	@IDF_PATH=$(IDF_PATH) make --no-print-directory -C sdk_build

flash: app.o
	@IDF_PATH=$(IDF_PATH) make --no-print-directory -C sdk_build flash

clean::
	@rm -rf sdk_build/build
