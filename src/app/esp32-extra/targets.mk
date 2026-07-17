# targets.mk

# PATHS
TARGETS_MK_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ROOT_DIR := $(abspath $(TARGETS_MK_DIR)/../../..)

SRC_CFORTH := $(ROOT_DIR)/src/cforth
SRC_EXTRA  := $(ROOT_DIR)/src/app/esp32-extra
SRC_LIB    := $(ROOT_DIR)/src/lib

V ?= 0
ifeq ($(V),1)
    Q =
else
    Q = @
endif

# HOST TOOLCHAIN
HOST_CC := gcc
HOST_CFLAGS := -DBITS32 -I. -I../../src/cforth -I../../src/app/esp32-extra -I../../src/lib
HOST_CFLAGS += -m32 -DFLOATING -DMORE_FP -DNOSYSCALL -fno-common
HOST_LDFLAGS := -lm -m32

# GENERATED HEADERS
GENERATED_HEADERS := prims.h vars.h init.x

# OBJECT FILES - extend.o is nodig voor ccalls!
META_OBJS := meta.o compiler.o io.o dictfile.o mallocl.o lineedit.o getc-kbd.o
FORTH_OBJS := main.o io.o nullbi.o dictfile.o mallocl.o lineedit.o linux-kbd.o \
              forth.o compiler.o syscall.o floatops.o extend.o

.PHONY: pipeline

# GENERATE HEADERS
forth.ip: $(SRC_CFORTH)/forth.c
	$(HOST_CC) -E -C -DMAKEPRIMS $(HOST_CFLAGS) $< > $@

makename: $(SRC_CFORTH)/makename.c
	$(HOST_CC) -o $@ $<

$(GENERATED_HEADERS): forth.ip makename
	./makename forth.ip
	@touch $(GENERATED_HEADERS)

# BUILD RULES
%.o: $(SRC_CFORTH)/%.c $(GENERATED_HEADERS)
	$(Q)$(HOST_CC) $(HOST_CFLAGS) -c $< -o $@

# TOOLS
meta: $(META_OBJS)
	$(Q)$(HOST_CC) $(HOST_CFLAGS) $(META_OBJS) -o meta $(HOST_LDFLAGS)

forth: $(FORTH_OBJS)
	$(Q)$(HOST_CC) $(HOST_CFLAGS) $(FORTH_OBJS) -o forth $(HOST_LDFLAGS)

makebi: $(SRC_CFORTH)/embed/makebi.c
	$(HOST_CC) -DBITS32 -I. -I$(SRC_CFORTH) -I$(SRC_EXTRA) -I$(SRC_LIB) \
		-m32 -o makebi $(SRC_CFORTH)/embed/makebi.c $(HOST_LDFLAGS)

# DICTIONARIES
kernel.dic: $(SRC_CFORTH)/interp.fth meta $(GENERATED_HEADERS)
	./meta $< kernel.dic

forth.dic: $(SRC_CFORTH)/load.fth forth kernel.dic
	./forth kernel.dic $(SRC_CFORTH)/load.fth

# PIPELINE
pipeline: kernel.dic forth.dic makebi
