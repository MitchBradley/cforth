# Builds a GRBL sender app for an ESP8266 module
# See src/app/grbl-esp8266/app.fth for details.

# Main application code directory
APPPATH = $(TOPDIR)/src/app/grbl-esp8266

# ESP8266-specific drivers
# Not all are used but they are listed as dependencies just in case
APPSRCS += $(wildcard $(TOPDIR)/src/app/esp8266/*.fth)

# Generic utilities
# Not all are used but they are listed as dependencies just in case
APPSRCS += $(wildcard $(TOPDIR)/src/lib/*.fth)

# Reuse the Makefile for the generic ESP8266 build.
# The above setting of APPPATH overrides the generic
# setting to build the desired application code.
include ../esp8266/Makefile
