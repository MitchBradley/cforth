# For building a host Forth application with serial port tools

default: app.dic

# Application code directory - i.e. this directory
APPPATH=$(TOPDIR)/src/app/host-serial

# OBJPATH2 is the build directory relative to here
OBJPATH2=../../../$(BUILDDIR)

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files for dependency checking
APPSRCS = $(APPPATH)/app.fth

SRC=$(TOPDIR)/src
include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk
CFLAGS += -m32

ifeq ($(OS),Windows_NT)
  API = win32
else
  API = linux
endif

# EXTENDSRC is the source file for extensions; it is compiled to extend.o
EXTENDSRC = $(APPPATH)/extend-$(API).c

VPATH += $(APPPATH)
INCS += -I$(APPPATH)

app.dic:  forth forth.dic $(APPSRCS)
	(cd $(APPPATH); $(OBJPATH2)/forth $(OBJPATH2)/forth.dic $(APPLOADFILE); mv $@ $(OBJPATH2))
