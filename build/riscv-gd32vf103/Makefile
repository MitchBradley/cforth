# Builds CForth for GD32VF103, for example "Polos Alef" boards

# You need the GD32VF103 Firmware Library; see below for the URL

# You also need the riscv-nuclei-elf- version of the gcc toolchain.
# I got it from https://github.com/riscv-mcu/riscv-gnu-toolchain/releases
# Its bin/ subdirectory must be in the search path

TOPDIR = ../..

MYNAME = riscv-gd32vf103

CONFIG += -DBITS32 -DT16

default: app.elf app.bin app.nm app.dump

CROSS ?= $(GD32V_TOOLCHAIN)/bin/riscv-nuclei-elf-
CPU_VARIANT ?= -march=rv32imac -mabi=ilp32 -mcmodel=medlow

GD32V_TOOLCHAIN_PARENT_PATH = $(TOPDIR)/..
GD32V_TOOLCHAIN ?= $(GD32V_TOOLCHAIN_PARENT_PATH)/rv_linux_bare_$(GD32V_TOOLCHAIN_VERSION)

GD32V_TOOLCHAIN_VERSION ?= 1908312208
GD32V_TOOLCHAIN_ARCHIVE = rv_linux_bare_$(GD32V_TOOLCHAIN_VERSION).tar.bz2
GD32V_TOOLCHAIN_URL = https://github.com/riscv-mcu/riscv-gnu-toolchain/releases/download/v9.2RC/$(GD32V_TOOLCHAIN_ARCHIVE)

GD32V_LIB_PARENT_PATH = $(TOPDIR)/..
GD32V_LIB ?= $(GD32V_LIB_PARENT_PATH)/GD32VF103_Firmware_Library-$(GD32V_LIB_VERSION)

GD32V_LIB_VERSION ?= 12b61d1bf29afbee8ec4eee81cdbf1bd9f89470a
GD32V_LIB_ARCHIVE = GD32VF103_Firmware_Library-$(GD32V_LIB_VERSION).zip
GD32V_LIB_URL = https://github.com/riscv-mcu/GD32VF103_Firmware_Library/archive/$(GD32V_LIB_VERSION)/$(GD32V_LIB_ARCHIVE)

$(GD32V_LIB):
	@echo Getting GD32VF103_Firmware_Library
	(cd $(GD32V_LIB_PARENT_PATH) \
	&& wget $(GD32V_LIB_URL) \
	&& echo Unpacking GD32VF103_Firmware_Library \
	&& unzip -q $(GD32V_LIB_ARCHIVE) \
	&& rm $(GD32V_LIB_ARCHIVE) \
	)

$(GD32V_TOOLCHAIN):
	@echo Getting riscv-gnu-toolchain
	(cd $(GD32V_TOOLCHAIN_PARENT_PATH) \
	&& wget $(GD32V_TOOLCHAIN_URL) \
	&& echo Unpacking riscv-gnu-toolchain \
	&& tar xjf $(GD32V_TOOLCHAIN_ARCHIVE) \
	&& rm $(GD32V_TOOLCHAIN_ARCHIVE) \
	)

$(GD32V_TOOLCHAIN)/install-tools/macro_list: $(GD32V_TOOLCHAIN) $(GD32V_LIB)
include $(GD32V_TOOLCHAIN)/install-tools/macro_list

# The recipe for DFU flashing follows

# The device needs to enter the DFU mode first, by starting with BOOT0=1
# (typically a button on a board).

DFU_UTIL = dfu-util

flash: app.bin
	$(DFU_UTIL) -d 28e9:0189 -a 0 -s 0x8000000:mass-erase:force:leave -D $<

include $(TOPDIR)/src/app/$(MYNAME)/targets.mk
