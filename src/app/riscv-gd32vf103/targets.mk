# APPPATH is the path to the application code, i.e. this directory
APPPATH=$(TOPDIR)/src/app/$(MYNAME)

# APPLOADFILE is the top-level "Forth load file" for the application code.
APPLOADFILE = app.fth

# APPSRCS is a list of Forth source files that the application uses,
# i.e. the list of files that APPLOADFILE floads.  It's for dependency checking.
APPSRCS = $(wildcard $(APPPATH)/*.fth)

include $(TOPDIR)/src/platform/$(MYNAME)/targets.mk
