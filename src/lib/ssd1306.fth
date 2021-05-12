\ Text mode driver for SSD1306 OLED display controller chip
\ Plugs into the bottom interface of "fb.fth"
\ Requires external definition of a font

0 [if]
$00 constant SETLOWCOLUMN \  Set Lower Column Start Address for Page Addressing Mode.
$10 constant SETHIGHCOLUMN \  Set Higher Column Start Address for Page Addressing Mode.
$20 constant MEMORYMODE \  Set Memory Addressing Mode.
$40 constant SETSTARTLINE \  Set display RAM display start line register from 0 - 63.
$81 constant SETCONTRAST \  Set Display Contrast to one of 256 steps.
$8D constant CHARGEPUMP \  Enable or disable charge pump.  Follow with 0X14 enable, 0X10 disable.
$A0 constant SEGREMAP \  Set Segment Re-map between data column and the segment driver. 
$A4 constant DISPLAYALLON_RESUME \  Resume display from GRAM content.
$A5 constant DISPLAYALLON \  Force display on regardless of GRAM content.
$A6 constant NORMALDISPLAY \  Set Normal Display.
$A7 constant INVERTDISPLAY \  Set Inverse Display.
$A8 constant SETMULTIPLEX \  Set Multiplex Ratio from 16 to 63.
$AE constant DISPLAYOFF \  Set Display off.
$AF constant DISPLAYON \  Set Display on.
$B0 constant SETSTARTPAGE \ Set GDDRAM Page Start Address.
$C0 constant COMSCANINC \  Set COM output scan direction normal.
$C8 constant COMSCANDEC \  Set COM output scan direction reversed.
$D3 constant SETDISPLAYOFFSET \  Set Display Offset.
$DA constant SETCOMPINS \  Sets COM signals pin configuration to match the OLED panel layout.
$DB constant SETVCOMDETECT \  This command adjusts the VCOMH regulator output.
$D5 constant SETDISPLAYCLOCKDIV \  Set Display Clock Divide Ratio/ Oscillator Frequency.
$D9 constant SETPRECHARGE \  Set Pre-charge Period
$E3 constant NOP \  No Operation Command.

\ SH1106 only
$30 constant SET_PUMP_VOLTAGE \  Set Pump voltage value: (30H~33H) 6.4, 7.4, 8.0 (POR), 9.0.
$AD constant SET_PUMP_MODE \  First byte of set charge pump mode
$8B constant PUMP_ON \  Second byte charge pump on.
$8A constant PUMP_OFF \  Second byte charge pump off.
[then]


\ Display-dependent (the SSD1306 can handle different OLED resolutions)

\ See SSD1306Ascii/src/SSD1306init.h in https://github.com/greiman/SSD1306Ascii.git
\ for init structures for different resolutions
\ For 64x48
create 'ssd-init
    $ae c,         \ Display Off
    $d5 c, $80 c,  \ Clock divisor
    $a8 c, $2f c,  \ Multiplexing
    $d3 c, $00 c,  \ Offset
    $40 $00 or c,  \ Start line
    $8d c, $14 c,  \ Charge pump (internal vcc)
    $a6 c,         \ Normal Display
    $a4 c,         \ Display All On Resume,
    $a0 $01 or c,  \ SegRemap - column 127 mapped to SEG0
    $c8 c,         \ Column scan direction reversed
    $da c,  $12 c, \ Pin config for height > 32
    $81 c,  $7f c, \ Contrast
    $d9 c,  $f1 c, \ precharge period (1, 15)
    $db c,  $40 c, \ VCOMH regulator level 
    $af c,         \ Display On
here 'ssd-init - constant /ssd-init

#64 constant ssd-width
#48 constant ssd-height

\ End of display dependencies

#64 constant ssd-#scanlines  \ Fixed by chip, not by connected display
: ssd-#cols   ( -- n )  ssd-width  ;
: pixels>pages  ( #pixels -- #pages )  3 rshift  ;
8 constant ssd-#pages  ( -- n )
: fb-#pages  ( -- n )  ssd-height pixels>pages  ;

#32 constant ssd-col-offset

0 value ssd-col        \ In pixels
0 value ssd-page       \ In 8-pixel chunks, i.e. "pages"
0 value ssd-startline  \ For scrolling

: char-width  ( -- n )  font-width 1+  ;
: pages/char  ( -- n )  font-height 7 + pixels>pages  ;
: char-scanlines  ( -- n )  pages/char 3 lshift  ;

$3c value ssd-i2c-slave
: ssd-cmd  ( cmd -- )
   0 ssd-i2c-slave i2c-b! abort" SSD1306 I2C write failed"
;
[ifdef] i2c-write-read
#100 buffer: ssd-buf
0 value ssd-ptr
: ssd-ram!  ( b -- )  ssd-ptr c!  ssd-ptr 1+ to ssd-ptr  ;
: ssd-ram{  ( -- )  ssd-buf to ssd-ptr  $40 ssd-ram!  ;
: }ssd-ram  ( -- )
   ssd-buf  ssd-ptr ssd-buf -  0 0  ssd-i2c-slave  true  i2c-write-read
   abort" i2c-write-read failed"
;
[else]
: ssd-ram{   ( -- )
   $40 ssd-i2c-slave i2c-start-write abort" ssd-ram{ failed"
;
: }ssd-ram   ( -- )  i2c-stop  ;
: ssd-ram!  ( b -- )  i2c-byte! abort" ssd-ram! failed"  ;
[then]

: ssd-startline!  ( y-pixel# -- )
   dup ssd-#scanlines >=  if  ssd-#scanlines -  then  ( y-pixel#' )
   dup to ssd-startline   $40 or ssd-cmd
;

: ssd-set-col  ( col -- )
   ssd-col-offset +             ( col' )
   dup $f and  $00 or  ssd-cmd  ( col )  \ Set column low nibble
   4 rshift    $10 or  ssd-cmd  ( )      \ Set column high nibble
;
: ssd-set-page  ( c -- )  $b0 or  ssd-cmd   ;

: line#>page  ( line# -- page )
   pages/char *                   ( page )
   ssd-startline pixels>pages +   ( page )
   dup ssd-#pages >=  if          ( page )
      ssd-#pages -                ( page' )
   then                           ( page )
;
: column#>col  ( char# -- )  char-width *  ;

\ Clear a rectangular text region starting at the character cursor
: ssd-clear-region       ( #cols #pages -- )
   line# line#>page  swap bounds  ?do ( #cols )  \ Outer loop over pages
      column# column#>col ssd-set-col ( #cols )
      i ssd-set-page                  ( #cols )
      ssd-ram{                        ( #cols )
      dup 0  ?do  0 ssd-ram!  loop    ( #cols )
      }ssd-ram                        ( #cols )
   loop                               ( #cols )
   drop                               ( )
;

: ssd-delete-characters  ( #characters -- )
   column#>col  pages/char ssd-clear-region   
;

: ssd-clear-to-eol  ( -- )
   ssd-#cols  column# column#>col  -  pages/char ssd-clear-region
;

: ssd-clear  ( -- )
   0 ssd-startline!
   0 to column#  0 to line#
   ssd-#cols  ssd-#pages  ssd-clear-region
;

[ifdef] ssd-reset-pin
: ssd-reset  ( -- )
  0 ssd-rst-pin gpio-pin!
  #10 ms
  1 ssd-rst-pin gpio-pin!
  #10 ms
;
[then]

: ssd-set-contrast  ( 0..255 -- )  $81 ssd-cmd  ssd-cmd  ;

: ssd-newline  ( -- )
   0 to column#
   line# #lines 1-  =  if
      ssd-startline char-scanlines +  ssd-startline!
      ssd-clear-to-eol
   else
      line# 1+ to line#
   then
;

: ssd-draw-character  ( char -- )
   font-char0 -                        ( ch# )
   font-#rows * font-width *  'font +  ( adr )

   line# line#>page  pages/char  bounds  ?do  ( adr )
      column# column#>col ssd-set-col       ( adr )
      i ssd-set-page                        ( adr )
      ssd-ram{                              ( adr )
      font-width 0  ?do                     ( adr )
         dup c@ ssd-ram!                    ( adr )
         ca1+                               ( adr' )
      loop                                  ( adr )
      \ Extra spacing column - char-width is 1 more than font-width
      0 ssd-ram!                            ( adr )
      }ssd-ram                              ( adr )
  loop                                      ( adr )
  drop                                      ( )
;

: ssd-delete-lines  ( #lines -- )
   ssd-#cols  column# column#>col  -  over pages/char *  ssd-clear-region   ( #lines )
   char-scanlines *  ssd-startline +  ssd-startline!  ( )
;

: ssd-init  ( -- )
   ssd-#cols char-width / to #columns
   fb-#pages pages/char / to #lines
   ['] ssd-draw-character to draw-character
   ['] ssd-delete-characters to delete-characters
   ['] ssd-delete-lines to delete-lines

   'ssd-init /ssd-init  bounds  ?do
      i c@ ssd-cmd
   loop
   ssd-clear
;
