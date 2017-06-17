# Builds a Forth interpreter to embed into a Linux kernel

default: app.o

TOPDIR=../..

CONFIG += -DBITS64

include $(TOPDIR)/src/app/embed-linux/targets.mk

test: test_main.o app.o
	$(CC) test_main.o app.o -o $@

EXTRA_CLEAN += test
