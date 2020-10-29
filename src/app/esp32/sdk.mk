ESP_IDF_REPO = https://github.com/espressif/esp-idf.git
ESP_IDF_VERSION ?= v3.1.1
ESP_IDF_ARCHIVE = esp-idf-$(ESP_IDF_VERSION).zip
ESP_IDF_URL = https://github.com/espressif/esp-idf/releases/download/$(ESP_IDF_VERSION)/$(ESP_IDF_ARCHIVE)

# This file within esp-idf lists the required toolchain versions
TOOLVERSIONS = $(IDF_PATH)/tools/toolchain_versions.mk

EXTRACT_TOOLVERSIONS := grep SUPPORTED_TOOLCHAIN $(IDF_PATH)/make/project.mk \
  | grep := \
  | sed -e s/SUPPORTED/CURRENT/ -e s/VERSIONS/VERSION/ -e s/crosstool-ng-// -e s/DESC/DESC_SHORT/ >$(TOOLVERSIONS)

$(TOOLVERSIONS):
	@echo Getting esp-idf
	(cd $(ESP_IDF_PARENT_PATH) \
	&& wget $(ESP_IDF_URL) \
	&& echo Unzipping esp-idf \
	&& unzip -q $(ESP_IDF_ARCHIVE) \
	&& rm $(ESP_IDF_ARCHIVE) \
	&& python -m pip install --user -r $(IDF_PATH)/requirements.txt \
	&& if [ ! -e $(TOOLVERSIONS) ]; then $(EXTRACT_TOOLVERSIONS); fi \
	)

.PHONY: tv
tv: $(TOOLVERSIONS)

# If the TOOLVERSIONS file is not present, make will trigger the rule to
# make it and then restart so that its information can then be used to
# get the right toolchain
-include $(TOOLVERSIONS)

XTGCC_VERSION = $(CURRENT_TOOLCHAIN_COMMIT_DESC_SHORT)-$(CURRENT_TOOLCHAIN_GCC_VERSION)

XTGCC_ARCHIVE = xtensa-esp32-elf-linux64-$(XTGCC_VERSION).tar.gz
XTGCC_DOWNLOAD = https://dl.espressif.com/dl/$(XTGCC_ARCHIVE)

# Inside XTGCC_PARENT_PATH we have subdirectories for different
# toolchain versions so it is easy to tell if we have the right
# one, and if not, to automatically fetch it
# Example subdirectory name: toolchain-1.22.0-80-g6c4433a-5.2.0/
XTGCC_CONTAINER_PATH ?= $(XTGCC_PARENT_PATH)/toolchain-$(XTGCC_VERSION)

XTGCCPATH ?= $(XTGCC_CONTAINER_PATH)/xtensa-esp32-elf/bin

$(XTGCCPATH):
	(mkdir -p $(XTGCC_CONTAINER_PATH) \
	&& cd $(XTGCC_CONTAINER_PATH) \
	&& wget $(XTGCC_DOWNLOAD) \
	&& tar xvf $(XTGCC_ARCHIVE) \
	&& rm $(XTGCC_ARCHIVE) \
	)
