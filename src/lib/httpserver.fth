\ Simple HTTP responder that can serve files and execute Forth commands
\ For a file, the HTTP request is: GET /filename
\ For a Forth command line, e.g. "here .", it is GET /forth&cmd=here%20%.
\
\ The entry point is handle-rcv  ( adr len peer -- )
\   adr len  is the HTTP request, already read from the incoming stream
\   peer     is a handle that is used to reply via
\            tcp-send ( adr len peer -- )


fl url.fth
fl redirect.fth

0 value peer

: tcp-transmit  ( adr len -- )  peer tcp-send  ;
' tcp-transmit to reply-send

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

: hello  " Hello" tcp-transmit  ;
defer homepage   ' hello to homepage
defer server-init  ' noop to server-init

\needs $=  : $=  ( $1 $2 -- )  compare 0=  ;

0 value url-args-adr
0 value url-args-len
: url-args$  ( adr len -- )  url-args-adr url-args-len  ;
: find-cmd  ( -- false | val$ true )
   url-args$ urldecode$         ( $ )
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

: handle-rcv  ( req$ peer -- )
   to peer                              ( req$ )
   http-get?  if                        ( url$ )
      2dup " /favicon.ico" $=  if       ( url$ )
         2drop                          ( )
      else                              ( url$ )
         ." URL: " 2dup type cr         ( url$ )
         1 /string                      ( url$' )
         '?' left-parse-string          ( arg$ filename$ )
         2swap to url-args-len to url-args-adr  ( filename$ )
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
;
