# Builds CForth for Ariel (Dell Wyse 3020)

TOPDIR=../..

CONFIG += -DBITS32 -DT16

ifneq "$(shell getconf LONG_BIT)" "32"
CFLAGS += -m32
endif

include $(TOPDIR)/src/app/arm-ariel/targets.mk
