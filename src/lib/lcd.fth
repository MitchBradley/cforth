\ LCD driver

\ The controller is Samsung S6A0069, which is compatible with HD44780

: lcd-addr@  ( -- n )  7 index!  a0-low  data@  h# 7f and  ;

: lcd-wait  ( -- )
   7 index!  a0-low  begin  data@ h# 80 and  0=  until
;

: lcd-data!  ( n -- )  7 index!  a0-high  data!  ;
: lcd-data@  ( n -- )  7 index!  a0-high  data@  ;

: lcd-cmd  ( n -- )  7 index!  a0-low  data!  d# 43 us  ;

: page  ( -- )  1 lcd-cmd  d# 1530 us  ;
: home  ( -- )  2 lcd-cmd  d# 1530 us  ;
: increment-mode  ( -- )  6 lcd-cmd  ;
: decrement-mode  ( -- )  4 lcd-cmd  ;
: shift-left   ( -- )  7 lcd-cmd  ;
: shift-right  ( -- )  5 lcd-cmd  ;

: lcd-mode  ( n -- )  8 or lcd-cmd  ;
\ 0  display off, cursor off, blink off
\ 1  display off, cursor off, blink on
\ 2  display off, cursor on,  blink off
\ 3  display off, cursor on,  blink off
\ 4  display on,  cursor off, blink off
\ 5  display on,  cursor off, blink on
\ 6  display on,  cursor on,  blink off
\ 7  display on,  cursor on,  blink on
: display-on  ( -- )  4 lcd-mode  ;

: cursor-left   ( -- )  h# 10  lcd-cmd  ;
: cursor-right  ( -- )  h# 14  lcd-cmd  ;
: entire-left   ( -- )  h# 18  lcd-cmd  ;
: entire-right  ( -- )  h# 1c  lcd-cmd  ;

\ Always use 8-bit mode (10 bit)
: big-font    ( -- )  h# 34 lcd-cmd  ;  \ 1 line 5x10
: small-font  ( -- )  h# 38 lcd-cmd  ;  \ 2 lines 5x7
\ 1line-small-font  ( -- )  h# 38 lcd-cmd  ;  \ 1 line 5x7

: cgram-addr!  ( n -- )  h# 40 or lcd-cmd  ;

\ h#00-h#27 for first line
\ h#40-h#67 for second line
: ddram-addr!  ( n -- )  h# 80 or lcd-cmd  ;

: init-lcd  ( -- )
   lcd-wait
   small-font
   increment-mode
   page  home
   display-on
;

: lcd-emit  ( b -- )  lcd-data!  ;
: lcd-cr    ( -- )  h# 40 ddram-addr!  ; 
: lcd-type  ( adr len -- )   bounds ?do  i c@ lcd-emit  loop  ;

: lcd-banner  ( -- )  init-lcd  " AgileTV" lcd-type  ;

: line  ( adr len -- )
   tuck lcd-type  d# 16 min  d# 16 swap  ?do  bl lcd-emit  loop  lcd-cr
;
