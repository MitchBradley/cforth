: init-fixture  ( -- )
   1 select-mcp8
   0 0 mcp8-b!  \ All pins are outputs
;

: led-off  ( gpio# -- )  mcp8-gpio-clr  ;
: led-on  ( gpio# -- )  mcp8-gpio-set  ;

0 constant red-gpio
1 constant green-gpio
2 constant blue-gpio

: led-color  ( color -- )
   9 mcp8-b@ 7 invert and  or  9 mcp8-b!
;

: led-color:  ( n "name" -- )  create ,  does> @ led-color  ;
0 constant led-black
1 constant led-red
2 constant led-green
3 constant led-yellow
4 constant led-blue
5 constant led-magenta
6 constant led-cyan
7 constant led-white

: >relay-gpio  ( relay# -- gpio# )  3 +  ;
: relay-on  ( relay# -- )  >relay-gpio mcp8-gpio-set  ;
: relay-off  ( relay# -- )  >relay-gpio mcp8-gpio-clr  ;
