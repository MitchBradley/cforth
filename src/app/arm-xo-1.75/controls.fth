[ifdef] rotate-gpio#
: rotate-button?  ( -- flag )
   rotate-gpio# gpio-pin@  0=
;
: check-button?  ( -- flag )
[ifdef] use_mmp2_keypad_control
   scan-keypad 2 and   0=
[else]
   check-gpio# gpio-pin@  0=
[then]
;
: early-activate-cforth?  ( -- flag )  rotate-button?  ;
: activate-cforth?  ( -- flag )  rotate-button?  ;
: show-fb?  ( -- flag )  check-button?  ;
[else]
: early-activate-cforth?  ( -- flag )
   d# 200 ms
   ukey3?      ( flag )
   dup  if
      begin  key?  while  key drop  repeat
   then
;
false constant activate-cforth?
false constant show-fb?
[then]

