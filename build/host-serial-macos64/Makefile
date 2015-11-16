# Builds a MacOS host Forth application with serial port tools

all: default

TOPDIR=../..

CONFIG += -DBITS64
CONFIG += -DFLOATING -DMOREFP

# To get libusb-1.0 on MacOS, download and upack a source tarball from
# www.libusb.org, then  ./configure && make && sudo make install
# Or, if you have the "Homebrew" package manager, just "brew install libusb"

FTDI = y

LIBUSB_INSTALLED := $(shell pkg-config --modversion libusb-1.0 2>/dev/null)
ifeq ($(LIBUSB_INSTALLED),)
  LIBUSB_INSTALLED := $(shell brew install libusb 2>/dev/null || echo NOBREW)
  ifeq ($(LIBUSB_INSTALLED),NOBREW)
    $(error Install either libusb-1.0 or the Homebrew package manager)
  endif
endif

# Static link so the user does not have to install libusb
INCS += $(shell pkg-config --cflags libusb-1.0)
LIBS += $(shell pkg-config --static --libs libusb-1.0)


# Big dictionary for parsing .obj files containing large graphical images
CONFIG += -DMAXDICT=0x800000

CONFIG += -DOPENGL

GLFW_INSTALLED := $(shell pkg-config --modversion glfw3 2>/dev/null)
ifeq ($(GLFW_INSTALLED),)
  GLFW_INSTALLED := $(shell brew install --build-bottle --without-shared-library glfw3 2>/dev/null || echo NOBREW)
  ifeq ($(LIBUSB_INSTALLED),NOBREW)
    $(error Install either glfw3 or the Homebrew package manager)
  endif
endif

# Static link so the user does not have to install glfw3
INCS += $(shell pkg-config --cflags glfw3)
LIBS += $(shell pkg-config --static --libs glfw3)


GCALLS += gcalls.fth

MYOBJS += glops.o

forth.o: glops.h

makegcalls: makegcalls.c
	$(CC) -o $@ $<

glops.h: makegcalls

glops.h: $(TOPDIR)/src/cforth/glops.c
	./makegcalls <$<

EXTRA_CLEAN += makegcalls glops.h gcalls.fth

include $(TOPDIR)/src/app/host-serial/targets.mk
