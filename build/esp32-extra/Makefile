# ============================================================================
# cForth ESP32 Makefile with Multi-configuration Support
# ============================================================================

# Usage: make help
# Documentation: ../../src/app/esp32-extra/docs

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD_DIR := $(ROOT_DIR)
EXTRA   := ../../src/app/esp32-extra

# ESP-IDF root path
CFORTH_ROOT := $(abspath $(ROOT_DIR)/../../..)
ESP_IDF_PATH := $(CFORTH_ROOT)/esp-idf-v5.5.1

# Configuration file (persistent)
CONFIG_FILE := $(ROOT_DIR)/.current_config
IDF_CONFIGS_DIR := $(EXTRA)/idf_configs

# Load current configuration with validation
ifneq ($(wildcard $(CONFIG_FILE)),)
CURRENT_CONFIG := $(shell cat $(CONFIG_FILE))
ifeq ($(wildcard $(IDF_CONFIGS_DIR)/$(CURRENT_CONFIG)),)
$(warning Configuration '$(CURRENT_CONFIG)' not found!)
$(warning Resetting to default 'esp32')
CURRENT_CONFIG := esp32
$(shell echo $(CURRENT_CONFIG) > $(CONFIG_FILE))
endif
else
CURRENT_CONFIG := esp32
$(shell echo $(CURRENT_CONFIG) > $(CONFIG_FILE))
endif

MAKEFLAGS += --no-print-directory

# Full path to selected configuration
SELECTED_CONFIG_DIR := $(IDF_CONFIGS_DIR)/$(CURRENT_CONFIG)

# IDF options - only for reconfigure
IDF_OPTS = --no-ccache

# ============================================================================
# OUTPUT CONTROL
# ============================================================================
MAKE_OUTPUT = --silent
IDF_OUTPUT = >/dev/null 2>&1

# Debug mode flag (set by debug target)
DEBUG_MODE := 0

# ============================================================================
# MAIN TARGET - Check SDK first, then build
# ============================================================================
.PHONY: all
all:
	@if [ ! -d "$(ESP_IDF_PATH)" ]; then \
		echo ""; \
		echo "========================================"; \
		echo "ESP-IDF not found at $(ESP_IDF_PATH)"; \
		echo "Running 'make sdk' to install..."; \
		echo "========================================"; \
		echo ""; \
		$(MAKE) sdk; \
		echo ""; \
		echo "=============================================="; \
		echo "SDK installation ended."; \
		echo "To complete the remainder of the installation:"; \
		echo "Close this terminal and open a new one."; \
		echo "Then run 'make' again in $(BUILD_DIR)"; \
		echo "=============================================="; \
		echo ""; \
		exit 0; \
	else \
		$(MAKE) test flash; \
	fi

help:
	@echo "cForth ESP32 - Build System"
	@echo ""
	@echo "Current configuration: $(CURRENT_CONFIG)"
	@echo ""
	@echo "Main targets:"
	@echo "  make           # Complete build & flash (quiet)"
	@echo "  make app       # Rebuild & flash app only"
	@echo "  make clean     # Use after changes in the Forth target"
	@echo "  make distclean # Use after changes in C (full cleanup)"
	@echo "  make flash     # Flash only"
	@echo "  make sdk       # Installs/updates and checks the sdk"
	@echo "  make test      # Build firmware only"
	@echo "  make debug     # Build with full output (for debugging)"
	@echo "  IDF_COMPONENT_MANAGER=1 make # Use the IDF component manager"
	@echo ""
	@echo "Configuration targets:"
	@echo "  make setconfig        # Select/restore a previous configuration"
	@echo "  make saveconfig       # Save current configuration"
	@echo ""
	@echo "Documentation: $(EXTRA)/docs "


# Forward debug targets to esp32.mk
debug-includes test-toolchain check-prepare:
	@$(MAKE) -f $(EXTRA)/esp32.mk $@

# ----------------------------------------------------------------------------
# CONFIGURATION SYNC Restoring
# ----------------------------------------------------------------------------
sync-config:
	@mkdir -p sdk_build sdk_build/main
	@cp -f $(SELECTED_CONFIG_DIR)/sdkconfig sdk_build/
	@cp -f $(SELECTED_CONFIG_DIR)/partitions.csv sdk_build/
	@cp -f $(SELECTED_CONFIG_DIR)/CMakeLists.txt sdk_build/
	@cp -f $(SELECTED_CONFIG_DIR)/main/CMakeLists.txt sdk_build/main/
	@cp -f $(SELECTED_CONFIG_DIR)/local_config.h sdk_build/
	@echo "Configuration restored from $(SELECTED_CONFIG_DIR)/"

# ----------------------------------------------------------------------------
# SETCONFIG - Select configuration and copy to sdk_build/
# ----------------------------------------------------------------------------
setconfig:
	@$(MAKE) --no-print-directory _show_config_menu

_show_config_menu:
	@echo ""
	@echo "=== cForth Configuration Selector ==="
	@echo "Current: $(CURRENT_CONFIG)"
	@echo ""
	@echo "Available configurations:"
	@echo ""
	@i=1; for config in $$(ls -1 $(IDF_CONFIGS_DIR)); do \
		if [ "$$config" = "$(CURRENT_CONFIG)" ]; then \
			echo "  $$i) [X] $$config"; \
		else \
			echo "  $$i) [ ] $$config"; \
		fi; \
		i=$$((i+1)); \
	done
	@echo ""
	@printf "Select configuration (1-$$(ls -1 $(IDF_CONFIGS_DIR) | wc -l)) or 'q' to quit: "
	@read choice; \
	if [ "$$choice" != "q" ]; then \
		if echo "$$choice" | grep -q '^[0-9]\+$$'; then \
			i=1; found=0; \
			for config in $$(ls -1 $(IDF_CONFIGS_DIR)); do \
				if [ $$i -eq $$choice ]; then \
					echo "Switching to: $$config"; \
					echo $$config > $(CONFIG_FILE); \
					$(MAKE) sync-config; \
					$(MAKE) distclean; \
					$(MAKE) all; \
					found=1; \
					break; \
				fi; \
				i=$$((i+1)); \
			done; \
			if [ $$found -eq 0 ]; then \
				echo "Invalid selection: $$choice"; \
			fi; \
		else \
			echo "Invalid input: please enter a number"; \
		fi; \
	fi

# ----------------------------------------------------------------------------
# SAVECONFIG - Save sdk_build/ configuration back to SELECTED_CONFIG_DIR
# ----------------------------------------------------------------------------
saveconfig:
	@echo "=== Saving configuration from sdk_build/ to $(SELECTED_CONFIG_DIR)/ ==="
	@if [ -f "sdk_build/sdkconfig" ]; then \
		cp -f sdk_build/sdkconfig $(SELECTED_CONFIG_DIR)/; \
		echo "  Saved: sdkconfig"; \
	else \
		echo "  WARNING: sdk_build/sdkconfig not found"; \
	fi
	@if [ -f "sdk_build/partitions.csv" ]; then \
		cp -f sdk_build/partitions.csv $(SELECTED_CONFIG_DIR)/; \
		echo "  Saved: partitions.csv"; \
	else \
		echo "  WARNING: sdk_build/partitions.csv not found"; \
	fi
	@if [ -f "sdk_build/CMakeLists.txt" ]; then \
		cp -f sdk_build/CMakeLists.txt $(SELECTED_CONFIG_DIR)/; \
		echo "  Saved: CMakeLists.txt"; \
	else \
		echo "  WARNING: sdk_build/CMakeLists.txt not found"; \
	fi
	@if [ -f "sdk_build/main/CMakeLists.txt" ]; then \
		cp -f sdk_build/main/CMakeLists.txt $(SELECTED_CONFIG_DIR)/main/; \
		echo "  Saved: main/CMakeLists.txt"; \
	else \
		echo "  WARNING: sdk_build/main/CMakeLists.txt not found"; \
	fi
	@if [ -f "sdk_build/local_config.h" ]; then \
		cp -f sdk_build/local_config.h $(SELECTED_CONFIG_DIR)/; \
		echo "  Saved: local_config.h"; \
	else \
		echo "  WARNING: sdk_build/local_config.h not found"; \
	fi
	@echo "=== Configuration saved! ==="

sdk:
	@$(MAKE) -f $(EXTRA)/sdk.mk install-sdk

# ============================================================================
# HOST BUILD
# ============================================================================
pipeline meta forth kernel.dic forth.dic makebi:
	@echo "=== Building host tools ($@) ==="
	@$(MAKE) -f $(EXTRA)/esp32.mk

# ============================================================================
# FORTH LIBRARY BUILD (formerly esp32-objs)
# ============================================================================
build_forth:
#	@echo "=== Step 1: Building host tools ==="
	@$(MAKE) -f $(EXTRA)/targets.mk pipeline meta forth kernel.dic forth.dic makebi
#	@echo "=== Step 2: Building Forth library (libforth.a) ==="
	@if [ -f "$(EXTRA)/tdate.c" ]; then \
		cp $(EXTRA)/tdate.c .; \
	else \
		echo "ERROR: tdate.c not found!"; \
		exit 1; \
	fi
	@if [ -f "$(EXTRA)/version" ]; then \
		cp $(EXTRA)/version .; \
	fi
	@$(MAKE) -f $(EXTRA)/sdk.mk check-idf
	@$(MAKE) --no-print-directory check_sdkconfig
	@echo "Building $(CURRENT_CONFIG) configuration"
	@$(MAKE) -f $(EXTRA)/esp32.mk libforth_only
	@if [ -d "sdk_build" ] && [ -f "libforth.a" ]; then \
		cp libforth.a sdk_build/; \
	fi

# Separate target for sdkconfig check
check_sdkconfig:
	@if [ ! -f "sdk_build/build/config/sdkconfig.h" ]; then \
		if [ -f "sdk_build/sdkconfig" ]; then \
			echo "Running IDF reconfigure..."; \
			cd sdk_build && echo "" | idf.py reconfigure 2>&1; \
			if [ $$? -ne 0 ]; then \
				echo "ERROR: reconfigure failed."; \
				echo "Try 'make sdk' followed by 'make'"; \
				exit 1; \
			fi \
		else \
			echo "ERROR: No sdkconfig found. Run 'make menuconfig' first."; \
			exit 1; \
		fi \
	fi

# ============================================================================
# IDF BUILD TARGETS
# ============================================================================
test: build_forth
	@echo "Building IDF project may take 1-5 minutes....."
	@if [ -d "sdk_build" ]; then \
		cd sdk_build && idf.py build $(IDF_OUTPUT); \
		if [ $$? -ne 0 ]; then \
			echo "Build failed - RUN: make debug for details"; \
			exit 1; \
		fi \
	fi

debug: DEBUG_MODE=1
debug: build_forth
	@echo "=== DEBUG: Building IDF project with full output ==="
	@if [ -d "sdk_build" ]; then \
		echo "Compiling... (this may take a few minutes)"; \
		cd sdk_build && (idf.py build 2>&1 || echo ">>> BUILD_FAILED <<<") | tee full_build.log; \
		if grep -q ">>> BUILD_FAILED <<<" full_build.log; then \
			echo ""; \
			echo "=========================================="; \
			echo "=== BUILD FAILED - check errors below ==="; \
			echo "=========================================="; \
			grep -E "error:|fatal:" full_build.log | head -10; \
			exit 1; \
		else \
			echo "=== Build successful! ==="; \
		fi \
	fi

app: build_forth
	@echo "Building and flashing IDF project may take 1-5 minutes....."
	@mkdir -p sdk_build
	@cd sdk_build && idf.py build > /dev/null 2>&1 && idf.py flash
	@echo "=== Flash completed! ==="

flash:
	@cd sdk_build && idf.py flash

# ----------------------------------------------------------------------------
# MENUCONFIG - No automatic sync, uses existing sdk_build/sdkconfig
# ----------------------------------------------------------------------------
menuconfig:
	@mkdir -p sdk_build
	@if [ ! -f "sdk_build/sdkconfig" ]; then \
		echo "WARNING: No sdk_build/sdkconfig found."; \
		echo "Run 'make setconfig' first or 'make sync-config' to restore."; \
		exit 1; \
	fi
	@echo "=== Running menuconfig on sdk_build/sdkconfig ==="
	@cd sdk_build && idf.py menuconfig
	@echo ""
	@echo "Changes saved to sdk_build/sdkconfig"
	@echo "Run 'make saveconfig' to save these changes permanently."

esp32-%:
	@$(MAKE) -f $(EXTRA)/esp32.mk $*

# ============================================================================
# CLEAN
# ============================================================================
clean:
	@echo "=== Cleaning build files ==="
	@rm -f app.dic tt*.o tt*.c tt*.s tt*.i 2>/dev/null || true
	@rm -f tembed.o rodict.o libforth.a 2>/dev/null || true
	@rm -f dict.h dicthdr.h userarea.h 2>/dev/null || true
	@rm -f sdk_build/libforth.a 2>/dev/null || true
	@if [ -d "sdk_build/build" ]; then \
		find sdk_build/build -name "*.o" -delete 2>/dev/null || true; \
		find sdk_build/build -name "*.d" -delete 2>/dev/null || true; \
	fi

distclean: clean
	@rm -f meta forth makename makebi 2>/dev/null || true
	@rm -f kernel.dic forth.dic 2>/dev/null || true
	@rm -f prims.h vars.h init.x forth.ip *.o 2>/dev/null || true
	@rm -f makeccalls tccalls.fth tdate.c version 2>/dev/null || true
	@rm -rf tools/mkspiffs/*.o tools/mkspiffs/spiffs/src/*.o 2>/dev/null || true
	@rm -rf cross_objs cross_objs/*.o cross_objs/*.a 2>/dev/null || true
	@rm -rf t_objects 2>/dev/null || true
	@rm -rf tools 2>/dev/null || true
	@rm -rf sdk_build/build 2>/dev/null || true
	@rm -f sdk_build/dependencies.lock 2>/dev/null || true
	@rm -f sdk_build/full_build.log 2>/dev/null || true
	@find sdk_build -name "CMakeCache.txt" -type f -delete 2>/dev/null || true
	@find sdk_build -name "CMakeFiles" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "=== Full distclean - all generated files removed ==="
