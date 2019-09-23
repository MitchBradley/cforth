# Builds CForth for ESP8266 with Sonoff WiFi switch code

TOPDIR=../..
UPDIR=$(realpath $(TOPDIR)/..)

CONFIG += -DBITS32

CFLAGS += -m32

CC := gcc

# Change these to reflect the locations of external stuff on your system,
# either here or on the command line, e.g. COMPORT=COM27 make download
SDK_PARENT_PATH ?= $(UPDIR)
NODEMCU_PARENT_PATH ?= $(UPDIR)
COMPORT ?= /dev/ttyS4
FM ?= dout
FS ?= 8m

APPPATH = $(TOPDIR)/src/app/sonoff
VPATH +=  $(APPPATH)

include $(TOPDIR)/src/app/esp8266/targets.mk

AHK = /mnt/c/Program\ Files/AutoHotKey/AutoHotKey.exe

# This target automates the process of building in Docker
# (which can host 32-bit apps but cannot easily access
# USB serial ports), then disconnecting the terminal emulator
# (which blocks the downloader's serial access), then
# performing a download under WSL (which can access USB
# serial but cannot run 32-bit apps), then reconnecting
# the terminal emulator.  It is only useful in my specific
# Windows compilation setup.  Most people will just use
#  make download
dl:
	$(AHK) DockerMake.ahk
	$(AHK) TeraTermDisconnect.ahk
	make download
	$(AHK) TeraTermConnect.ahk
