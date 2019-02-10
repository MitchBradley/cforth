# Builds a Linux host Forth application with OpenGL

all: default

TOPDIR=../..

CONFIG += -DBITS64

LIBS += -lm

CONFIG += -DOPENGL
INCS += $(shell pkg-config --cflags glfw3 glu)
LIBS += $(shell pkg-config --static --libs glfw3 )
LIBS += $(shell pkg-config --libs glu)

# The inclusion of the FTDI libraries was for an old
# project that abused an FTDI dongle as a GPIO port
#FTDI = y
#INCS += $(shell pkg-config --cflags libusb-1.0)
#LIBS += $(shell pkg-config --libs libusb-1.0)

obj_to_gl: $(TOPDIR)/src/app/glfw/obj_to_gl.c
	$(CC) -o $@ $< -lm

glfaces.bin: obj_to_gl


# test.obj is a Wavefront .obj file to render
# We preprocess it into a set of binary files for fast loading
glfaces.bin: ~/Downloads/test.obj
	./obj_to_gl <$<

include $(TOPDIR)/src/app/glfw/targets.mk
