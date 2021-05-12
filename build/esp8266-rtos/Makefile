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

# This is the final target file of the make process
APPELF := build/$(APPNAME).elf

default: $(APPELF)

# The topmost directory of the cforth repository
TOPDIR=../..

# The directory that contains the cforth repository
UPDIR=$(realpath $(TOPDIR)/..)

# This is directory in which the SDK will be installed.
# It defaults to the directory that contains the cforth repository.
IDF_PARENT_PATH ?= $(UPDIR)

# The directory than contains this Makefile, i.e. the app build directory
CFORTH_BUILD_PATH ?= $(abspath .)

include $(TOPDIR)/src/app/$(APPNAME)/targets.mk

clean::
	@rm -rf build
