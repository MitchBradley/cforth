purpose: X/YMODEM protocol for serial uploads and downloads
copyright: Copyright 2003  AgileTV Corporation  All Rights Reserved

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

variable buf-start
variable buf-end
variable mem-start
variable mem-end

: putc  ( char -- )  buf-start @ c!  1 buf-start +!  ;

: end-delay  ( -- )  d# 200 ms  ;


vocabulary modem
only forth also modem also   modem definitions
base @ decimal

\ Common to both sending and receiving
0 value crc?   0 value big?   \ 0 value streaming?
variable #control-z's
d# 128 constant 128by
d# 1024 constant 1k
variable sector#
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

: receive-setup  ( adr maxlen -- )
   1 sector# !   #naks off   #control-z's off
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
variable got-sector#
: try-receive  ( adr maxlen -- adr maxlen actual-len )
   ( packet OK return:  none )
   ( retry return: throws -1 )
   ( done  return: throws 1 )
   ( abort return: throws 2 )
   begin
      timed-in  throw
      case
         soh of  false to big?     r0-msg       endof  \ expected...
         stx of  true to big?      r1-msg       endof  \ expected...
         -1  of  timeout-msg -1 throw           endof
         nul of  1 throw                        endof  \ XXX check this
         can of  can-msg 2 throw                endof
         eot of  done-msg ack m-emit  1 throw   endof
        ( default) bogus-char -1 throw
      endcase                        ( adr maxlen )
   again

   /sector <  if  2 throw  then      ( adr )
   timed-in                throw     ( adr sec# )
   timed-in                throw     ( adr sec# ~sec# )
   h# ff xor over <>       throw     ( adr sec# )
   got-sector# !                     ( adr )
   /sector  receive-data   throw     ( )

   ack m-emit
   sector# @ panel-d.
   1 sector# +!   \ Expected sector#

   #naks off
   /sector                           ( actual )
;
: !receive-packet  ( adr maxlen -- adr maxlen actual-len )
   r2-msg
   begin        ( adr maxlen )
      2dup ['] try-receive catch  case   ( adr maxlen [ actual 0 | x x n ] )
         \ The usual case: successful packet reception
         0  of  ( adr maxlen actual-len ) exit  endof

         ?interrupt

         \ Retryable error
         -1 of  ( adr maxlen x x ) 2drop receive-error             endof

         \ Handle termination conditions at a higher level
         ( default: adr maxlen x x n ) throw
      endcase   ( adr maxlen )
   again
;
: (receive)  ( adr0 maxlen -- adr0 len )
   receive-setup                      ( adr0 maxlen )
   gobble  nak m-emit                 ( adr0 maxlen )
   2dup                               ( adr0 maxlen adr0 maxlen )
   begin  dup 0>  while               ( adr0 maxlen adr remlen )
      ['] !receive-packet catch  case
         0 of         ( adr0 maxlen adr remlen actual-len )   \ Packet ok
            /string   ( adr0 maxlen adr' remlen' )
         endof
         1 of         ( adr0 maxlen adr remlen )   \ Normal end of transmission
            nip - exit   ( adr0 len )
         endof
         ( default ) can m-emit abrt-msg   throw
      endcase
   repeat                              ( adr0 maxlen adr remlen )
   can m-emit  of-msg  end-delay 
;

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
         [char] C  of  sector# @ 1 <>  if  [char] C bogus-char  then  endof

         ( default) dup bogus-char
      endcase
   again
;
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

: pad  ( -- b )  control Z  sector# @  0<>  and  ;
\ Send without confirmation
: send-packet  ( adr len big? -- )
   if  1k  stx  else  128by soh  then  ( adr len /sec start ) 
   m-emit                                       ( adr len /sec ) 

   \ Sector number
   sector# @  dup m-emit  h# ff xor m-emit      ( adr len /sec )

   over - 0  2swap                              ( #pad 0 adr len )
   crc?  if                                     ( #pad 0 adr len )
      crc-send                                  ( #pad crc )
      swap 0  ?do  pad updcrc m-emit  loop      ( crc' )
      0 updcrc updcrc drop                      ( crc' )
      wbsplit m-emit m-emit                     ( )
   else                                         ( #pad 0 adr len )
      checksum-send                             ( #pad sum )
      swap 0  ?do  pad  dup m-emit  +  loop     ( sum' )
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
