cmake_minimum_required(VERSION 3.16)

# Chip detection - set automatically by IDF
if(CONFIG_IDF_TARGET_ESP32C3)
    message("🔧 Building for ESP32-C3")
    set(CHIP_DEFINES "-DESP32_C3")
    set(CHIP_CFLAGS "")           # No special compiler flags for C3
    set(CHIP_LDFLAGS "")           # No special linker flags for C3
else()
    message("🔧 Building for ESP32")
    set(CHIP_DEFINES "-DESP32")
    set(CHIP_CFLAGS "-mlongcalls -mtext-section-literals")  # Xtensa compiler flags
    set(CHIP_LDFLAGS "-mlongcalls -mtext-section-literals")  # Xtensa linker flags
endif()

idf_component_register(
    SRCS
        "interface.c"
        "../../../../src/app/esp32-extra/forth_esp32.c"
        "../../../../src/app/esp32-extra/tmain.c"
        "../../../../src/app/esp32-extra/consio.c"
        "../../../../src/app/esp32-extra/fileio_esp32.c"
        "../../../../src/app/esp32-extra/fileio.c"
        "../../../../src/app/esp32-extra/extend.c"
        "../../../../src/cforth/embed/startapp.c"
        "../../tdate.c"
    INCLUDE_DIRS
        "."
        "../../../../src/app/esp32-extra"
        "../../../../src/cforth"
        "../../../../src/cforth/embed"
        "../../../../src/lib"
    PRIV_REQUIRES
        freertos
        esp_system
        esp_common
        esp_rom
        soc
        hal
        heap
        driver
        esp_driver_uart
        esp_driver_gpio
        esp_driver_spi
        esp_driver_i2c
        esp_adc
        esp_timer
        nvs_flash
        spi_flash
        wear_levelling
        fatfs
        esp_wifi
        esp_netif
        esp_event
        lwip
        esp_http_client
        newlib
        log
        pthread
        esp_hw_support
        esp_pm
        joltwallet__littlefs
)

# Compiler flags - PRIVATE (for this component only)
target_compile_options(${COMPONENT_LIB} PRIVATE
    "-DBITS32"
    "-DFLOATING"
    "-DMORE_FP"
    "-DNOSYSCALL"
    "-DTARGET"
    ${CHIP_DEFINES}
)

# Compiler flags - INTERFACE (for dependent components)
target_compile_options(${COMPONENT_LIB} INTERFACE
    "$<$<COMPILE_LANGUAGE:C>:-ffunction-sections>"
    "$<$<COMPILE_LANGUAGE:C>:-fdata-sections>"
    "$<$<COMPILE_LANGUAGE:C>:${CHIP_CFLAGS}>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-error=unused-variable>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-error=unused-function>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-error=implicit-function-declaration>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-error=cast-function-type>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-unused-function>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-unused-variable>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-unused-but-set-variable>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-cast-function-type>"
)

# Library linking
target_link_libraries(${COMPONENT_LIB} INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/../../libforth.a"
)

# Linker flags - with whole-archive for libforth.a
target_link_options(${COMPONENT_LIB} INTERFACE
    "-Wl,--whole-archive"
    "${CMAKE_CURRENT_SOURCE_DIR}/../../libforth.a"
    "-Wl,--no-whole-archive"
    "-u" "app_main"
)

# General linker flags - chip specific
target_link_options(${COMPONENT_LIB} INTERFACE
    ${CHIP_LDFLAGS}
    "-Wl,--gc-sections"
    "-Wl,--check-sections"
    "-nostdlib"
)

# Floating point
target_link_options(${COMPONENT_LIB} INTERFACE
    "LINKER:-u,_printf_float"
    "LINKER:-u,_scanf_float"
    "LINKER:-u,__trunctfdf2"
    "-lm"
)

# --- Configure FreeRTOS settings for Forth ---
set(FreeRTOS_HEAP_SCHEME 4 CACHE STRING "FreeRTOS heap scheme")
