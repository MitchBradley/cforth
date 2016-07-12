\ Driver for speaker pump via 8388 motor driver
\ D12 is enable, D11 is phase

: init-pump  ( -- )  #12 gpio-is-output  #11 gpio-is-output  ;
: set-phase  ( -- )  if  1 #11 gpio-pin!  else  0 #11 gpio-pin!  then  ;
: en-on  ( -- )  1 #12 gpio-pin!  ;
: en-off  ( -- )  0 #12 gpio-pin!  ;
3 value half
: buzz  ( #counts -- )  0 ?do  en-on half ms  en-off half ms  loop  ;
: buzz2  ( #counts -- )
   en-on  0 ?do  0 set-phase half ms  1 set-phase half ms  loop  en-off
;
