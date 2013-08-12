# For building a host Forth application with serial port tools

default: app.dic

# APPLOADFILEE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files for dependency checking
APPSRCS = $(APPPATH)/app.fth

app.dic:  forth forth.dic $(APPSRCS)
	(cd $(APPPATH); $(OBJPATH2)/forth $(OBJPATH2)/forth.dic $(APPLOADFILE); mv app.dic $(OBJPATH2))

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

# OBJPATH is the build directory relative to $(SRC)/cforth
OBJPATH=../../$(BUILDDIR)

# OBJPATH2 is the build directory relative to APPPATH
OBJPATH2=../../../$(BUILDDIR)

VPATH += $(APPPATH)
INCS += -I$(APPPATH)
