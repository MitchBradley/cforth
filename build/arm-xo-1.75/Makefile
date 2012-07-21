# This is a template build directory for an embedded Forth application
# Copy this directory to a new one and edit this file appropriately

# There are several things to configure, including the target CPU
# instruction set, the location of system (platform) dependent code,
# and the location of application-specific code.


# The name of the final output file. The rule for making this is in
# $(PLATPATH)/targets.mk

NAME=cforth
EXT=img


# TOPDIR is relative to this directory; don't change this unless
# you put your build subdirectory at a different tree level
TOPDIR=../..
SRC=$(TOPDIR)/src

# BUILDDIR is relative to TOPDIR; it's the name of this directory
# !!CHANGE!!
BUILDDIR=build/arm-xo-1.75

# OBJPATH is relative to $(SRC)/cforth/embed; don't change
OBJPATH=../../../$(BUILDDIR)

# APPPATH is where your application code lives.
APPPATH=$(TOPDIR)/src/app/arm-xo-1.75

# APPLOADFILE is the top-level "Forth load file" for your application code.
# It's okay to leave its name as "app.fth" and just use APPPATH to set the
# location of your application code.
APPLOADFILE = app175.fth

# APPSRCS is a list of Forth source files that your application uses,
# i.e. the list of files that app.fth floads.  It's for dependency checking.
APPSRCS = $(wildcard $(APPPATH)/*.fth)

# OBJPATH2 is relative to APPPATH; don't change unless your APPPATH
# is at a different tree level
OBJPATH2=../../../$(BUILDDIR)


# PLATPATH is where the platform-specific code lives.  You might need to
# make a new platform directory and populate it with drivers and startup
# code for your system.
# !!CHANGE!!
PLATPATH = $(SRC)/platform/arm-xo-1.75

VPATH += $(PLATPATH)
INCS += -I$(PLATPATH)
DEFS += -DCL2

# Set this to ROM or RAM depending on where you want the base Forth
# dictionary to live.  RAM is nice if you have enough, so you can
# patch the dictionary.
DICTIONARY=RAM

DICTSIZE=0xe000

# Target compiler definitions.  Change this to a different cpu/* directory
# if you are cross-compiling
# !!CHANGE!!
ifneq "$(findstring arm,$(shell uname -m))" ""
include $(SRC)/cpu/host/compiler.mk
else
include $(SRC)/cpu/arm/compiler.mk
endif

include $(SRC)/common.mk                     # Probably won't need to change this
include $(SRC)/cforth/embed/targets.mk       # Probably won't need to change this
include $(PLATPATH)/targets.mk

default: $(NAME).$(EXT) shim.img
