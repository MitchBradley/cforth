# Builds a Linux host Forth application with serial port tools

all: default

TOPDIR=../..

CONFIG += -DBITS64
CONFIG += -DFLOATING -DMOREFP

LIBS += -lm

# OpenGL stuff
# You may need   sudo apt-get install libglfw3-dev
CONFIG += -DMAXDICT=0x800000
CONFIG += -DOPENGL
GCALLS += gcalls.fth

INCS += $(shell pkg-config --cflags glfw3 glu)
LIBS += $(shell pkg-config --static --libs glfw3 )
LIBS += $(shell pkg-config --libs glu)

FTDI = y
INCS += $(shell pkg-config --cflags libusb-1.0)
LIBS += $(shell pkg-config --libs libusb-1.0)

MYOBJS += glops.o

forth.o: glops.h

makegcalls: makegcalls.c
	$(CC) -o $@ $<

glops.h: makegcalls

glops.h: $(TOPDIR)/src/cforth/glops.c
	./makegcalls <$<

EXTRA_CLEAN += makegcalls glops.h gcalls.fth

include $(TOPDIR)/src/app/host-serial/targets.mk
