: init-pulser  false gpio-output 0 gpio-mode  ;
#100 value frequency
: half-period  ( -- ms )  #500 frequency /  ;
: pulse  ( -- )
   begin
      half-period ms  1 0 gpio-pin!  half-period ms  0 0 gpio-pin!
   key? until
;
init-pulser
