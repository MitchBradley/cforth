ARCH=/usr/local/arm
UTILS=$(ARCH)/arm-linux/bin
TCC=$(UTILS)/gcc
TLD=$(UTILS)/ld
LIBDIRS=-L$(ARCH)/lib/gcc-lib/arm-linux/3.2/

TOBJDUMP=$(ARCH)/bin/arm-linux-objdump
TOBJCOPY=$(ARCH)/bin/arm-linux-objcopy
