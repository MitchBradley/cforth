\ Driver for N-line LCD connected through PCF8574 I2C GPIO chip

$27 value lcd-i2c-slave
1 buffer: lcd-byte
: lcd-i2c!  ( b -- )
   lcd-byte c!  lcd-byte 1  lcd-byte 0  lcd-i2c-slave  false
   i2c-write-read abort" LCD I2C op failed"
;

0 value lcd-regval
: lcd-pulse  ( -- )  lcd-regval dup 4 or lcd-i2c!  lcd-i2c!  ;

: lcd-send  ( b -- )  dup to lcd-regval  lcd-i2c!  ;

: backlight-on  ( -- )   8 lcd-send  ;
: backlight-off  ( -- )  0 lcd-send  ;

: lcd-char-mode  ( -- )  1 ms  lcd-regval 1 or  to lcd-regval   ;
: lcd-data-mode  ( -- )  1 ms  lcd-regval 1 invert and  to lcd-regval  ;
: lcd-write4  ( nibble -- )
   4 lshift  lcd-regval $f and  or  lcd-send
   lcd-pulse
;
: lcd!  ( b -- )  $10 /mod  lcd-write4 lcd-write4  ;
: lcd-cmd  ( b -- )  lcd-data-mode  lcd!  ;
: clear-lcd  ( -- )  1 lcd-cmd  3 ms  ;
: home-lcd  ( -- )  2 lcd-cmd  3 ms  ;
: lcd-cursor-on    ( -- )  $e lcd-cmd  ;
: lcd-cursor-blink ( -- )  $d lcd-cmd  ;
: lcd-cursor-off  ( -- )  $c lcd-cmd  ;
: init-lcd  ( -- )
   backlight-on
   $33 lcd-cmd
   $32 lcd-cmd
   lcd-cursor-off
   $28   lcd-cmd \ FunctionSetCmd(20), 4bitmode (!10), 4line (8=0), 5x8dots (!4)
   4  2 or  lcd-cmd   \ EntryModeSet(4), ENTRYLEFT(2), shiftdecrement (!1)
   clear-lcd
;
: lcd-at  ( col# line# -- )
   case
      0 of  0    endof
      1 of  $40  endof
      2 of  $14  endof
      3 of  $54  endof
      ( default ) drop 0
   endcase                ( col# ddram-offset )
   +  $80 or  lcd-cmd
;

: lcd-emit  ( char -- )  lcd-char-mode lcd!  ;
: lcd-type  ( adr len -- )  bounds ?do  i c@ lcd-emit  loop  ;
: lcd-type-at  ( adr len col# line# -- )  lcd-at lcd-type  ;
: lcd-clear-at  ( col# line# #chars -- )
   >r  2dup lcd-at  r>        ( col# line# #chars )
   0  ?do  bl lcd-emit  loop  ( col# line# )
   lcd-at
;
: lcd-clear-type-at  ( adr len col# line# #chars -- )
   lcd-clear-at      ( adr len )
   lcd-type          ( )
;
