# APPPATH is the path to the application code, i.e. this directory
APPPATH=$(TOPDIR)/src/app/arm-xo-1.75

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app175.fth

# APPSRCS is a list of Forth source files that the application uses,
# i.e. the list of files that APPLOADFILE floads.  It's for dependency checking.
APPSRCS = $(wildcard $(APPPATH)/*.fth)

DEFS += -DCL2

default: cforth.img shim.img

include $(TOPDIR)/src/platform/arm-xo-1.75/targets.mk
