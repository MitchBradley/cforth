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

.PHONY: nodemcu-fw

NODEMCU_REPO ?= https://github.com/nodemcu/nodemcu-firmware.git
NODEMCU_COMMIT ?= 7b83bbb
$(NODEMCU_PATH):
	(cd $(NODEMCU_PARENT_PATH) \
	&& git clone $(NODEMCU_REPO) \
	&& cd $(abspath $(NODEMCU_PATH)) \
	&& git branch cforth $(NODEMCU_COMMIT) \
	&& git checkout cforth \
	&& git apply --whitespace=fix $(abspath $(APPPATH))/*.patch \
	&& tar -xzf tools/esp-open-sdk.tar.gz
	)

$(NODEMCU_PATH)/sdk: $(NODEMCU_PATH)
	cd $(NODEMCU_PATH) && make --no-print-directory sdk_patched

$(PLAT_OBJS): $(NODEMCU_PATH)/sdk

BUILDDIR := $(realpath .)

nodemcu-fw: $(NODEMCU_PATH)/sdk app.o
	(cd $(NODEMCU_PATH) && PATH=${PATH}:$(XTGCCPATH) FORTHOBJS=$(BUILDDIR)/app.o make --no-print-directory)
	cp $(NODEMCU_PATH)/bin/*.bin .

LOADCMD=tools/esptool.py --port $(COMPORT) -b 115200 write_flash -fm=dio -fs=32m 0x00000 bin/0x00000.bin 0x10000 bin/0x10000.bin

download: nodemcu-fw
	(cd $(NODEMCU_PATH) && $(LOADCMD))
