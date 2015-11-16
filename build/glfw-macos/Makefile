# Builds a MacOS host Forth application with OpenGL under GLFW

all: default

TOPDIR=../..

CONFIG += -DMAXDICT=0x800000
CONFIG += -DBITS64
CONFIG += -DFLOATING -DMOREFP

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

include $(TOPDIR)/src/app/glfw/targets.mk
