# allow override of default cross location
CROSS ?= riscv64-linux-gnu-
TCC=$(CROSS)gcc
TLD=$(CROSS)ld
TOBJDUMP=$(CROSS)objdump
TOBJCOPY=$(CROSS)objcopy

TCFLAGS += $(CPU_VARIANT)
TSFLAGS += $(CPU_VARIANT)
