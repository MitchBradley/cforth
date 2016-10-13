# Builds CForth for ESP8266

TOPDIR=../..

# CONFIG += -DBITS32 -DT16
CONFIG += -DBITS32

CFLAGS += -m32

CC := gcc

# Change these to reflect the locations of external stuff on your system
GCCPATH := C:/
CROSS ?= $(GCCPATH)xtensa-lx106-elf/bin/xtensa-lx106-elf-
NODEMCU_PATH = $(TOPDIR)/../nodemcu-firmware
SDK_VER:=1.5.4.1
COMPORT ?= COM36

include $(TOPDIR)/src/app/esp8266/targets.mk
