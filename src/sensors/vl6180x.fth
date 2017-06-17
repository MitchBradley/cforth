\ Driver for STMicro VL6180X time-of-flight distance and ambient light sensor

$29 constant vl-slave

3 buffer: vl-buf

: vl-setreg  ( w.reg# -- )  wbsplit vl-buf c!  vl-buf 1+ c!  ;
: vl-run  ( wbuf wlen rbuf rlen -- )
   vl-slave false i2c-write-read abort" VL6180X op failed"
;

: vl!  ( b w.reg# -- )
   vl-setreg  vl-buf 2+ c!
   vl-buf 3  pad 0  vl-run
;   
: vl@  ( wreg# -- b )
   vl-setreg
   vl-buf 2  vl-buf 2+ 1  vl-run
   vl-buf 2+ c@
;

create vl-init-table
   \ Mandatory
   $01 w, $207 w,  $01 w, $208 w,  $00 w, $096 w,  $FD w, $097 w,
   $00 w, $0E3 w,  $04 w, $0E4 w,  $02 w, $0E5 w,  $01 w, $0E6 w,
   $03 w, $0E7 w,  $02 w, $0F5 w,  $05 w, $0D9 w,  $CE w, $0DB w,
   $03 w, $0DC w,  $F8 w, $0DD w,  $00 w, $09F w,  $3C w, $0A3 w,
   $00 w, $0B7 w,  $3C w, $0BB w,  $09 w, $0B2 w,  $09 w, $0CA w,
   $01 w, $198 w,  $17 w, $1B0 w,  $00 w, $1AD w,  $05 w, $0FF w,
   $05 w, $100 w,  $05 w, $199 w,  $1B w, $1A6 w,  $3E w, $1AC w,
   $1F w, $1A7 w,  $00 w, $030 w,
   \ Recommended
   $10 w, $011 w,  $30 w, $10a w,  $46 w, $03f w,  $ff w, $031 w,  
   $63 w, $040 w,  $01 w, $02e w,
   \ Optional
   $09 w, $01b w,  \ Default ranging inter-measurement period 100ms
   $31 w, $03e w,  \ Default ALS inter-measurement period 500ms
   $24 w, $014 w,  \ Interrupt on New Sample Ready threshold event
here vl-init-table - constant /vl-init-table

: w@+  ( adr -- adr' w )  dup wa1+ swap w@  ;

: init-vl6180x  ( -- )
   $16 vl@ 1 and  0=  if  exit  then
   vl-init-table /vl-init-table  bounds  ?do
      i w@  i wa1+ w@  vl!
   2 /w* +loop
   0 $16 vl!    \ Clear just-reset bit
;
: vl-distance  ( -- n )
   $1 $18 vl!
   begin  1 ms  $4f vl@ 4 and  until
   $62 vl@
;
: .vl-distance  ( -- )  vl-distance .d  ." mm"  ;

: vl-avg-dist ( -- n )
   0  #10 0  do  vl-distance +  loop  #10 /
;
