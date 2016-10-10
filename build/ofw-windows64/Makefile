# Builds a Windows Forth application with Open Firmware

all: default

TOPDIR=../..
PREFIX += CBP=$(realpath $(TOPDIR)/src)
PREFIX += BP=$(realpath $(TOPDIR)/../openfirmware)
CC = gcc

CONFIG += -DBITS64 -m64

FTDI = n
INCS += -I.
LIBS += -L.

include $(TOPDIR)/src/app/ofw/targets.mk
