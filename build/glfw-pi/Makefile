# Builds a Linux host Forth application with OpenGL

all: default

TOPDIR=../..

CONFIG += -DBITS32

CONFIG += -DFLOATING -DMOREFP
LIBS += -lm

CONFIG += -DOPENGL
INCS += $(shell pkg-config --cflags glfw3 glu)
LIBS += $(shell pkg-config --static --libs glfw3 )
LIBS += $(shell pkg-config --libs glu)

FTDI = n
# INCS += $(shell pkg-config --cflags libusb-1.0)
# LIBS += $(shell pkg-config --libs libusb-1.0)

MYOBJS += glops.o

forth.o: glops.h

makegcalls: makegcalls.c
	cc -o $@ $<

obj_to_gl: $(TOPDIR)/src/app/glfw/obj_to_gl.c
	cc -o $@ $<

glfaces.bin: obj_to_gl


# test.obj is a Wavefront .obj file to render
# We preprocess it into a set of binary files for fast loading
glfaces.bin: ~/Downloads/test.obj
	./obj_to_gl <$<

glops.h: makegcalls

glops.h: $(TOPDIR)/src/cforth/glops.c
	./makegcalls <$<

include $(TOPDIR)/src/app/glfw/targets.mk
