# Makefile fragment for the final target application

SRC=$(TOPDIR)/src

# Target compiler definitions
CROSS ?= arm-none-eabi-
CPU_VARIANT=-mthumb -mcpu=cortex-m3
include $(SRC)/cpu/arm/compiler.mk

# Select the chip variant
# MD is Medium Density, for 64K and 128K FLASH sizes
DEFS += -DSTM32F10X_MD

# Defining USE_STDPERIPH_DRIVER causes the CMSIS driver include files to
# include stm32l1xx_conf.h
DEFS += -DUSE_STDPERIPH_DRIVER

DICTIONARY=ROM

ifneq ($(findstring FLOATING,$(CONFIG)),)
  DICTSIZE ?= 0x3000
else
  DICTSIZE ?= 0x4000
endif

CFLAGS += -m32 -march=i386

TCFLAGS += -Os

# Use thumb instruction set to save a little space
TCFLAGS += -mthumb

# Omit unreachable functions from output

TCFLAGS += -ffunction-sections -fdata-sections
TCFLAGS += -ffunction-sections -fdata-sections
TLFLAGS += --gc-sections

# VPATH += $(SRC)/cpu/arm
VPATH += $(SRC)/platform/$(MYNAME)
VPATH += $(SRC)/lib
VPATH += $(STMLIB)/Libraries/STM32F10x_StdPeriph_Driver/src
VPATH += $(STMLIB)/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/

# This directory, including board information
INCS += -I$(SRC)/platform/$(MYNAME)

# Include files for CPU cores
INCS += -I$(STMLIB)/Libraries/CMSIS/CM3/CoreSupport

# Contains stm32l1xx.h defining the hardware registers
INCS += -I$(STMLIB)/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x

# Include files defining standard peripheral driver APIs for various devices
INCS += -I$(STMLIB)/Libraries/STM32F10x_StdPeriph_Driver/inc

include $(SRC)/common.mk
include $(SRC)/cforth/targets.mk

# Platform-specific object files for low-level startup and platform I/O

# CLKCONFIG = -1v8-msi2000
# CLKCONFIG ?= -1v8-hsi16m-16m

# FIRST_OBJ = tstartup_stm32f10x_mdp.o
FIRST_OBJ = tstartup_stm32f10x.o

# PLAT_OBJS += tsystem_stm32f10x$(CLKCONFIG).o
PLAT_OBJS += tstm32f10x_usart.o tstm32f10x_rcc.o
PLAT_OBJS += tstm32f10x_gpio.o
PLAT_OBJS += tstm32f10x_adc.o
PLAT_OBJS += tmisc.o tsystick.o
PLAT_OBJS += ttmain.o mallocembed.o
PLAT_OBJS += tconsoleio.o 
PLAT_OBJS += tsystem_stm32f10x.o
PLAT_OBJS += tgpio.o
PLAT_OBJS += tadc.o

ttmain.o: vars.h

# EXTEND_OBJS ?= ti2c.o

PLAT_OBJS += $(EXTEND_OBJS)

# Object files for the Forth system and application-specific extensions

FORTH_OBJS = tembed.o textend.o


# Recipe for linking the final image

LDSCRIPT = $(SRC)/platform/$(MYNAME)/stm32_flash.ld

TLDBODY = -T$(LDSCRIPT) $(FIRST_OBJ) $(PLAT_OBJS) $(FORTH_OBJS)
ifneq ($(findstring FLOATING,$(CFLAGS)),)
  # The software floating point library needs a few things from libc,
  # most notably malloc, so we cannot easily do a tight libc-less link
  # with ld.  Instead we link with gcc and let it work out the details.
  LDCMD := $(TCC) $(CPU_VARIANT) \
	   $(TLDBODY) \
	   -lc -lgcc -lm -specs=nosys.specs
else
  LDCMD := $(TLD) $(TLFLAGS) \
	   $(TLDBODY) \
	   $(LIBDIRS) -lgcc
endif

app.elf: $(FIRST_OBJ) $(PLAT_OBJS) $(FORTH_OBJS)
	@echo Linking $@ ... 
	$(LDCMD) -o $@


# LIBM := $(shell $(TCC) --print-file-name=libm.a)
# LIBC := $(shell $(TCC) --print-file-name=libc.a)

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

EXTRA_CLEAN += *.bin *.elf *.dump *.nm *.img date.c $(FORTH_OBJS) $(PLAT_OBJS)

include $(SRC)/cforth/embed/targets.mk
