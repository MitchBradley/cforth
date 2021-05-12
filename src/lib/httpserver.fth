\ Simple HTTP responder that can serve files and execute Forth commands
\ For a file, the HTTP request is: GET /filename
\ For a Forth command line, e.g. "here .", it is GET /forth&cmd=here%20%.
\
\ The entry point is handle-rcv  ( adr len peer -- )
\   adr len  is the HTTP request, already read from the incoming stream
\   peer     is a handle that is used to reply via
\            tcp-send ( adr len peer -- )


fl url.fth
\needs reply-send fl redirect.fth

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
   begin  dup  while            ( $ )
      '&' left-parse-string     ( $'  head$ )
      '=' left-parse-string     ( $   val$ name$ )
      " cmd" $=  if             ( $  val$ )
	 2swap 2drop            ( val$ )
         true exit              ( -- val$ )
      else                      ( $  val$ )
         2drop                  ( $ )
      then                      ( $ )
   repeat                       ( $ )
   2drop false                  ( false )
;

: do-forth  ( -- )
   find-cmd  if  reply{ evaluate space }reply  then
;

: set-values  ( -- error? )
   url-args$ urldecode$         ( $ )

   begin  dup  while            ( $ )
      '&' left-parse-string     ( $'  head$ )
      '=' left-parse-string     ( $   val$ name$ )
      2swap  ['] evaluate catch  if  ( $   val$ name$ )
         2drop 2drop 2drop true exit
      then                      ( $  name$ n )
      -rot                      ( $  n name$ )
      $find 0=  if              ( $  n name$ )
         2drop drop 2drop true exit
      then                      ( $  n xt )
      (to)                      ( $ )
   repeat                       ( $ )
   2drop false                  ( false )
;
: .no-favicon  ( -- )
   ." <head>" cr
   ." <link rel='icon' href='data:,'>" cr
\   ." <meta http-equiv='Cache-Control' content='no-cache, no-store, must-revalidate' />" cr
   ." <meta http-equiv='Pragma' content='no-cache' />" cr
\   ." <meta http-equiv='Expires' content='0' />" cr
   ." </head>" cr
;
: .prolog  ( -- )  ." <!DOCTYPE html><html>" cr  .no-favicon  ." <body>" cr    ;
: .epilog  ( -- )  ." </body></html>" cr  ;
: .reload-after  ( ms -- )
   ." <script>" cr
   ." setTimeout(function(){location.replace(location.origin);},"
   (.d) type  \ Insert the timeout value
   ." )" cr
   ." </script>" cr
;
: do-setval  ( -- )
   reply{
   .prolog
   set-values  if  ." Error"  else  ." Done"  then
   #500 .reload-after
   .epilog
   }reply
;

0 value #rcv
: handle-rcv  ( req$ peer -- )
   to peer                              ( req$ )
   http-get?  if                        ( url$ )
      2dup " /favicon.ico" $=  if       ( url$ )
         reply{ space }reply
         2drop                          ( )
      else                              ( url$ )
#rcv 1+ to #rcv
   ." URL: " 2dup type space #rcv .d  cr         ( url$ )
\         ." URL: " 2dup type cr         ( url$ )
         1 /string                      ( url$' )
         '?' left-parse-string          ( arg$ filename$ )
         2swap to url-args-len to url-args-adr  ( filename$ )
         dup  if                        ( filename$ )
            2dup  " forth"  $=  if      ( filename$ )
	       2drop  do-forth          ( )
            else
               2dup  " setval"  $=  if  ( filename$ )
                  2drop  do-setval      ( )
               else                     ( filename$ ) 
                  t-send-file           ( )
               then
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
