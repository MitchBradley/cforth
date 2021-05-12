#0 constant ERR_OK              \ No error, everything OK.
#-1 constant ERR_MEM            \ Out of memory error.
#-2 constant ERR_BUF            \ Buffer error.
#-3 constant ERR_TIMEOUT        \ Timeout.
#-4 constant ERR_RTE            \ Routing problem.
#-5 constant ERR_INPROGRESS     \ Operation in progress
#-6 constant ERR_VAL            \ Illegal value.

\ Above errors are fatal, below ones are not

#-7 constant ERR_WOULDBLOCK     \ Operation would block.
#-8 constant ERR_ABRT           \ Connection aborted.
#-9 constant ERR_RST            \ Connection reset.
#-10 constant ERR_CLSD          \ Connection closed.
#-11 constant ERR_CONN          \ Not connected.
#-12 constant ERR_ARG           \ Illegal argument.
#-13 constant ERR_USE           \ Address in use.
#-14 constant ERR_IF            \ Low-level netif error
#-15 constant ERR_ISCONN        \ Already connected.

create inet-addr-any  0 l,
create inet-addr-none  $ffffffff l,

\ pbuf  is  next.l, bufp.l, totlen.w, thislen.w, type.b, flags.b, refcnt.w, ptr.l

: close-connection  ( pcb -- )
   0 0 2 pick tcp-poll  ( pcb )

   \ We leave these handlers installed because browsers tend to reuse
   \ connections from some time after our side has signaled "close"
   \ 0 over tcp-err   ( pcb )
   \ 0 over tcp-recv  ( pcb )
   \ 0 over tcp-sent  ( pcb )

   tcp-close        ( err )
   \ err could be ERR_MEM if there was insufficient memory to do the
   \ close, in which case we are supposed to retry later via either a
   \ poll callback or a sent callback.  For now we ignore that case.
   drop             ( )
;

: pbuf>len  ( pbuf -- adr thislen totlen )
   >r                (             r: pbuf )
   r@ la1+ l@        ( adr         r: pbuf )
   r@ 2 la+ wa1+ w@  ( adr thislen r: pbuf )
   r> 2 la+ w@       ( adr thislen totlen )
;

defer handle-peer-data  ( adr len peer -- )
: type-peer-data  ( adr len peer -- )  drop  type  ;
' type-peer-data to handle-peer-data

defer respond   ( -- close? )
: null-respond  ( -- close?)  true  ;
' null-respond to respond

\ : .rs  ( -- )  rp0 @  rp@  ?do  i l@ .x  /l +loop cr  ;

0 value rx-pcb
\ The LWIP stack treats the receiver callback return value as:
\   ERR_OK:   Everything is okay
\   ERR_ABRT: Something is confused so prematurely abort
\             the TCP connection by sending a RST segment
\   else:     The callback is temporarily unable to accept
\             the incoming data, so the LWIP stack should
\             hold onto it and invoke the receiver callback
\             later.

: receiver  ( err pbuf pcb arg -- err )
   \ There is no point to looking at the err argument because
   \ the LWIP code always sets it to ERR_OK. The LWIP documentation
   \ gives no indication what other values might mean.  I assume that
   \ the err argument is present only for consistency with other callbacks.
   drop  to rx-pcb  nip         ( pbuf )
   ?dup 0=  if                  ( )
      \ ." Connection closed" cr cr
      rx-pcb close-connection   ( )
      \ This is a normal termination, not a premature abort
      \ As I understand it, ERR_ABRT is for cases where something
      \ has gone wrong.
      ERR_OK exit               ( -- err )
   then                         ( pbuf )

[ifndef] notdef
   \ Set up the continuation mechanism so that, when tcp-write-wait
   \ returns to the OS via continuation, a subsequent tcp-sent callback
   \ will resume execution of Forth with the PCB on the stack, along
   \ with a couple of other values from the sent callback.
   rx-pcb tcp-sent-continues    ( pbuf )
[then]

   \ Say that the data has been received, thus allowing the TCP
   \ stack to open the receive window.  The data is still safe
   \ in the pbuf, which the stack has already disconnected from
   \ the PCB in which it was received.  Doing this now might speed
   \ things up by overlapping TCP ACK network activity with our
   \ data processing.
   dup pbuf>len                 ( pbuf adr len totlen )
   rx-pcb tcp-recved            ( pbuf adr len )

   \ Give the data to the application code
   rx-pcb handle-peer-data      ( pbuf )

   \ Release the data buffer
   pbuf-free drop               ( )

   \ Call the application code to respond to the data
   \ respond returns true if the connection should be closed
   \ or false if more data is expected.
   respond  if                  ( )
      rx-pcb close-connection   ( )
   then
   ERR_OK
;

: sent-handler  ( len pcb arg -- err )
   2 pick  ." Sent " .d cr
   3drop  ERR_OK
;
\needs string-array fl ${CBP}/lib/stringar.fth
string-array tcp-errors
  ," No error"
  ," Out of memory"
  ," Buffer error"
  ," Timeout"
  ," Routing"
  ," In progress"
  ," Illegal value"
  ," Would block"
  ," Connection aborted"
  ," Connection reset"
  ," Connection closed"
  ," Not connected"
  ," Illegal argument"
  ," Already connected"
end-string-array

: error-handler  ( err arg -- )
   nip  ?dup  if  ( err )
      ." TCP: "  negate tcp-errors count type
   then
;
0 value listen-pcb
: accepter  ( err new-pcb arg -- err )
   drop >r           ( err r: new-pcb )
   ?dup  if          ( err r: new-pcb )
      r> drop        ( err )
      ." Accept error " .d cr  ( )
      ERR_VAL exit
   then
   listen-pcb tcp-accepted  \ was r@ tcp-accepted
\   #5553 r@ tcp-arg
\  poll-interval ['] poller r@ tcp-poll
   ['] receiver r@ tcp-recv
   ['] error-handler r@ tcp-err
   ['] sent-handler r@ tcp-sent
   r> drop
   ERR_OK
;
: unlisten  ( -- )
   listen-pcb  ?dup  if  tcp-close drop  0 to listen-pcb  then
;

: listen  ( -- )
   unlisten
   tcp-new    ( pcb )
   #80 inet-addr-any  2 pick  tcp-bind  abort" Bind failed"  ( pcb )
   1 swap tcp-listen-backlog  to listen-pcb
   ['] accepter listen-pcb tcp-accept   ( )
\   #1234 listen-pcb tcp-arg             ( )
   ." Listening on " .ssid  space  ipaddr@ .ipaddr  ."  port " #80 .d  cr
;

\ tcp-write-wait queues the data to be sent, then returns to the LWIP stack
\ from either the recv callback or the sent callback via "continuation".
\ When the data has been delivered, "continuation" returns to Forth with
\ len,pcb,fh on the stack.  This is like a blocking send, except that
\ the "blocking" happens in the LWIP stack.


: tcp-send  ( adr len pcb -- )
   tcp-write  ?dup  if  ( stat )
[ifdef] NOTDEF
      ." tcp-write returned " .d cr
[else]
      drop
[then]
   then                 ( )

   ERR_OK continuation  ( len pcb arg )
   swap to rx-pcb       ( len arg )
   2drop
;

: tcp-write-wait  ( adr len -- )  rx-pcb tcp-send  ;

: continuation-test  ( -- close? )
   " Hello"r"n" tcp-write-wait
   " Goodbye"r"n" tcp-write-wait
   " You say yes"r"n" tcp-write-wait
   " I say no"r"n" tcp-write-wait
   " You say goodbye"r"n" tcp-write-wait
   " And I say hello"r"n" tcp-write-wait
   " I don't know why you say goodbye I say hello"r"n" tcp-write-wait
   true
;

' continuation-test to respond


: simple-connected  ( err pcb arg -- stat )
   drop nip
   ." Connected, pcb is " . cr
   ERR_OK
;

defer connected
' simple-connected to connected

: connect  ( port# host -- )
   \ XXX handle error callbacks
   ['] connected  -rot   ( cb port# host )
   tcp-new               ( cb port# host pcb )
   tcp-connect 0<> abort" tcp-connect failed"
;

\ This is the default host IP for ESP8266's in softap mode
create esp-ip  #192 c, #168 c, #4 c, #1 c,

false value tcp-connected?
: null-tcp-sent  ( len pcb arg -- err )
   2drop  ( len )
   drop
   ERR_OK
;
: tcp-connected  ( err pcb arg -- stat )
   drop to rx-pcb               ( err )
   ?dup  if                     ( err )
      ." Connect failed, err = " .x  cr
   else                         ( )
      true to tcp-connected?
      ['] receiver      rx-pcb tcp-recv
      ['] error-handler rx-pcb tcp-err
      ['] null-tcp-sent rx-pcb tcp-sent
   then

   ERR_OK
;
\needs resolve fl ${CBP}/app/esp8266/resolve.fth

: service>port  ( $ -- n )
   push-decimal $number? pop-base  ( false | d true )
   0= abort" Bad TCP port"         ( d )
   drop                            ( n )
;

0 value tcp-rcv-msecs
: stream-connect ( rcv-timeout-msecs port$ server$ -- fd|-error )
   2>r 2>r                  ( timeout r: server$ port$ )
   to tcp-rcv-msecs         ( r: server$ port$ )
   false to tcp-connected?
   ['] false to respond  \ Don't close the connection

   tcp-new to rx-pcb      ( r: server$ port$ )

   ['] tcp-connected      ( cb r: server$ port$ )
   2r> service>port       ( cb port# r: server$ )
   2r> resolve-host       ( cb port# 'host )
   rx-pcb tcp-connect  ?dup  if  ( error )
      nip negate exit     ( -- -error )
   then                   ( )
   \ Wait 10 seconds for a connection to be established, then give up
   #1000  0  do           ( )
      #10 ms  tcp-connected?  if  unloop rx-pcb exit  then
   loop
   -1
;
: do-tcp-poll  ( fd -- )
   drop
   tcp-rcv-msecs ms
   \ The callback will handle the receive data if any
;
