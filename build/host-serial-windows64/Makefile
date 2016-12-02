# Builds a Windows Forth application with serial port tools

# Change the below to 'y' or pass in on the command line to enable support

# FTDI=y includes code to access FTDI serial chips using FTDI's low-level
# API, which lets you do special things like manage all their GPIO pins.
# The default FTDI=n omits that code, but without it you can still use FTDI
# devices as serial ports, using normal (not FTDI-specific) serial port
# access APIs.

# OPENGL=y includes support for OpenGL, so you can draw 3D graphics
# in a separate window.  It's tricky to use.

FTDI ?= n
OPENGL ?= n

all: default

TOPDIR=../..
CC = gcc

CONFIG += -DBITS64 -m64
CONFIG += -DFLOATING -DMOREFP

ifeq ($(FTDI),y)
# FTDI dongle support.
# libusb.h and libusb-1.0.a must be copied into this directory
# Get the libusb 1.0 Windows binary snapshot from
#   https://sourceforge.net/projects/libusb/files
# Unpack it, then copy into this directory:
#   include/libusb.h
#   MinGW64/static/libusb-1.0.a

INCS += -I.
LIBS += -L.
LIBS += -lusb-1.0
endif

# GUI support - message boxes and file open dialog
LIBS += -lcomdlg32 -lcomctl32

ifeq ($(OPENGL),y)
# OpenGL Dependencies:
# You need to copy the following into this directory:
#  GLEW - From http://glew.sourceforge.net/index.html, in the
#    Downloads section, get Binaries  Windows 32-bit and 64-bit
#    and extract the zip into e.g. ./glew-1.13.0/
#  GLFW - From http:/www.glfw.org/download.html get the
#    64-bit Windows binaries zip file.  Extract include/GLFW/
#    as ./GLFW/  and extract lib-mingw/ as ./GLFW64/

INCS += -I./glew-1.13.0/include

CONFIG += -DMAXDICT=0x800000
CONFIG += -DOPENGL
CONFIG += -DUSE_GLEW -DGLEW_STATIC

GCALLS += gcalls.fth

LIBS += -L./GLFW64

LIBS += -L./glew-1.13.0/lib/Release/x64

LIBS += -lglew32s
LIBS += -lglfw3
LIBS += -lopengl32
LIBS += -lglu32

LIBS += -lgdi32

MYOBJS += glops.o

forth.o: glops.h

makegcalls: makegcalls.c
	$(CC) -o $@ $<

glops.h: makegcalls

glops.h: $(TOPDIR)/src/cforth/glops.c
	./makegcalls <$<

EXTRA_CLEAN += makegcalls glops.h gcalls.fth
endif

include $(TOPDIR)/src/app/host-serial/targets.mk
