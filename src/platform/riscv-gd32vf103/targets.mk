# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
include $(SRC)/cpu/riscv/compiler.mk

DEFS += -DUSE_STDPERIPH_DRIVER
DEFS += -DHXTAL_VALUE=8000000U

DICTIONARY = ROM

ifneq ($(findstring FLOATING,$(CONFIG)),)
	DICTSIZE ?= 0x3000
else
	DICTSIZE ?= 0x4000
	TLFLAGS += -lm
endif

CFLAGS += -m32 -march=i386

TCFLAGS += -Os

# Omit unreachable functions from output

TCFLAGS += -ffunction-sections -fdata-sections
TLFLAGS += -Wl,--gc-sections
TLFLAGS += -Wl,--defsym -Wl,__stack_size=0x80

VPATH += $(SRC)/platform/$(MYNAME)
VPATH += $(SRC)/lib
VPATH += $(SRC)/cforth
VPATH += $(GD32V_LIB)/Firmware/GD32VF103_standard_peripheral/Source
VPATH += $(GD32V_LIB)/Firmware/GD32VF103_standard_peripheral
VPATH += $(GD32V_LIB)/Firmware/RISCV/stubs
VPATH += $(GD32V_LIB)/Firmware/RISCV/drivers
VPATH += $(GD32V_LIB)/Firmware/RISCV/env_Eclipse
VPATH += $(GD32V_LIB)/Template

# This directory, including board information
INCS += -I$(SRC)/platform/$(MYNAME)

INCS += -I$(GD32V_LIB)/Firmware/GD32VF103_standard_peripheral/Include
INCS += -I$(GD32V_LIB)/Firmware/GD32VF103_standard_peripheral
INCS += -I$(GD32V_LIB)/Firmware/RISCV/drivers
INCS += -I$(GD32V_LIB)/Template

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk

# Platform-specific object files for low-level startup and platform I/O

PLAT_OBJS += tsystem_gd32vf103.o
PLAT_OBJS += tgd32vf103_usart.o
PLAT_OBJS += tgd32vf103_rcu.o
PLAT_OBJS += tgd32vf103_gpio.o
PLAT_OBJS += tsystick.o
PLAT_OBJS += twrite.o

PLAT_OBJS += tn200_func.o
PLAT_OBJS += tstart.o
PLAT_OBJS += tentry.o
PLAT_OBJS += thandlers.o
PLAT_OBJS += tinit.o

PLAT_OBJS += ttmain.o
PLAT_OBJS += mallocembed.o
PLAT_OBJS += tconsoleio.o
PLAT_OBJS += tgpio.o

ttmain.o: vars.h

# EXTEND_OBJS ?= ti2c.o

PLAT_OBJS += $(EXTEND_OBJS)

# Object files for the Forth system and application-specific extensions

FORTH_OBJS = tembed.o textend.o

# Recipe for linking the final image

# 16k Flash, 6k RAM -- too small
#LDSCRIPT = $(GD32V_LIB)/Firmware/RISCV/env_Eclipse/GD32VF103x4.lds
# 32k Flash, 10k RAM -- too small
#LDSCRIPT = $(GD32V_LIB)/Firmware/RISCV/env_Eclipse/GD32VF103x6.lds
# 64k Flash, 20k RAM -- Sipeed Longan Nano Lite
#LDSCRIPT = $(GD32V_LIB)/Firmware/RISCV/env_Eclipse/GD32VF103x8.lds
# 128k Flash, 32k RAM -- GD32VF103V-EVAL, Sipeed Longan Nano,
# Wio Lite RISC-V, Polos Alef
LDSCRIPT = $(GD32V_LIB)/Firmware/RISCV/env_Eclipse/GD32VF103xB.lds

LDCMD := $(TCC) $(CPU_VARIANT) $(TLFLAGS) \
	 -T$(LDSCRIPT) $(PLAT_OBJS) $(FORTH_OBJS) \
	 -nostartfiles -specs=nosys.specs

app.elf: $(PLAT_OBJS) $(FORTH_OBJS)
	@echo Linking $@ ...
	$(LDCMD) -o $@


# This rule extracts the executable bits from an ELF file, yielding raw binary.

%.img: %.elf
	@$(TOBJCOPY) -O binary $< $@
	date  "+%F %H:%M" >>$@
	@ls -l $@

# Override the default .dump rule to include the interrupt vector table

%.dump: %.elf
	@$(TOBJDUMP) -s -j .init $< >$@
	@$(TOBJDUMP) --disassemble $< >>$@

# This rule builds a date stamp object that you can include in the image
# if you wish.

EXTRA_CLEAN += *.bin *.elf *.dump *.nm *.img date.c $(FORTH_OBJS) $(PLAT_OBJS)

include $(SRC)/cforth/embed/targets.mk
