defer tx
#256 constant /chunk
/chunk buffer: reply-buf
0 value reply-len
: flush-reply  ( -- )
   reply-len  if
      '*' sys-emit
      reply-buf reply-len tx
      0 to reply-len
   then
;
: reply  ( c )
   reply-len /chunk =  if  flush-reply  then  ( c )
   reply-buf reply-len + c!                   ( )
   reply-len 1+ to reply-len                  ( )
;
: reply+emit  ( c -- )  dup sys-emit  reply  ;
: reply+cr  ( -- )  #13 reply  #10 reply+emit  ;
: reply-on  ( -- )
   ['] reply+emit to (emit
   ['] reply+cr   to cr
;
: reply-off  ( -- )
   ['] sys-emit to (emit
   ['] sys-cr   to cr
;
: reply{  ( -- )  0 to reply-len  reply-on  ;
: }reply  ( -- )  flush-reply   reply-off  ;

#80 value port   0 value server  0 value client
: tcp-transmit  ( adr len -- )
reply-off
   begin       ( adr len )
      2dup client 
.s cr
send  
.s cr
case      ( adr len )
         0 of  2drop 
reply-on  exit  endof  ( adr len )
        -7 of  'W' sys-emit #400 ms 'w' sys-emit       endof  ( adr len )  \ retry after a delay
        ( default )  ." TCP error " .d cr  2drop exit
      endcase
   again
;
' tcp-transmit to tx
alias t tcp-transmit
: tcr ( -- )  " "r"n" tcp-transmit  ;

#128 buffer: file-buf
: remove-eofs  ( adr len -- adr len' )
   begin  dup  while
      2dup + 1- c@ $1a <>  if  exit  then
      1-
   repeat
;
0 value verbose?
: t-send-file  ( filename$ -- )
   r/o open-file  if  drop ." File open failed" cr exit  then  >r
   begin
      file-buf #128 r@ read-file  drop  ( actual )
   ?dup while                           ( actual )
      file-buf swap remove-eofs         ( adr len )
      verbose?  if  2dup type  then     ( adr len )
      tcp-transmit                      ( )
   repeat
   r> close-file drop
;

: hello  " Hello from ESP8266" tcp-transmit  ;
defer homepage   ' hello to homepage
defer server-init  ' noop to server-init
: collapse$  ( adr len n -- adr len-n )
   >r  r@ -            ( adr len-n  r: n )
   over dup r> +       ( adr len-n  adr adr+n )
   swap 2 pick  move   ( adr len-n )
;
: url%  ( $ -- $' )
   dup 3 <  if  exit  then          ( adr len )
   over 1+ 2                        ( adr len  number$ )
   push-hex $number pop-base  if    ( adr len n )
      1 /string                     ( adr' len' )
   else                             ( adr len n )
      2 pick c!                     ( adr len )
      1 /string                     ( adr' len' )
      2 collapse$                   ( adr' len' )
   then                             ( adr len )
;

: urldecode$  ( $ -- $' )
   over swap             ( adr adr len )
   begin  ?dup  while    ( adr rem-adr  len )
      over c@ '%' =  if  ( adr rem-adr  len )
	 url%            ( adr rem-adr' len' )
      else               ( adr rem-adr  len )
	 1 /string       ( adr rem-adr' len' )
      then               ( adr rem-adr' len' )
   repeat                ( adr rem-adr )
   over -                ( adr len )
;
0 value args-adr
0 value args-len
: parse-args  ( url$ -- filename$ )
   '?' left-parse-string            ( arg$ filename$ )
   2swap  to args-len  to args-adr  ( filename$ )
;
: $=  ( $1 $2 -- )  compare 0=  ;
: find-cmd  ( -- false | val$ true )
   args-adr args-len urldecode$ ( $ )
   2dup tcp-transmit  tcr       ( $ )
   begin  dup  while            ( $ )
      '&' left-parse-string     ( $'  head$ )
      '=' left-parse-string     ( $   val$ name$ )
      " cmd" $=  if             ( $  val$ )
	 2swap 2drop true exit  ( -- val$ )
      else                      ( $  val$ )
         2drop                  ( $ )
      then                      ( $ )
   repeat                       ( $ )
   2drop false                  ( false )
;

: do-forth  ( -- )
    find-cmd  if  reply{ evaluate }reply  then
;
#256 buffer: url-buf
0 value url-len
: save-url  ( adr len -- )
   dup to url-len      ( adr len )
   url-buf swap move   ( )
;

: handle-rcv  ( -- )
   7 client tcp-bufcnt!
   \ client .espconn   
   url-buf url-len                      ( url$ )
   http-get?  if                        ( url$ )
      2dup " /favicon.ico" $=  if       ( url$ )
         2drop                          ( )
      else                              ( url$ )
         ." URL: " 2dup type cr         ( url$ )
         1 /string                      ( url$' )
         parse-args                     ( filename$ )
         dup  if                        ( filename$ )
            2dup  " forth"  $=  if      ( filename$ )
	       2drop  do-forth          ( )
            else                        ( filename$ )
	       t-send-file              ( )
	    then                        ( )
	 else                           ( null$ )
            2drop homepage              ( )
         then                           ( )
      then                              ( )
   else
      2drop
\      type
   then
   client tcp-disconnect
;
: rcv   ( adr len handle -- )
." Client is " dup . cr
   to client   save-url    ( )
   \ Schedule the work for later so we do not have
   \ nested callbacks if the reply takes a long
   \ time and must do "ms" to avoid watchdogs.
   ['] handle-rcv 2 alarm
;

\ : ds ." Disconn " .espconn ;  : cn ." Conn " .espconn ;  : tx ." Sent " .espconn ;
: serve
   server-init
   0 0 0  \ 0 ['] ds ['] cn
   0 ['] rcv  " 0.0.0.0" port #400 tcp-listen to server
   ." Serving " .ssid space ipaddr@ .ipaddr cr
;
: unserve  ( -- )  server unlisten  ;

: udp-serve   0 ['] rcv " 0.0.0.0" #1234 udp-listen to server  ;
