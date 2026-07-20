# ============================================================================
# sdk.mk - ESP-IDF Installation Helper (Simple Linear Approach)
# ============================================================================

THIS_FILE := $(lastword $(MAKEFILE_LIST))
MAKEFILE_DIR := $(abspath $(dir $(THIS_FILE)))
CFORTH_ROOT := $(abspath $(MAKEFILE_DIR)/../../../..)
BUILD_DIR := $(abspath .)

ESP_IDF_VERSION := v5.5.1
ESP_IDF_INSTALL_PATH := $(CFORTH_ROOT)/esp-idf-$(ESP_IDF_VERSION)
LITTLEFS_DIR := $(BUILD_DIR)/sdk_build/managed_components/joltwallet__littlefs

# ============================================================================
# STEP 1: DOWNLOAD EVERYTHING
# ============================================================================
.PHONY: download-all
download-all:
	@echo "=== Step 1: Downloading all components ==="
	@echo "1a. Downloading ESP-IDF $(ESP_IDF_VERSION)..."
	@if [ ! -d "$(ESP_IDF_INSTALL_PATH)" ]; then \
		git clone --recursive --depth=1 --branch $(ESP_IDF_VERSION) \
			https://github.com/espressif/esp-idf.git $(ESP_IDF_INSTALL_PATH); \
		if [ $$? -ne 0 ]; then \
			echo "ERROR: ESP-IDF download failed"; \
			exit 1; \
		fi \
	else \
		echo "  ESP-IDF already exists"; \
	fi
	@echo "1b. Downloading LittleFS component..."
	@if [ ! -d "$(LITTLEFS_DIR)" ]; then \
		mkdir -p $(BUILD_DIR)/sdk_build/managed_components; \
		cd $(BUILD_DIR)/sdk_build/managed_components && \
		git clone --recursive https://github.com/joltwallet/esp_littlefs.git joltwallet__littlefs; \
		if [ $$? -ne 0 ]; then \
			echo "ERROR: LittleFS download failed"; \
			exit 1; \
		fi \
	else \
		echo "  LittleFS already exists"; \
		cd $(LITTLEFS_DIR) && git submodule update --init --recursive 2>/dev/null || true; \
	fi
	@echo "=== Download complete ==="

# ============================================================================
# STEP 2: CHECK IF EVERYTHING IS PRESENT
# ============================================================================
.PHONY: check-all
check-all:
	@echo "=== Step 2: Checking all components ==="
	@ERRORS=0
	@if [ -d "$(ESP_IDF_INSTALL_PATH)" ]; then \
		echo "  [OK] ESP-IDF: $(ESP_IDF_INSTALL_PATH)"; \
	else \
		echo "  [FAIL] ESP-IDF not found"; \
		ERRORS=$$((ERRORS + 1)); \
	fi
	@if [ -f "$(ESP_IDF_INSTALL_PATH)/tools/idf.py" ]; then \
		echo "  [OK] idf.py found"; \
	else \
		echo "  [FAIL] idf.py not found"; \
		ERRORS=$$((ERRORS + 1)); \
	fi
	@if [ -d "$(LITTLEFS_DIR)" ]; then \
		echo "  [OK] LittleFS: $(LITTLEFS_DIR)"; \
	else \
		echo "  [FAIL] LittleFS not found"; \
		ERRORS=$$((ERRORS + 1)); \
	fi
	@if [ -f "$(LITTLEFS_DIR)/src/littlefs/lfs.h" ]; then \
		echo "  [OK] littlefs/lfs.h found"; \
	else \
		echo "  [FAIL] littlefs/lfs.h not found (submodule missing)"; \
		ERRORS=$$((ERRORS + 1)); \
	fi
	@if [ "$${ERRORS:-0}" -ne 0 ] 2>/dev/null; then \
		echo "ERROR: $$ERRORS component(s) missing"; \
		exit 1; \
	else \
		echo "=== All components OK ==="; \
	fi

# ============================================================================
# STEP 3: EXPORT ENVIRONMENT (skip if already exported)
# ============================================================================
.PHONY: export-env
export-env:
	@echo "=== Step 3: Exporting environment ==="
	@if [ -n "$${IDF_PATH}" ]; then \
		echo "  ESP-IDF already exported: $${IDF_PATH}"; \
	elif [ -f "$(CFORTH_ROOT)/cforth/src/app/esp32-extra/export551.sh" ]; then \
		echo "  Running export551.sh..."; \
		cd $(CFORTH_ROOT)/cforth/src/app/esp32-extra && ./export551.sh; \
		if [ $$? -ne 0 ]; then \
			echo "ERROR: export551.sh failed"; \
			exit 1; \
		fi; \
		echo ""; \
		echo "=== ESP-IDF ENVIRONMENT EXPORTED ==="; \
		echo "Close this terminal and ignore the following errors."; \
		echo ""; \
		exit 1; \
	else \
		echo "ERROR: export551.sh not found at $(CFORTH_ROOT)/cforth/src/app/esp32-extra/"; \
		echo "Please run: make sdk from the esp32-extra directory"; \
		exit 1; \
	fi

# ============================================================================
# STEP 4: INSTALL EVERYTHING
# ============================================================================
.PHONY: install-all
install-all:
	@echo "=== Step 4: Installing all components ==="
	@echo "4a. Installing toolchains..."
	@cd $(ESP_IDF_INSTALL_PATH) && ./install.sh esp32
	@cd $(ESP_IDF_INSTALL_PATH) && ./install.sh esp32c3
	@echo "4b. Updating submodules..."
	@cd $(ESP_IDF_INSTALL_PATH) && git submodule update --init --recursive
	@echo "4c. Setting Component Manager to disabled..."
	@export IDF_COMPONENT_MANAGER=0
	@echo "=== Installation complete ==="

# ============================================================================
# STEP 5: VALIDATE EVERYTHING
# ============================================================================
.PHONY: validate-all
validate-all:
	@echo "=== Step 5: Validating installation ==="
	@ERRORS=0
	@if [ -f "$(ESP_IDF_INSTALL_PATH)/tools/idf.py" ]; then \
		echo "  [OK] idf.py exists"; \
	else \
		echo "  [FAIL] idf.py missing"; \
		ERRORS=$$((ERRORS + 1)); \
	fi
	@TOOLCHAIN=$$(find $(HOME)/.espressif/tools/xtensa-esp-elf -name xtensa-esp32-elf-gcc 2>/dev/null | head -1); \
	if [ -n "$$TOOLCHAIN" ]; then \
		echo "  [OK] Xtensa toolchain: $$TOOLCHAIN"; \
	else \
		echo "  [FAIL] Xtensa toolchain not found"; \
		ERRORS=$$((ERRORS + 1)); \
	fi
	@TOOLCHAIN=$$(find $(HOME)/.espressif/tools/riscv32-esp-elf -name riscv32-esp-elf-gcc 2>/dev/null | head -1); \
	if [ -n "$$TOOLCHAIN" ]; then \
		echo "  [OK] RISC-V toolchain: $$TOOLCHAIN"; \
	else \
		echo "  [FAIL] RISC-V toolchain not found"; \
		ERRORS=$$((ERRORS + 1)); \
	fi
	@if [ -f "$(LITTLEFS_DIR)/src/littlefs/lfs.h" ]; then \
		echo "  [OK] LittleFS ready"; \
	else \
		echo "  [FAIL] LittleFS not ready"; \
		ERRORS=$$((ERRORS + 1)); \
	fi
	@if [ "$${ERRORS:-0}" -ne 0 ] 2>/dev/null; then \
		echo "ERROR: $$ERRORS validation(s) failed"; \
		exit 1; \
	else \
		echo "=== All validations passed ==="; \
	fi

# ============================================================================
# MAIN TARGETS
# ============================================================================
.PHONY: install-sdk
install-sdk:
	@$(MAKE) -f $(THIS_FILE) download-all
	@$(MAKE) -f $(THIS_FILE) check-all
	@$(MAKE) -f $(THIS_FILE) export-env
	@$(MAKE) -f $(THIS_FILE) install-all
	@$(MAKE) -f $(THIS_FILE) validate-all

.PHONY: check-idf
check-idf:
	@if [ -z "$${IDF_PATH}" ]; then \
		echo "ESP-IDF not activated!"; \
		echo "Run: 'make sdk' first, then open a new shell"; \
		exit 1; \
	else \
		echo "ESP-IDF active: $${IDF_PATH}"; \
	fi

.PHONY: clean-sdk
clean-sdk:
	@echo "Cleaning ESP-IDF SDK..."
	@rm -rf $(ESP_IDF_INSTALL_PATH)
	@rm -rf $(HOME)/.espressif
	@echo "SDK completely removed"

# ============================================================================
# FIX: Update LittleFS submodules if lfs.h is missing
# ============================================================================
.PHONY: fix-littlefs
fix-littlefs:
	@echo "Fixing LittleFS submodules..."
	@if [ -d "$(LITTLEFS_DIR)" ]; then \
		cd $(LITTLEFS_DIR) && git submodule update --init --recursive; \
		if [ -f "$(LITTLEFS_DIR)/src/littlefs/lfs.h" ]; then \
			echo "  [OK] LittleFS fixed"; \
		else \
			echo "  [FAIL] Could not fix LittleFS"; \
			exit 1; \
		fi \
	else \
		echo "ERROR: LittleFS not found"; \
		exit 1; \
	fi

