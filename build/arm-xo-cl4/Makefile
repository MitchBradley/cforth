# Builds CForth for OLPC XO-4

TOPDIR=../..

CONFIG += -DBITS32 -DT16

ifneq "$(shell getconf LONG_BIT)" "32"
CFLAGS += -m32
endif

include $(TOPDIR)/src/app/arm-xo-cl4/targets.mk
