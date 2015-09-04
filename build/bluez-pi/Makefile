# Builds a Linux host Forth application with serial port tools and Bluetooth tools

TOPDIR=../..

CONFIG += -DBITS32 -DT16

FTDI = y
INCS += -I/usr/include/libusb-1.0
LIBS += -lusb-1.0

BLUEZ_DIR := $(TOPDIR)/src/app/bluez

include $(BLUEZ_DIR)/targets.mk
