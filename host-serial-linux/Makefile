# Builds a Linux host Forth application with serial port tools

TOPDIR=../..

CONFIG += -DBITS32 -DT16

ifneq "$(findstring 86,$(shell uname -m))" ""
CONFIG += -m32
endif

FTDI = y
INCS += -I/usr/include/libusb-1.0
LIBS += -lusb-1.0

include $(TOPDIR)/src/app/host-serial/targets.mk
