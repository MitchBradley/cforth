# Builds a Windows Forth application with serial port tools

all: default

TOPDIR=../..
CC = gcc

CONFIG += -DBITS64 -m64
CONFIG += -DFLOATING -DMOREFP

# FTDI dongle support.
# libusb.h and libusb-1.0.a must be copied into this directory
# Get the libusb 1.0 Windows binary snapshot from
#   https://sourceforge.net/projects/libusb/files
# Unpack it, then copy into this directory:
#   include/libusb.h
#   MinGW64/static/libusb-1.0.a

FTDI = y
INCS += -I.
LIBS += -L.
LIBS += -lusb-1.0

# GUI support - message boxes and file open dialog
LIBS += -lcomdlg32 -lcomctl32

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

include $(TOPDIR)/src/app/host-serial/targets.mk
