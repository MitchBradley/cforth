\ Interface to Adafruit RGB LCD plate for Raspberry Pi

\needs mcp-set  fload ../../lib/mcp23017.fth
\needs .color   fload ../../lib/colors.fth

: setup-lcd  ( -- )
   $1f 0 mcp-w!  \ Set GPIO 4..0 as input (switches), others output
   $1f $c mcp-w!  \ Pullup GPIO 4..0 for switches
   #14 mcp-gpio-clr  \ R/W_ low for writing only
   #13 mcp-gpio-clr  \ EN low (will be pulsed high)
;

: backlight-color  ( bgr-bits -- )
   9 6  do
      dup 1 and  if
         i mcp-gpio-clr
      else
         i mcp-gpio-set
      then
      2/
   loop
   drop
;

: lcd-color:  ( n "name" -- )  create ,  does> @ backlight-color  ;

0 lcd-color: lcd-black
1 lcd-color: lcd-red
2 lcd-color: lcd-green
3 lcd-color: lcd-yellow
4 lcd-color: lcd-blue
5 lcd-color: lcd-magenta
6 lcd-color: lcd-cyan
7 lcd-color: lcd-white

: lcd-pulse  ( -- )  #13 mcp-gpio-set  #13 mcp-gpio-clr  ;

: lcd-char-mode  ( -- )  1 ms  #15 mcp-gpio-set  ;
: lcd-data-mode  ( -- )  1 ms  #15 mcp-gpio-clr  ;
: lcd-write4  ( nibble -- )
   $12 mcp-w@  $1e00 invert  and   ( nibble w )
   over 8 and  if  $0200 or  then  ( nibble w )
   over 4 and  if  $0400 or  then  ( nibble w )
   over 2 and  if  $0800 or  then  ( nibble w )
   over 1 and  if  $1000 or  then  ( nibble w )
   $12 mcp-w!                      ( nibble )
   lcd-pulse                       ( nibble )
   drop
;
: lcd!  ( b -- )  $10 /mod  lcd-write4 lcd-write4  ;
: clear-lcd  ( -- )  lcd-data-mode  1 lcd!  3 ms  ;
: home-lcd  ( -- )  lcd-data-mode  2 lcd!  3 ms  ;
: lcd-cursor-on   ( -- )  $e lcd!  ;
: lcd-cursor-off  ( -- )  $c lcd!  ;
: init-lcd  ( -- )
   setup-lcd
   lcd-data-mode
   $33 lcd!
   $32 lcd!
   8  4 or  lcd!   \ DisplayControlCmd (8), DISPLAYON(4), cursoroff (!2), blinkoff (!1)
   $20  8 or  lcd! \ FunctionSetCmd(20), 4bitmode (!10), 2line (8), 5x8dots (!4)
   4  2 or  lcd!   \ EntryModeSet(4), ENTRYLEFT(2), shiftdecrement (!1)
   clear-lcd
;
: lcd-at  ( col# line# -- )   if  $40 or  then  $80 or  lcd-data-mode  lcd!  ;
: lcd-emit  ( char -- )  lcd-char-mode lcd!  ;
: lcd-type  ( adr len -- )  lcd-char-mode  bounds ?do  i c@ lcd!  loop  ;
: lcd-type-at  ( adr len col# line# -- )  lcd-at lcd-type  ;

: lcd-switches@  ( -- mask )  $12 mcp-w@ $1f and  ;
