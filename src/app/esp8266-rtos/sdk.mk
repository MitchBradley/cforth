IDF_NAME ?= ESP8266_RTOS_SDK
IDF_PATH ?= $(IDF_PARENT_PATH)/$(IDF_NAME)

# This file within the SDK lists the required toolchain versions
TOOLVERSIONS = $(IDF_PATH)/tools/toolchain_versions.mk

# This is for getting a specific release version .zip file
# IDF_VERSION ?= v3.3
# IDF_ARCHIVE = $(IDF_NAME)-$(IDF_VERSION).zip
# IDF_URL = $(IDF_GITUSER)/$(IDF_NAME)/releases/download/$(IDF_VERSION)/$(IDF_ARCHIVE)
#
# $(TOOLVERSIONS):
# 	@echo Getting $(IDF_NAME)
# 	(cd $(IDF_PARENT_PATH) \
# 	&& wget $(IDF_URL) \
# 	&& echo Unzipping $(IDF_ARCHIVE) \
# 	&& unzip -q $(IDF_ARCHIVE) \
# 	&& rm $(IDF_ARCHIVE) \
# 	&& python -m pip install --user -r $(IDF_PATH)/requirements.txt \
# 	)

# This is for cloning the lastest version from GitHub
IDF_GITUSER ?= https://github.com/espressif
IDF_REPO = $(IDF_GITUSER)/$(IDF_NAME).git

$(TOOLVERSIONS):
	@echo Getting $(IDF_NAME)
	(cd $(IDF_PARENT_PATH) \
	&& git clone $(IDF_REPO) \
	&& python -m pip install --user -r $(IDF_PATH)/requirements.txt \
	)

# If the TOOLVERSIONS file is not present, make will trigger the rule to
# make it and then restart so that its information can then be used to
# get the right toolchain
-include $(TOOLVERSIONS)

# It is hard to convert the names in toolchain_versions.mk to filenames,
# so we hardcode it here.
XTGCC_VERSION = gcc8_4_0-esp-2020r3

TOOLPREFIX = xtensa-lx106-elf
XTGCC_ARCHIVE = $(TOOLPREFIX)-$(XTGCC_VERSION)-linux-amd64.tar.gz
XTGCC_DOWNLOAD = https://dl.espressif.com/dl/$(XTGCC_ARCHIVE)

# Inside XTGCC_PARENT_PATH we have subdirectories for different
# toolchain versions so it is easy to tell if we have the right
# one, and if not, to automatically fetch it
# Example subdirectory name: toolchain-1.22.0-80-g6c4433a-5.2.0/
XTGCC_CONTAINER_PATH ?= $(XTGCC_PARENT_PATH)/toolchain-$(XTGCC_VERSION)

XTGCCPATH ?= $(XTGCC_CONTAINER_PATH)/$(TOOLPREFIX)/bin

$(XTGCCPATH):
	@ echo Getting toolchain
	(mkdir -p $(XTGCC_CONTAINER_PATH) \
	&& cd $(XTGCC_CONTAINER_PATH) \
	&& wget $(XTGCC_DOWNLOAD) \
	&& tar xf $(XTGCC_ARCHIVE) \
	&& rm $(XTGCC_ARCHIVE) \
	)
