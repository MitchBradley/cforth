# For building a host Forth application with serial and Bluetooth tools

default: app.dic

# Application code directory - i.e. this directory
APPPATH=$(TOPDIR)/src/app/bluez

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files for dependency checking
APPSRCS  = $(APPPATH)/app.fth
APPSRCS += $(APPPATH)/bluetooth.fth

SRC=$(TOPDIR)/src
include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk

# EXTENDSRC is the source file for extensions; it is compiled to extend.o
EXTENDSRC = $(APPPATH)/extend.c

VPATH += $(APPPATH)
INCS += -I$(APPPATH)

VPATH += $(TOPDIR)/src/lib
INCS += -I$(TOPDIR)/src/lib

VPATH += $(TOPDIR)/src/app/host-serial
INCS += -I$(TOPDIR)/src/app/host-serial

VPATH += $(TOPDIR)/src/app/host-serial/libftdi
INCS += -I$(TOPDIR)/src/app/host-serial/libftdi

MYOBJS  = sha256.o
MYOBJS += sfc-client.o

ifeq ($(FTDI),y)
	FTDIDIR = $(APPPATH)/libftdi
	VPATH += $(FTDIDIR)
	INCS += -I$(FTDIDIR)
	CFLAGS += -DUSE_FTDI
	LIBS += -lusb-1.0
	MYOBJS += ftdi.o
endif

HOSTOBJS += $(MYOBJS)

forth: $(MYOBJS)
extend.o: $(EXTENDSRC)

app.dic:  forth forth.dic $(APPSRCS)
	echo $(HOSTOBJS)
	(cd $(APPPATH); $(BUILDDIR)/forth $(BUILDDIR)/forth.dic $(BUILDDIR)/ccalls.fth $(APPLOADFILE); mv $@ $(BUILDDIR))
