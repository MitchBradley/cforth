# For building a host Forth application with serial port and OpenGL tools

default: app.dic

CONFIG += -DFLOATING -DMOREFP
CONFIG += -DOPENGL
GCALLS += gcalls.fth
MYOBJS += glops.o

forth.o: glops.h

glops.h: makegcalls

glops.h: $(TOPDIR)/src/cforth/glops.c
	./makegcalls <$<

makegcalls: makegcalls.c
	cc -o $@ $<

EXTRA_CLEAN += makegcalls glops.h gcalls.fth


# Application code directory - i.e. this directory
APPPATH=$(TOPDIR)/src/app/glfw

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files for dependency checking
APPSRCS = $(APPPATH)/app.fth

SRC=$(TOPDIR)/src
include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk

# EXTENDSRC is the source file for extensions; it is compiled to extend.o
EXTENDSRC = $(APPPATH)/extend.c

VPATH += $(APPPATH)
INCS += -I$(APPPATH)

VPATH += $(TOPDIR)/src/lib
INCS += -I$(TOPDIR)/src/lib

HOSTOBJS += $(MYOBJS)

forth: $(MYOBJS)
extend.o: $(EXTENDSRC)

app.dic:  forth forth.dic $(APPSRCS)
	./forth forth.dic ccalls.fth $(GCALLS) $(APPPATH)/$(APPLOADFILE)
