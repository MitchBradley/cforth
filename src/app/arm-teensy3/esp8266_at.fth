\ Interface to ESP8266 AT command set with modified result strings

\ RESPONSE FORMAT
\ [...] means ... is optional, usually because of mux being disabled
\
\ O                       Okay
\ E<msg>\r\n              Error
\ +<data>\r\n             Parameter
\ C[@<from>]\r\n          Connected
\ D[@<from>]\r\n          Disconnected
\ R[@<from>,]<len>:<data> Received Data
\ >                       ESP8266 is ready to receive transmit data

: talk  ( -- )
   begin
      key?  if  key  dup '~' =  if exit then  uemit  then
      ukey?  if  ukey emit  then
   again
;

#1000 value at-timeout
: timed-ukey  ( -- true | char false )
   get-msecs at-timeout +   ( limit )
   begin                    ( limit )
      ukey?  if  drop  ukey false exit  then
      dup get-msecs - 0<    ( limit timeout? )
   until                    ( limit )
   drop true
;
: wait-echo  ( exp-char -- )
   begin
      timed-ukey abort" Echo timeout"  ( exp-char got-char )
      over =  ( exp-char gotit? )
   until   ( exp-char )
   drop    ( )
;
: consume  ( -- )  begin  ukey?  while  ukey drop  1 ms  repeat  ;

: utype  ( adr len -- )  bounds ?do  i c@ uemit  loop  ;
: utype-echoed  ( adr len -- )
    bounds  ?do
       i c@ dup uemit  wait-echo
    loop
;

defer resync  ' noop to resync
: handle-+  ( -- )
   begin
      timed-ukey abort" Timeout"  ( char )
      dup linefeed <>             ( char )
   while                          ( char )
      dup carret <>  if  emit  else  drop  then
   repeat                         ( char )
   drop cr
;

: add-char-to-pstr  ( char pstr -- )
   dup c@ #31 >  if  2drop exit  then  ( char pstr )
   tuck  count + c!                    ( pstr )   
   dup c@ 1+ swap c!                   ( )
;

#32 buffer: error-pstr
: set-error  ( adr len -- )  #31 min  error-pstr place  ;
: show-error  ( -- )  error-pstr count type  ;
: collect-error  ( -- )
   0 error-pstr c!
   begin
      timed-ukey  if  exit  then  ( char )
      case
	 carret  of  endof
	 linefeed  of  exit  endof
         ( default )  dup error-pstr add-char-to-pstr
      endcase
   again	 
;

#32 buffer: param-pstr
: collect-param  ( -- )
   0 param-pstr c!
   begin
      timed-ukey  if  exit  then  ( char )
      case
	 carret    of  endof
	 linefeed  of  exit  endof
	 ':'       of  exit  endof
         ( default )  dup param-pstr add-char-to-pstr
      endcase
   again	 
;

: decimal-number  ( $ -- n )
   push-decimal $number pop-base  if  ." Bad number" cr 0  then
;
: parse-from   ( -- id rem$ )
   param-pstr count             ( $ )
   over c@ '@' =  if            ( $ )
      1 /string                 ( $' )
      ',' split-string          ( from$ rem$ )
      dup if  1 /string  then   ( from$ rem$' )
      2swap                     ( rem$ from$ )
      decimal-number            ( rem$ id )
   else                         ( rem$ )
      0                         ( rem$ id )
   then                         ( rem$ id )
   -rot                         ( id rem$ )
;
: connected  ( -- )  \ [@from]\r\n
   collect-param  parse-from 2drop  ( id )
   drop
;
: disconnected  ( -- )  \ [@from]\r\n
   collect-param  parse-from 2drop  ( id )
   drop
;

defer wait-cmd-response

#2048 buffer: packet-buf
0 value packet-len
: collect-packet  ( len -- )
   dup to packet-len   ( len )
   packet-buf swap bounds  ?do
      timed-ukey  abort" Timeout"
      i c!
   loop
   wait-cmd-response abort" Collect packet ok timeout"
;

: at-cmd  ( adr len -- )
   " AT" utype  utype  " "r"n" utype
   wait-cmd-response  if  resync  then
;

0 value rx-id
: wait>  ( -- )  timed-ukey abort" Timeout"  '>' <>  abort" Prompt not >"  ;

: close-connection  ( id -- )  " +CIPCLOSE=%d" sprintf at-cmd  ;

0 value send-adr
0 value send-len
: send  ( adr len -- )
   to send-len to send-adr
   send-len rx-id  " AT+CIPSEND=%d,%d"r"n" sprintf utype  ( )
\   wait-cmd-response abort" No O"
   wait-cmd-response abort" No O"
;
: finish-response  ( -- )  rx-id close-connection  ;

: http-get?  ( req$ -- false | url$ true )
   over " GET " comp 0=  if        ( req$ )
      4 /string                    ( req$' )  \ Lose "GET "
      bl split-string  2drop true  ( url$ true )
   else                            ( adr len )
      false                        ( req$ false )
   then
;


: hdr
   " <html><head><title>Empire Gardens Grow-o-matic</title>" send
   " <meta HTTP-EQUIV=Pragma CONTENT=no-cache>" send
   " <meta HTTP-EQUIV=Expires CONTENT=-1>" send
   " <style>" send
   " input,button,td{font:40px sans-serif;} .l{font-weight:bold;text-align:right;}" send
   " input,button{color:green;} button{width:100%;}" send
   " </style>" send
   " </head><body>" send
;
: footer
   " </body></html>" send
;
: brk  ( -- )  " <br>" send  ;
: table-begin ( -- ) " <table>" send ;
: table-end ( -- ) " </table>" send ;
: save$  ( adr len -- adr1 len1 )  pad pack count  ;
: n.nn$  ( n -- $ )
   push-decimal
   <# u# u# '.' hold u#s u#>
   pop-base
   save$
;
: n.n$  ( n -- $ )
   push-decimal
   <# u# '.' hold u#s u#>
   pop-base
   save$
;
: bme-data  ( -- )
   pht   ( pa %rh*1024 C*100 )   
   push-decimal
   " <tr><td class=l>Temperature: </td><td>" send  n.nn$ send " C</td></tr>" send
   " <tr><td class=l>Humidity: </td><td>" send  #10 >>round (.) send " %</td></tr>" send
   " <tr><td class=l>Pressure: </td><td>" send  #100 #101324 */ n.nn$ send  "  atm</td></tr>" send
   pop-base
;
: ph-sensor  ( -- )
   " <tr><td class=l>pH: </td><td>" send
   pH*10 0 max n.n$ send
   " </td></tr>" send
;
: pump-links  ( -- )
   " <tr><td><a href=""/?spray=pulse""><button>Spray</button></a></td>" send
       " <td><a href=""/?nutrient=pulse""><button>Nutrients</button></a></td>" send
       " <td><a href=""/?recirculate=pulse""><button>Recirculate</button></a></td></tr>" send
   " <tr><td><a href=""/?phup=pulse""><button>pH Up</button></a></td>" send
       " <td><a href=""/?phdown=pulse""><button>pH Down</button></a></td>" send
       " <td><a href=""/?water=pulse""><button>Water</button></a></td></tr>" send
;
#10 value ec-limit-low
#30 value ec-limit-high
: configure  ( -- )
   " <form><table>" send
   " <tr><td>pH Low: <input type=text name=phlow size=4 value=" send ph-limit-low n.n$ send
\   " pH Low: <input type=range name=phlow min=3.0 max=7.0 step=0.1 value=" send ph-limit-low n.n$ send
   " >&nbsp;</td><td>" send
   " pH High: <input type=text name=phhigh size=4 value=" send ph-limit-high n.n$ send
   " ></td></tr>" send
   " <tr><td>EC Low: <input type=text name=eclow size=4 value=" send ec-limit-low n.n$ send
   " >&nbsp;</td><td>" send
   " EC High: <input type=text name=echigh size=4 value=" send ec-limit-high n.n$ send
   " ></td></tr>" send
   " <tr><td><input type=submit value=Submit></td>" send
   " <td></td></tr></table></form>" send
;

: configuration  ( -- )
\   " pH Limits: " send  ph-limit-low n.n$ send  "  " send ph-limit-high n.n$ send brk
;
: homepage  ( -- )
   hdr

   table-begin
   ph-sensor bme-data
   table-end

   table-begin
   pump-links
   table-end

   configuration
   configure
   footer
;

: convert-ph  ( f -- n ) 10E0 f* int   0 max  #140 min  ;
: convert-ec  ( f -- n ) 10E0 f* int   #05 max  #60 min  ;

vocabulary url-commands
also url-commands definitions
: spray  ( val$ -- )  ." Spray: " type cr  ;
: water  ( val$ -- )  ." Water: " type cr  ;
: phup   ( val$ -- )  ." pH Up: " type cr  ;
: phdown ( val$ -- )  ." pH Down: " type cr  ;
: nutrients  ( val$ -- )  ." Nutrients: " type cr  ;
: recirculate  ( val$ -- )  ." Recirculate: " type cr  ;
: phlow  ( val$ -- )
   fnumber  0=  if  ( f )  convert-ph to ph-limit-low  then
;
: phhigh  ( val$ -- )
   fnumber  0=  if  ( f )  convert-ph to ph-limit-high  then
;
: eclow  ( val$ -- )
   fnumber  0=  if  ( f )  convert-ec to ec-limit-low  then
;
: echigh  ( val$ -- )
   fnumber  0=  if  ( f )  convert-ec to ec-limit-high  then
;
previous definitions


: execute-arg ( val$ name$ -- )
   ['] url-commands search-wordlist if
      execute
   else
      2drop
   then
;
: handle-arg ( arg$ -- )
  '=' left-parse-string execute-arg
;
: handle-url-params ( url$ -- )
   '?' left-parse-string 2drop ( params$ )
   dup if       ( params$ )
      begin
	 dup while
	    '&' left-parse-string ( rem$ arg$ )
	    handle-arg            ( rem$ )
      repeat                      ( rem$ )
   then
   2drop
;




: respond  ( -- )
   packet-buf packet-len  http-get?  if  ( url$ )
      2dup " /favicon.ico" compare 0= if
	 2drop                        ( )
      else                            ( url$ )
	 2dup ." URL: " type cr       ( url$ )
	 handle-url-params            ( )
         homepage                     ( )
      then
   then
   finish-response
;

: rx-data  ( -- )  \ [@from,]<len>:<data>
   collect-param  parse-from  ( id rem$ )
   rot to rx-id               ( rem$ )
   decimal-number             ( len )
   collect-packet             ( )
   respond
;

: do-wait-cmd-response  ( -- error? )
   begin
      timed-ukey  if  " Timeout" set-error  true exit  then  ( char )
dup emit
      case
         'O' of   false exit  endof
         'X' of   collect-error show-error true  exit  endof
         '+' of   handle-+  endof
         'C' of   connected  endof
	 'D' of   disconnected endof
	 'R' of   rx-data  endof
         '>' of   send-adr send-len utype  endof
      endcase
   again
;
' do-wait-cmd-response to wait-cmd-response

: at-echo-off  ( -- )
   " ATE0"r"n" utype
   wait-cmd-response  if  resync  then
;
: at-echo-on  ( -- )  " E1" at-cmd  ;

: do-resync  ( -- )  consume  ( do reset somehow )  consume  ;
: ap-mode  ( -- )  " +CWMODE=2" at-cmd  ;
: start-server  ( -- )
   at-echo-off
   " +RST" at-cmd
   " resetting ..." type #1000 ms
   at-echo-off
   " +CIPAP?" at-cmd
   " +CIPMUX=1" at-cmd
   " +CIPSERVER=1,80" at-cmd
;

: handle-request  ( -- )
   ukey? 0=  if  exit  then
   ukey case
      'O'  of  endof
      'X'  of  collect-error show-error endof
      '+'  of  handle-+      endof
      'C' of   connected     endof
      'D' of   disconnected  endof
      'R' of   rx-data       endof
   endcase
;

1 value time
: serve  ( -- )
   init-bme
   start-server
   begin  handle-request time ms  key? until
;
