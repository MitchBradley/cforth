# Builds a Windows Forth application with Open Firmware

all: default

TOPDIR=../..
PREFIX += CBP=$(realpath $(TOPDIR)/src)
PREFIX += BP=$(realpath $(TOPDIR)/../openfirmware)
CC = gcc

CONFIG += -DBITS32 -m32

include $(TOPDIR)/src/app/ofw/targets.mk
