# These are the build instructions for common file types
# The actual build is done in lower-level directories.  Makefiles in those
# lower level directories include this file and add adaptations
# for specific environments

TLFLAGS += -static
TCFLAGS += -O
TCFLAGS += -g
# TCFLAGS = -O2 -fno-optimize-sibling-calls

# VPATH += 

# INCS += 

all: default

%.o: %.S
	$(TCC) $(INCS) $(DEFS) $(TSFLAGS) -c $< -o $@

%.o: %.s
	$(TCC) $(INCS) $(DEFS) -c $< -o $@

%.o: %.c
	$(TCC) $(INCS) $(DEFS) $(TCFLAGS) $(TCPPFLAGS) -c $< -o $@

# clean:
#	rm -f *.o
#	rm -f a.out
#	rm -f $(EXTRA_CLEAN)
#	for dir in $(SUBDIRS); do \
#	  $(MAKE) -C $$dir clean; \
#	done
