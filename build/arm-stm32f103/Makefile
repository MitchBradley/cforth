# Builds CForth for STM32F103, for example "Blue Pill" boards

# You need the STM Standard Peripheral Library; see below for the URL

# You also need the arm-none-eabi- version of the gcc toolchain.
# I got it from https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads
# Its bin/ subdirectory must be in the search path

STMLIB ?= $(TOPDIR)/../STM32F10x_StdPeriph_Lib_V3.5.0

TOPDIR=../..

MYNAME=arm-stm32f103

CONFIG += -DBITS32 -DT16

default: app.elf app.bin app.nm app.dump

include $(TOPDIR)/src/app/$(MYNAME)/targets.mk


ifeq ("$(wildcard $(STMLIB))","")
  $(info You need the STM Standard Peripheral Library)
  $(info Get it from http://www.st.com/content/st_com/en/products/embedded-software/mcus-embedded-software/stm32-embedded-software/stm32-standard-peripheral-libraries/stsw-stm32054.html)
  $(info Get it from https://my.st.com/content/ccc/resource/technical/software/firmware/48/ab/e5/17/0d/79/43/74/stsw-stm32054.zip/files/stsw-stm32054.zip/_jcr_content/translations/en.stsw-stm32054.zip)
  $(info Unpack it into the parent directory of the cforth/ tree)
  $(error )
endif


# The recipe for serial flashing follows
# This one uses a Python script, but there are numerous alternatives that
# you can find by searching the web.

# Change COMPORT or override on the command line as necessary
# This is the serial port that talks to the target board via
# the target's USART1 wires
COMPORT ?= /dev/ttyUSB0

# Flashing via serial requires BOOT0=1 and BOOT1=0 (typically jumper settings)
# and the terminal emulator serial port connection must be closed.
# The target board must be reset after setting those jumpers
# After flashing, restore the jumpers to their previous settings,
# reopen the terminal emulator serial port connection, and reset the target board
# You can get stm32loader.py from https://github.com/jsnyder/stm32loader

STMLOADER ?= $(TOPDIR)/../stm32loader/stm32loader.py

VERIFY ?= -v

flash: app.bin
	python $(STMLOADER) -p $(COMPORT) -e -w $(VERIFY) app.bin
