# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
CROSS ?= arm-none-eabi-
CPU_VARIANT=-mthumb -mcpu=cortex-m3
include $(SRC)/cpu/arm/compiler.mk

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk

# Defining USE_STDPERIPH_DRIVER causes the CMSIS driver include files to
# include stm32l1xx_conf.h
DEFS += -DUSE_STDPERIPH_DRIVER

DICTIONARY=ROM
DICTSIZE=0x2000

include $(SRC)/cforth/embed/targets.mk

STMLIB ?= /usr/local/stm32l1xx_periph-lib

CFLAGS += -m32 -march=i386

TCFLAGS += -Os

# Omit unreachable functions from output

TCFLAGS += -ffunction-sections -fdata-sections
TLFLAGS += --gc-sections

# VPATH += $(SRC)/cpu/arm
VPATH += $(SRC)/lib
VPATH += $(SRC)/platform/arm-stm32l1xx-discovery
VPATH += $(STMLIB)/Libraries/STM32L1xx_StdPeriph_Driver/src

# This directory, including board information
INCS += -I$(SRC)/platform/arm-stm32l1xx-discovery

# Include files for CPU cores
INCS += -I$(STMLIB)/Libraries/CMSIS/Include

# Contains stm32l1xx.h defining the hardware registers
INCS += -I$(STMLIB)/Libraries/CMSIS/Device/ST/STM32L1xx/Include

# Include files defining standard peripheral driver APIs for various devices
INCS += -I$(STMLIB)/Libraries/STM32L1xx_StdPeriph_Driver/inc


# Platform-specific object files for low-level startup and platform I/O

# CLKCONFIG = -1v8-msi2000
CLKCONFIG ?= -1v8-hsi16m-16m

FIRST_OBJ = tstartup_stm32l1xx_mdp.o

PLAT_OBJS += tsystem_stm32l1xx$(CLKCONFIG).o
PLAT_OBJS += tstm32l1xx_usart.o tstm32l1xx_rcc.o tstm32l1xx_gpio.o
PLAT_OBJS += tstm32l1xx_i2c.o tmisc.o tsystick.o
PLAT_OBJS += ttmain.o tconsoleio.o mallocembed.o

EXTEND_OBJS ?= ti2c.o

PLAT_OBJS += $(EXTEND_OBJS)

# Object files for the Forth system and application-specific extensions

FORTH_OBJS = tembed.o textend.o


# Recipe for linking the final image

LDSCRIPT = $(SRC)/platform/arm-stm32l1xx-discovery/stm32_flash.ld

app.elf: $(FIRST_OBJ) $(PLAT_OBJS) $(FORTH_OBJS)
	@echo Linking $@ ... 
	$(TLD) -o $@  $(TLFLAGS) -T$(LDSCRIPT) \
	   $(FIRST_OBJ) $(PLAT_OBJS) $(FORTH_OBJS) \
	   $(LIBDIRS) -lgcc


# This rule extracts the executable bits from an ELF file, yielding raw binary.

%.img: %.elf
	@$(TOBJCOPY) -O binary $< $@
	date  "+%F %H:%M" >>$@
	@ls -l $@

# Override the default .dump rule to include the interrupt vector table

%.dump: %.elf
	@$(TOBJDUMP) -s -j .isr_vector $< >$@
	@$(TOBJDUMP) --disassemble $< >>$@

# This rule builds a date stamp object that you can include in the image
# if you wish.

.PHONY: date.o

date.o:
	echo 'const char version[] = "'`cat version`'" ;' >date.c
	echo 'const char build_date[] = "'`date  --iso-8601=minutes`'" ;' >>date.c
	echo "const unsigned char sw_version[] = {" `cut -d . --output-delimiter=, -f 1,2 version` "};" >>date.c
	$(TCC) -c date.c -o $@

EXTRA_CLEAN += *.elf *.dump *.nm *.img date.c $(FORTH_OBJS) $(PLAT_OBJS)
