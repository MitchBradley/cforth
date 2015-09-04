# Builds a MacOS Forth application for programming a Nod Backspin

TOPDIR=../..

CONFIG += -DBITS64

FTDI = y
INCS += -I/usr/local/include/libusb-1.0
# To get libusb-1.0 on MacOS, download and upack a source tarball from
# www.libusb.org, then  ./configure && make && sudo make install
# Or, if you have the "Homebrew" package manager, just "brew install libusb"

BUNDLE=macos-backspin-programmer.tgz

all: $(BUNDLE)

# Static link so the user does not have to install libusb
# This ends up needing several other MacOS frameworks and libraries
LIBS += /usr/local/lib/libusb-1.0.a  -framework CoreFoundation  -framework IOKit  -lobjc

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
DISTRIBUTED_FILES = $(TRANSIENT_DISTRIBUTED_FILES) program-backspin.command reboot-backspin.command README.txt

$(BUNDLE): $(DISTRIBUTED_FILES)
	rm -rf NodBackspinProgrammer
	mkdir NodBackspinProgrammer
	cp $(DISTRIBUTED_FILES) NodBackspinProgrammer
	chmod a+x NodBackspinProgrammer/*.command
	tar cfz $@ NodBackspinProgrammer
	rm -rf NodBackspinProgrammer

.PHONY: $(BUNDLE)

EXTRA_CLEAN += $(TRANSIENT_DISTRIBUTED_FILES) $(BACKSPIN_SRC) *.tgz
