# Builds CForth for ESP8266

TOPDIR=../..

# CONFIG += -DBITS32 -DT16
CONFIG += -DBITS32

CFLAGS += -m32

CC := gcc

# Change these to reflect the locations of external stuff on your system,
# either here or on the command line, e.g. COMPORT=COM27 make download
XTGCCPATH ?= /c/xtensa-lx106-elf/bin/
CROSS ?= $(XTGCCPATH)xtensa-lx106-elf-
NODEMCU_PARENT_PATH ?= $(TOPDIR)/../
NODEMCU_PATH ?= $(NODEMCU_PARENT_PATH)nodemcu-firmware
SDK_VER:=1.5.4.1
COMPORT ?= COM36

include $(TOPDIR)/src/app/esp8266/targets.mk
