# Builds CForth for OLPC XO-1.75

TOPDIR=../..

CONFIG += -DBITS32 -DT16

ifneq "$(shell getconf LONG_BIT)" "32"
CFLAGS += -m32
endif

include $(TOPDIR)/src/app/arm-xo-1.75/targets.mk
