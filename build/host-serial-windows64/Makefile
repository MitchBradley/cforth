# Builds a Windows Forth application with serial port tools

all: forth

TOPDIR=../..
CC = gcc

# FTDI dongle support.
# libusb.h and libusb-1.0.a must be copied into this directory
# Get the libusb 1.0 Windows binary snapshot from
#   https://sourceforge.net/projects/libusb/files
# Unpack it, then copy into this directory:
#   include/libusb.h
#   MinGW64/static/libusb-1.0.a

FTDI = y
FTDI = n
INCS += -I.
LIBS += -L.
LIBS += -lusb-1.0

# GUI support - message boxes and file open dialog
LIBS += -lcomdlg32 -lcomctl32

CONFIG += -DBITS64 -m64
CONFIG += -DFLOATING -DMOREFP

include $(TOPDIR)/src/app/host-serial/targets.mk
