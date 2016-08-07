#80 value port   0 value server  0 value client
: t ( adr len -- )
   begin       ( adr len )
      2dup client send  case      ( adr len )
         0 of  2drop exit  endof  ( adr len )
        -7 of  5 ms  endof        ( adr len )  \ retry after a delay
        ( default )  ." TCP error " .d cr  2drop exit
   again
;
: tcr ( -- )  " "r"n" t  ;

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
      t                                 ( )
   repeat
   r> close-file drop
;

: hello  " Hello from ESP8266" t  ;
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
#256 constant /chunk
: do-forth  ( -- )
    find-cmd  if
       \ This will do for initial testing, but we really should hook (emit so we can
       \ send when a smaller buffer fills up, instead of possibly creating
       \ a large log that uses too much memory
       log{ evaluate }log
       log$  begin  dup  while   ( adr len )
	  2dup /chunk min  tuck  ( adr len  adr thislen )
	  tuck t                 ( adr len thislen )
          /string                ( adr len )
       repeat                    ( adr 0 )
       2drop
   then
;
: rcv   ( adr len handle -- )
   to client                            ( adr len )
   5 client tcp-bufcnt!
   \ client .espconn   
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
: ds ." Disconn " .espconn ;  : cn ." Conn " .espconn ;  : tx ." Sent " .espconn ;
: serve
   server-init
   0 0 0  \ 0 ['] ds ['] cn
   0 ['] rcv  " 0.0.0.0" port #400 tcp-listen to server
   ." Serving " .ssid space ipaddr@ .ipaddr cr
;
: unserve  ( -- )  server unlisten  ;

: reply  ( -- )  " Okay!"r"n" client send client tcp-disconnect  ;
: r1 0 parse client send " "r"n" client send  ;
: r r1 client tcp-disconnect  ;

: udp-serve   0 ['] rcv " 0.0.0.0" #1234 udp-listen to server  ;
