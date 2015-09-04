-1 value scanner-fd

defer scanner-missing
: bye-scanner-missing  ( -- )
   ." Plug in scanner then type   ./go" cr
   bye
;
' bye-scanner-missing to scanner-missing

: ?open-scanner  ( -- )
   scanner-fd 0>  if  exit  then

   open-scanner to scanner-fd

   scanner-fd 0<  if
      scanner-missing
   then

   scanner-fd non-blocking
;

0 value ctrl?
0 value shift?
: >shifted  ( code -- char )
   " X"(1b)!@#$%^&*()_+"(0809)QWERTYUIOP{}"(0d)CASDFGHJKL:""~S\ZXCVBNM<>?S*X "
   drop + c@
;
: code>key  ( code -- false | char' true )
   dup #57 >  if  drop false exit  then   ( code )

   shift?  if
      false to shift?
      >shifted
   else
      \ Per KEY_* in /usr/include/linux/input.h
      " X"(1b)1234567890-="(0809)qwertyuiop[]"(0d)Casdfghjkl;'`S\zxcvbnm,./S*X "
      drop + c@   ( char )
      case
         'C' of  true to ctrl?  false exit  endof
         'S' of  true to shift? false exit  endof
         ( default ) dup
      endcase     ( char )
   then
   ctrl?  if  false to ctrl?  h# 1f and  then
   true
;

\ Read Linux input events, sifting out only the key-down ones
\ and translating to ASCII.

\ We don't handle CAPSLOCK; to do that we would have to look at
\ both up and down events to be able to clear the caps lock.
\ Since this is primarily for handling barcode scanners, that's
\ not a problem.

\ This is a struct input_event, consisting of
\ struct timeval time   (which is two C longs - or two Forth cells)
\ __u16 type  (Forth /w)
\ __u16 code  (Forth /w)
\ __s32 value (Forth /l)
2 /n*  2 /w* +  /l + constant /input-event
/input-event buffer: the-event

: input-event-data  ( -- adr )  the-event 2 na+  ;  \ Skips timeval

: scan-char?  ( -- false | char true )
   the-event /input-event scanner-fd h-read-file   ( actual )
   /input-event <>  if  false exit  then           ( )

   \ Want EV_KEY
   input-event-data w@  1 <>  if  false exit  then  ( )

   \ Want key down
   input-event-data 2 wa+ l@  1 <>  if  false exit  then  ( )

   \ Map key code to ASCII
   input-event-data wa1+ w@ code>key
;

: .scanner  ( -- )
   ?open-scanner
   begin  key? if key drop exit  then
      scan-char?  if  emit  then
   again
;

0 [if]
\ This version lets the Linux keyboard driver map events to keys.
\ The problem is that the scanner gets added to the /dev/console
\ keyboard which is then attached by a getty.
: open-scanner  ( -- )
   " /dev/console" h-open-file  dup 0< abort" Can't open scanner"
   to scanner-fd
   scanner-fd non-blocking
;

1 buffer: the-char
: xscan-char?  ( -- false | char true )
   the-char 1 scanner-fd h-read-file   ( actual )
   1 =  if  the-char c@  true  else  false  then
;
[then]
