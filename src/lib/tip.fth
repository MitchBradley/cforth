\ Connect diagnostic console through to the remote serial port

\ tip ( -- )
\    Transfer characters between the device under test
\    and the console until "^]" (control-]) is typed.

: (tip)  ( -- )
   begin
      key?  if
         key  case
            control ]   of  exit       endof
            control S   of  ptt-off    endof
            control Q   of  start-app  endof
            ( default )  dup  rem-emit
         endcase  
      then
      rem-avail?  if  emit  then
   again
;

: tip  ( -- )
   rem-off
   start-app
   ." Interrupt character is ^]" cr
   (tip)
;

: tip-bootloader  ( -- )
   rem-off
   init-rem-uart
   flush-rem
   rem-power-cycle
   ." Interrupt character is ^]" cr
   (tip)
;

