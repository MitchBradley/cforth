# Builds a MacOS host Forth application with serial port tools

TOPDIR=../..

CONFIG += -DBITS64

FTDI = y
INCS += $(shell pkg-config --cflags libusb-1.0)
# To get libusb-1.0 on MacOS, download and upack a source tarball from
# www.libusb.org, then  ./configure && make && sudo make install
# Or, if you have the "Homebrew" package manager, just "brew install libusb"
# You might also need "brew install pkg-config"

# Static link so the user does not have to install libusb
# This ends up needing several other MacOS frameworks and libraries

# We cannot use the obvious method of just saying
#   -Wl,--static $(shell pkg-config --static --libs libusb-1.0)
# That fails because we want to link statically with libusb, but
# dynamically with the system-supplied libraries and frameworks.
# So we have to piece together a pathname to the static libusb-1.0.a,
# removing the -L prefix and the trailing space

LIBDIR := $(strip $(subst -L,,$(shell pkg-config --libs-only-L libusb-1.0)))
LIBUSBFILE := $(LIBDIR)/libusb-1.0.a

# This adds libusb-required frameworks like IOKit and CoreFoundation
FRAMEWORKS := $(shell pkg-config --static --libs-only-other libusb-1.0)

# The static version of libusb also needs -lobjc (dynamically linked)
# We could try to get it from:
#   $(shell pkg-config --static --libs-only-l libusb-1.0)
# but that also adds -lusb-1.0, thus creating a runtime dependency on
# the libusb dynamic library, which is what we are trying to avoid
# (we don't want the user to have to install anything)
LIBSMORE += -lobjc

LIBS += $(LIBUSBFILE) $(FRAMEWORKS)  $(LIBSMORE)

include $(TOPDIR)/src/app/host-serial/targets.mk
