needs sclk-gpio spi_master.fth

marker -spi_ledstrip_apa102.fth

DECIMAL

-1  to miso-gpio           #4000000 to SpiSpeed

4   value #Leds            0   value /ledstrip
0   value seed             4   constant /ledframe
0   value &ledstrip        0 value &SavedStrip
20  variable LightLevel    LightLevel !
    variable LedstripPtr   &ledstrip LedstripPtr !
$FF variable filter        filter !
224 constant PrefixCmd


0 [if]
begin-structure /ledframe
      cfield: LedCmd \ For 0xE0 and 31 levels of brightness
      cfield: LedBlue
      cfield: LedGreen
      cfield: LedRed
end-structure
[THEN]

8 constant #bits/byte
: .c      ( n - ) s>d <# bl hold  # # # #>  type ;
: .c@     ( adr - )  c@ .c ;
: 4dup            ( n1 n2 n3 n4 - n1 n2 n3 n4  n1 n2 n3 n4 ) 2over 2over ;
: 4drop           ( n1 n2 n3 n4 - )       2drop 2drop ;
: ledOffset  ( led# - adrOffset ) 1+  /ledframe * ;
: >led       ( led# - adr ) ledOffset LedstripPtr @ + ;
: SetCmd          ( Brightness - LedCmd ) 31 min PrefixCmd or ;
: #EndingBytes ( - #cells ) #Leds 2 / #bits/byte / 1 + ;
: ResetStartFrame ( - )      LedstripPtr @ off ;
: SetEndFrame     ( - )      #Leds >led #EndingBytes $ff fill ;
: init-seed       ( - )      random 7 * + get-msecs + to seed ;

: initApa102      ( - )
   InitSpiMaster
   #Leds 1 + /ledframe * #EndingBytes + dup to /ledstrip allocate throw
   dup to &ledstrip LedstripPtr !
   /ledstrip  allocate throw  to &SavedStrip
;
: >led!      ( Red Green Blue Cmdlevel led# - )
    >led dup >r c!
    r@ 1+   c!
    r@ 2 +  c!
    r> 3 +  c!
;
: DumpStrip       (  - )
    cr ." # Level red grn blue"
    #Leds 0   do
       cr i  .c space i >led
       dup c@ ( 15 and ) .c
       dup 3 + .c@
       dup 2 + .c@
       1+      .c@
    loop
;
: Rnd        ( -- rnd )
    seed dup 0= or   dup 13 lshift xor   dup 17 rshift xor
    dup 5 lshift xor dup to seed
;
: SetLed     ( cmd r g b - LedParm )
   8 lshift swap    #16 lshift or    swap #24 lshift   or or
;
: FillLeds ( red green blue brightness #Leds FirstLed# - )
    >r >r SetCmd r> r> do
       4dup i  >led!
    loop  4drop
;
: .Strip   ( - )
    ResetStartFrame  SetEndFrame  &ledstrip  /ledstrip spi-master-write
;
: clr-Strip ( - )  0 0 0 0 #Leds 0 FillLeds ;
: StripOff  ( - )  &ledstrip LedstripPtr !  clr-Strip .Strip ;

1 [IF] \ Use

: StripRed   ( - )   10 0 0 16 #Leds 0 FillLeds .Strip ;
: StripGreen ( - )   0 10 0 16 #Leds 0 FillLeds .Strip ;
: StripBlue  ( - )   0 0 10 16 #Leds 0 FillLeds .Strip ;

: rndLed ( - r g b brightness )
   Rnd filter @ and  ( 5 max ) Rnd filter @ and Rnd filter @ and Rnd
   LightLevel @ and 1 max SetCmd
;
: rndStrip ( -)
    #Leds 0  ?do
      rndLed  i >led!
    loop
;
: rndLoops ( #loops MSTimeOut  - )
   swap 0  ?do
     rndStrip  dup ms  .Strip
   loop  drop
;
: rndShow (  #rndLoops - )
   dup init-seed   dup 0   ?do
      i dup * 1+
      over i - dup * 4 * 30 max   rndLoops
   3 +loop  drop
;
initApa102  \ StripOff StripBlue
cr .( Start blinking.. )
8 filter !
StripBlue 500 ms StripRed 500 ms  StripGreen 300 ms  #10 rndShow 400 ms

quit
: EndlesLoops ( - ) begin 3 rnd $3ff and  rndloops again ;
EndlesLoops
quit
[THEN]

\ \s

