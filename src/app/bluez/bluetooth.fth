\ Bluetooth Low Energy interface.
\ This implementation depends on Linux Bluetooth sockets - BTPROTO_HCI
\ sockets for scanning and BTPROTO_L2CAP sockets for data connections.

\ Error reporting from Posix system calls
fl ../../cforth/printf.fth

#100 buffer: abort-msg
: sprintf-abort  ( ? pattern$ -- )
   sprintf abort-msg pack  'abort$ !
   -2 throw
;
[ifndef] cscount
: cscount  ( adr -- adr len )
   dup                               ( adr cur-adr )
   begin  dup c@  while  1+  repeat  ( adr end-adr )
   over -                            ( adr len )
;
[then]
: ?posix-err  ( n -- )
   0<  if
      \ EALREADY is not really a problem
      errno  dup #114 =  if  drop exit  then
      dup >r strerror cscount r>
      " Syscall error %d: %s" sprintf-abort
   then
;

\ Non-blocking reads
/l wa1+ wa1+ buffer: poll-fd  \ n.fid w.events w.revents
: do-poll  ( ms fid mask -- nfds )
   swap poll-fd !          ( ms mask )
   poll-fd la1+ w!         ( ms )
   0 poll-fd la1+ wa1+ w!  ( ms )   \ returned events
   1 poll-fd poll          ( nfds ) \ 1 is nfds
;
: do-poll-in  ( ms fid -- nfds )  1 do-poll  ;
: do-poll-out  ( ms fid -- nfds )  4 do-poll  ;

: timed-read  ( adr len fid ms -- actual | -1 )
   over do-poll-in 1 =  if  ( adr len fid )
      h-read-file           ( actual )
   else                     ( adr len fid )
      3drop -1              ( -1 )
   then                     ( actual | -1 )
;

\ Packet construction
0 value pkt
0 value pkt2
#100 buffer: packet
: pkt{  ( -- )  packet to pkt  ;
: }pkt  ( -- adr len )  packet  pkt over -  ;
: pkt2{  ( -- )  pkt to pkt2  ;
: }pkt2  ( -- adr len )  pkt2  pkt over -  ;
: +pkt  ( n -- adr )  pkt  tuck + to pkt  ;
: pkt-b,  ( b -- )  1 +pkt c!  ;
: pkt-w,  ( w -- )  /w +pkt w!  ;
: pkt-l,  ( l -- )  /l +pkt l!  ;
: pkt-$,  ( adr len -- )  dup +pkt swap move  ;


0 value hci#
0 value hci-fh
6 buffer: my-bdaddr
6 buffer: his-bdaddr
1 value secure-level  \ 0:SDP, 1:low, 2:medium, 3:high
false value random?
-1 value bt-fh

\needs le-w@  : le-w@  ( adr -- w )  dup c@  swap ca1+ c@  bwjoin  ;
\needs le-l@  : le-l@  ( adr -- l )  dup le-w@  swap wa1+ le-w@  wljoin  ;
\needs le-w!  : le-w!  ( w adr -- )  >r wbsplit  r@ ca1+ c!  r> c!  ;
\needs le-l!  : le-l!  ( l adr -- )  >r lwsplit  r@ wa1+ le-w!  r> le-w!  ;

\ dir is 0 for no IO, 1 for write, 2 for read
: >ioctl  ( number dir size type -- n )
   rot #14 lshift    ( number size type n )
   rot or 8 lshift   ( number type n' )
   or 8 lshift       ( number n' )
   or                ( n' )
;

: hci-ioctl  ( arg number dir -- )  /l 'H' >ioctl  hci-fh  ioctl  ?posix-err  ;
: hci-wioctl  ( arg number -- )  1 hci-ioctl  ;
: hci-rioctl  ( arg number -- )  2 hci-ioctl  ;

\ The HCIUP ioctl will fail if it is already up, so ignore that failure
: hci-up    ( -- )  hci# #201 ['] hci-wioctl catch  if  2drop  then  ;
: hci-down  ( -- )  hci# #202 hci-wioctl  ;
: hci-reset  ( -- )  hci# #203 hci-wioctl  ;

#8 buffer: 'hci-dev-req
: hci-set-piscan  ( -- )
   hci# 'hci-dev-req w!
   3 'hci-dev-req la1+ l!  \ 1 is SCAN_INQUIRY, 2 is SCAN_PAGE
   'hci-dev-req #221 hci-wioctl
;

#92 buffer: 'hci-devinfo
: hci-get-devinfo  ( -- )  hci# 'hci-devinfo w!  'hci-devinfo #211 hci-rioctl  ;
: hci-bdaddr  ( -- 'bdaddr )  hci-get-devinfo 'hci-devinfo #10 +  ;

: hci-open  ( -- )
   hci-fh  if  exit  then
   1 $80003  #31 socket  dup ?posix-err  to hci-fh  \ 1 BTPROTO_HCI   $80000 SOCK_CLOEXEC  3 SOCK_RAW   #31 PF_BLUETOOTH
   pkt{ #31 pkt-w,   hci# pkt-w,  0 pkt-w,  }pkt ( adr len )   \ 0 is hci_channel
   swap hci-fh bind  ?posix-err
   hci-bdaddr my-bdaddr 6 move
   hci-up
   hci-set-piscan
;
: hci-close  ( -- )  hci-fh  if  hci-fh h-close-handle  0 to hci-fh  then  ;

\needs bwjoin : bwjoin  ( lo hi -- w )  8 lshift or  ;
\needs le-w@  : le-w@  ( adr -- w )  dup c@ swap 1+ c@ bwjoin  ;

#100 constant /hci-buf
/hci-buf buffer: scan-buf
: +sb  ( n -- adr )  scan-buf +  ;
: .2x  ( -- )  push-hex <# u# u# u#> pop-base type  ;
: .bdaddr  ( adr -- )
   1 5  do dup i + c@  .2x ." :"  -1 +loop  c@ .2x
;

\ Advertisement display
: .le-flags  ( b -- )
    ." Flags: "
    dup 1 and  if  ." limited "  then
    2 and  if  ." general"  then
    cr
;
: .nx  ( adr len -- )  1- 0 swap  do  dup i + c@ .2x  -1 +loop  drop  ;
: .uuid128  ( adr -- )  #16 .nx  ;
: .uuids128  ( adr len -- )  bounds ?do  i .uuid128 space #16 +loop  ;
: .uuid16  ( adr -- )  2 .nx  ;
: .uuids16  ( adr len -- )  bounds ?do  i .uuid16 space 2 +loop  ;
: .solicit16  ( adr len -- )   ." Soliciting: " .uuids16 cr  ;
: .solicit128  ( adr len -- )   ." Soliciting: " .uuids128 cr  ;
: .service-data  ( adr len -- )
   ." ServiceData: " over  .uuid16  ( adr len )
   2 /string  dup  if  cdump  else  2drop  then  cr
;
: .interval  ( adr -- )
   ." Connection min: " dup le-w@ .x  ." max: " wa1+ le-w@ .x cr
;
: .mfg-data  ( adr len -- )   ." MfgData: " cdump cr  ;
: .services16  ( adr len -- )  ." Services: " .uuids16  ;
: .services32  ( adr len -- )
   ." Services: "  bounds  ?do  i 4 .nx space  4 +loop
;
: .services128  ( adr len -- )  ." Services: " .uuids128  ;
: .short-name  ( adr len -- )  ." ShortName: " type cr  ;
: .full-name  ( adr len -- )  ." FullName: " type cr  ;
: b>n  ( b -- n )  dup $80 >=  if  $100 -  then  ;
: .txpower  ( adr -- )  ." TxPower: " c@ b>n .d ." dBm" cr  ;
: .cod  ( adr -- )  ." Class: "  3 .nx  cr  ;
: .sphash   ( adr -- )  ." Hash: "  #16 cdump  ;
: .sprandom ( adr -- )  ." Randomizer: "  #16 cdump  ;
: .smtk  ( adr -- )  ." SMTK: "  .uuid128  cr  ;

: .smoob  ( adr -- )
   c@
   dup 1 and  if  ." OOB "  then
   dup 2 and  if  ." LE "  then
   dup 4 and  if  ." LE+BR/EDR "  then
   8 and  if  ." random"  else  ." public"  then
   cr
;
: .le-tag  ( adr len type -- )
   case   ( adr len )
      $01 of  over c@ .le-flags  endof
      $02 of  2dup .services16  ." ..."  cr  endof
      $03 of  2dup .services16  cr  endof
      $04 of  2dup .services32  ." ..."  cr  endof
      $05 of  2dup .services32  cr  endof
      $06 of  2dup .services128  ." ..."  cr  endof
      $07 of  2dup .services128  cr  endof
      $08 of  2dup .short-name  endof
      $09 of  2dup .full-name  endof
      $0a of  over .txpower  endof
      $0d of  over .cod  endof
      $0e of  over .sphash  endof
      $0f of  over .sprandom  endof
      $10 of  over .smtk  endof
      $11 of  over .smoob  endof
      $12 of  over .interval  endof
      $14 of  2dup .solicit16  endof
      $15 of  2dup .solicit128  endof
      $16 of  2dup .service-data  endof
      $ff of  2dup .mfg-data  endof
   endcase
   2drop
;
: scanned-bdaddr  ( -- adr )  2 +sb  ;
: .tags  ( -- )
   9 +sb  8 +sb c@  bounds ?do
     i 2+  i c@ 1-  i 1+ c@ .le-tag
   i c@ 1+ +loop
;
: .my-bdaddr  ( -- )  ." BDADDR: " scanned-bdaddr .bdaddr  ;
: .advertisement  ( -- )
   ." Type: " 0 +sb c@ .x  ." AddrType: "  1 +sb c@ .x
   .my-bdaddr cr
   .tags
   cr
;
\ End of advertisement display


\ Scanning

\ SOL_HCI 0  SOL_L2CAP 6  SOL_SCO #17  SOL_RFCOMM #18

: set-hci-filter  ( ocf+ogf events.h events.l -- )
   \   EVENT_PKT type      events.l events.h opcode
   pkt{  1 4 lshift  pkt-l,  pkt-l,  pkt-l,  pkt-w,  }pkt  swap
   2 0 hci-fh setsockopt ?posix-err   \ HCI_FILTER  SOL_HCI
;

: use-cmd-filter  ( ocf+ogf -- )
   \ LE_META_EVENT  CMD_STATUS   CMD_COMPLETE
   1 $1e lshift   1 $f lshift  1 $e lshift or    ( ocf+ogf events.h events.l )
   set-hci-filter
;
: use-scan-filter  ( -- )  0  1 $1e lshift  0  set-hci-filter  ;  \ LE_META_EVENT

: hci{  ( ocf+ogf -- )
   hci-open
   dup use-cmd-filter
   pkt{ 1 pkt-b,  pkt-w,  0 pkt-b,    \ HCI_COMMAND_PKT.b , OGF|OCF.w, plen.b
;
: }hci  ( -- adr len )
   packet  pkt over -  dup 4 -  packet 3 + c!
   hci-fh h-write-file ?posix-err
;

/hci-buf buffer: hci-out
: hci-wait-event  ( ms -- true | adr len false )
   >r  hci-out #100 hci-fh  r>  timed-read   ( -1 | actual )
   dup -1 =  if  drop true exit  then  ( actual )
   hci-out c@ 4 <>  if           ( actual )
      ." Non-event packet: " hci-out swap cdump cr  abort
   then                          ( )
   hci-out swap 1 /string
   false
;
: hci-wait-complete  ( -- )
   begin
      #1000 hci-wait-event  abort" Command complete timeout"  ( adr len )
      over c@ case                  ( adr len )
         $0e of  2drop exit  endof  ( adr len )
         $3e of  2drop       endof  ( )
         ( default )                ( adr len code )
         ." Unexpected: " -rot cdump cr
      endcase                       ( )
   again
;
: hci-start/stop-scanning  ( start -- )
   \ The 1 is "filter duplicates"
   $200c hci{ ( start ) pkt-b, 1 pkt-b, }hci
   hci-wait-complete
;
\ Vol 2 7.8.10
: set-scan-parameters  ( -- )
   \ #16 * 0.625 ms = 10 ms
   \          active   interval   window     public    accept_all
   $200b hci{ 1 pkt-b, #16 pkt-w, #16 pkt-w, 0 pkt-b,  0 pkt-b,  }hci
   hci-wait-complete
;
: +scan  ( -- )
   set-scan-parameters  1 hci-start/stop-scanning  use-scan-filter
;
: -scan  ( -- )  0 hci-start/stop-scanning  ;

\ Vol 2 7.7.65.2

: .unexpected  ( adr len -- )  ." Unexpected packet: " cdump cr  ;

: hci-wait-meta  ( ms -- true | adr len false )
   hci-wait-event  if  true exit  then   ( adr len )
   \ evt(meta$3e).b plen.b  data[plen]
   over c@  $3e <>  if                   ( adr len )
      .unexpected true exit              ( -- true )
   then                                  ( adr len )
   over 1+ c@  over 2- <>  if            ( adr len )
      ." plen disagrees with len: " cdump cr  true exit
   then                                  ( adr len )
   2 /string  false                      ( adr len )
;

: hci-wait-advertisement  ( ms -- true | adr len false )
   hci-wait-meta  if  true  exit  then   ( adr len )
   \  subevent(adv$02).b Nreports.b  data[]
   over c@  2 <>  if                     ( adr len )
      ." Expecting adv subevent 2: "  cdump cr  ( )
      true exit                          ( -- true )
   then                                 ( adr len )
   over 1+ c@  1 <>  if                  ( adr len )
      ." Expecting 1 adv report: "  cdump cr  ( )
      true exit                          ( -- true )
   then                                  ( adr len )
   2 /string  false                      ( adr len false )
;

\ SCAN_PAGE 2  SCAN_INQUIRY 1
: hci-set-scan  ( scan-bits -- )
   pkt{ hci# pkt-w, 0 pkt-w,  pkt-l, }pkt  drop #221 hci-wioctl
;

#50 value scan-timeout-ms
: get-scan  ( -- timeout )
   scan-timeout-ms hci-wait-advertisement  if  true exit  then  ( adr len )
   \  type.b adrtype.b bdaddr.b[6] datlen.b advdata.b[datlen] rssi.b
   scan-buf swap move  ( )
   false
;
: .scan  ( -- )  get-scan  0=  if  .advertisement  then  ;

\ Assumes that scan-buf contains the portion of the advertising report
\ beginning with the type field (omitting Meta$3e, plen, subevent$2, nreports$1)
: scanned-name$  ( -- adr len )
   \ 0:type 1:adrtype 2-7:bdaddr 8:tagslen 9-N:tags
   \ Each tag is (len+1).b, type.b, data[len]
   \ Tag types 8 and 9 are for two forms of advertising name
   9 +sb  8 +sb c@  bounds ?do
     i 1+ c@  8 9 between  if
        i 2+  i c@ 1-  unloop  exit  ( -- adr len )
     then
   i c@ 1+ +loop
   " "
;

: initial-substring?  ( small$ large$ -- flag )
   2 pick  <  if  3drop false exit  then   ( small$ large-adr )
   over compare 0=
;

defer show-scanned  ' noop to show-scanned
: .scanned  2dup type  cr  ;

[ifndef] cscount
: cscount  ( adr -- adr len )
   dup                               ( adr cur-adr )
   begin  dup c@  while  1+  repeat  ( adr end-adr )
   over -                            ( adr len )
;
[then]
: .cstring  ( adr -- )  begin  dup c@  ?dup  while  emit  1+  repeat  drop  ;

: bt-connected?  ( -- flag )  bt-fh -1 <>  ;
: bt-disconnect
   bt-connected?  if  bt-fh h-close-handle  -1 to bt-fh  then
;
variable so-error
: get-socket-error  ( -- bits )
   \ len adr SO_ERROR SOL_SOCKET fd --
   /l so-error 4 1 bt-fh getsockopt 0<  if  0  else  so-error l@  then
;
: bt-poll-out  ( timeout -- events #events )
   bt-fh do-poll-out          ( #events )
   poll-fd la1+ wa1+ w@ swap  ( events #events )
;
: ((connect))  ( 'bdaddr -- )
   bt-disconnect      ( 'bdaddr )
   his-bdaddr 6 move  ( )

   0 5 #31 socket  dup ?posix-err  to bt-fh  \ 0 BTPROTO_L2CAP  5 SOCK_SEQPACKET  #31 PF_BLUETOOTH

   \    family=BT   PSM       bdaddr              cid   BDADDR_LE_PUBLIC
   pkt{ #31 pkt-w,  0 pkt-w,  my-bdaddr 6 pkt-$,  4 pkt-w,  1 pkt-b, }pkt  ( adr len )
   swap bt-fh bind  ?posix-err

   \    level                key_size
   pkt{ secure-level pkt-b,  0 pkt-b, }pkt   ( adr len )
   swap  4  #274  bt-fh  setsockopt  ?posix-err  \ 4=BT_SECURITY #274=SOL_BLUETOOTH

   $800 4 bt-fh fcntl ?posix-err  \ $800=O_NONBLOCK 4=F_SETFL

   \    family=BT   PSM       bdaddr               cid   BDADDR_LE_PUBLIC
   pkt{ #31 pkt-w,  0 pkt-w,  his-bdaddr 6 pkt-$,  4 pkt-w,  1 pkt-b, }pkt  ( adr len )
   swap  bt-fh  connect  0<  if
      errno #115 <>  errno #11 <>  and  abort" BT connect failed (connect)"
   then

   \ Wait up to 10 seconds for the socket to become writable
   #10000 bt-poll-out  1 <> abort" BT connect failed (poll)"
   4 and 0= abort" BT connect failed (poll fd)"

   \ Wait one second to ensure the connection stays up.  Sometimes the
   \ final connection establishment fails about 0.6 seconds after
   \ apparent initial "success", reporting POLLHUP.
   #1000 ms
   #1000 bt-poll-out  1 <> abort" BT connect failed (poll2)"
   $10 and  abort" BT connection hangup"
;

: (connect)  ( 'bdaddr -- )
   ['] ((connect)) catch  ?dup  if
      bt-disconnect
      throw
   then
;

#20 buffer: 'uuid
: set-uuid16  ( uuid16 -- 'uuid  )  #16 'uuid l!  'uuid la1+ w!  'uuid  ;

: .4x push-hex <# u# u# u# u# u#> pop-base type space ;
: .wx  ( adr offset -- )  + w@ .4x ;

#32 buffer: pdu-out
0 value pdu-ptr
: pdu-c,  ( b -- )  pdu-ptr c!  pdu-ptr 1+ to pdu-ptr  ;
: pdu-w,  ( w -- )  wbsplit swap pdu-c, pdu-c,  ;
: pdu-$,  ( adr len -- )  tuck  pdu-ptr swap move  pdu-ptr + to pdu-ptr  ;
: pdu{  ( opcode -- )  pdu-out to pdu-ptr  pdu-c,  ;
: pdu{w,  ( w opcode -- )  pdu{ pdu-w,  ;
: }pdu  ( -- )
   pdu-out  pdu-ptr over -  bt-fh h-write-file
   0< abort" BT write failed"
;

0 value /pending-notification
#40 buffer: pending-notification

$100 buffer: pdu-in

defer handle-unexpected-pdu  ( len -- )
: show-unexpected-pdu  ( len -- )
   pdu-in c@ $1b =  if   ( len )
      to /pending-notification
      pdu-in pending-notification /pending-notification move
   else
      ." Unexpected PDU: "  pdu-in swap cdump  cr
   then
;
' show-unexpected-pdu to handle-unexpected-pdu

-1 constant timeout
-2 constant error-response
-3 constant disconnected
-4 constant short-pdu

0 value error
: set-error  ( n -- )  to error  ;
: expect-response  ( -- true | len false )
   0 to error

   begin
      pdu-in $100 bt-fh #1000 timed-read  ( -1|len )
      dup 0<  if  drop timeout set-error  true  exit  then   ( len )

      dup 1 <  if  drop short-pdu set-error true exit  then  ( len )
      pdu-in c@  1 =  if  drop error-response set-error true exit  then  ( len )
      pdu-in c@  pdu-out c@ 1 +  =   if  false exit  then    ( len )
      handle-unexpected-pdu                                  ( )
   again
;

: $.uuid  ( uuid$ -- )
   2 =  if  ." SIG " 0 .wx  exit  then  ( adr )
   dup 3 + le-l@ $a0e5e9 =  if      ( adr )
      ." NOD " #12 .wx  exit        ( -- )
   then                             ( adr )
   #16 bounds  do  i c@ .2x  loop   ( )
;

\ Tool for looping over the characteristics in a handle range
0 value element-length
0 value next-handle
0 value end-handle

: >pdu-data$  ( len -- adr len' )
   pdu-in 1+ c@ to element-length   ( len )
   pdu-in swap  2 /string           ( adr len' )
;

defer parse-item  ( handle value-handle perm uuid$ -- )

: do-characteristics-list   ( high low -- end-code true | false )
   \ 8 is READ_BY_TYPE_REQ, $2803 is UUID for "characteristic"
   8 pdu{w, pdu-w, $2803 pdu-w,  }pdu

   expect-response  if  true exit  then  ( len )
   >pdu-data$  bounds  ?do               ( )
      i 3 + le-w@ 1+ to next-handle      ( )
      i le-w@  i 3 + le-w@  i 2+ c@      ( handle value-handle perm )
      i element-length 5 /string parse-item ( results true | false )
      if  true unloop exit  then         ( )
   element-length +loop                  ( )
   false
;

: over-characteristics  ( high low xt -- ?? true | false )
   to parse-item  to next-handle   to end-handle
   begin
      end-handle next-handle do-characteristics-list  ( ?? true | false )
   until
;

: show-primary  ( start end uuid$ -- )
   $.uuid  ."  S: " swap .4x  ." E: " .4x  cr
;
: do-discover-primaries  ( high low -- end? )
   \ $10 is READ_BY_GROUP_REQ, $2800 is UUID for "primary service"
   $10 pdu{w, pdu-w, $2800 pdu-w,  }pdu

   expect-response  if  true exit  then  ( len )
   >pdu-data$   bounds  ?do
      i 2+ le-w@ 1+ to next-handle
      i le-w@  i 2+ le-w@  i element-length  4 /string  show-primary
   element-length +loop
   false
;

: .primaries  ( -- )
   1 to next-handle  $ffff to end-handle
   begin
      end-handle next-handle do-discover-primaries
   until
;

: write-handle  ( adr len handle -- )
   $12 pdu{w,  pdu-$,  }pdu
   expect-response abort" write-handle failed"  ( len )
   \ The length is 1 and the PDU contains only the response code $13
   drop
;
: write-cmd-handle  ( adr len handle -- )  $52 pdu{w,  pdu-$,  }pdu  ;

: read-handle  ( handle -- adr len )
   $0a pdu{w, }pdu  expect-response abort" Read handle failed"  ( len )
   pdu-in swap 1 /string
;


\needs wbsplit  : wbsplit  ( w -- b.low b.high )  ;
\needs be-w! : be-w!  ( w adr -- )  >r  wbsplit r@ c! r> 1+ c!  ;

#16 constant /uuid

: set-uuid128  ( uuid$ -- 'uuid )  #128 'uuid l!  'uuid la1+ swap move  'uuid  ;

\ : read-uuid128   ( uuid16 -- )  set-uuid128  $ffff 1  btbuf  bt-read-uuid .err  ;

: >uuid$  ( 'uuid -- adr len )  dup la1+  swap l@ 3 rshift  ;
: the-uuid$  ( -- adr len )  'uuid >uuid$  ;

: >service-handles  ( 'uuid -- high low )
   1 6 pdu{w,  $ffff pdu-w,  $2800 pdu-w,  ( 'uuid )  >uuid$ pdu-$,  }pdu
   expect-response abort" Can't find service handles"  ( len )
   drop  pdu-in 3 + le-w@  pdu-in 1+ le-w@
;
: >sig-service-handles ( uuid16 -- high low )  set-uuid16 >service-handles  ;

\ Worker for over-characterstics for locating handles for a UUID
: find-uuid-handle   ( handle value-handle perm uuid$ -- false | value-handle char-handle true )
   the-uuid$  compare 0=  if    ( handle value-handle perm )
      drop swap true            ( value-handle char-handle true )
   else                         ( handle value-handle perm )
      3drop false               ( false )
   then                         ( false | value-handle char-handle true )
;

: find-sig-handles  ( char-uuid16 service-uuid16 -- value-handle char-handle )
   >sig-service-handles    ( char-uuid16 high low )
   rot set-uuid16 drop     ( high low )
   ['] find-uuid-handle over-characteristics  ( [ value-handle char-handle ] )
   error abort" Can't find handle"
;

: >sig-vhandle  ( char-uuid16 service-uuid16 -- value-handle )  find-sig-handles drop  ;

: sig-handle:  ( char-uuid16 service-uuid16 "name" -- handle )
   create 0 ,  w, w,
   does>
   dup @  0=  if                 ( adr )
      dup na1+ wa1+ w@           ( adr char-uuid16 )
      over na1+ w@ >sig-vhandle  ( adr handle )
      over !                     ( adr )
   then                          ( adr )
   @                             ( handle )
;

: >hid-report-vhandle  ( report-ref# -- value-handle )
   >r                           ( hid-high hid-low  r: ref# )
   $1812 >sig-service-handles   ( hid-high hid-low  r: ref# )
   $2a4d set-uuid16 drop        ( hid-high hid-low  r: ref# )
   begin                        ( high low  r: ref#)
      over swap                 ( high  high low  r: ref# )
      ['] find-uuid-handle over-characteristics  ( high [ value-handle char-handle ] r: ref# )
   error 0=  while              ( high  value-handle char-handle  r: ref# )
      drop dup 2+ read-handle   ( high  value-handle adr len  r: re# )
      drop c@ r@ =  if          ( high  value-handle  r: ref# )
         nip  r> drop  exit     ( -- value-handle  )
      then                      ( high  value-handle  r: ref# )
      3 +                       ( high low'  r: ref# )
   repeat                       ( high  r: ref# )
   r> 2drop true abort" Can't find report handle"
;

: hid-report-handle:  ( report-ref# "name" -- handle )
   create 0 ,  ,
   does>
   dup @  0=  if                      ( adr )
      dup na1+ @ >hid-report-vhandle  ( adr handle )
      over !                          ( adr )
   then                               ( adr )
   @                                  ( handle )
;

: flush-handles  ( -- )
   ['] forth  follow
   begin  another?  while
      dup definer  dup ['] sig-handle: =  swap ['] hid-report-handle: =  or  if
         >body off
      else
         drop
      then
   repeat

;

: display-notification  ( handle value-handle perm uuid$ -- end? )
   rot $10 and  if                      ( handle value-handle uuid$ )
      \ Notifiable
      $.uuid  ." H: " swap .4x           ( value-handle )
      1+ read-handle  drop le-w@         ( notification? )
      if  ." ON"  else  ." OFF"  then cr ( )
   else                                  ( handle value-handle uuid$ )
      2drop 2drop                        ( )
   then                                  ( )
   false
;
: .notifications  ( -- )  $ffff 1  ['] display-notification  over-characteristics  ;

: display-characteristic  ( handle value-handle perm uuid$ -- end? )
   $.uuid  ."  H: " rot .4x  ." P: " .2x  ."  VH: " .4x   cr
   false
;

: .chars  ( -- )  $ffff 1  ['] display-characteristic  over-characteristics  ;

1 buffer: byte-buf
: byte-write-handle  ( b handle -- )  swap byte-buf c!  byte-buf 1  rot  write-handle  ;

: read-sig-uuid  ( char-uuid16 service-uuid16 -- adr len )  >sig-vhandle read-handle  ;

: >ccc  1+  ;
: notify-on  ( handle -- )  " "(01 00)" rot >ccc write-handle  ;
: notify-off  ( handle -- )  " "(00 00)" rot >ccc write-handle  ;

: read-device-info  ( uuid16 -- $ )  $180a read-sig-uuid  ;
: .model         $2a24 read-device-info type  ;
: .manufacturer  $2a29 read-device-info type  ;
: .sn            $2a25 read-device-info type  ;
: .fw            $2a26 read-device-info type  ;
: .sw            $2a28 read-device-info type  ;
: .hw            $2a27 read-device-info type  ;

$2a19 $180f sig-handle: battery-handle

: .devname  $2a00 $1800 read-sig-uuid  type ;
: .sysid    $2a23 $180a read-sig-uuid  cdump  ;

: bt+null  ( adr len -- adr len' )  2dup +  0 swap c!  1+  ;

$100 buffer: pdu

: notified-handle  ( -- h )  pdu 1+ le-w@  ;
: pdu>notify-data$   ( pdu-len -- data-adr data-len )  pdu swap 3 /string  ;

: .ws  ( adr len -- )  bounds  ?do  i le-w@ w->n .d  /w +loop  ;

: wait-notify  ( timeout -- true | data-adr data-len false )
   /pending-notification  if      ( timeout )
      drop                        ( )
      /pending-notification  0 to /pending-notification  ( len )
      pending-notification pdu 2 pick  move   ( len )
      pdu>notify-data$ false                  ( data-adr data-len false )
      0 to /pending-notification    ( data-adr data-len false )
      exit                          ( -- data-adr data-len false )
   then                           ( timeout )

   >r                         ( r: timeout )

   begin
      pdu $100 bt-fh  r@  timed-read     ( len | -1 )
      dup 0>                             ( len flag )
   while                                 ( len )
      pdu c@ $1b =  if                   ( len )
         r> drop  pdu>notify-data$  false exit  ( -- data-adr data-len false )
      else                               ( len )
         handle-unexpected-pdu           ( )
      then
   repeat                                ( -1  r: timeout )
   r> 2drop true                         ( true )
;

: show-notifications  ( -- )
   ." Handle : data" cr
   begin
      #100 wait-notify  0=  if
         notified-handle .x ." : " cdump cr
      then
   key? until
   key drop
;

defer handle-other-notification  ( adr len -- )
' 2drop to handle-other-notification

\ Suitable for handle-other-notification, for debugging
: .notification  ( adr len -- )
   ." Handle: 0x" notified-handle .x
   ." Data: " cdump cr
;
: show-discards  ( -- )  ['] .notification to handle-other-notification  ;

: drain-notifications  ( -- )
   begin
      #100 wait-notify
   0= while
      handle-other-notification
  repeat
;

: wait-handle  ( timeout handle -- true | data-adr data-len false )
   begin                             ( timeout handle )
      over wait-notify               ( timeout handle [] )
   0= while                          ( timeout handle adr len )
      2 pick notified-handle =  if   ( timeout handle adr len )
         2swap 2drop false exit      ( -- adr len false )
      else                           ( timeout handle adr len )
         handle-other-notification   ( timeout handle )
      then                           ( timeout handle )
   repeat                            ( timeout handle )
   2drop true
;

: get-number  ( -- n )
   push-decimal
   safe-parse-word  $number  abort" Bad number"  ( n )
   pop-base
;

6 buffer: bin-bdaddr-buf
: $>hex  ( adr len -- )
   push-hex $number abort" Bad hex number"  pop-base
;
: bdaddr>binary  ( adr -- 'bdaddr )
   \ The loop runs backwards because the binary is little-endian
   0  5  ?do                 ( adr )
      dup 2 $>hex            ( adr b )
      bin-bdaddr-buf i + c!  ( adr )
      2+                     ( adr' )
   -1 +loop                  ( adr )
   drop  bin-bdaddr-buf      ( 'bdaddr )
;
