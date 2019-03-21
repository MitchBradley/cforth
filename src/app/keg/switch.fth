3 constant switch-pin
: init-switch  ( -- )
   true gpio-input switch-pin gpio-mode
;
: switch?  ( -- flag )
   switch-pin gpio-pin@ 0=
;
: wait-switch-released  ( -- )
   begin  1 ms  switch? 0= until
;
