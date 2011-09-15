# allow override of default cross location
ifeq ($(CROSS),)
    CROSS=/usr/local/arm/arm-linux/bin/
endif
TCC=$(CROSS)gcc
TLD=$(CROSS)ld
TOBJDUMP=$(CROSS)objdump
TOBJCOPY=$(CROSS)objcopy
TCFLAGS += -marm

LIBDIRS=-L$(dir $(shell $(TCC) -print-libgcc-file-name))
