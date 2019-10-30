\ Driver for HX711 load cell amplifier

1 value hx711-polarity  \ or -1; depends on hookup

5 value hx711-sck-pin
6 value hx711-dout-pin
: hx711-power-on  ( -- )  0 hx711-sck-pin gpio-pin!  ;
: hx711-power-off  ( -- )  1 hx711-sck-pin gpio-pin!  ;
: hx711-pulse  ( -- )  hx711-power-off 3 us hx711-power-on  ;
: init-hx711  ( -- )
   false gpio-input  hx711-dout-pin gpio-mode
   false gpio-output hx711-sck-pin gpio-mode
   hx711-power-off #100 ms  hx711-power-on
;

\ To read the load cell, apply 24 pulses on PD_SCK.  Data
\ is valid on DOUT 100 nsec after PD_SCK's rising edge,
\ MSB first.  Then apply 1 to 3 extra pulses to set the
\ gain - 1 pulse (total 25) for 128, 2 for 32, 3 for 64

#24 constant hx711-#bits
1 value hx711-#extra-pulses \ 1: x128, 2: x32, 3: x64

: hx711-read  ( -- n )
   0  hx711-#bits 0  do    ( u )
      hx711-pulse          ( u )
      2* hx711-dout-pin gpio-pin@ 1 and or  ( u' )
      3 us
   loop                    ( u )
   8 << 8 >>a              ( n ) \ Sign extend
   hx711-#extra-pulses 0  do  hx711-pulse  loop
;
: hx711-ready?  ( -- flag )  hx711-dout-pin gpio-pin@ 0=  ;
: hx711-raw-sample  ( -- counts )
   #100 0 do
      hx711-ready?  if
         hx711-read unloop exit
      then
      #10 ms
   loop
   true abort" HX711 not ready"
;
: hx711-average  ( #samples -- )
   0  over 0 ?do         ( #samples sum )
      hx711-raw-sample + ( #samples sum' )
  loop                   ( #samples sum )
  swap /
;
0 value hx711-offset
#1150 value hx711-divisor

: hx711-tare  ( -- )   #20 hx711-average  to hx711-offset  ;
: hx711-sample  ( -- counts )
   begin
      hx711-raw-sample  hx711-offset -    ( delta-counts )
      hx711-polarity *                    ( delta-counts )
   dup 0<  while                          ( delta-counts )
      \ If the sample value is a little smaller than the offset,
      \ it is probably due to drift, so we adjust the offset
      \ and return 0.
      dup hx711-divisor / #-20 >  if      ( delta-counts )
         hx711-polarity *                 ( delta-counts )
         hx711-offset +  to hx711-offset  ( )
         0 exit                           ( -- 0 )
      then                                ( delta-counts )
      \ If it is wildly off, the sample is probably bogus
      \ so we try again.
      drop                                ( )
   repeat                                 ( delta-counts )
;

: hx711-lbs*10  ( -- lbs*10 )
   3 hx711-average  hx711-divisor /
;
: >lbs*10  ( counts -- lbs*10 )  hx711-divisor /  ;
: >lbs  ( counts -- lbs )  hx711-divisor /  5 + #10 /  ;

: >lbs.$  ( counts -- $ )
   >lbs*10  push-decimal  <# u# '.' hold u#s u#>  pop-base
;
: >lbs$  ( counts -- $ )
   >lbs  push-decimal  <# u#s u#>  pop-base
;

\ 0 value hx711-max-counts
: hx711-loop  ( -- )
   hx711-tare
   \ 0 to hx711-max-counts

   begin
      \ hx711-sample hx711-max-counts max to hx711-max-counts
      \ hx711-max-counts >lbs$ type (cr
      hx711-sample dup 0>=  if  >lbs$ type (cr  else  drop  then
   key? until
;
: go
   init-hx711
   hx711-loop
;
