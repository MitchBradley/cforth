 # HOWTO Compile for ESP8266 #

CForth for ESP8266 piggybacks on the nodemcu-firmware code, replacing
its Lua interpreter with Forth.

Making CForth in build/esp8266 will automatically fetch the
nodemcu-firmware source code and patch it to use CForth instead
of Lua.  By default, the nodemcu-firmware tree will be located
in the same parent directory as the cforth tree.

The rules for setting up the nodemcu-firmware tree are in
src/app/esp8266/targets.mk in the $(NODEMCU_PATH): target.

Those rules further prepare the nodemcu-firmware tree by
running "make sdk_patched", which fetches the appropriate
version of ESP SDK.

## Compiling CForth ##

Starting from the top directory of the cforth tree:

  cd build/esp8266
  make

The binary files that you download to the ESP8266 module will
be created in the nodemcu-firmware tree:

  $(CFORTH_TOPDIR)/../nodemcu-firmware/bin/0x00000.bin
  $(CFORTH_TOPDIR)/../nodemcu-firmware/bin/0x10000.bin

## Downloading CForth to an ESP8266 module ##

  COMPORT=my_comport_name make download

substituting an appropriate value for my_comport_name .  On Windows,
the name would be something like COM5.  On Linux it would be something
like /dev/ttyUSB0.  On MacOS, the name depends on which USB serial chip
that you are using to connect to the ESP module, probably /dev/cu.<something>.

## Explanation of the patches to nodemcu-firmware ##

See src/app/esp8266/0001-Use-CForth-not-Lua-as-the-extension-language.patch

1) In the top level Makefile, we omit the spiffs-image and spiffs-image-remove
targets because the are hard to build in some environments (e.g. Windows).
The down side of this is that you cannot pre-populate the SPIFFS filesystem.

2) Also in the top level Makefile, we change the basic rule for compiling
object files to be less verbose, substituting the message "CC source_filename.c"
for the full command line.

3) In app/Makefile, we omit a bunch of unused Lua modules and their associated
library files, thus greatly speeding up compilation.  Instead we substitute
$(FORTHOBJS), which is the CForth "app.o" file that contains all of CForth.

4) In app/driver/uart.c, app/include/driver/uart.h, and
app/user/user_main.c we disable the new Lua tasking interface and
revert to the direct ESP SDK tasking interface.

5) In app/platform/platform.c we define NODE_ERR(...) as a no-op, which
eliminates the need to pull in the libc printf.  In spiffs/spiffs_config.h
we turn off SPIFFS_TEST_VISUALIZATION for the same reason.  There are also
some changes in app/user/user_main.c for this reason.

6) In app/spiffs/spiffs_config.h we change the SPIFFS initialization code
so it is less prone to finding SPIFFS objects that have been obsoleted
by increases in the base code size that encroach upon the SPIFFS area.
https://github.com/nodemcu/nodemcu-firmware/issues/1479
Recent changes to the nodemcu code base have solved this problem in a
different way but we have not yet updated to that version (and we probably
never will; instead the plan is to get rid of nodemcu entirely).

7) In ld/nodemcu.ld we include the Forth stuff in the correct load section.

8) In tools/esptool.py we change the #! line to force the use of Python2.7,
since esptool.py will not work with Python 3.
