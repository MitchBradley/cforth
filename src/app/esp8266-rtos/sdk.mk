# This makefile fragment gets the SDK into a subdirectory
# of IDF_PARENT_PATH, then uses install.sh from the SDK
# to install the toolchain, the uses export.sh to create
# a makefile fragment named toolchain_path.mk .
#
# The installation work is done only once.  Subsequently,
# toolchain_path.mk will be present and it will be included,
# setting XTGCCPATH to the toolchain location.

IDF_NAME ?= ESP8266_RTOS_SDK
IDF_PATH ?= $(IDF_PARENT_PATH)/$(IDF_NAME)

IDF_GITUSER ?= https://github.com/espressif
IDF_REPO = $(IDF_GITUSER)/$(IDF_NAME).git

SHELL=/bin/bash
PATCHFILE = $(abspath $(TCPATH)/sdk.patch)
$(IDF_PATH)/export.sh:
	@echo Getting $(IDF_NAME)
	@cd $(IDF_PARENT_PATH) \
	&& git clone $(IDF_REPO) \
	&& sh $(IDF_NAME)/install.sh \
	&& (cd $(IDF_NAME); patch -p1 <$(PATCHFILE))

TOOLPATH_MK=$(IDF_PATH)/toolchain_path.mk

# Use export.sh from the SDK to add the toolchain to PATH,
# then create toolchain_path_mk that sets XTGCCPATH,
# use "which" to find the toolchain patch from PATH.
$(TOOLPATH_MK): $(IDF_PATH)/export.sh
	@echo Setting compiler path
	@(. $(IDF_PATH)/export.sh >/dev/null \
	&& echo XTGCCPATH = `which xtensa-lx106-elf-gcc | xargs dirname` >$@\
	)

-include $(TOOLPATH_MK)
