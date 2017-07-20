\ Load file for application-specific Forth extensions

fl ../../platform/arm-teensy3/gpio.fth

: be-in      0 swap m!  ;
: be-out     1 swap m!  ;
: be-pullup  2 swap m!  ;

: go-on      1 swap p!  ;
: go-off     0 swap p!  ;

: wait  ( ms -- )
   get-msecs +
   begin
      dup get-msecs - 0<  key?  or
   until
   drop
;

: lb
   d be-out  e be-out
   begin
      d go-on  d# 125 wait  d go-off
      e go-on  d# 125 wait  e go-off
      key?
   until
;

: .commit  ( -- )  'version cscount type  ;

: .built  ( -- )  'build-date cscount type  ;

: banner  ( -- )
   cr ." CForth built " .built
   ."  from " .commit
   cr
;

: app
   banner
   hex quit
;

" app.dic" save
