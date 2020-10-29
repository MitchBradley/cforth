NODEMCU_PATH ?= $(NODEMCU_PARENT_PATH)/nodemcu-firmware
SDK_VER:=1.5.4.1

XTGCCPATH ?= $(NODEMCU_PATH)/esp-open-sdk/xtensa-lx106-elf/bin/
CROSS ?= $(XTGCCPATH)xtensa-lx106-elf-

# Include files from the SDK
SDK_DIR:=$(NODEMCU_PATH)/sdk/esp_iot_sdk_v$(SDK_VER)
INCS += -I$(TOP_DIR)/sdk-overrides/include -I$(SDK_DIR)/include

INCS += -I$(NODEMCU_PATH)/app/include
INCS += -I$(NODEMCU_PATH)/app/platform
INCS += -I$(NODEMCU_PATH)/app/spiffs
INCS += -I$(NODEMCU_PATH)/app/libc
INCS += -I$(NODEMCU_PATH)/app/netif

NODEMCU_REPO ?= https://github.com/nodemcu/nodemcu-firmware.git
NODEMCU_COMMIT ?= 7b83bbb
$(NODEMCU_PATH):
	(cd $(NODEMCU_PARENT_PATH) \
	&& git clone $(NODEMCU_REPO) \
	&& cd $(abspath $(NODEMCU_PATH)) \
	&& git branch cforth $(NODEMCU_COMMIT) \
	&& git checkout cforth \
	&& git apply --whitespace=fix $(abspath $(TOPDIR))/src/app/esp8266/*.patch \
	&& tar -xzf tools/esp-open-sdk.tar.gz \
	)

$(NODEMCU_PATH)/sdk: $(NODEMCU_PATH)
	cd $(NODEMCU_PATH) && make --no-print-directory sdk_patched

$(PLAT_OBJS): $(NODEMCU_PATH)/sdk

BUILDDIR := $(realpath .)

0x10000.bin 0x00000.bin: $(NODEMCU_PATH)/sdk app.o
	(cd $(NODEMCU_PATH) && PATH="${PATH}:$(XTGCCPATH)" FORTHOBJS=$(BUILDDIR)/app.o make --no-print-directory)
	mv $(NODEMCU_PATH)/bin/*.bin .

# Use FS=1m FM=dout for most Sonoff devices
FS?=32m
FM?=dio

LOADCMD=$(NODEMCU_PATH)/tools/esptool.py --port $(COMPORT) -b 115200 write_flash -fm=$(FM) -fs=$(FS) 0x00000 0x00000.bin 0x10000 0x10000.bin

download: 0x00000.bin 0x10000.bin
	$(LOADCMD)
