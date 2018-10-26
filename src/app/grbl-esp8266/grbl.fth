\ GBRL sender that transmits the file "gcode" when you press a button

\ A multicolor LED, and optionally a small OLED display, shows the status

\needs init-gpio-rgb-led fl ../esp8266/gpio-rgb-led.fth

\needs init-gpio-switch  fl ../esp8266/gpio-switch.fth
: wait-switch-pressed  ( -- )  begin  #50 ms  switch? until  ;
: wait-switch-released  ( -- )  begin  #50 ms  switch? 0= until  ;

\ Driver to display text on Wemos Mini OLED display
fl ${CBP}/lib/fb.fth
fl ${CBP}/lib/font5x7.fth
fl ${CBP}/lib/ssd1306.fth

\ The OLED display is optional, so if it fails to initialize
\ we discard any messages sent to it.
0 value oled-active?
: init-oled  ( -- )   1 2 i2c-setup  ['] ssd-init catch 0=  to oled-active?  ;
: oled-line  ( adr len -- )
   oled-active?  if  #columns min fb-type fb-cr  else  2drop  then
;
: oled-cr  ( -- )  oled-active?  if  fb-cr  then  ;

: init-peripherals  ( -- )
   6 5 0  true init-gpio-rgb-led  \ R:D6 G:D5 B:D0 active-high
   3 init-gpio-switch             \ Switch on D3
   init-oled
;

\ Send a character on UART1.  The commonly-used ESP12F modules can
\ only transmit, not receive, on UART1, because the die pins for
\ UART1 Rx are not connected to any external pins on the module.
\ We receive on UART0 Rx via the D7 pin, using system_uart_swap
\ to move the Rx line from its usual pin.  It is tempting to transmit
\ on the swapped D8 pin, but the system fails to boot if GRBL's Rx line
\ is connected to D8 when you first power on the system.  Fortunately,
\ D4 doesn't have that booting problem, so we can 

: tx1  ( c -- )
   \ Wait for space in the FIFO.  At the usual 115200 baud, this should
   \ take no longer than about 100 usec.
   begin  $6000.0f1c l@  #16 rshift  $ff and  $126 >=   while  relax  repeat
   \ Write the character to the FIFO
   $6000.0f00 l!
;

\ Move the UART pins around so we can talk to GRBL instead of to
\ the normal Rx/Tx pins connected to the USB serial chip.
: grbl-setup  ( -- )
   1 2 << $6000.0308 l!    \ Disable GPIO2 on D4 pin
   $20 $6000.0838 l!       \ Set D4 (ESP GPIO2) pin to UART1 TX
   system_uart_swap #10 ms \ KEY listens on D7
;
\ Restore UART0 to the normal Rx/Tx pins, so we can debug if necessary 
: grbl-teardown  ( -- )
   system_uart_de_swap     \ Restore KEY to normal RX pin
   #out off
;
: grbl-write  ( adr len -- )  bounds  ?do  i c@ tx1  loop  ;


#1000 constant ticks/ms
0 value time-limit
: set-timeout  ( #ms -- )  ticks/ms *  timer@ + to time-limit  ;
: timeout?  ( -- flag )  timer@ time-limit - 0>=  ;

0 value time-ms
: +time-limit  ( -- )  time-ms set-timeout  ;


\ Depends on system_uart_swap having been previously run so
\ that key? and key, which use UART0, read GRBLs Tx via D7
: grbl-read-timed  ( adr len ms2 ms1 -- -1 | #read )
   set-timeout  to time-ms               ( adr len )
   tuck  0 ?do                           ( len adr )
      begin  key? 0=  while              ( len adr )
         1 ms                            ( len adr )
         timeout?  if                    ( len adr )
            2drop  i unloop exit         ( -- #read )
         then                            ( len adr )
      repeat
      key  over i + c!                   ( len adr )
      +time-limit                        ( len adr )
   loop                                  ( len adr )
   drop                                  ( #read )
;

\ This last-was-status? dance lets us display GRBL coordinate status
\ on a single display line, then switch to a new line when something
\ else needs to be displayed.
false value last-was-status?
: ?add-cr  ( -- )
   last-was-status?  if
     oled-cr
     false to last-was-status?
   then
;
: ?oled-pad-line  ( n -- )  ?dup  if  pad swap oled-line  then  ;
: wait-grbl-quiet  ( -- )  pad #100 #10 #100 grbl-read-timed  ?oled-pad-line  ;

\ Unused; we don't have a connection to the GRBL reset line, so we
\ cannot force a reset except by power cycling.  GRBL will have
\ already issued its signon message by the time we can configure
\ the serial port to see it.
: wait-grbl-signon  ( -- len )  pad #100 #200 #3000 grbl-read-timed  ;

#256 constant /response
/response buffer: response-buf
0 value #response
: response$  ( -- adr len )  response-buf #response  ;

\ Entry/exit condition: response-buf does not contain a complete line
\ Action: Add any available Rx characters to the buffer.  Remove
\ and handle any complete lines that result

: remove-line  ( index -- )
   response$ rot /string      ( tail$ )
   dup to #response           ( tail$ )
   response-buf swap move     ( )
;

\ The GRBL buffer is in the controller.  We track its free space.
\ When #grbl-avail is more than the next gcode line length, we
\ send that line.
#127 constant /grbl-buf      \ Total size of GRBL input buffer
/grbl-buf value #grbl-avail  \ Free space in GRBL input buffer

\ The local gcode buffer holds lines that have already been
\ sent to GRBL, plus one line waiting to be sent.
\ As acks ("ok") arrive from GRBL, the oldest, i.e. the first,
\ line is removed from the local buffer.

/grbl-buf 2* constant /gcode-buf
/gcode-buf buffer: gcode-buf
0 value #gcode            \ Occupied space in our gcode buffer
0 value /next-gcode-line  \ Length of line waiting to be sent
: gcode-buf-avail  ( -- n )  /gcode-buf #gcode -  ;
: gcode-buf-end  ( -- adr )  gcode-buf #gcode +  ;
: 'next-gcode-line  ( -- n )  gcode-buf-end /next-gcode-line -  ;

\needs cindex fl lex.fth

\ The oldest GCode line is the first one in the buffer.
\ It is the first one that GRBL has not yet acknowledged.
: oldest-gcode-linelen  ( -- n )
   #gcode 0=  if  0 exit  then
   gcode-buf #gcode carret cindex  ( false | adr true )
   dup 0=  if  grbl-teardown  then
   0= abort" Error: missing newline in GCode buffer"  ( adr )
   gcode-buf -  1+      ( n )
;

\ When a GRBL ACK ("ok") is received, we remove the oldest
\ line in our buffer and update #grbl-avail to reflect
\ the amount of space now available in the GRBL input buffer.
: remove-gcode-line  ( -- )
   oldest-gcode-linelen               ( len )
   dup #grbl-avail + to #grbl-avail   ( len )
   #grbl-avail /grbl-buf >  if        ( len )
      grbl-teardown
      ." GRBL buf underflow"
      debug-me
   then                               ( len )
   ?add-cr gcode-buf over 1- oled-line  ( len )
   #gcode over - to #gcode            ( len )
   gcode-buf + gcode-buf #gcode move  ( )
;

false value gcode-eof-reached?
: gcode-sent?  ( -- flag )
   #gcode 0=  gcode-eof-reached? and
;

0 value gcode-fid
/grbl-buf constant max-gcode-line

\ Move a GCode line from the input file to the transmit buffer
\ It will be sent when GRBL has room in its input buffer
: read-gcode-line  ( -- )
   gcode-eof-reached?  if  exit  then
   gcode-buf-end /grbl-buf gcode-fid ( adr len fid )
   read-line  if  #-98 throw  then   ( cnt more? )
   dup 0= to gcode-eof-reached?      ( cnt more? )
   if                                ( cnt )
      1+ to /next-gcode-line         ( )
      #gcode /next-gcode-line +  to #gcode  ( )
      carret gcode-buf-end 1- c!     ( )
   else                              ( cnt )
      drop                           ( )
   then                              ( )
;
: ?read-gcode-line  ( -- )
   /next-gcode-line 0=  if  read-gcode-line  then
;

1 [if]
: request-grbl-status  ( -- )  ;
: show-status  ( adr len -- )  2drop  ;
[else]
0 value #grbl-lines
: show-send-status  ( -- )
   ." #grbl-avail " #grbl-avail .
   ." #gc "  #gcode .
   ." /gc "  /next-gcode-line .
   cr
;
: request-grbl-status  ( -- ) " ?" grbl-write  ;
: show-status  ( adr len -- )  1- type (cr  ;
[then]

\ If there is a GCode line waiting to be sent and
\ GRBL has room, send it.
: ?send-grbl-line  ( -- )
   /next-gcode-line 0=  if  exit  then
   /next-gcode-line #grbl-avail <=  if
      'next-gcode-line /next-gcode-line grbl-write
      #grbl-avail /next-gcode-line - to #grbl-avail
      0 to /next-gcode-line
   then
;

\ Handlers for the various GRBL responses
: handle-ok  ( -- )
   2drop remove-gcode-line
   \ Update transmit buffer stats
;
: handle-status  ( adr len -- )
   show-status
   true to last-was-status?
;
: handle-error  ( adr len -- )
   oled-line
   remove-gcode-line
;
: handle-other  ( adr len -- )
   ?add-cr  oled-line
;

: $starts-with?  ( $1 $2 --  flag )
   2 pick over <  if  2drop 2drop false exit  then
   rot drop tuck $=
;
: handle-grbl-response  ( adr len -- )
   dup 0=  if  2drop exit  then  ( adr len )
   2dup " ok"  $=  if   ( adr len )
      handle-ok  exit
   then
   2dup " error"  $starts-with?  if  ( adr len )
      handle-error  exit
   then
   over c@ '<' =  if   ( adr len )
      handle-status  exit
   then
   handle-other
;

\ Read any available response characters from GRBL into our buffer.
\ When complete lines are present in the buffer, process and remove them.
: get-response  ( -- )
   response-buf /response  #response /string          ( adr len )
   #10 #200 grbl-read-timed                           ( #read )
   dup 0<=  if  drop request-grbl-status  exit  then  ( #read )
   #response + to #response                           ( )
   begin  response$ linefeed cindex  while            ( lf-adr )
      response-buf -                                  ( lf-offset )
      response-buf over 1- handle-grbl-response       ( lf-offset ) \ Omit CR with 1-
      1+ remove-line                                  ( )           \ Omit LF with 1+
   repeat                                             ( )
;

\ Ensure that GRBL is responsive
: sync-grbl  ( -- error? )
   " "r" grbl-write
   \ GRBL should respond quickly to the carriage return by
   \ sending an "ok".  We read everything that comes back.
   \ It's an error if we get nothing.
   pad #200  #50 #1000 grbl-read-timed 0=
;

: $send-gcode-file  ( filename$ -- error? status$ )
   r/o open-file  if  drop true " No gcode" exit  then  ( fid )
   sync-grbl if  true  " no GRBL"  exit  then
   to gcode-fid  ( )
   false to gcode-eof-reached?
   0 to #gcode
   /grbl-buf to #grbl-avail
   begin  gcode-sent? 0=  while
      get-response
      ?send-grbl-line
      ?read-gcode-line
   repeat
   gcode-fid close-file drop
   false " DONE"
;
: send-the-file  ( -- ) 
   grbl-setup   
   " gcode" $send-gcode-file
   grbl-teardown
;

\ UI based on a switch, a multicolor LED, and optionally a small text display
\ When the LED is yellow it is ready to go.  Press the switch to start and
\ the LED turns green while sending.  If all goes well, the LED turns yellow
\ again to start over.
\ If an error occurs the LED turns red and you have to press/release the switch
\ to acknowledge the problem and get back to yellow.
: run  ( -- )
   init-peripherals
   begin      
      yellow-led  " READY" oled-line
      wait-switch-pressed
      green-led   " SENDING" oled-line
      wait-switch-released
      send-the-file  oled-line  if
         red-led     wait-switch-pressed
         magenta-led wait-switch-released
      then
   again
;
