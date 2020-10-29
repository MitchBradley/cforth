#10 to eol
\needs $=  : $=  ( $1 $2 -- )  compare 0=  ;

: find-cmd  ( -- false | val$ true )
   url-args$ urldecode$         ( $ )
   2dup reply{ type cr }reply   ( $ )
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
: save-first-line  ( adr len -- )
   #10 left-parse-string   ( rem$ head$ )
   dup to url-len          ( rem$ head$ )
   url-buf swap move       ( rem$ )
   2drop
;

' save-first-line to handle-data

: hello  reply{ ." Hello from ESP8266" cr }reply   ;
defer homepage   ' hello to homepage

0 value #connections

: handle-url  ( -- close? )
   \ client .espconn   
   url-buf url-len                      ( url$ )
   http-get?  if                        ( url$ )
\      2dup " /favicon.ico" $=  if       ( url$ )
\         2drop                          ( )
\      else                              ( url$ )
\         ." URL: " 2dup type cr         ( url$ )
#connections 1+ to #connections
   ." URL: " 2dup type space #connections .d  cr         ( url$ )
         1 /string                      ( url$' )
         parse-args                     ( filename$ )
         dup  if                        ( filename$ )
            2dup  " forth"  $=  if      ( filename$ )
	       2drop  do-forth          ( )
            else                        ( filename$ )
	       send-file                ( )
	    then                        ( )
	 else                           ( null$ )
            2drop homepage              ( )
         then                           ( )
\      then                              ( )
   else
      2drop
\      type
   then
   true
;
' handle-url to respond
