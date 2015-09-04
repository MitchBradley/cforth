# Builds a Windows Forth application for programming a Nod Backspin

TOPDIR=../..

# FTDI dongle support.
# libusb.h and libusb-1.0.a must be copied into this directory
FTDI = y
INCS += -I.
LIBS += -L.
LIBS += -lusb-1.0

# GUI support - message boxes and file open dialog
LIBS += -lcomdlg32 -lcomctl32

CONFIG += -DBITS32 -DT16 -m32

BUNDLE=windows-backspin-programmer.zip

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

backspin-programmer.dic: app.dic $(BACKSPIN_SRC)
	./forth backspin-download.fth

TRANSIENT_DISTRIBUTED_FILES = backspin-programmer.dic
DISTRIBUTED_FILES = $(TRANSIENT_DISTRIBUTED_FILES) program-backspin.bat reboot-backspin.bat README.txt

$(BUNDLE): $(DISTRIBUTED_FILES)
	rm -rf NodBackspinProgrammer
	mkdir NodBackspinProgrammer
	cp forth.exe $(DISTRIBUTED_FILES) NodBackspinProgrammer
	zip -r $@ NodBackspinProgrammer
	chmod a+x $@
	rm -rf NodBackspinProgrammer

.PHONY: $(BUNDLE)

EXTRA_CLEAN += *.exe $(TRANSIENT_DISTRIBUTED_FILES) $(BACKSPIN_SRC) *.zip
