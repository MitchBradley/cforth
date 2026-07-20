# ============================================================================
# ESP32 BUILD SYSTEM FOR IDF v5.5.1
# ============================================================================
# Based on V336 structure
# Fixed: rodict.o compiled for ESP32 with prepare_builtin_dictionary
# Enhanced: Full IDF build integration + path mismatch detection

# ============================================================================
# CONFIGURATION
# ============================================================================

# Toolchain
ESP32_CC   := xtensa-esp32-elf-gcc
ESP32_CXX  := xtensa-esp32-elf-g++
ESP32_AR   := xtensa-esp32-elf-ar
ESP32_LD   := xtensa-esp32-elf-gcc
ESP32_SIZE := xtensa-esp32-elf-size

# Directories
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)
ESP32_SRC := $(ROOT_DIR)/src/app/esp32-extra
CFORTH_SRC := $(ROOT_DIR)/src/cforth
EMBED_SRC := $(ROOT_DIR)/src/cforth/embed
BUILD_DIR      := .

# SDK configuration
SDK_BUILD_DIR  := $(BUILD_DIR)/sdk_build
SDK_CONFIG_DIR := $(SDK_BUILD_DIR)/build/config
SDK_CONFIG     := $(SDK_CONFIG_DIR)/sdkconfig.h

# Output control
ifeq ($(VERBOSE),1)
	QUIET :=
	REDIRECT :=
else
	QUIET := @
	REDIRECT := > /dev/null 2>&1
endif


# Environment check
check-env:
	@if [ -z "$(IDF_PATH)" ]; then \
		echo ""; \
		echo "ERROR: ESP-IDF environment not active!"; \
		echo "Run: source $(IDF_PATH)/export.sh"; \
		echo ""; \
		exit 1; \
	fi

# Build directory path check
check-build-dir:
	@if [ -f "$(SDK_BUILD_DIR)/build/project_description.json" ]; then \
		CONFIGURED_PATH=$$(grep -o '"build_dir": "[^"]*"' $(SDK_BUILD_DIR)/build/project_description.json | cut -d'"' -f4); \
		CURRENT_PATH="$(abspath $(SDK_BUILD_DIR))"; \
		if [ -n "$$CONFIGURED_PATH" ] && [ "$$CONFIGURED_PATH" != "$$CURRENT_PATH" ]; then \
			echo ""; \
			echo "ERROR: Build directory configured for different path"; \
			echo "  Old path: $$CONFIGURED_PATH"; \
			echo "  New path: $$CURRENT_PATH"; \
			echo ""; \
			echo "Automatically running fullclean to update path..."; \
			cd $(SDK_BUILD_DIR) && idf.py fullclean > /dev/null 2>&1; \
		fi \
	fi

# ============================================================================
# COMPILER FLAGS - OPTIMIZED FOR IDF v5.5.1
# ============================================================================

# Base includes
BASE_INCLUDES := -I$(BUILD_DIR) -I$(CFORTH_SRC) -I$(ESP32_SRC) -I$(EMBED_SRC)

# SDK config must come first
SDK_INCLUDES := -I$(SDK_CONFIG_DIR)

# ============================================================================
# TOOLCHAIN - CHIP SPECIFIC
# ============================================================================

# Determine IDF_TARGET if not set
ifeq ($(IDF_TARGET),)
	ifneq ($(wildcard $(SDK_BUILD_DIR)/sdkconfig),)
	IDF_TARGET := $(shell grep "^CONFIG_IDF_TARGET=" $(SDK_BUILD_DIR)/sdkconfig | cut -d'"' -f2)
	else
	IDF_TARGET := esp32
	endif
endif

# Chip-specific toolchain
ifeq ($(IDF_TARGET),esp32c3)
	ESP32_CC   := riscv32-esp-elf-gcc
	ESP32_CXX  := riscv32-esp-elf-g++
	ESP32_AR   := riscv32-esp-elf-ar
	ESP32_LD   := riscv32-esp-elf-gcc
	ESP32_SIZE := riscv32-esp-elf-size
	CHIP_CFLAGS = -march=rv32imc_zicsr_zifencei -mabi=ilp32
	CHIP_DEFINES = -DESP32_C3 -DRISCV -DBITS32
else
	ESP32_CC   := xtensa-esp32-elf-gcc
	ESP32_CXX  := xtensa-esp32-elf-g++
	ESP32_AR   := xtensa-esp32-elf-ar
	ESP32_LD   := xtensa-esp32-elf-gcc
	ESP32_SIZE := xtensa-esp32-elf-size
	CHIP_CFLAGS = -mlongcalls -mtext-section-literals
	CHIP_DEFINES = -DESP32 -DXTENSA -DBITS32
endif

# ============================================================================
# OPTIMIZED IDF INCLUDES
# ============================================================================

# Base paths that work for all chips
IDF_INCLUDES_BASE = \
	-I$(IDF_PATH)/components/esp_timer/include \
	-I$(IDF_PATH)/components/esp_system/include \
	-I$(IDF_PATH)/components/esp_common/include \
	-I$(IDF_PATH)/components/driver/include \
	-I$(IDF_PATH)/components/esp_driver_gpio/include \
	-I$(IDF_PATH)/components/soc/include \
	-I$(IDF_PATH)/components/esp_wifi/include \
	-I$(IDF_PATH)/components/esp_event/include \
	-I$(IDF_PATH)/components/esp_netif/include \
	-I$(IDF_PATH)/components/nvs_flash/include \
	-I$(IDF_PATH)/components/esp_hw_support/include \
	-I$(IDF_PATH)/components/esp_rom/include \
	-I$(IDF_PATH)/components/newlib/platform_include \
	-I$(IDF_PATH)/components/heap/include \
	-I$(IDF_PATH)/components/hal/include \
	-I$(IDF_PATH)/components/esp_adc/include \
	-I$(IDF_PATH)/components/esp_driver_uart/include \
	-I$(IDF_PATH)/components/esp_driver_spi/include \
	-I$(IDF_PATH)/components/esp_driver_i2c/include \
	-I$(IDF_PATH)/components/log/include

# Build-generated includes
BUILD_INCLUDES = \
	-I$(SDK_BUILD_DIR)/build/config \
	-I$(SDK_BUILD_DIR)/build/config/include

# Chip-specific paths
# Chip-specific paths
IDF_INCLUDES_CHIP = \
	-I$(IDF_PATH)/components/soc/$(IDF_TARGET)/include \
	-I$(IDF_PATH)/components/soc/$(IDF_TARGET)/include/soc \
	-I$(IDF_PATH)/components/soc/$(IDF_TARGET)/register \
	-I$(IDF_PATH)/components/soc/$(IDF_TARGET)/register/soc \
	-I$(IDF_PATH)/components/hal/$(IDF_TARGET)/include \
	-I$(IDF_PATH)/components/esp_adc/$(IDF_TARGET)/include \
	-I$(IDF_PATH)/components/esp_rom/$(IDF_TARGET) \
	-I$(IDF_PATH)/components/esp_common/include/$(IDF_TARGET)

# FreeRTOS paths (differs per chip)
ifeq ($(IDF_TARGET),esp32c3)
	FREERTOS_PORT = riscv
	FREERTOS_ARCH = riscv
	EXTRA_INCLUDES = \
		-I$(IDF_PATH)/components/riscv/include \
		-I$(IDF_PATH)/components/riscv/$(IDF_TARGET)/include
else
	FREERTOS_PORT = xtensa
	FREERTOS_ARCH = xtensa
	EXTRA_INCLUDES = \
		-I$(IDF_PATH)/components/xtensa/include \
		-I$(IDF_PATH)/components/xtensa/$(IDF_TARGET)/include
endif

FREERTOS_INCLUDES = \
	-I$(IDF_PATH)/components/freertos/config/include \
	-I$(IDF_PATH)/components/freertos/config/include/freertos \
	-I$(IDF_PATH)/components/freertos/FreeRTOS-Kernel/include \
	-I$(IDF_PATH)/components/freertos/FreeRTOS-Kernel/portable/$(FREERTOS_PORT)/include \
	-I$(IDF_PATH)/components/freertos/FreeRTOS-Kernel/portable/$(FREERTOS_PORT)/include/freertos \
	-I$(IDF_PATH)/components/freertos/esp_additions/include \
	-I$(IDF_PATH)/components/freertos/esp_additions/include/freertos \
	-I$(IDF_PATH)/components/freertos/config/$(FREERTOS_ARCH)/include \
	-I$(IDF_PATH)/components/freertos/config/$(FREERTOS_ARCH)/include/freertos

# RTC/ROM headers
# RTC/ROM headers
IDF_INCLUDES_RTC = \
	-I$(IDF_PATH)/components/esp_hw_support/port/$(IDF_TARGET)/include \
	-I$(IDF_PATH)/components/esp_rom/$(IDF_TARGET)/include \
	-I$(IDF_PATH)/components/soc/$(IDF_TARGET)/include 

# All includes combined
IDF_INCLUDES = \
	$(IDF_INCLUDES_BASE) \
	$(BUILD_INCLUDES) \
	$(IDF_INCLUDES_CHIP) \
	$(FREERTOS_INCLUDES) \
	$(EXTRA_INCLUDES) \
	$(IDF_INCLUDES_RTC)

# ============================================================================
# OPTIMIZED COMPILATION FLAGS
# ============================================================================

# Core compilation flags
DICT_SIZE ?= 0x8000   # 32KB 
COMPILE_FLAGS := -O2 -DFLOATING -DMORE_FP -DNOSYSCALL -DTARGET -DMAXDICT=$(DICT_SIZE)
COMPILE_FLAGS += -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0
COMPILE_FLAGS += -fno-stack-protector -fno-inline-functions -nostdlib -g

# Header conflict workarounds
WORKAROUND_FLAGS := -D_TIME_T_DECLARED -D__time_t_defined -DCFORTH_C=1 -Wno-error

# Warning suppression
C_WARN_FLAGS := -Wno-error -Wno-implicit-function-declaration -Wno-incompatible-pointer-types
C_WARN_FLAGS += -Wno-unused-variable -Wno-unused-function -Wno-cast-function-type

# Combined flags
ESP32_CFLAGS := $(BASE_INCLUDES) $(SDK_INCLUDES) $(IDF_INCLUDES)
ESP32_CFLAGS += $(COMPILE_FLAGS) $(WORKAROUND_FLAGS) $(C_WARN_FLAGS)
ESP32_CFLAGS += $(CHIP_CFLAGS) $(CHIP_DEFINES)

# ============================================================================
# DEBUG TARGETS
# ============================================================================

.PHONY: show-chip-config
show-chip-config:
	@echo "=========================================="
	@echo "CHIP CONFIGURATION"
	@echo "=========================================="
	@echo "IDF_TARGET:    $(IDF_TARGET)"
	@echo "Toolchain CC:  $(ESP32_CC)"
	@echo "Toolchain AR:  $(ESP32_AR)"
	@echo "CHIP_CFLAGS:   $(CHIP_CFLAGS)"
	@echo "CHIP_DEFINES:  $(CHIP_DEFINES)"
	@echo "=========================================="

# ============================================================================
# OBJECT FILE RULES
# ============================================================================

textend.o: $(ESP32_SRC)/extend.c $(SDK_CONFIG)
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

tmain.o ttmain.o: $(ESP32_SRC)/tmain.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o tmain.o
	$(QUIET) cp tmain.o ttmain.o 2>/dev/null || true

tcompiler.o: $(CFORTH_SRC)/compiler.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

tforth.o: $(CFORTH_SRC)/forth.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

tsyscall.o: $(CFORTH_SRC)/syscall.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

tfloatops.o: $(CFORTH_SRC)/floatops.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

tlineedit.o: $(CFORTH_SRC)/lineedit.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

tconsio.o: $(ESP32_SRC)/consio.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

tfileio.o: $(ESP32_SRC)/fileio_esp32.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

startapp.o: $(EMBED_SRC)/startapp.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

rodict.o: $(EMBED_SRC)/rodict.c dict.h dicthdr.h userarea.h
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -fno-common -fdata-sections -ffunction-sections \
	-c $< -o $@

tdate.o: tdate.c
	$(QUIET) $(ESP32_CC) $(ESP32_CFLAGS) -c $< -o $@

# Base objects for tembed.o
TBASEOBJS := tforth.o tcompiler.o tsyscall.o tfloatops.o tlineedit.o
EMBEDOBJS := startapp.o tconsio.o
DICTOBJ   := rodict.o

tembed.o: $(TBASEOBJS) $(EMBEDOBJS) $(DICTOBJ)
	$(QUIET) $(ESP32_LD) -nostdlib -r -o $@ $(TBASEOBJS) $(EMBEDOBJS) $(DICTOBJ)

# ============================================================================
# LIBRARY TARGET
# ============================================================================

ESP32_LIB_OBJS := tmain.o tconsio.o tcompiler.o tforth.o tsyscall.o tfloatops.o tlineedit.o textend.o rodict.o

APP_OBJS := ttmain.o tfileio.o tembed.o textend.o tdate.o

libforth.a: $(ESP32_LIB_OBJS)
	$(QUIET) rm -f $@
	$(QUIET) $(ESP32_AR) rcs $@ $(ESP32_LIB_OBJS)

# ============================================================================
# DICTIONARY GENERATION
# ============================================================================

makeccalls: ../../src/cforth/makeccalls.c
	$(QUIET) gcc -I../../src/cforth -o makeccalls ../../src/cforth/makeccalls.c
	$(QUIET) chmod +x makeccalls

tccalls.fth: makeccalls ../../src/app/esp32-extra/extend.c
	$(QUIET) ./makeccalls < ../../src/app/esp32-extra/extend.c > $@

dict.h dicthdr.h userarea.h: app.dic makebi
	$(QUIET) ./makebi app.dic

app.dic: tccalls.fth ../../src/app/esp32-extra/app.fth forth.dic makebi
	$(QUIET) ./forth forth.dic tccalls.fth ../../src/app/esp32-extra/app.fth

# ============================================================================
# IDF BUILD INTEGRATION
# ============================================================================

# Target for building only the Forth library (no IDF build)
libforth_only: check-env check-build-dir $(ESP32_LIB_OBJS) tfileio.o tdate.o startapp.o dict.h dicthdr.h userarea.h rodict.o tembed.o libforth.a
	@if [ -d "sdk_build" ] && [ -f "libforth.a" ]; then \
	cp libforth.a sdk_build/; \
	fi

flash: esp32-objs
	$(QUIET) if [ -d "sdk_build" ]; then \
		cd sdk_build && \
		idf.py flash; \
		if [ $$? -ne 0 ]; then \
			echo "Flash failed - RUN: make debug for details"; \
			exit 1; \
		fi \
	else \
		echo "ERROR: sdk_build directory not found"; \
		exit 1; \
	fi

# Default target
all: esp32-objs

# ============================================================================
# PHONY TARGET DECLARATIONS
# ============================================================================
.PHONY: check-env check-build-dir all debug-includes test-toolchain check-prepare

# ============================================================================
# DEBUG HELPERS
# ============================================================================
debug-includes:
	@echo "Include paths in use:"
	@echo "$(ESP32_CFLAGS)" | tr ' ' '\n' | grep "^-I" | head -20

test-toolchain:
	@echo "int main() { return 0; }" > /tmp/test_esp32.c
	@$(ESP32_CC) $(ESP32_CFLAGS) -c /tmp/test_esp32.c -o /tmp/test_esp32.o 2>&1
	@if [ $$? -eq 0 ]; then \
		echo "Toolchain works"; \
	else \
		echo "Toolchain failed"; \
	fi
	@rm -f /tmp/test_esp32.c /tmp/test_esp32.o

check-prepare:
	@echo "Checking for prepare_builtin_dictionary in libforth.a:"
	@nm libforth.a 2>/dev/null | grep -i prepare_builtin_dictionary || echo "NOT FOUND"
