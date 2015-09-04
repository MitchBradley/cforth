# Builds a Linux Forth application for programming a Nod Backspin

TOPDIR=../..

CONFIG += -DBITS64

# FTDI dongle support.
# libusb.h and libusb-1.0.a must be copied into this directory
FTDI = y
INCS += -I/usr/include/libusb-1.0
LIBS += -lusb-1.0

BUNDLE=linux-backspin-programmer.tgz

all: $(BUNDLE)

include $(TOPDIR)/src/app/host-serial/targets.mk

BACKSPIN_SRC += common-tools.fth
BACKSPIN_SRC += serial-tools.fth
BACKSPIN_SRC += get-images.fth
BACKSPIN_SRC += stmicro-load.fth
BACKSPIN_SRC += download.fth
BACKSPIN_SRC += backspin-download.fth

DIAGS_DIR=$(TOPDIR)/../../fw/diags/wicedforth

%.fth:
	cp $(DIAGS_DIR)/$@ $@

%.bat:
	cp $(DIAGS_DIR)/$@ $@

backspin-programmer.dic: app.dic $(BACKSPIN_SRC)
	./forth backspin-download.fth

TRANSIENT_DISTRIBUTED_FILES = forth backspin-programmer.dic
DISTRIBUTED_FILES = $(TRANSIENT_DISTRIBUTED_FILES) program-backspin reboot-backspin README.txt

$(BUNDLE): $(DISTRIBUTED_FILES)
	rm -rf NodBackspinProgrammer
	mkdir NodBackspinProgrammer
	cp $(DISTRIBUTED_FILES) NodBackspinProgrammer
	chmod a+x NodBackspinProgrammer/program-backspin NodBackspinProgrammer/reboot-backspin
	tar cfz $@ NodBackspinProgrammer
	rm -rf NodBackspinProgrammer

.PHONY: $(BUNDLE)

EXTRA_CLEAN += $(TRANSIENT_DISTRIBUTED_FILES) $(BACKSPIN_SRC) *.tgz
