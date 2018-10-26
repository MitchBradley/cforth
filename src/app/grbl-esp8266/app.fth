\ Application load file for GRBL sender.
\ A Wemos D1 Mini ESP8266 board (or any ESP12-based
\ module) connects serially to a GRBL controller.
\ Press a pushbutton switch to start sending the
\ file "gcode" (in the ESP FLASH filesystem) to
\ the GRBL controller.  Status is displayed on a
\ multicolor LED and optionally on an OLED display.
\ The LED is blue when booting, yellow when ready,
\ green when sending, and red if the send aborted
\ with an error.

fl ../esp8266/common.fth

\ GRBL sender application
fl ${CBP}/lib/lex.fth
fl grbl.fth

: app  ( -- )
   \ If the ESP module is connected to a host via the USB serial port,
   \ the banner will be displayed on the serial terminal at startup,
   \ and you can get an ok prompt by typing a character quickly.
   \ Thereby you can load a new GCode file by typing
   \   ok rf gcode
   \   <send file with XModem>

   banner  hex
   interrupt?  if  quit  then

   \ Otherwise, the system will run the GRBL sender app
   ['] run catch drop
   quit
;

" app.dic" save

