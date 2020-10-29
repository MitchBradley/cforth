# Builds CForth for ESP8266 using FreeRTOS

APPNAME := esp8266-rtos

default: forth.elf

TOPDIR=../..
UPDIR=$(realpath $(TOPDIR)/..)

CONFIG += -DBITS32
CONFIG += -DFLOATING -DMORE_FP
LIBS += -lm

CFLAGS += -m32

CC := gcc

# Change these to reflect the locations of external stuff on your system,
# either here or on the command line
XTGCC_PARENT_PATH ?= $(UPDIR)
XTGCCPATH ?= $(XTGCC_PARENT_PATH)/xtensa-lx106-elf/bin/

# ESP8266_RTOS_SDK
ESP_IDF_PARENT_PATH ?= $(UPDIR)
IDF_PATH ?= $(ESP_IDF_PARENT_PATH)/ESP8266_RTOS_SDK

CFORTH_PATH ?= $(abspath .)

include $(TOPDIR)/src/app/$(APPNAME)/targets.mk

# ESP_IDF_PATHS:=IDF_PATH="$(IDF_PATH)" CFORTH_PATH="$(CFORTH_PATH)" PATH="$(PATH):$(XTGCCPATH)"

ESP_IDF_PATHS := IDF_PATH="$(IDF_PATH)" CFORTH_PATH="$(CFORTH_PATH)" XTGCCPATH="$(XTGCCPATH)"

forth.elf: app.o
	@VERBOSE=1 $(ESP_IDF_PATHS) make --no-print-directory -C sdk_build

# If COMPORT is in the environment - e.g.  COMPORT=COM36 make flash
# override the CONFIG_ESPTOOLPY_PORT setting in sdk_build/sdkconfig,
# otherwise use that setting.
# The following line forces COMPORT to be imported from the environment.
COMPORT ?=
ifneq ($(COMPORT),)
	ESPPORT_OVERRIDE = ESPPORT=$(COMPORT)
endif

flash: app.o
	@$(ESP_IDF_PATHS) $(ESPPORT_OVERRIDE) make --no-print-directory -C sdk_build flash

monitor:
	@$(ESP_IDF_PATHS) $(ESPPORT_OVERRIDE) make --no-print-directory -C sdk_build monitor

# In many build setups, including native Linux, "make flash" per above will work.
# It fails inside Docker on a Windows host due to the lack of host USB serial port access.
# It also fails in Windows Subsystem for Linux (WSL) due to WSL's inability to run
# 32-bit apps.
# "make download" as below works in WSL, since it only runs one app (python) which
# is a 64-bit app.  The recipe for "make download" was determined by running
# "make flash" under Docker (with an extra "echo" line added to the "flash" target
# rules), and copying the command line.
# Usage: COMPORT=/dev/ttyS5 make download
# download: app.o
# 	@(cd sdk_build/build && python "$(IDF_PATH)/components/esptool_py/esptool/esptool.py" --chip esp8266 --port $(COMPORT) --baud 921600 --before default_reset --after hard_reset write_flash -u --flash_mode dio --flash_freq 40m --flash_size detect 0x1000 bootloader/bootloader.bin 0x10000 forth.bin 0x8000 partitions.bin)

# dlonly:
# 	@(cd sdk_build/build && python $(IDF_PATH)/components/esptool_py/esptool/esptool.py --chip esp32 --port $(COMPORT) --baud 921600 --before default_reset --after hard_reset write_flash -u --flash_mode dio --flash_freq 40m --flash_size detect 0x1000 bootloader/bootloader.bin 0x10000 forth.bin 0x8000 partitions.bin)

# clean::
# 	@rm -rf sdk_build/build
