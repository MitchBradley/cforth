# Builds CForth for ESP8266 with bathroom scale

TOPDIR=../..
UPDIR=$(realpath $(TOPDIR)/..)

CONFIG += -DBITS32

CFLAGS += -m32

CC := gcc

# Change these to reflect the locations of external stuff on your system,
# either here or on the command line, e.g. COMPORT=COM27 make download
SDK_PARENT_PATH ?= $(UPDIR)
NODEMCU_PARENT_PATH ?= $(UPDIR)
COMPORT ?= /dev/ttyS4

APPPATH = $(TOPDIR)/src/app/scale

include $(TOPDIR)/src/app/esp8266/targets.mk
