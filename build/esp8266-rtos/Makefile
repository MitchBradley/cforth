# Builds CForth for ESP8266 using FreeRTOS
#
# make
#   compiles the binary file
# make flash
#   compiles and downloads via /dev/ttyUSB0
# make monitor
#   runs a serial terminal emulator on /dev/ttyUSB0
# COMPORT=/dev/ttyS12 make flash
#   compiles and downloads via /dev/ttyS12
# COMPORT=/dev/ttyS12 make monitor
#   runs a serial terminal emulator on /dev/ttyS12

APPNAME := esp8266-rtos

default: sdk_build/build/$(APPNAME).elf

TOPDIR=../..
UPDIR=$(realpath $(TOPDIR)/..)

# Change these to reflect the locations of external stuff on your system,
# either here or on the command line
XTGCC_PARENT_PATH ?= $(UPDIR)
IDF_PARENT_PATH ?= $(UPDIR)

CFORTH_PATH ?= $(abspath .)

# If COMPORT is in the environment - e.g.  COMPORT=COM36 make flash
# override the CONFIG_ESPTOOLPY_PORT setting in sdk_build/sdkconfig,
# otherwise use that setting.
# The following line forces COMPORT to be imported from the environment.
COMPORT ?=
ifneq ($(COMPORT),)
	ESPPORT_OVERRIDE = ESPPORT=$(COMPORT)
endif

include $(TOPDIR)/src/app/$(APPNAME)/targets.mk

clean::
	@rm -rf sdk_build/build
