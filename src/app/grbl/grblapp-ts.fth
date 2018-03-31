fl grbl.fth
fl fb16.fth
fl touchscreen.fth

: touched?  ( -- flag )
   ts-event?  if
      event-type ev-key =  if
         event-code btn-touch =  if
            event-value 1 =  if
               true exit
            then
         then
      then
   then
   false
;
: kill-on-button  ( -- )
   touched?  if  fb-magenta abort  then
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
   open-touchscreen
   begin
      fb-green
      touched?  if  run  then
      #10 ms
   again
;
