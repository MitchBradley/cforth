# Builds a Windows Forth application with serial port tools

TOPDIR=../..

# FTDI dongle support.
# libusb.h and libusb-1.0.a must be copied into this directory
FTDI = y
INCS += -I.
LIBS += -L.
LIBS += -lusb-1.0

# GUI support - message boxes and file open dialog
LIBS += -lcomdlg32 -lcomctl32

CONFIG += -DBITS32 -DT16 -m32

include $(TOPDIR)/src/app/host-serial/targets.mk
