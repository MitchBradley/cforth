# Builds a Linux host Forth application with serial port tools

TOPDIR=../..

CONFIG += -DBITS64

FTDI = y
INCS += -I/usr/include/libusb-1.0
LIBS += -lusb-1.0

include $(TOPDIR)/src/app/host-serial/targets.mk
