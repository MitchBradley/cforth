\ Sends GCode to a GRBL CNC controller
\ ok send MyFile.gcode

\ Verbosity controls
false value show-gcode?   \ Show GCode lines as they are sent
false value show-ack?     \ Show OK/Error ack lines as they are received
false value show-line#?   \ Show how many lines have been executed and how many are queued
false value show-buf?     \ Show the space left in GRBL's Rx buffer
false value show-time?     \ Show the elapsed time in seconds

-1 value comport  \ File handle for serial port

\ User interface event handler
defer handle-ui-events

\ Simple UI.  Type q to exit, anything else gets you back to the Forth ok prompt
: key-ui  key?  if  key 'q' =  if  bye  else  abort  then  then  ;
' key-ui to handle-ui-events

: read-grbl  ( timeout-ms -- adr len )
   pad #4  rot comport timed-read-com   0 max   pad swap
;

: flush-grbl  ( initial-timeout -- )
    read-grbl     ( adr len )
    begin  dup  while  ( adr len )
       type            ( )
       #100 read-grbl  ( adr len )
    repeat             ( adr len )
    2drop              ( )
;
: send-gcode-line  ( adr len -- )  comport write-com drop  ;
: reset-grbl  ( -- )
   #500 flush-grbl

   " "(18)" send-gcode-line
   #1000 flush-grbl
   #1000 flush-grbl
   " $X"n" send-gcode-line
   #1000 flush-grbl
   #1000 flush-grbl
;
: open-grbl  ( -- )
   comport 0>=  if exit then
   0 open-com to comport
   comport 0< abort" Can't open serial port"
   #115200 comport baud
   #500 flush-grbl
   #500 flush-grbl
   reset-grbl
;
: close-grbl  ( -- )
   comport 0<  if
      comport close-com
      -1 to comport
   then
;

\ A couple of convenience words for interactive testing
: r  #100 flush-grbl  ;
: w  0 parse  send-gcode-line  " "n" send-gcode-line  r r  ;

#128 constant /rxbuf           \ The size of GRBL's Rx buffer, determined externally

/rxbuf cells buffer: linelens  \ Array of lengths of lines queued in GRBL's Rx buffer
0 value #queued-lines          \ The number of lines queued in GRBL's Rx buffer
0 value bufavail               \ Current free bytes in GRBL's Rx buffer

0 value sent-line#             \ The number of lines that have been sent so far
0 value executed-line#         \ The number of lines that have been executed so far

0 value time0                  \ Start time in milliseconds

\ Show some statistics
: .q  ." q "   #queued-lines 0 ?do  linelens i na+ @ .d   loop  ;
defer show-stats
: type-stats  ( -- )
   show-line#?  if  executed-line# .d  sent-line# executed-line# - .d   then
   show-buf?  if  bufavail .d   then
   show-time?  if  get-msecs time0 - #1000 / .d  then
   #out @  if  (cr  then
;
' type-stats to show-stats

\ Remove a line from the queued list and increase the buffer count by its length
\ Called with an ack ('ok') is received from GRBL
: -line  ( -- )
   #queued-lines 0=  if  exit  then
   bufavail  linelens @  + to bufavail
   #queued-lines 1- to #queued-lines
   linelens cell+  linelens  #queued-lines cells move
   executed-line# 1+ to executed-line#
;

\ Add a line from the queued list and decrease the buffer count by its length
\ Called when a line is sent to GRBL
: +line  ( linelen -- )
   dup  linelens #queued-lines cells + !  ( linelen )
   bufavail swap -  to bufavail
   #queued-lines 1+ to #queued-lines
   sent-line# 1+ to sent-line#
;

/rxbuf 2+ buffer: the-line     \ The next line to be sent to GRBL

/rxbuf buffer: response-buf    \ Buffer to accumulate response lines from GRBL
0 value #response              \ The number of bytes in response-buf

\ Remove trailing carriage return, if present
: -cr  ( $ -- $' )
   ?dup  0=  if  exit  then  ( $ )
   2dup 1- +  c@  #13  =  if  1-  then   ( $- )
;

\ Interpret GRBL response data
: parse-response  ( -- )
    response-buf #response " "(0a)" lex  if          ( tail$ head$ char )

       \ The response data contains a complete line
       drop                                          ( tail$ head$ )

       \ If the response line isn't empty, record that a queued line has been processed
       -cr   dup  if                                 ( tail$ head$ )
          -line                                      ( tail$ head$ )

          2dup  " ok"  compare  if                   ( tail$ head$ )
             \ Display error lines
             type cr                                 ( tail$ )
          else                                       ( tail$ head$ )
             \ Show ok acks only if asked to
             show-ack?  if  cr type cr  else  2drop  then  ( tail$ )
          then                                       ( tail$ )
       else                                          ( tail$ )
          2drop                                      ( )
       then

       \ If there is any trailing data in the response buffer, move it to the beginning
       to #response  response-buf #response move     ( )

    else                                             ( $ )
       \ No linefeed; so far the line is incomplete
       2drop                                         ( )
    then                                             ( )
;

\ Handle GRBL response if available
: handle-rx  ( -- )
   response-buf /rxbuf  #response /string    ( adr len )
   #1 comport timed-read-com  dup 0<  if     ( actual | -1 )
      drop                          ( )
   else                             ( actual )
      #response +  to #response     ( )
   then                             ( )
   parse-response
;

\ Wait until there is room in GRBLs Rx buffer, meanwhile handling events
: wait-ready  ( -- )   begin  handle-ui-events  handle-rx   bufavail 0>  until  ;

0 value fid
0 value linelen

\ Get one GCode line from the input file and send it when GRBL has room
: send-line  ( -- done? )
   the-line /rxbuf fid read-line abort" Read failed"  ( actual more? )
   0=  if  drop true  exit  then                      ( actual )
   #10 the-line 2 pick + c!  1+ to linelen            ( )
   linelen +line                                      ( )
   wait-ready                                         ( )
   show-gcode?  if  the-line linelen type  then       ( )
   the-line linelen send-gcode-line                   ( )
   show-stats                                         ( )
   false                                              ( false )
;

\ Send a GCode file to GRBL
: send-lines  ( -- )   begin  depth 0<  if ." Stack Underflow !!!" cr  bye then  send-line until  ;
: $send-file  ( filename$ -- )

   0 to #queued-lines
   0 to sent-line#
   0 to executed-line#
   /rxbuf to bufavail
   get-msecs to time0

   r/o open-file abort" Can't open input file" to fid

   open-grbl
   ['] send-lines  catch       ( aborted? )
   dup  if  reset-grbl  then   ( aborted? )
   close-grbl                  ( aborted? )
   
   fid close-file drop         ( aborted? )
   throw
;

: send  ( "filename" -- )  safe-parse-word $send-file  ;

: t " GCode/LogoArray.gcode" $send-file  ;
