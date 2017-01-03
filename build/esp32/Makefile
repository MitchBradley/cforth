# Builds CForth for ESP8266

default: forth.elf

TOPDIR=../..

# CONFIG += -DBITS32 -DT16
CONFIG += -DBITS32

CFLAGS += -m32

CC := gcc

# Change these to reflect the locations of external stuff on your system,
# either here or on the command line, e.g. COMPORT=COM27 make download
XTGCCPATH ?= /c/msys32/opt/xtensa-esp32-elf/bin/
CROSS ?= $(XTGCCPATH)xtensa-esp32-elf-

# ESP32 SDK
IDF_PATH ?= $(TOPDIR)/../esp-idf
IDF_TEMPLATE_PATH ?= $(TOPDIR)/../esp-idf-template

COMPORT ?= COM27

include $(TOPDIR)/src/app/esp32/targets.mk

forth.elf: app.o
	@IDF_PATH=$(IDF_PATH) make --no-print-directory -C sdk_build

flash: app.o
	@IDF_PATH=$(IDF_PATH) make --no-print-directory -C sdk_build flash

clean::
	@rm -rf sdk_build/build
