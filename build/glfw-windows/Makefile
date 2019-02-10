# Builds a Windows Forth application with serial port tools

# Compile with mingw-w64 using the x86_64 (64-bit) toolchain

all: default

TOPDIR=../..
CC = gcc

# FTDI dongle support.
# libusb.h and libusb-1.0.a must be copied into this directory
# Get the libusb 1.0 Windows binary snapshot from
#   https://sourceforge.net/projects/libusb/files
# Unpack it, then copy into this directory:
#   include/libusb.h
#   MinGW64/static/libusb-1.0.a

# The inclusion of the FTDI libraries was for an old
# project that abused an FTDI dongle as a GPIO port
# FTDI = y
# INCS += -I.
# LIBS += -L.
# LIBS += -lusb-1.0

INCS += -I./glew-1.13.0/include

# GUI support - message boxes and file open dialog
LIBS += -lcomdlg32 -lcomctl32

# Dependencies:
# You need to copy the following into this directory:
#  GLEW - From http://glew.sourceforge.net/index.html, in the
#    Downloads section, get Binaries  Windows 32-bit and 64-bit
#    and extract the zip into e.g. ./glew-1.13.0/
#  GLFW - From http:/www.glfw.org/download.html get the
#    64-bit Windows binaries zip file.  Extract include/GLFW/
#    as ./GLFW/  and extract lib-mingw/ as ./GLFW64/

LIBS += -L./GLFW64

LIBS += -L./glew-1.13.0/lib/Release/x64

LIBS += -lglew32s
LIBS += -lglfw3
LIBS += -lopengl32
LIBS += -lglu32

LIBS += -lgdi32

CONFIG += -DBITS64 -m64
CONFIG += -DUSE_GLEW -DGLEW_STATIC

obj_to_gl: $(TOPDIR)/src/app/glfw/obj_to_gl.c
	$(CC) -o $@ $< -lm

glfaces.bin: obj_to_gl


# test.obj is a Wavefront .obj file to render
# We preprocess it into a set of binary files for fast loading
glfaces.bin: ~/Downloads/test.obj
	./obj_to_gl <$<

include $(TOPDIR)/src/app/glfw/targets.mk
