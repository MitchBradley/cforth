ARCH=/usr/local/arm
UTILS=$(ARCH)/arm-linux/bin
TCC=$(UTILS)/gcc
TLD=$(UTILS)/ld
LIBDIRS=-L$(dir $(shell $(TCC) -print-libgcc-file-name))

TOBJDUMP=$(ARCH)/bin/arm-linux-objdump
TOBJCOPY=$(ARCH)/bin/arm-linux-objcopy

TCFLAGS += -marm
