\ See license at end of file
purpose:  Finite State Machines for PPP

\ Each FSM is described by a data structure and a set of callbacks.

struct
   /token field >resetci	\ Reset our Configuration Information
   /token field >cilen		\ Length of our Configuration Information
   /token field >addci		\ Add our Configuration Information
   /token field >ackci		\ ACK our Configuration Information
   /token field >nakci		\ NAK our Configuration Information
   /token field >rejci		\ Reject our Configuration Information
   /token field >reqci		\ Request peer's Configuration Information
   /token field >up		\ Called when fsm reaches OPENED state
   /token field >down		\ Called when fsm leaves OPENED state
   /token field >finished	\ Called when we don't want the lower layer
   /token field >extcode	\ Called when unknown code received
constant /fsm_callbacks

struct
   /n field >protocol		\ Data Link Layer Protocol field value
   /n field >retransmits	\ Number of retransmissions left
   /n field >nakloops		\ Number of nak loops since last ack
   /fsm_callbacks field >callbacks	\ Callback routines
   1 field >f_state		\ State
   1 field >id			\ Current id
   1 field >reqid		\ Current request id
   1 field >seen_ack		\ Have received valid Ack/Nak/Rej to Req
constant /fsm

/fsm buffer: lcp-fsm
/fsm buffer: ipcp-fsm
/fsm buffer: ccp-fsm

0 value thefsm

\ Callbacks
: do-callback  ( fsm+index -- )   >callbacks token@ execute  ;

: resetci    ( -- )                    thefsm >resetci   do-callback  ;
: cilen      ( -- len )                thefsm >cilen     do-callback  ;
: addci      ( a n -- residue )        thefsm >addci     do-callback  ;
: ackci      ( a n -- good? )          thefsm >ackci     do-callback  ;
: nakci      ( a n -- good? )          thefsm >nakci     do-callback  ;
: rejci      ( a n -- good? )          thefsm >rejci     do-callback  ;
: reqci      ( a n rej? -- n2 res )    thefsm >reqci     do-callback  ;
: finished   ( -- )                    thefsm >finished  do-callback  ;
: extcode    ( a n code id -- flag )   thefsm >extcode   do-callback  ;
: go-down    ( -- )                    thefsm >down	 do-callback  ;
: go-up	     ( -- )                    thefsm >up	 do-callback  ;

: this-id   ( -- n )  thefsm >reqid c@  ;

: next-id   ( fsm -- n )
   dup >id dup c@ 1+ dup rot c!
   dup rot >reqid c!
;

: .fsm   ( state fsm -- )
   case
      lcp-fsm   of  ." lcp "  .state-name  endof
      ipcp-fsm  of  ." ipcp " .state-name  endof
      ccp-fsm   of  ." ccp "  .state-name  endof
      >r  ." FSM: " .  ." state: " .  r> 
   endcase
;
: set-state   ( state -- )
   show-states? if   dup thefsm .fsm  then
   thefsm >f_state c!
;
: thestate   ( -- n )  thefsm >f_state c@  ;
: set-fsm  ( fsm -- state )  to thefsm  thestate  ;

: set-retransmits    ( n -- )   thefsm >retransmits !  ;
: decr-retransmits   ( -- )  -1 thefsm >retransmits +!  ;
: retransmits-done?  ( -- done? )   thefsm >retransmits @ 0<=  ;

\ Send some data.
\ Used for all packets sent to our peer by this module.
: fsm_send   ( data datalen code id fsm -- )
   >r
   \ Adjust length to be smaller than MTU
   2swap  peer_mru HEADERLEN - umin		( code id data datalen )
   tuck outpacket_buf PPP_HDRLEN + HEADERLEN + swap move
   HEADERLEN +					( code id outlen )
   r> >protocol @ outpacket_buf makeheader	( code id outlen a )
   >r rot r@ c! swap r@ 1+ c! dup r> 2+ be-w!	( outlen )
   outpacket_buf swap PPP_HDRLEN + 
   ppp-write drop
;

: send-termreq   ( -- )  0 0 TERMREQ  thefsm next-id  thefsm fsm_send  ;
: send-termack   ( id -- )  >r  0 0 TERMACK r> thefsm fsm_send  ;

defer fsm_timeout
: set-timer   ( -- )   ['] fsm_timeout  thefsm  DEFTIMEOUT  timeout  ;
: end-timer   ( -- )   ['] fsm_timeout  thefsm  untimeout  ;

\ Send a Configure-Request.
: fsm_sconfreq   ( retransmit? -- )
   thestate  dup REQSENT <>  over ACKRCVD <> and  swap ACKSENT <> and  if
      \ Not currently negotiating - reset options
      resetci
      0 thefsm >nakloops !
   then							( retransmit? )

   0=  if
      \ New request - reset retransmission counter, use new ID
      DEFMAXCONFREQS set-retransmits
      thefsm next-id drop
   then
   
   false thefsm >seen_ack c!

   \ Make up the request packet
   outpacket_buf PPP_HDRLEN + HEADERLEN +		( a )
   
   cilen  peer_mru HEADERLEN -  min			( a n )
   2dup addci  if  ( this should never happen )  then	( a n )
   
   \ send the request to our peer
   CONFREQ thefsm >reqid c@ thefsm fsm_send

   \ start the retransmit timer
   decr-retransmits
   set-timer
;
: initial-confreq  ( -- )  0 fsm_sconfreq  ;
: initial-confreq-send  ( -- )  0 fsm_sconfreq  REQSENT set-state  ;

: fsm_tocl   ( -- )
   retransmits-done?  if
      \ ." We've waited for an ack long enough.  Peer probably heard us." cr
      thestate CLOSING = if  CLOSED  else  STOPPED  then  set-state
      finished
   else
      send-termreq  set-timer  decr-retransmits
   then
;
: fsm_to   ( -- )
   retransmits-done?  if
      STOPPED set-state  finished
   else
      1 fsm_sconfreq  thestate ACKRCVD =  if  REQSENT set-state  then
   then
;

\ Timeout expired.
: (fsm_timeout)   ( fsm -- )
   thefsm >r
   set-fsm  case
      CLOSING   of  fsm_tocl  endof
      STOPPING  of  fsm_tocl  endof
      REQSENT   of  fsm_to    endof
      ACKRCVD   of  fsm_to    endof
      ACKSENT   of  fsm_to    endof
   endcase
   r> to thefsm
;
' (fsm_timeout) to fsm_timeout


\ Finite State Machine

\ Initialize fsm state.
: fsm_init   ( fsm -- )
   dup set-fsm drop
   INITIAL set-state
   0 swap >id c!
;

\ The lower layer is up.
: fsm_lowerup   ( fsm -- )
   set-fsm  case
      INITIAL  of  CLOSED set-state      endof
      STARTING of  initial-confreq-send  endof
   endcase
;

\ The lower layer is down.
\ Cancel all timeouts and inform upper layers.
: fsm_lowerdown   ( fsm -- )
   set-fsm  case
      CLOSED   of  INITIAL  set-state             endof
      STOPPED  of  STARTING set-state             endof
      CLOSING  of  INITIAL  set-state  end-timer  endof
      STOPPING of  STARTING set-state  end-timer  endof
      REQSENT  of  STARTING set-state  end-timer  endof
      ACKRCVD  of  STARTING set-state  end-timer  endof
      ACKSENT  of  STARTING set-state  end-timer  endof
      OPENED   of  go-down  STARTING set-state    endof
   endcase
;

\ Link is allowed to come up.
: fsm_open   ( fsm -- )
   set-fsm  case
      INITIAL  of  STARTING set-state    endof
      CLOSED   of  initial-confreq-send  endof
      CLOSING  of  STOPPING set-state    endof
   endcase
;

: fsm_closing   ( -- )
   thestate OPENED <>  if  end-timer  else  go-down  then
   
   DEFMAXTERMREQS set-retransmits
   send-termreq
   set-timer
   decr-retransmits
   CLOSING set-state
;

\ Cancel timeouts and either initiate close or possibly go directly to
\ the CLOSED state.
: fsm_close   ( fsm -- )
   set-fsm  case
      STARTING  of  INITIAL set-state  endof
      STOPPED   of  CLOSED  set-state  endof
      STOPPING  of  CLOSING set-state  endof
      REQSENT   of  fsm_closing        endof
      ACKRCVD   of  fsm_closing        endof
      ACKSENT   of  fsm_closing        endof
      OPENED    of  fsm_closing        endof
   endcase
;


\ Receive Configure-Request.
: fsm_rconfreq   ( inp len id -- )
   thestate  case
      CLOSED    of  ( inp len id )  nip nip send-termack  exit  endof
      CLOSING   of  ( inp len id )  3drop exit  endof
      STOPPING  of  ( inp len id )  3drop exit  endof
      OPENED    of  go-down  initial-confreq    endof
      STOPPED   of  initial-confreq-send        endof
   endcase						( inp len id )
   
   \ Pass the requested configuration options
   \ to protocol-specific code for checking.
   2 pick rot  thefsm >nakloops @  DEFMAXNAKLOOPS >=	( inp id inp len rej? )
   reqci						( inp id n code )
   \ send the Ack, Nak or Rej to the peer
   rot over thefsm swap >r				( inp n code id fsm )
   fsm_send    r>					( code )
   dup CONFACK =  if
      drop						( )
      thestate ACKRCVD =  if
	 end-timer
	 OPENED set-state
	 go-up
      else
	 ACKSENT set-state
      then
      0 thefsm >nakloops !
   else							( code )
      \ we sent CONFACK or CONFREJ
      thestate ACKRCVD <>  if  REQSENT set-state  then	( code )
      CONFNAK =  if  1 thefsm >nakloops +!  then	( )
   then							( )
;

\ Receive Configure-Ack.
: fsm_rconfack   ( a n id -- )
   \ Exit if not the expected id
   dup thefsm >reqid c@ <>  thefsm >seen_ack c@  or  if	 3drop  exit  then
   
   3dup drop ackci 0=  if  3drop  exit  then		( a n id ) \ ignore Ack
   
   1 thefsm >seen_ack c!				( a n id )
   
   thestate case					( a n id [state] )
      CLOSED   of  nip nip send-termack  endof		( )
      STOPPED  of  nip nip send-termack  endof		( )
      REQSENT  of
         3drop  ACKRCVD set-state  DEFMAXCONFREQS set-retransmits
      endof
      ACKRCVD  of					( a n id )
	 \ ." An extra valid Ack?" cr
	 3drop  end-timer  initial-confreq-send
      endof
      ACKSENT of					( a n id )
	 3drop  end-timer  OPENED set-state
	 DEFMAXCONFREQS set-retransmits  go-up
      endof
      OPENED  of  3drop  go-down  initial-confreq-send  endof
   endcase
;

\ Receive Configure-Nak or Configure-Reject.
: fsm_rconfnakrej   ( a n code id -- )
   \ Exit if not the expected id
   thefsm >reqid c@ <>  thefsm >seen_ack c@  or  if  3drop  exit  then
   							( a n code )
   
   CONFNAK =  if  2dup nakci  else  2dup rejci  then	( a n ret ) 
   dup 0=  if  3drop  exit  then			( a n ret )
   
   1 thefsm >seen_ack c!				( a n ret )

   thestate case
      CLOSED of						( a n ret )
	 3drop						( )
	 this-id send-termack
      endof
      STOPPED of					( a n ret )
	 3drop						( )
	 this-id send-termack
      endof
      REQSENT of					( a n ret )
	 \ ." They didn't agree to what we wanted - try another request" cr
	 nip nip  end-timer
	 0>  if
	    STOPPED set-state		\ kludge for stopping CCP
	 else
	    initial-confreq
	 then
      endof

      ACKSENT  of					( a n ret )
	 \ ." They didn't agree to what we wanted - try another request..." cr
	 nip nip  end-timer
	 0>  if
	    STOPPED set-state		\ kludge for stopping CCP
	 else
	    initial-confreq
	 then
      endof

      ACKRCVD  of					( a n ret )
	 \ ." Got a Nak/reject when we had already had an Ack??" cr
	 3drop  end-timer  initial-confreq-send
      endof

      OPENED  of					( a n ret )
	 3drop  go-down  initial-confreq-send
      endof
   endcase
;

\ Receive Terminate-Req.
: fsm_rtermreq   ( id -- )
   thestate case
      ACKRCVD  of  REQSENT set-state  endof	\ Start over and keep trying
      ACKSENT  of  REQSENT set-state  endof	\ Start over and keep trying
      OPENED   of
	 \ ." terminated at peer's request" cr
	 go-down  0 set-retransmits  STOPPING set-state  set-timer
      endof
   endcase				( id )
   send-termack
;

\ Receive Terminate-Ack.
: fsm_rtermack   ( -- )
   thestate case
      CLOSING   of  end-timer  CLOSED  set-state  finished  endof
      STOPPING  of  end-timer  STOPPED set-state  finished  endof
      ACKRCVD   of             REQSENT set-state            endof
      OPENED    of  go-down  initial-confreq                endof
   endcase
;

\ Receive an Code-Reject.
: fsm_rcoderej   ( len -- )
   HEADERLEN <  if  exit  then
   thestate ACKRCVD =  if  REQSENT set-state  then
;

\ Peer doesn't speak this protocol.
\ Treat this as a catastrophic error (RXJ-).
: fsm_protreject   ( fsm -- )
   dup set-fsm  case
      CLOSING   of  end-timer  CLOSED  set-state  finished  endof
      CLOSED    of             CLOSED  set-state  finished  endof
      STOPPING  of  end-timer  STOPPED set-state  finished  endof
      REQSENT   of  end-timer  STOPPED set-state  finished  endof
      ACKRCVD   of  end-timer  STOPPED set-state  finished  endof
      ACKSENT   of  end-timer  STOPPED set-state  finished  endof
      STOPPED   of             STOPPED set-state  finished  endof
      OPENED    of
	go-down
	DEFMAXTERMREQS set-retransmits
	send-termreq  set-timer  decr-retransmits  STOPPING set-state
     endof
  endcase
;

\ Input packet.
: fsm_input   ( a n fsm -- )
   set-fsm drop
   dup HEADERLEN < if   2drop  exit   then			( a n )
   over wa1+ be-w@ dup HEADERLEN < if   2drop  exit   then	( a n len )
   tuck < if   2drop  exit   then				( a len )
   
   HEADERLEN /string
   
   thestate dup INITIAL = swap STARTING = or if			( a len )
      2drop  exit
   then								( a len )

   \ Action depends on code.
   over HEADERLEN - dup c@ swap ca1+ c@			( a len code id )
   over case						( a len code id [code])
      CONFREQ  of  nip fsm_rconfreq          endof	( )
      CONFACK  of  nip fsm_rconfack          endof	( )
      CONFNAK  of  fsm_rconfnakrej           endof	( )
      CONFREJ  of  fsm_rconfnakrej           endof	( )
      TERMREQ  of  >r 3drop r> fsm_rtermreq  endof	( )
      TERMACK  of  4drop fsm_rtermack        endof	( )
      CODEREJ  of  2drop nip fsm_rcoderej    endof	( )
      ( default )					( a len code id code )
         drop						( a len code id )
         4dup extcode if				( a len code id )
	    4drop					( )
         else						( a len code id )
	    >r drop HEADERLEN negate /string CODEREJ r>	( a len code id )
	    thefsm fsm_send				( )
         then						( )
         0						( fodder )
   endcase						( )
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
