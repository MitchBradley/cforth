# These are the build instructions for common file types
# The actual build is done in lower-level directories.  Makefiles in those
# lower level directories include this file and add adaptations
# for specific environments

TLFLAGS += -static
TCFLAGS += -O
TCFLAGS += -g
TCFLAGS += -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0
# TCFLAGS = -O2 -fno-optimize-sibling-calls

# VPATH += 

# INCS += 

BUILDDIR = $(shell pwd)

all: default

t%.o: %.S
	@echo TAS $<
	@$(TCC) $(INCS) $(DEFS) $(TSFLAGS) -c $< -o $@

t%.o: %.s
	@echo TAS $<
	@$(TCC) $(INCS) $(DEFS) -c $< -o $@

t%.o: %.c
	@echo TCC $<
	@$(TCC) $(INCS) $(DEFS) $(TCFLAGS) $(TCPPFLAGS) -c $< -o $@

%.o: %.c
	@echo CC $<
	@$(CC) $(CFLAGS) -c $<

%.bin: %.elf
	@echo OBJCOPY $< $@
	@$(TOBJCOPY) -O binary $< $@

%.nm: %.elf
	@nm -n $< >$@

%.dump: %.elf
	@echo OBJDUMP $<
	@$(TOBJDUMP) --disassemble $(DUMPFLAGS) $< >$@

# clean:
#	rm -f *.o
#	rm -f a.out
#	rm -f $(EXTRA_CLEAN)
#	for dir in $(SUBDIRS); do \
#	  $(MAKE) -C $$dir clean; \
#	done
