0 value comport
false value verbose?
0 value sent-line#
0 value executed-line#
: flush-grbl  ( -- )
   pad #1000  #1000 comport timed-read-com pad swap type
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
0 value fid
/rxbuf cells buffer: linelens
0 value #lines
0 value ccount
: -line  ( -- )
   #lines 0=  if  exit  then
   ccount  linelens @  - to ccount
   #lines 1- to #lines
   linelens cell+  linelens  #lines cells move
   executed-line# 1+ to executed-line#
;
: +line  ( linelen -- )
   dup  linelens #lines cells + !  ( linelen )
   ccount +  to ccount
   #lines 1+ to #lines
   sent-line# 1+ to sent-line#
;

/rxbuf 2+ buffer: the-line

/rxbuf buffer: response-buf
0 value #response

: .lines  ( -- )
   sent-line# .d executed-line# .d (cr
;
: parse-response  ( -- )
    response-buf #response #10 left-parse-string  ( rem-adr rem-len begin-adr begin-len )
    \ XXX Check for ok or error, if not then print line
    dup  if      ( rem-adr rem-len begin-adr begin-len )
       -line
       verbose?  if  type cr  else  2drop  .lines  then
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
      ccount /rxbuf 1- <
   until
;

: send-line  ( -- done? )
   the-line /rxbuf fid read-line abort" Read failed"  ( actual more? )
   0=  if  drop true  exit  then                      ( actual )
   #10 the-line 2 pick + c!  1+                       ( linelen )
   dup +line                                          ( linelen )
   wait-ready                                         ( linelen )
   verbose?  if  the-line over type  then
   the-line swap send-gcode-line                      ( )
   false                                              ( false )
;

: $send-file  ( filename$ -- )
   open-grbl
   r/o open-file abort" Can't open input file" to fid
   begin  send-line  until
   fid close-file drop
;
: send  ( "filename" -- )  safe-parse-word $send-file  ;
: t " LogoArray.gcode" $send-file  ;
