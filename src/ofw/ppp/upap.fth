\ See license at end of file
purpose: UPAP -- PPP User Password Authentication Protocol

decimal

258 buffer: upap_username
258 buffer: upap_password

variable upap_transmits

0 value upap-to

0 value upap_id
0 value upap-clientstate

: set-upap-state   ( state -- )
   show-states? if   ." upap "  dup .state-name  then
   to upap-clientstate
;
: authreq?   ( -- flag )  upap-clientstate AUTHREQ =  ;	\ A common query

\ Send an Authenticate-Request.
: upap_sauthreq   ( -- )
   upap_username c@  upap_password c@  + HEADERLEN + 2+	( outlen )

   PPP_PAP outpacket_buf makeheader				( outlen outp )
   upap_id 1+ to upap_id
   1 putc  upap_id putc   swap putw	\ 1 is UPAP_AUTHREQ	( outp )
   upap_username c@ putc
   upap_username count puts
   upap_password c@ putc
   upap_password count puts					( outp )
   outpacket_buf tuck - ppp-write drop				( )
   
   upap-to 0 3 timeout			\ 3 is UPAP_DEFTIMEOUT
   1 upap_transmits +!
   AUTHREQ set-upap-state
;

\ Retransmission timer for sending auth-reqs expired.
: upap_timeout   ( arg -- )
   drop  authreq? 0=  if  exit  then
   
   upap_transmits @  d# 10 >= if
      \ give up in disgust
      BADAUTH set-upap-state 
      1 auth_withpeer_fail 
      exit
   then

   upap_sauthreq		\ Send Authenticate-Request
;

\ Initialize a UPAP unit.
: upap_init   ( -- )
   0 upap_username c!
   0 upap_password c!
   0 to upap_id
   INITIAL set-upap-state
   ['] upap_timeout to upap-to
;

\ Give up waiting for the peer to send an auth-req.
\ The lower layer is up.
\ Start authenticating if pending.
: upap_lowerup   ( -- )

   upap-clientstate  case
      INITIAL  of  CLOSED set-upap-state  endof
      PENDING  of  upap_sauthreq          endof
   endcase
;

\ The lower layer is down.
\ Cancel all timeouts.
: upap_lowerdown   ( -- )
   \ Cancel timeout if one is pending
   authreq?  if	 ['] upap_timeout 0 untimeout  then
   INITIAL set-upap-state
;


\ Peer doesn't speak this protocol.
\ This shouldn't happen.  In any case, pretend lower layer went down.
: upap_protrej   ( -- )
   authreq?  if  1 auth_withpeer_fail  then	\ Timeout pending?
   upap_lowerdown
;

: bad-auth-msg?  ( a n id -- flag )
   drop  authreq? 0=  if  2drop  true exit  then		( a n )

   \ Parse message.
   dup 1 < if   2drop true  exit   then				( a n )

   swap count rot 1- over < if  2drop false  exit   then	( a msglen )
   2drop	\ type cr
   false
;

\ Receive Authenticate-Ack.
: upap_rauthack   ( a n id -- )
   bad-auth-msg?  if  exit  then
   
   OPENED set-upap-state

   ['] upap_timeout 0 untimeout		\ Cancel timeout
   1 auth_withpeer_success		\ UPAP_WITHPEER
;

\ Receive Authenticate-Nakk.
: upap_rauthnak   ( a n id -- )
   bad-auth-msg?  if  exit  then
   
   5 set-upap-state				\ 5 is UPAPCS_BADAUTH
   
   BADAUTH set-upap-state
   1 auth_withpeer_fail
;

\ Input UPAP packet.
: upap_input   ( a n -- )
   dup HEADERLEN < if   2drop exit   then			( a n )
   
   over 2+ be-w@  dup HEADERLEN < if  3drop exit   then	( a n len )
   tuck < if   3drop exit   then				( a n )

   over dup 1+ c@ swap c@ case
      2  of  upap_rauthack  endof		\ UPAP_AUTHACK	( a n id )
      3  of  upap_rauthnak  endof		\ UPAP_AUTHNAK	( a n id )
      3drop
   endcase
;

\ Authenticate us with our peer (start client).
: upap_authwithpeer   ( $user $password -- )
   upap_password place   upap_username place  0 upap_transmits !

   \ Lower layer up yet?
   upap-clientstate  case
      INITIAL  of  PENDING set-upap-state  exit  endof
      PENDING  of                          exit  endof
   endcase
   
   upap_sauthreq				\ Start protocol
;
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
