\ Teensy 3.1 has LED to ground on pin PTC5
: led-gpio##  ( port# pin# -- )  port-c#  5  ;

: led-init
   0 +af1 +dse  led-gpio##  pcr!
   led-gpio##  gpio-dir-out
;

: led-on      led-gpio##  gpio-set     ;
: led-toggle  led-gpio##  gpio-toggle  ;
: led-off     led-gpio##  gpio-clr     ;

: blink
   led-init
   begin
      led-on  d# 100 ms  led-off  d# 900 ms
      key?
   until
;

: d12-gpio##  port-d# 7  ;
: d12-init  0 +af1 +dse d12-gpio## pcr! d12-gpio## gpio-dir-out  ;

: d12-blink
   d12-init
   begin
      d12-gpio## gpio-set d# 10 ms  d12-gpio## gpio-clr d# 90 ms
      key?
   until
;
