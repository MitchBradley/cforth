# Builds a Linux host Forth application with serial port tools and a Bluez interface

TOPDIR=../..

CONFIG += -DBITS32 -DT16

FTDI = y
INCS += -I/usr/include/libusb-1.0
LIBS += -lusb-1.0

BLUEZ_DIR := $(TOPDIR)/src/app/bluez

include $(BLUEZ_DIR)/targets.mk


CHARGE_GO += $(BLUEZ_DIR)/charge

CHARGE_SRC += $(BLUEZ_DIR)/charging.fth
CHARGE_SRC += $(BLUEZ_DIR)/command.fth
CHARGE_SRC += $(BLUEZ_DIR)/ina219.fth
CHARGE_SRC += $(BLUEZ_DIR)/muxit.fth
CHARGE_SRC += $(BLUEZ_DIR)/result-file.fth
CHARGE_SRC += $(BLUEZ_DIR)/scanner.fth
CHARGE_SRC += $(BLUEZ_DIR)/rly16.fth
CHARGE_SRC += $(BLUEZ_DIR)/setup-charge
CHARGE_SRC += $(TOPDIR)/src/app/host-serial/rpi-gpio.fth

charge-kit.tgz: forth app.dic $(CHARGE_SRC)
	mkdir -p charge-kit
	cp $(CHARGE_SRC) charge-kit/
	cp $(CHARGE_GO) charge-kit/go
	cp forth app.dic charge-kit/
	(cd charge-kit && tar cfz ../charge-kit.tgz --owner=root --group=root *)
	rm -rf charge-kit


