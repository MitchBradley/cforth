\ Driver for Wemos RGB LED shield
\ The LED is a WS2812B connected to D2

: init-wemos-led  ( -- )  2 1 4 init-ws2812b  ;
: led!  ( rgb -- )
   lbsplit              ( b g r 0 )
   drop  rot  0         ( g r b 0 )
   bljoin               ( brg )
   sp@ 3 write-ws2812b  ( brg )
   drop
;
: led:  ( rgb "name" -- )  create ,  does> @ led!  ;
$000000 led: black-led
$0000ff led: blue-led
$00ff00 led: green-led
$ff0000 led: red-led
$00ffff led: cyan-led
$ffff00 led: yellow-led
$ff00ff led: magenta-led
$ffffff led: white-led
$ff3000 led: orange-led


