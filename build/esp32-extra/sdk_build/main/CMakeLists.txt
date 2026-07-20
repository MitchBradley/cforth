cmake_minimum_required(VERSION 3.16)

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
    REQUIRES
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
    PRIV_REQUIRES
        esp_adc
        joltwallet__littlefs
)

target_compile_options(${COMPONENT_LIB} PRIVATE
    "-DBITS32"
    "-DFLOATING"
    "-DMORE_FP"
    "-DNOSYSCALL"
    "-DTARGET"
    "-DESP32"
)

target_compile_options(${COMPONENT_LIB} INTERFACE
    "$<$<COMPILE_LANGUAGE:C>:-mlongcalls>"
    "$<$<COMPILE_LANGUAGE:C>:-mtext-section-literals>"
    "$<$<COMPILE_LANGUAGE:C>:-ffunction-sections>"
    "$<$<COMPILE_LANGUAGE:C>:-fdata-sections>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-error=unused-variable>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-error=unused-function>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-error=implicit-function-declaration>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-error=cast-function-type>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-unused-function>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-unused-variable>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-unused-but-set-variable>"
    "$<$<COMPILE_LANGUAGE:C>:-Wno-cast-function-type>"
)

target_link_libraries(${COMPONENT_LIB} INTERFACE 
    "${CMAKE_CURRENT_SOURCE_DIR}/../../libforth.a"
)

target_link_options(${COMPONENT_LIB} INTERFACE
    "-Wl,--whole-archive"
    "${CMAKE_CURRENT_SOURCE_DIR}/../../libforth.a"
    "-Wl,--no-whole-archive"
    "-u" "app_main"
)

target_link_options(${COMPONENT_LIB} INTERFACE
    "-mlongcalls"
    "-mtext-section-literals"
    "-Wl,--gc-sections"
    "-Wl,--check-sections"
    "-nostdlib"
)

# --- FreeRTOS settings for Forth ---
set(FreeRTOS_HEAP_SCHEME 4 CACHE STRING "FreeRTOS heap scheme")
