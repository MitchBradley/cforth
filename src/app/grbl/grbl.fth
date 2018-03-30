false value show-gcode?   \ Show GCode lines as they are sent
false value show-ack?     \ Show OK/Error ack lines as they are received
false value show-line#?   \ Show how many lines have been executed and how many are queued
false value show-buf?     \ Show the space left in GRBL's Rx buffer
true value show-time?     \ Show the elapsed time in seconds

0 value comport

: flush-grbl  ( -- )
   pad #1000  #500 comport timed-read-com pad swap type
;
: open-grbl  ( -- )
   comport if exit then
   0 open-com to comport
   comport 0< abort" Can't open serial port"
   #115200 comport baud
   flush-grbl
   #2000 ms
   flush-grbl
;
: r  pad #100  #100 comport timed-read-com  pad swap type  ;
: send-gcode-line  ( adr len -- )  comport write-com drop  ;
: w  0 parse  send-gcode-line  " "n" send-gcode-line  r r  ;

#128 constant /rxbuf
/rxbuf cells buffer: linelens
0 value #queued-lines
0 value bufavail
0 value time0

0 value sent-line#
0 value executed-line#

: .lines  ( -- )
   show-line#?  if  executed-line# .d  sent-line# executed-line# - .d   then
   show-buf?  if  bufavail .d   then
   show-time?  if  get-msecs time0 - #1000 / .d  then
   #out @  if  (cr  then
;

: -line  ( -- )
   #queued-lines 0=  if  exit  then
   bufavail  linelens @  + to bufavail
   #queued-lines 1- to #queued-lines
   linelens cell+  linelens  #queued-lines cells move
   executed-line# 1+ to executed-line#
;
: +line  ( linelen -- )
   dup  linelens #queued-lines cells + !  ( linelen )
   bufavail swap -  to bufavail
   #queued-lines 1+ to #queued-lines
   sent-line# 1+ to sent-line#
;

/rxbuf 2+ buffer: the-line

/rxbuf buffer: response-buf
0 value #response

: parse-response  ( -- )
    response-buf #response #10 left-parse-string  ( rem-adr rem-len begin-adr begin-len )
    \ XXX Check for ok or error, if not then print line
    dup  if      ( rem-adr rem-len begin-adr begin-len )
       -line
       show-ack?  if  type cr  else  2drop  then
    else
       2drop
    then
    ( rem-adr rem-len )
    to #response   response-buf #response move  ( )
;

: handle-rx  ( -- )
   response-buf  /rxbuf #response -  #10 comport timed-read-com  dup 0<  if  ( actual | -1 )
      drop                          ( )
   else                             ( actual )
      #response +  to #response     ( )
   then                             ( )
   parse-response
;

: wait-ready  ( -- )
   begin
      handle-rx
      bufavail 0>
   until
;

0 value fid

0 value linelen

: send-line  ( -- done? )
   the-line /rxbuf fid read-line abort" Read failed"  ( actual more? )
   0=  if  drop true  exit  then                      ( actual )
   #10 the-line 2 pick + c!  1+ to linelen            ( )
   linelen +line                                      ( )
   wait-ready                                         ( )
   show-gcode?  if  the-line linelen type  then       ( )
   the-line linelen send-gcode-line                   ( )
   .lines                                             ( )
   false                                              ( false )
;

: $send-file  ( filename$ -- )
   open-grbl

   0 to #queued-lines
   0 to sent-line#
   0 to executed-line#
   /rxbuf to bufavail
   get-msecs to time0

   r/o open-file abort" Can't open input file" to fid
   begin  send-line  until
   fid close-file drop
;
: send  ( "filename" -- )  safe-parse-word $send-file  ;
: t " LogoArray.gcode" $send-file  ;
