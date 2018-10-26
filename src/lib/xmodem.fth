purpose: X/YMODEM protocol for serial uploads and downloads

\ Xmodem protocol file transfer to and from memory
\ Commands:
\   send  ( adr len -- )
\   receive  ( adr maxlen -- adr len )

\ Interface to the serial line:
\
\ m-key?     -- flag
\       Flag is true if a character is available on the serial line
\ m-key      -- char
\       Gets a character from the serial line
\ m-emit        char --
\       Puts the character out on the serial line.

: end-delay  ( -- )  d# 200 ms  ;


vocabulary modem
only forth also modem also   modem definitions
base @ decimal

\ Files sent with XMODEM are padded at the end with ^Z
\ Ideally they would be removed by xmodem-to-file:
: remove-eofs  ( adr len -- adr len' )
   begin  dup  while
      2dup + 1- c@ $1a <>  if  exit  then
      1-
   repeat
;

\ Common to both sending and receiving
0 value crc?   0 value big?   \ 0 value streaming?
variable #control-z's
d# 128 constant 128by
d# 1024 constant 1k
variable checksum
variable #errors    4 constant max#errors  variable #naks
: /sector  ( -- n )  big?  if  1k  else  128by  then  ;

\ ASCII control characters
    0 constant nul
    1 constant soh  \ Start of header; 128-byte packets
    2 constant stx  \ Start of header; 1024-byte packets
    4 constant eot
    6 constant ack
d# 21 constant nak
d# 24 constant can

: timeout!  ( ms -- )  ms>ticks   timer-init !  ;
: timeout:  \ name  ( milliseconds -- )
   create ,
   does>  @ timeout!
;
d# 3000 timeout: short-timeout  d# 6000 timeout: long-timeout
d# 60000 timeout: initial-timeout
short-timeout

: gobble  ( -- ) \ eat characters until they stop coming
   d# 100 timeout!   begin  timed-in  0=  while  drop  repeat   long-timeout
;

variable done?
: rx-abort  ( -- )  end-delay  2 done? !  ;
: tx-abort  ( -- )  end-delay  2 done? !  true abort" aborted"  ;

\ It would be nice to use control C, but some operating systems don't pass it
: ?interrupt  ( -- )  \ aborts if user types control Z
   panel-button? if  can m-emit  abrt-msg tx-abort   then
;

\ Receiving



variable got-sector#
: receive-setup  ( -- )
   0 got-sector# !   #naks off   #control-z's off
;
: update-sector#  ( byte -- )
   dup  0=  if  $100 +  then         ( sector-offset )
   got-sector# @  $ff invert and  +  ( sector# )
   got-sector# !
;
: receive-error ( -- ) \ eat rest of packet and send a nak
   gobble
   1 #naks +!   #naks @ max#errors >  if
      can m-emit   giveup-msg rx-abort
   then
   nak m-emit
;

: receive-data  ( adr len -- error? )
   0 -rot bounds                               ( chk endadr startadr )
   crc?  if                                    ( crc endadr startadr )
      ?do  timed-in throw  updcrc  i c!  loop  ( crc )
      timed-in throw  timed-in throw           ( crc high low )
      swap bwjoin  <>                          ( error? )
   else                                        ( sum endadr startadr )
      ?do  timed-in throw  dup i c!  +  loop   ( sum )
      h# ff and  timed-in throw  <>            ( error? )
   then                                        ( error? )
;
variable base-adr
variable end-adr
0 value chunk-sector#
: buf$  ( -- adr len )
   base-adr @   got-sector# @  chunk-sector# -  /sector *
;
/sector buffer: junk-buf
: try-receive  ( -- )
   ( packet OK return:  none )
   ( retry return: throws -1 )
   ( done  return: throws 1 )
   ( abort return: throws 2 )
   ( memory overflow return: throws 3 )
   timed-in  throw
   case
      soh of  false to big?     r0-msg       endof  \ expected...
      stx of  true to big?      r1-msg       endof  \ expected...
      -1  of  timeout-msg -1 throw           endof
      nul of  1 throw                        endof  \ XXX check this
      can of  can-msg 2 throw                endof
      eot of  done-msg ack m-emit  1 throw   endof
      ( default) bogus-char -1 throw
   endcase                           ( )

   timed-in                throw     ( sec# )
   timed-in                throw     ( sec# ~sec# )
   h# ff xor over <>       throw     ( sec# )
   update-sector#                    ( )
   buf$ +  /sector -                 ( bottom-adr )
   dup end-adr @ u>=  if             ( adr )
      can m-emit 3 throw
   then                              ( adr )
   \ This is in case of a resend of a previous sector
   \ after we have moved on.
   dup base-adr @ u<  if             ( adr )
      drop junk-buf                  ( adr' )
   then                              ( adr' )
   /sector  receive-data   throw     ( )

   ack m-emit
   got-sector# @ panel-d.

   #naks off
;
: !receive-packet  ( -- )
   r2-msg
   begin        ( )
      ['] try-receive catch  case   ( [ 0 | n ] )
         \ The usual case: successful packet reception
         0  of  ( ) exit  endof

         ?interrupt

         \ Retryable error
         -1 of  ( ) receive-error  endof

         \ Handle termination conditions at a higher level
         ( default: n ) throw
      endcase   ( )
   again
;
: +receive  ( -- adr len more? )
   got-sector# @  to chunk-sector#
   begin
      buf$ +  end-adr @ =  if  buf$ true  exit  then   ( -- adr len more? )

      r2-msg
      ['] try-receive catch  case
         0 of   endof   \ Packet ok

         ?interrupt

        -1 of  receive-error  endof

         1 of           \ Normal end of transmission
            buf$ remove-eofs false  exit   ( -- adr len more? )
         endof
         2 of           \ Canceled
            can-msg end-delay   2 throw
         endof

         3 of            \ Overflow
            of-msg end-delay   3 throw
         endof
         ( default ) can m-emit abrt-msg   throw
      endcase
   again
;
: start-receive  ( adr maxlen -- )
   over base-adr !        ( adr maxlen )
   + end-adr !            ( )
   receive-setup  gobble	      
   nak m-emit
;
: (receive)  ( adr maxlen -- adr len )  start-receive  +receive drop  ;

\ Sending
modem definitions

: bail-out  ( -- )  can m-emit  giveup-msg tx-abort  ;
: wait-ack  ( -- proceed? )  \ wait for ack or can
[ifdef] streaming?  \ YMODEM-g
   streaming?  if
      m-key?  if  m-key can =  if  bail-out  then  then
      true exit
   then
[then]
   
   #errors off
   begin
      ?interrupt
      timed-in  if
         1 #errors +!  #errors @  max#errors >  if  bail-out  then
         timeout-msg false  exit
      then
      case
         ack of   #naks off  true exit  endof
         can of   can-msg tx-abort       endof
         nak of
            1 #naks +!  #naks @  max#errors >  if  bail-out  then
            false exit
         endof

         \ If we get a C, restart
         [char] C  of  got-sector# @ 0<>  if  [char] C bogus-char  then  endof

         ( default) dup bogus-char
      endcase
   again
;
variable sector#
: start-receiver  ( -- )  \ wait for nak
   gobble
   upld-msg
   sector# off
   #naks off  false to crc?
   initial-timeout
   begin
      timed-in  if  timeout-msg tx-abort exit  then
      case
         can of   can-msg  tx-abort      endof
         nak of   true          endof
         [char] C  of  true to crc?  crc-msg  true  endof
[ifdef] streaming?
         [char] G  of  true to streaming?  true to crc?  true  endof
[then]
         nul of   false   endof   \ Startup transients generate nulls
         ( default)  dup ignore-char  false swap
      endcase
   until
   gobble long-timeout
;

: padch  ( -- b )  control Z  sector# @  0<>  and  ;
\ Send without confirmation
: send-packet  ( adr len big? -- )
   if  1k  stx  else  128by soh  then  ( adr len /sec start ) 
   m-emit                                       ( adr len /sec ) 

   \ Sector number
   sector# @  dup m-emit  h# ff xor m-emit      ( adr len /sec )

   over - 0  2swap                              ( #pad 0 adr len )
   crc?  if                                     ( #pad 0 adr len )
      crc-send                                  ( #pad crc )
      swap 0  ?do  padch updcrc m-emit  loop    ( crc' )
      0 updcrc updcrc drop                      ( crc' )
      wbsplit m-emit m-emit                     ( )
   else                                         ( #pad 0 adr len )
      checksum-send                             ( #pad sum )
      swap 0  ?do  padch  dup m-emit  +  loop   ( sum' )
      m-emit                                    ( )
   then                                         ( )
; 

\ Send until delivery confirmed
: deliver-packet  ( adr len big? -- )
   sector# @ panel-d.
   begin  3dup send-packet  wait-ack until
   3drop
;

: end-data  ( -- )
   begin  eot m-emit  wait-ack  until  \ End the protocol
   done-msg  end-delay
;

: sx  ( adr len -- )
   m-init
   start-receiver                    ( adr len )
   begin  dup 0>  while              ( adr len )
      1 sector# +!                   ( adr len )
      2dup  /sector min              ( adr len adr /this )
      tuck  big?  deliver-packet     ( adr len /this )
      /string                        ( adr' len' )
   repeat                            ( adr len )
   2drop                             ( )

   end-data
;

0 [if]
\ Info format:
\ <filename>NUL<decimal_size>[[ <decimal_modtime>] <octal_permsissions.]NUL...
: send-file  ( adr len name$ -- )
   m-init
   start-receiver
   here place                     ( adr len )
   " "(00)" here $cat             ( adr len )
   push-decimal dup (.) pop-base  ( adr len len$ )
   here $cat  here count          ( adr len batch$ )
   false deliver-packet           ( adr len )
   sx
;

: sb-end  ( -- )  start-receiver  " "(00)" false deliver-packet  end-delay  ;

: sb  ( adr len name$ -- )  send-file sb-end  ;
[then]

forth definitions

alias sx sx

only forth also definitions

base !
