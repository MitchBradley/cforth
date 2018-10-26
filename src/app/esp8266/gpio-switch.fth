\ Driver for switch connected to a GPIO

3 value switch-gpio
: init-gpio-switch  ( gpio# -- )
   to switch-gpio
   true  gpio-input  switch-gpio gpio-mode
;
: switch?  ( -- flag )  switch-gpio gpio-pin@ 0=  ;
