# APPPATH is the path to the application code, i.e. this directory
APPPATH=$(TOPDIR)/src/app/arm-ariel

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files that your application uses,
# i.e. the list of files that app.fth floads.  It's for dependency checking.
APPSRCS = $(wildcard $(APPPATH)/*.fth)

DEFS += -DARIEL

default: cforth.img

include $(TOPDIR)/src/platform/arm-ariel/targets.mk
