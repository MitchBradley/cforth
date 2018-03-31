fl grbl.fth
fl fb16.fth
fl raspi-gpio.fth

: kill-on-button  ( -- )
   #1000 gpio17-event?  if  fb-magenta  abort  then
;

: run
   ['] kill-on-button to handle-ui-events

   fb-red
   ['] t catch  if
      \ #2000 ms
   then
;
: fb-ui  ( -- )
   open-fb
   setup-gpios
   begin
      fb-green
      #100000 gpio17-event?  if  run  then
   again
;
