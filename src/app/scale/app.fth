\ Bathroom scale application

\ This converts an inexpensive digital bathroom scale
\ to a smart scale that can send weight readings to
\ a spreadsheet.  It has the additional benefit of
\ moving the display up to a wall-mounted position
\ where us old folks can read it without crouching
\ down and squinting.

\ Start with an inexpensive digital bathroom scale.
\ Remove the electronics (control board and LCD),
\ leaving the four load cell sensors at the corners.
\ Connect the sensors to an HX711 and connect its
\ digital output to an ESP8266 like a WeMos D1 Mini.

\ The ESP8266 displays the weight reading on a small
\ OLED display.
fl ../../app/esp8266/common.fth

fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

fl ../../app/esp8266/wifi.fth

fl ../../app/esp8266/tcpnew.fth

\needs set-column fl ${CBP}/lib/fb.fth
\needs 'font      fl ${CBP}/lib/font5x7.fth
\needs ssd-init   fl ${CBP}/lib/ssd1306.fth

\needs switch?    fl ${CBP}/app/esp8266/gpio-switch.fth

\needs init-wemos-oled : init-wemos-oled  ( -- )  1 2 i2c-setup  ssd-init  ;

\needs hx711-tare  fl ${CBP}/sensors/hx711.fth
\ Default pins are SCK:5 and DOUT:6
4 to hx711-sck-pin
3 to hx711-dout-pin

\needs ssd-font: fl numfont.fth
\needs numfont   fl numfont-bits.fth

: fb-blank  ( -- )  #10 numfont  ;
: digit-or-blank  ( n -- )  ?dup  0= if  #10  then  ;
: .weight  ( lbs -- )
   0 0 fb-at-xy

   \ Always display the ones digit
   2 set-column
   #10 /mod swap numfont  ( lbs/10 )

   \ Blank both the tens and hundreds digits
   \ if they are both zero, otherwise display
   \ at least the tens digit.
   1 set-column
   ?dup  0=  if           ( )
      fb-blank
      0 set-column fb-blank
      exit
   then                   ( lbs/10)
   #10 /mod swap numfont  ( lbs/100 )

   \ Blank the hundreds digit if it is zero
   \ otherwise display it
   0 set-column
   ?dup  if  numfont  else  fb-blank  then
;

\needs sprintf fl ${CBP}/cforth/printf.fth

\ Connecting directly to script.google.com via HTTP doesn't
\ work because google now insists on secure connections,
\ which are tricky to support directly on ESP8266.  The
\ workaround is to use a proxy on the local network.  See
\ ./README.md for more information.
\ : spreadsheet-host$  ( -- $ )  " script.google.com"  ;

: spreadsheet-host$  ( -- $ )  " 192.168.2.254"  ;  \ HTTP to HTTPS proxy
#6000 value host-port

: spreadsheet-url-prefix  ( -- $ )
   " https://script.google.com/macros/s/AKfycbzoqDrfzZnZxK-xu28QzirvZDwbjd3pXztE_2H9XA/exec?Weight="
;

: dns-handler  ( 'buf 'ipaddr 'name -- )
   drop  ?dup  if  ( 'buf 'ipaddr ) swap 4 move  else  ( buf ) on  then
;
: tcp-out  ( $ -- )  rx-pcb tcp-write drop  ;

0 value holdoff-gpio
: init-holdoff  ( -- )
   0 gpio-output holdoff-gpio gpio-mode
   0 holdoff-gpio gpio-pin!
;

: fb-message  ( $ -- )  0 8 fb-at-xy  fb-type  ;
: slumber  ( -- )
   " Sleeping" fb-message  #500 ms
   ssd-clear
   ." Sleeping" cr

   1 deep-sleep-option!  \ Wakeup RF too
   0 deep-sleep
   #1000 ms
;

4 buffer: host-ip
: resolve-host  ( -- )
   host-ip off
   host-ip ['] dns-handler host-ip spreadsheet-host$ dns-gethostbyname  ( res )
   \ Returns 0 if the name is resolved immediately
   dup 0=  if  drop exit  then
   \ Returns $f4 on error
   $f4 = abort" DNS resolve argument error"
   \ Returns $fb if a request must be sent
   #50 0  do
      host-ip @ ?leave
      #100 ms
   loop
   host-ip @  -1 =  if   
      ." DNS failed" cr
      " DNS" fb-message
      #2000 ms
      slumber
   then
;

: send-get  ( -- $ )
   ['] hx711-sample catch  if  " 160"  else >lbs$  then  ( value )
   spreadsheet-url-prefix
   " GET %s%s HTTP/1.1"r"n"r"n" sprintf
   tcp-out
;   

: $-white  ( $ -- $' )
   begin  dup  while  ( $ )
      2dup + 1- c@  bl >  if  exit  then  ( $ )
      1-              ( $' )
   repeat             ( $ )
;

false value got-average?

: show-average  ( adr len -- )
   $-white  
   push-decimal  $number?  pop-base  if   ( d )
      drop                 ( n )
      ." average is " dup .d cr
      " Average" fb-message
      .weight
      true to got-average?
   else               ( )
      " bad number" fb-message
   then
;

false value is-chunked?

vocabulary html-headers
also html-headers definitions
: Location:  ( redirect$ -- exit? )
   " GET " tcp-out  tcp-out  "  HTTP/1.1"r"n"r"n" tcp-out
   true
;
: Transfer-encoding:  ( type$ -- exit? )  " chunked" $= to is-chunked?  false ;
previous definitions

: -cr  ( $ -- $' )  dup if 2dup 1- + c@ carret =  if 1-  then  then  ;
\ This is called when data is received from the TCP connection
: default-order  ( -- )  only forth also definitions  ;

: handle-body  ( body$ -- )
   linefeed left-parse-string -cr  ( rem$ first-line$ )
   \ If the transfer is chunked, the first line is the chunk length
   \ so we discard it and get the second line
   is-chunked?  if                 ( rem$ first-line$ )
      2drop                        ( rem$ )
      carret left-parse-string     ( rem$' first-line$ )
   then                            ( rem$' first-line$ )
   \ Either way, we don't need the rest so discard it
   2swap 2drop                     ( first-line$ )
   show-average
;
: parse-http  ( adr len -- )
   begin  dup  while        ( adr len )
      linefeed left-parse-string -cr  ( rem$ head$ )
      bl left-parse-string        ( rem$ tail$ word$ )
\ 2dup type cr
      \ If we reach the end of the headers without exiting,
      \ we assume that we have the data we want
      dup 0=  if                  ( rem$ tail$ word$ )
         2drop 2drop              ( rem$ )
         handle-body              ( )
         exit
      then                        ( rem$ tail$ word$ )
      ['] html-headers search-wordlist if  ( rem$ tail$ )
         execute  if 2drop exit then       ( rem$ )
      else                                 ( rem$ tail$ )
         2drop                             ( rem$ )
      then                        ( rem$ )
   repeat                         ( rem$ )
   2drop                          ( )
;

: handle-web-data  ( adr len peer -- )
   drop  ( adr len )
   \ ." Received " dup .d ." bytes" cr  ( adr len )
   \ 2dup type cr  ( adr len )

   \ 5-byte packets are end chunks: 0"r"n"r"n
   dup #5 >  if  parse-http  else  2drop  then
;

\ This is called when the connection succeeds
false value tcp-connected?

: null-sent-handler  ( len pcb arg -- err )  3drop ERR_OK  ;

: web-connected  ( err pcb arg -- stat )
   drop to rx-pcb               ( err )
   ?dup  if                     ( err )
      ." Connect failed, err = " .x  cr 
   else                         ( )
      true to tcp-connected?
      ['] receiver      rx-pcb tcp-recv
      ['] error-handler rx-pcb tcp-err
      ['] null-sent-handler  rx-pcb tcp-sent
   then

   ERR_OK
;

: wait-connected  ( -- )
   #50 0  do
     #100 ms  tcp-connected?   if  unloop  exit  then
   loop
   true abort" TCP connect failed"
;

: check-respond  ( -- flag )
   ['] null-sent-handler rx-pcb tcp-sent  \ Don't install the continuation handler
   got-average?
;

: send-weight-to-sheets  ( -- )
   " wifi-on" included

   resolve-host

   false to got-average?

   false to tcp-connected?
   ['] handle-web-data to handle-peer-data
   ['] check-respond to respond  \ Close the connection after the response

   ['] web-connected host-port host-ip
   tcp-new   ( cb port# host-ip pcb )
   tcp-connect  0<> abort" connect failed"
   wait-connected

   send-get
;

0 value time-limit
: reset-time  ( seconds -- )  #1000000 * timer@ + to time-limit  ;
: ?reset-time  ( lbs -- lbs )  dup 2 >  if  #5 reset-time  then  ;
: show-weight  ( -- )
   #888 .weight
   ['] hx711-tare catch  if
      #777 .weight
      ['] hx711-tare catch  if
         " Scale init failed" fb-message
         #2000 ms
         slumber
      then
   then
   #15 reset-time

   begin
      hx711-sample >lbs ?reset-time  .weight  relax
      switch?  if
         " Sending" fb-message
         send-weight-to-sheets  
         begin  #300 ms  ." ." got-average? until
         #3000 ms
         slumber
      then
      #100 ms
      time-limit timer@ - 0<  if  slumber  then
   key? until
   quit
;
: run  ( -- )
   init-holdoff
   7 init-gpio-switch  init-wemos-oled
   init-hx711
   #200 ms
   show-weight
;

: lcd.error  ( -- )
   dup .error
   -2 =  if 
      'abort$ @ count fb-message
   then
;

: app
   banner  hex
   \ interrupt?  if  quit  then
   ['] run catch fb-message
   slumber
;

" app.dic" save
