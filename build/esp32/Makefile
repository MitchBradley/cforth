# Builds CForth for ESP8266

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
XTGCCPATH ?= $(XTGCC_PARENT_PATH)/xtensa-esp32-elf/bin/
CROSS ?= $(XTGCCPATH)xtensa-esp32-elf-

# ESP32 SDK
IDF_PARENT_PATH ?= $(UPDIR)
IDF_PATH ?= $(IDF_PARENT_PATH)/esp-idf

CFORTH_PATH ?= $(abspath $(TOPDIR)/build/esp32)

include $(TOPDIR)/src/app/esp32/targets.mk

ESP_IDF_PATHS:=IDF_PATH=$(IDF_PATH) CFORTH_PATH=$(CFORTH_PATH) PATH=$(PATH):$(XTGCCPATH)

forth.elf: app.o
	@$(ESP_IDF_PATHS) make --no-print-directory -C sdk_build

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

clean::
	@rm -rf sdk_build/build
