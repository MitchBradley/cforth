\ See license at end of file
purpose: CHAP -- PPP  Cryptographic Handshake Authentication Protocol

decimal

5	constant CHAP_DIGEST_MD5	\ use MD5 algorithm

\ CHAP codes.
1	constant CHAP_CHALLENGE
2	constant CHAP_RESPONSE
3	constant CHAP_SUCCESS
4	constant CHAP_FAILURE

258 buffer: rhostname			\ hostname received from remote system
258 buffer: rchallenge			\ challenge received from remote system
258 buffer: chap-resp-name		\ our name
258 buffer: secret			\ our secret for remote system
16  buffer: chap-response		\ digest calculated as response

0 value chap-clientstate
0 value chap-resp-type		\ hash algorithm for responses

0 value chap-rto		\ address of chap_responsetimeout

variable chap-resp-transmits	\ Number of transmissions of response
variable chap-resp-id

: set-chap-state   ( state -- )
   show-states? if   ." chap "  dup .state-name  then
   to chap-clientstate
;

\ Authenticate us with our peer (start client).
: chap_authwithpeer   ( our_name digest -- )
   to chap-resp-type
   chap-resp-name place				( )

   chap-clientstate PENDING = if  exit  then

   chap-clientstate INITIAL = if
      \ lower layer isn't up - wait until later
      PENDING set-chap-state
      exit
   then

   \ We get here as a result of LCP coming up.
   \ So even if chap was open before, we will 
   \ have to re-authenticate ourselves.
   LISTEN set-chap-state
;

\ send a response packet
: chap_sendresponse   ( -- )
    chap-resp-name c@  21 +			( outlen )
    PPP_CHAP outpacket_buf makeheader		( outlen outp )
    CHAP_RESPONSE putc
    chap-resp-id c@ putc
    over putw					( outlen outp )
    16 putc
    chap-response 16 puts			( outlen outp )
    chap-resp-name count  puts		\ append our name
    drop PPP_HDRLEN + outpacket_buf swap 
    ppp-write drop
    
    RESPONSE set-chap-state
    chap-rto  0  3  timeout
    1 chap-resp-transmits +!
;

\ Timeout expired on sending response.
: chap_responsetimeout   ( arg -- )
   drop
   chap-clientstate RESPONSE <> if  exit   then
   
   chap_sendresponse		\ re-send the response
;

\ Initialize a CHAP unit.
: chap_init   ( -- )
   INITIAL set-chap-state 
   ['] chap_responsetimeout to chap-rto	
;

\ The lower layer is up.
\ Start up if we have pending requests.
: chap_lowerup   ( -- )
   chap-clientstate case
      INITIAL of  CLOSED set-chap-state  endof
      PENDING of  LISTEN set-chap-state  endof
   endcase
;

\ The lower layer is down.
\ Cancel all timeouts.
: chap_lowerdown   ( -- )
   chap-clientstate RESPONSE = if
      ['] chap_responsetimeout 0 untimeout
   then
   INITIAL set-chap-state
;

\ Peer doesn't grok CHAP.
: chap_protrej   ( -- )
   chap-clientstate dup INITIAL <>  swap CLOSED <> and if
      4 auth_withpeer_fail
   then
   chap_lowerdown		\ shutdown CHAP
;

\ open the CHAP secret file and return the secret
\ for authenticating the given client on the given server.
\ (We could be either client or server).
: get_secret   ( server -- got? )
   \ 0 secret c!					( server )
   \ count " zinc.farmworks.com" $= 0= if
   \    2drop  false  exit
   \ then						( )
   drop							( )
   
   chap-secret secret place
   true
;

\ Receive Challenge and send Response.
: chap_receivechallenge   ( a n id -- )
   chap-resp-id c!
   
   chap-clientstate   dup CLOSED =  swap PENDING =  or  if
      2drop exit
   then						( a n )
   
   dup 2 < if  2drop exit  then			( a n )
   
   swap getc					( n a rchal_len )
   2dup rchallenge place			( n a rchal_len )
   rot swap /string 1-				( a n )
   dup 0< if  2drop exit  then			( a n )
   
   255 min  rhostname place			( )

   \ get secret for authenticating ourselves with the specified host
   rhostname  get_secret 0= if
      ." No CHAP secret found for authenticating us to " rhostname count type cr
   then						( )
   
   \ cancel response timeout if necessary
   chap-clientstate RESPONSE = if
      ['] chap_responsetimeout  0  untimeout
   then

   0 chap-resp-transmits !			( )
   
   \  generate MD based on negotiated type
   chap-resp-type case		\ only MD5 is defined for now
      CHAP_DIGEST_MD5 of			( )
	 MD5Init
	 chap-resp-id 1    MD5Update
	 secret count      MD5Update
	 rchallenge count  MD5Update
	 MD5Final
	 md5digest  chap-response  16 move
	 chap_sendresponse
      endof
      ( default )
      ." unknown digest type " chap-resp-type . cr
   endcase
;

\ Receive and process response.
: chap_receiveresponse   ( a n id -- )
   \ ." chap_receiveresponse" cr
   3drop
;

: ?print  ( a n -- )  dup  if  2dup type  then  2drop  ;

\ Receive Success
: chap_receivesuccess   ( a n id -- )
   drop
   
   \ Answer to a duplicate response?
   chap-clientstate OPENED = if   2drop exit   then	( a n )
   
   \ should not happen
   chap-clientstate RESPONSE <> if   exit   then	( a n )

   ['] chap_responsetimeout  0  untimeout		( a n )

   \ Print the message
   ?print					( )
   
   OPENED set-chap-state
   4 auth_withpeer_success		\ CHAP_WITHPEER
;

\ Receive failure.
: chap_receivefailure   ( a n id -- )
   drop
   \ should not happen
   chap-clientstate RESPONSE <> if   2drop exit   then	( a n )
   
   ['] chap_ResponseTimeout  0  untimeout	( a n )

   \ Print the message
   ?print					( )
   
   4 auth_withpeer_fail
;

\ Input CHAP packet.
: chap_input   ( a n -- )
   dup HEADERLEN < if   2drop exit   then	( a n )
   
   >r 
   dup 2+ be-w@ dup HEADERLEN < if		( a len )
      r> 3drop  exit
   then						( a len )
   dup r> > if  2drop exit  then		( a n )
   
   over >r					( a n r: a )
   HEADERLEN /string				( a n r: a )
   r> be-w@ wbsplit case			( a n id [sel] )
      CHAP_CHALLENGE  of  chap_receivechallenge  endof
      CHAP_RESPONSE   of  chap_receiveresponse   endof
      CHAP_FAILURE    of  chap_receivefailure    endof
      CHAP_SUCCESS    of  chap_receivesuccess    endof
      ( default )				\ Need code reject?
      3drop
      ." Unknown CHAP code received. " cr
   endcase
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
