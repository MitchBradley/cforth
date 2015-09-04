# Builds a MacOS host Forth application with serial port tools

TOPDIR=../..

CONFIG += -DBITS64

# To get libusb-1.0 on MacOS, download and upack a source tarball from
# www.libusb.org, then  ./configure && make && sudo make install
# Or, if you have the "Homebrew" package manager, just "brew install libusb"
FTDI = y
INCS += -I/usr/local/include/libusb-1.0

# Static link so the user does not have to install libusb
# This ends up needing several other MacOS frameworks and libraries
LIBS += /usr/local/lib/libusb-1.0.a  -framework CoreFoundation  -framework IOKit  -lobjc

include $(TOPDIR)/src/app/host-serial/targets.mk
