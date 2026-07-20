# ============================================================================
# cForth ESP32 Component - CMakeLists.txt
# Integrates host-tools, cross-compilation and dictionary generation for IDF 5.5.1
# Location: src/app/esp32-extra/CMakeLists.txt
# ============================================================================

cmake_minimum_required(VERSION 3.5)

# ----------------------------------------------------------------------------
# 1. CONFIGURATION
# ----------------------------------------------------------------------------
set(COMPONENT_NAME cforth_esp32)

# Project root paths
set(CFORTH_ROOT ${CMAKE_SOURCE_DIR})
set(CFORTH_SRC ${CFORTH_ROOT}/src/cforth)
set(CFORTH_EXTRA ${CFORTH_ROOT}/src/app/esp32-extra)
set(CFORTH_LIB ${CFORTH_ROOT}/src/lib)
set(HOST_TOOLS_DIR ${CMAKE_BINARY_DIR}/host_tools)
set(CROSS_OBJ_DIR ${CMAKE_BINARY_DIR}/cross_objs)

# Compiler flags for ESP32
set(ESP32_CFLAGS 
    "-DBITS32" 
    "-DNOSYSCALL"
    "-DFLOATING"
    "-DMORE_FP"
    "-mlongcalls"
    "-ffunction-sections" 
    "-fdata-sections"
    "-Wno-error=unused-function"
    "-Wno-implicit-function-declaration"
)

# Include directories for cross-compilation
set(ESP32_INCLUDES
    ${CFORTH_SRC}
    ${CFORTH_EXTRA}
    ${CMAKE_BINARY_DIR}          # For prims.h, vars.h, init.x
    ${CFORTH_LIB}
)

# ----------------------------------------------------------------------------
# 2. GENERATION OF COMMON HEADERS (prims.h, vars.h, init.x)
# ----------------------------------------------------------------------------
add_custom_command(
    OUTPUT 
        ${CMAKE_BINARY_DIR}/prims.h
        ${CMAKE_BINARY_DIR}/vars.h
        ${CMAKE_BINARY_DIR}/init.x
    COMMAND 
        ${CMAKE_COMMAND} -E make_directory ${HOST_TOOLS_DIR}
    COMMAND
        cd ${HOST_TOOLS_DIR} && 
        gcc -E -C -DMAKEPRIMS -DBITS32 -DFLOATING -DMORE_FP -DNOSYSCALL 
            -I${CFORTH_SRC} -I${CFORTH_EXTRA} -I${CFORTH_LIB}
            ${CFORTH_SRC}/forth.c > forth.ip
    COMMAND
        cd ${HOST_TOOLS_DIR} &&
        gcc -o makename ${CFORTH_SRC}/makename.c
    COMMAND
        cd ${HOST_TOOLS_DIR} && ./makename forth.ip
    COMMAND
        ${CMAKE_COMMAND} -E copy 
            ${HOST_TOOLS_DIR}/prims.h 
            ${HOST_TOOLS_DIR}/vars.h 
            ${HOST_TOOLS_DIR}/init.x 
            ${CMAKE_BINARY_DIR}/
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Generate prims.h, vars.h, init.x from forth.c"
)

# ----------------------------------------------------------------------------
# 3. BUILDING HOST TOOLS (meta, forth) ON THE BUILD HOST
# ----------------------------------------------------------------------------
# First the host object files
set(HOST_SRCS
    ${CFORTH_SRC}/meta.c
    ${CFORTH_SRC}/compiler.c
    ${CFORTH_SRC}/io.c
    ${CFORTH_SRC}/dictfile.c
    ${CFORTH_SRC}/mallocl.c
    ${CFORTH_SRC}/lineedit.c
    ${CFORTH_SRC}/getc-kbd.c
    ${CFORTH_SRC}/main.c
    ${CFORTH_SRC}/nullbi.c
    ${CFORTH_SRC}/linux-kbd.c
    ${CFORTH_SRC}/forth.c
    ${CFORTH_SRC}/syscall.c
    ${CFORTH_SRC}/floatops.c
    ${CFORTH_SRC}/extend.c
)

foreach(src ${HOST_SRCS})
    get_filename_component(basename ${src} NAME_WE)
    set(obj ${HOST_TOOLS_DIR}/${basename}.o)
    
    add_custom_command(
        OUTPUT ${obj}
        COMMAND gcc -m32 -DBITS32 -DNOSYSCALL -DFLOATING -DMORE_FP
                    -I${CFORTH_SRC} -I${CFORTH_EXTRA} -I${CFORTH_LIB} -I${CMAKE_BINARY_DIR}
                    -c ${src} -o ${obj}
        DEPENDS ${CMAKE_BINARY_DIR}/prims.h
        COMMENT "Building host object: ${basename}.o"
    )
    list(APPEND HOST_OBJS ${obj})
endforeach()

# Host binary: meta
add_custom_command(
    OUTPUT ${HOST_TOOLS_DIR}/meta
    COMMAND gcc -m32 ${HOST_OBJS} -o ${HOST_TOOLS_DIR}/meta -lm
    DEPENDS ${HOST_OBJS}
    COMMENT "Building host tool: meta"
)

# Host binary: forth (different object set)
set(FORTH_HOST_OBJS)
foreach(basename main io nullbi dictfile mallocl lineedit linux-kbd forth compiler syscall floatops extend)
    list(APPEND FORTH_HOST_OBJS ${HOST_TOOLS_DIR}/${basename}.o)
endforeach()

add_custom_command(
    OUTPUT ${HOST_TOOLS_DIR}/forth
    COMMAND gcc -m32 ${FORTH_HOST_OBJS} -o ${HOST_TOOLS_DIR}/forth -lm
    DEPENDS ${FORTH_HOST_OBJS}
    COMMENT "Building host interpreter: forth"
)

# ----------------------------------------------------------------------------
# 4. DICTIONARY GENERATION (kernel.dic, forth.dic) WITH HOST TOOLS
# ----------------------------------------------------------------------------
add_custom_command(
    OUTPUT ${HOST_TOOLS_DIR}/kernel.dic
    COMMAND cd ${HOST_TOOLS_DIR} && ./meta ${CFORTH_SRC}/interp.fth kernel.dic
    DEPENDS ${HOST_TOOLS_DIR}/meta ${CMAKE_BINARY_DIR}/init.x
    COMMENT "Generate kernel.dic"
)

add_custom_command(
    OUTPUT ${HOST_TOOLS_DIR}/forth.dic
    COMMAND cd ${HOST_TOOLS_DIR} && ./forth kernel.dic ${CFORTH_SRC}/load.fth
    DEPENDS ${HOST_TOOLS_DIR}/forth ${HOST_TOOLS_DIR}/kernel.dic
    COMMENT "Generate forth.dic"
)

# ----------------------------------------------------------------------------
# 5. CROSS-COMPILATION FOR ESP32 (t*.o FILES)
# ----------------------------------------------------------------------------
set(CROSS_SRCS
    ${CFORTH_SRC}/main.c      -> tmain.o
    ${CFORTH_SRC}/forth.c     -> tforth.o
    ${CFORTH_SRC}/compiler.c  -> tcompiler.o
    ${CFORTH_SRC}/io.c        -> tio.o
    ${CFORTH_SRC}/dictfile.c  -> tdictfile.o
    ${CFORTH_SRC}/mallocl.c   -> tmallocl.o
    ${CFORTH_SRC}/lineedit.c  -> tlineedit.o
    ${CFORTH_SRC}/syscall.c   -> tsyscall.o
    ${CFORTH_SRC}/floatops.c  -> tfloatops.o
    ${CFORTH_SRC}/extend.c    -> textend.o
    ${CFORTH_EXTRA}/syswrap.c -> tsyswrap.o
    ${CFORTH_EXTRA}/tmain.c   -> ttmain.o
)

foreach(src_target ${CROSS_SRCS})
    # Parse "source.c -> target.o"
    string(REPLACE " -> " ";" src_target_list ${src_target})
    list(GET src_target_list 0 src_file)
    list(GET src_target_list 1 target_name)
    
    set(target_path ${CROSS_OBJ_DIR}/${target_name})
    
    add_custom_command(
        OUTPUT ${target_path}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CROSS_OBJ_DIR}
        COMMAND ${CMAKE_C_COMPILER} ${ESP32_CFLAGS}
                -I${CFORTH_SRC} -I${CFORTH_EXTRA} -I${CFORTH_LIB} -I${CMAKE_BINARY_DIR}
                -c ${src_file} -o ${target_path}
        DEPENDS ${src_file} ${CMAKE_BINARY_DIR}/prims.h
        COMMENT "Cross-compiling: ${target_name}"
    )
    
    list(APPEND ALL_CROSS_OBJS ${target_path})
endforeach()

# ----------------------------------------------------------------------------
# 6. GENERATION OF app.dic FOR ESP32
# ----------------------------------------------------------------------------
# First create an FTH script that loads the t*.o files
add_custom_command(
    OUTPUT ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "\\ makeapp.fth - Load ESP32 objects and generate app.dic" > ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tmain.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tforth.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tcompiler.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tio.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tdictfile.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tmallocl.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tlineedit.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tsyscall.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tfloatops.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"textend.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"tsyswrap.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"ttmain.o\\" \\$add-obj" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "s\\"app.dic\\" \\$save-dict" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMAND echo "bye" >> ${CROSS_OBJ_DIR}/makeapp.fth
    COMMENT "Generate makeapp.fth script"
)

# Generate app.dic with the host forth tool
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/app.dic
    COMMAND cd ${CROSS_OBJ_DIR} && ${HOST_TOOLS_DIR}/forth ${HOST_TOOLS_DIR}/forth.dic makeapp.fth
    DEPENDS ${HOST_TOOLS_DIR}/forth ${HOST_TOOLS_DIR}/forth.dic ${ALL_CROSS_OBJS} ${CROSS_OBJ_DIR}/makeapp.fth
    COMMENT "Generate app.dic for ESP32"
)

# ----------------------------------------------------------------------------
# 7. REGISTER ESP32 COMPONENT WITH EMBEDDED DICTIONARIES
# ----------------------------------------------------------------------------
idf_component_register(
    SRCS
        interface.c        # contains app_main()
        syswrap.c
        tmain.c            # ttmain.o compatibility
        
    INCLUDE_DIRS
        .
        ${CFORTH_SRC}
        ${CFORTH_EXTRA}
        ${CMAKE_BINARY_DIR}       # prims.h, vars.h, init.x
        
    REQUIRES
        esp_timer
        esp_common
        nvs_flash
        driver
        soc
        
    EMBED_TXTFILES
        ${HOST_TOOLS_DIR}/kernel.dic
        ${CMAKE_BINARY_DIR}/app.dic
        ${HOST_TOOLS_DIR}/forth.dic
        
    PRIV_REQUIRES
        esp_timer
        
    # Link the cross-compiled objects
    LINK_OPTIONS
        -Wl,--start-group
        ${ALL_CROSS_OBJS}
        -Wl,--end-group
)

# Extra compile definitions
target_compile_definitions(${COMPONENT_LIB} 
    PRIVATE 
        BITS32 
        NOSYSCALL
        FLOATING
        MORE_FP
        IDF_VERSION=\"5.5.1\"
)

# ----------------------------------------------------------------------------
# 8. CUSTOM TARGETS FOR MANUAL CONTROL
# ----------------------------------------------------------------------------
add_custom_target(cforth_host_tools ALL
    DEPENDS 
        ${HOST_TOOLS_DIR}/meta
        ${HOST_TOOLS_DIR}/forth
        ${HOST_TOOLS_DIR}/kernel.dic
        ${HOST_TOOLS_DIR}/forth.dic
    COMMENT "Build all host tools and dictionaries"
)

add_custom_target(cforth_cross_objs ALL
    DEPENDS ${ALL_CROSS_OBJS}
    COMMENT "Cross-compile ESP32 objects (t*.o)"
)

add_custom_target(cforth_app_dic ALL
    DEPENDS ${CMAKE_BINARY_DIR}/app.dic
    COMMENT "Generate ESP32 app.dic"
)

# ----------------------------------------------------------------------------
# 9. OUTPUT CONFIGURATION
# ----------------------------------------------------------------------------
# Ensure generated files are available
set_directory_properties(PROPERTIES
    ADDITIONAL_MAKE_CLEAN_FILES 
    "${HOST_TOOLS_DIR};${CROSS_OBJ_DIR};${CMAKE_BINARY_DIR}/prims.h;${CMAKE_BINARY_DIR}/vars.h;${CMAKE_BINARY_DIR}/init.x"
)

message(STATUS "cForth ESP32 component configured for IDF 5.5.1")
message(STATUS "  Host tools dir: ${HOST_TOOLS_DIR}")
message(STATUS "  Cross objects dir: ${CROSS_OBJ_DIR}")
message(STATUS "  ESP32 dictionaries: kernel.dic, app.dic, forth.dic")

# ============================================================================
# END OF CMakeLists.txt
# ============================================================================
