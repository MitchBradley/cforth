: wifi-on  ( -- )
   2 wifi-opmode!   \ AP mode
   .ssid  space  ipaddr@ .ipaddr
;

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
   0 over tcp-err   ( pcb )
   0 over tcp-recv  ( pcb )
   0 over tcp-sent  ( pcb )
   tcp-close drop   ( )
;

: pbuf>len  ( pbuf -- totlen adr thislen )
   >r                (             r: pbuf )
   r@ 2 la+ w@       ( totlen      r: pbuf )
   r@ la1+ l@        ( totlen adr  r: pbuf )
   r> 2 la+ wa1+ w@  ( totlen adr thislen )
;

defer handle-data  ( adr len -- )
' type to handle-data

defer respond   ( -- err )
' ERR_OK to respond

: .rs  ( -- )  rp0 @  rp@  ?do  i l@ .x  /l +loop cr  ;

defer closeit  ( pcb -- )
' close-connection to closeit

0 value rx-pcb
: receiver  ( err pbuf pcb arg -- err )
   3 roll  ?dup  if  ." Rx error " . cr   3drop ERR_VAL exit  then  ( pbuf pcb arg )
   drop   to rx-pcb             ( pbuf )
   ?dup 0=  if                  ( pbuf )
      ." Connection closed" cr cr
      rx-pcb close-connection   ( )
      ERR_OK exit               ( -- err )
   then                         ( pbuf )
   dup pbuf>len                 ( pbuf totlen  adr len )
   handle-data                  ( pbuf totlen )
   rx-pcb tcp-recved            ( pbuf )
   pbuf-free drop               ( )
   rx-pcb tcp-sent-continues    ( )
   rx-pcb respond               ( )
   rx-pcb closeit               ( )
   ERR_OK                       ( err )
;

: sent-handler  ( len pcb arg -- err )
   2 pick  ." Sent " .d cr
   3drop  ERR_OK
;
: error-handler  ( err arg -- )
   ." Error " swap .d " with arg " .d cr
;
0 value listen-pcb
: accepter  ( err new-pcb arg -- )
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

: tcp-write-wait  ( adr len -- )
   rx-pcb tcp-write     ( stat )
   ?dup  if             ( stat )
      " tcp-write returned " .d cr
   then                 ( )
   ERR_OK continuation  ( len pcb arg )
   swap to rx-pcb       ( len arg )
   2drop                ( )
;

' tcp-write-wait to reply-send

: ct  ( -- err )
   reply{
   ." Hello" cr
   ." Goodbye" cr
   ." You say yes" cr
   ." I say no" cr
   ." You say goodbye" cr
   ." And I say hello" cr
   ." I don't know why you say goodbye I say hello" cr
   ." Some of us are incredibly smelly beasts that can only be mitigated with acid" cr
   ." Some of us are incredibly smelly beasts that can only be mitigated with acid" cr
   ." Some of us are incredibly smelly beasts that can only be mitigated with acid" cr
   ." Some of us are incredibly smelly beasts that can only be mitigated with acid" cr
   ." Some of us are incredibly smelly beasts that can only be mitigated with acid" cr
   }reply
;
' ct to respond

: continuation-test  ( -- err )
   " Hello"r"n" tcp-write-wait
   " Goodbye"r"n" tcp-write-wait
   " You say yes"r"n" tcp-write-wait
   " I say no"r"n" tcp-write-wait
   " You say goodbye"r"n" tcp-write-wait
   " And I say hello"r"n" tcp-write-wait
   " I don't know why you say goodbye I say hello"r"n" tcp-write-wait
;

\ ' continuation-test to respond


fl sendfile.fth
