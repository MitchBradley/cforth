# allow override of default cross location
CROSS ?= /usr/local/arm/arm-linux/bin/
TCC=$(CROSS)gcc
TLD=$(CROSS)ld
TOBJDUMP=$(CROSS)objdump
TOBJCOPY=$(CROSS)objcopy

CPU_VARIANT ?= -marm
TCFLAGS += $(CPU_VARIANT)

LIBGCC=$(shell $(TCC) $(TCFLAGS) -print-libgcc-file-name)

# This subst mess handles Windows pathnames that may contain spaces
# Without it, the dir function can mess up badly

# Tricky way to get a variable that contains a space character
space :=
space +=

# First replace spaces with semicolons
LS := $(subst $(space),;,$(LIBGCC))
# Then perform dir on the space-less path
DS := $(dir $(LS))
# Finally restore the spaces
LIBGCCDIR := $(subst ;,$(space),$(DS))

# And quote the result to protect the spaces
LIBDIRS:=-L"$(LIBGCCDIR)"
