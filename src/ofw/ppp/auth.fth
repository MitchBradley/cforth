\ See license at end of file
purpose: PPP authentication and phase control

\ Bits in auth_pending (used inline)
\ 1	constant UPAP_WITHPEER
\ 4	constant CHAP_WITHPEER

0 value auth_pending		\ Pending authentication operations
0 value auth_required		\ Peer is required to authenticate

: pap-id       ( -- a n )   " pap-id"       $ppp-info  ;
: pap-password ( -- a n )   " pap-password" $ppp-info  ;
: chap-name    ( -- a n )   " chap-name"    $ppp-info  ;
: chap-secret  ( -- a n )   " chap-secret"  $ppp-info  ;

\ LCP has gone down; it will either die or try to re-establish.
: link_down   ( -- )
   ipcp-fsm fsm_close
   \ ccp_close
   4 to phase			\ 4 is PHASE_TERMINATE
;

\ Proceed to the network phase.
: network_phase   ( -- )
   3 to phase			\ 3 is PHASE_NETWORK
   ipcp-fsm fsm_open
   \ ccp_open
;

\ We have failed to authenticate ourselves to the peer using the given protocol.
: auth_withpeer_fail   ( protocol -- )
   case
      4  of  ." CHAP"  endof
      1  of  ." PAP"   endof
      ( default )  ." Unknown"
   endcase
   ."  authentication failed" cr
   link_down
;

\ We have authenticated ourselves to the peer using the given protocol.
: auth_withpeer_success   ( peer-code -- )
   invert auth_pending and
   dup to auth_pending
   \ If there is no more authentication still being done,
   \ proceed to the network phase.
   0= if  network_phase  then
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
