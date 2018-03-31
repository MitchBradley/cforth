-1 value ts-fid
: open-touchscreen  ( -- )
   ts-fid 0<  if
      " /dev/input/touchscreen" h-open-file to ts-fid
      ts-fid non-blocking
   then
;
\ This is a struct input_event, consisting of
\ struct timeval time   (which is two C longs - or two Forth cells)
\ __u16 type  (Forth /w)
\ __u16 code  (Forth /w)
\ __s32 value (Forth /l)
2 /n*  2 /w* +  /l + constant /input-event
/input-event buffer: the-event
: input-event-data  ( -- adr )  the-event 2 na+  ;  \ Skips timeval

: ts-event?  ( -- any? )
   the-event /input-event ts-fid h-read-file   ( actual )
   /input-event =
;   
1 constant ev-key
3 constant ev-abs
$14a constant btn-touch
: event-type  ( -- n )  input-event-data w@   ;
: event-code  ( -- n )  input-event-data wa1+ w@   ;
: event-value  ( -- n )  input-event-data 2 wa+ l@   ;

: .events  ( -- )
   begin
      ts-event?  if
         event-type . event-code . event-value . cr
      then
   key? until
   key drop
;
