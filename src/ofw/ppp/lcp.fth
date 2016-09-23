\ See license at end of file
purpose: LCP -- PPP Link Control Protocol

decimal

\ Options.
1	constant CI_MRU			\ Maximum Receive Unit
2	constant CI_ASYNCMAP		\ Async Control Character Map
3	constant CI_AUTHTYPE		\ Authentication Type
4	constant CI_QUALITY		\ Quality Protocol
5	constant CI_MAGICNUMBER		\ Magic Number
7	constant CI_PCOMPRESSION	\ Protocol Field Compression
8	constant CI_ACCOMPRESSION	\ Address/Control Field Compression

\ LCP-specific packet types.
8	constant PROTREJ		\ Protocol Reject
9	constant ECHOREQ		\ Echo Request
10	constant ECHOREP		\ Echo Reply
11	constant DISCREQ		\ Discard Request

\ Lengths of configuration options.
4	constant CILEN_SHORT
6	constant CILEN_LONG
5	constant CILEN_CHAP
8	constant CILEN_LQR

\ LCP options
struct
    4 field >asyncmap		\ Value of async map
    4 field >magicnumber
    4 field >numloops		\ Number of loops during magic number neg.
    4 field >lqr_period		\ Reporting period for LQR 1/100ths second
    
    2 field >mru		\ Value of MRU
    1 field >neg_mru 		\ Negotiate the MRU?
    1 field >neg_asyncmap 	\ Negotiate the async map?
    
    1 field >neg_upap 		\ Ask for UPAP authentication?
    1 field >neg_chap 		\ Ask for CHAP authentication?
    1 field >neg_magicnumber 	\ Ask for magic number?
    1 field >neg_pcompression 	\ HDLC Protocol Field >Compression?
    
    1 field >neg_accompression 	\ HDLC Address/Control Field >Compression?
    1 field >neg_lqr 		\ Negotiate use of Link Quality Reports
    1 field >chap_mdtype	\ which MD type (hashing algorithm)
    1+
constant /lcp

/lcp buffer: lcp-want
/lcp buffer: lcp-allow
/lcp buffer: lcp-got
/lcp buffer: lcp-his
/lcp buffer: lcp-nope		\ options we've seen Naks for
/lcp buffer: lcp-try		\ options to request next time

32 buffer: xmit_accm		\ extended transmit ACCM
PPP_MRU buffer: nak_buffer	\ where we construct a nak packet

0 value lcp_echos_pending	\ Number of outstanding echo msgs
0 value lcp_echo_number		\ ID number of next echo frame
0 value lcp_echo_timer_running	\ TRUE if a timer is running
0 value lcp_echo_interval 	\ Interval between LCP echo-requests
0 value	lcp_echo_fails		\ Tolerance to unanswered echo-requests

0 value looped_back

DEFLOOPBACKFAIL value lcp_loopbackfail

variable nakp  0 nakp !
variable rejp  0 rejp !

: put-nakp-char   ( -- )  nakp putchar  ;
: put-nakp-short  ( -- )  nakp putshort  ;
: put-nakp-long   ( -- )  nakp putlong  ;

: lcp-state   ( -- n )   lcp-fsm >f_state c@  ;

\ LCP is allowed to come up.
: lcp_open   ( -- )    lcp-fsm fsm_open  ;

\ Take LCP down.
: lcp_close   ( -- )   lcp-fsm fsm_close  ;

\ Callbacks

\ Reset our Configuration Info.
: lcp_resetci   ( -- )
   magic lcp-want >magicnumber !
   0 lcp-want >numloops !
   lcp-want lcp-got /lcp move
   PPP_MRU to peer_mru
;

\ Return length of our CI.
: ?lencivoid   ( n1 neg -- n2 )	c@ if  CILEN_VOID  +  then  ;
: ?lencichap   ( n1 neg -- n2 )	c@ if  CILEN_CHAP  +  then  ;
: ?lencishort  ( n1 neg -- n2 )	c@ if  CILEN_SHORT +  then  ;
: ?lencilong   ( n1 neg -- n2 )	c@ if  CILEN_LONG  +  then  ;
: ?lencilqr    ( n1 neg -- n2 )	c@ if  CILEN_LQR   +  then  ;
: lcp_cilen   ( -- cilen )
   lcp-got >r
   0
   r@ >neg_mru		?lencishort
   r@ >neg_asyncmap	?lencilong
   r@ >neg_chap		?lencichap
   \ Only ask for one of CHAP and UPAP, even if we will accept either.
   r@ >neg_chap c@ 0= if
      r@ >neg_upap	?lencishort
   then
   r@ >neg_lqr		?lencilqr
   r@ >neg_magicnumber	?lencilong
   r@ >neg_pcompression	?lencivoid
   r> >neg_accompression ?lencivoid
;

: rot-swap-putc  ( a1 val opt -- val a2 )  rot swap putc  ;

\ Add our desired CIs to a packet.
: addcivoid   ( a1 opt neg -- a2 )
   c@  if
      putc  CILEN_VOID putc
   else
      drop
   then
;
: addcishort   ( a1 val opt neg -- a2 )
   c@  if
      rot-swap-putc  CILEN_SHORT putc  swap putw
   else
      2drop
   then
;
: addcilong   ( a1 val opt neg -- a2 )
   c@  if
      rot-swap-putc  CILEN_LONG  putc  swap putl
   else
      2drop
   then
;
: addcilqr   ( a1 val opt neg -- a2 )
   c@  if
      rot-swap-putc  CILEN_LQR   putc  PPP_LQR putw  swap putl
   else
      2drop
   then
;
: addcichap   ( a1 val opt neg -- a2 )
   c@  if
      rot-swap-putc  CILEN_CHAP putc  PPP_CHAP putw  swap putc
   else
      2drop
   then
;

: lcp_addci   ( a n -- left-over )
    lcp-got >r
    over						( a n a1 )
    r@ >mru w@		CI_MRU	          r@ >neg_mru	         addcishort
    r@ >asyncmap l@	CI_ASYNCMAP       r@ >neg_asyncmap       addcilong
    r@ >chap_mdtype c@	CI_AUTHTYPE       r@ >neg_chap	         addcichap
    r@ >neg_chap c@ 0= if
       PPP_PAP          CI_AUTHTYPE       r@ >neg_upap           addcishort
    then
    r@ >lqr_period l@   CI_QUALITY	  r@ >neg_lqr	         addcilqr
    r@ >magicnumber l@  CI_MAGICNUMBER	  r@ >neg_magicnumber	 addcilong
                        CI_PCOMPRESSION   r@ >neg_pcompression   addcivoid
                        CI_ACCOMPRESSION  r> >neg_accompression  addcivoid
							( a n a1 )
    rot - -
;
: ackcivoid   ( a1 n1 opt neg -- a2 n2 error? )
   c@ if					( a1 n1 opt )
      -rot CILEN_VOID - dup 0<  if  rot drop  true  exit  then	( opt a n )
      -rot  getc rot <>				( n a err )
      swap getc CILEN_VOID <> rot or
      rot swap					( a n err )
   else						( a1 n1 opt )
      drop false				( a n err )
   then						( a2 n2 err )
;
: ackcishort   ( a1 n1 val opt neg -- a2 n2 error? )
   c@ if
      2swap CILEN_SHORT - dup 0< if
	 2nip  true  exit
      then				( val opt a n )
      >r  getc rot <> swap		( val err a )
      getc CILEN_SHORT <> rot or	( val a err )
      -rot getw rot <> rot or		( a err )
      r> swap
   else
      2drop false
   then
;
: ackcilong   ( a1 n1 val opt neg -- a2 n2 error? )
   c@ if
      2swap CILEN_LONG - dup 0< if
	 2nip  true  exit
      then				( val opt a n )
      >r  getc rot <> swap		( val err a )
      getc CILEN_LONG <> rot or		( val a err )
      -rot getl rot <> rot or		( a err )
      r> swap
   else
      2drop false
   then
;
: ackcilqr   ( a1 n1 val opt neg -- a2 n2 error? )
   c@ if
      2swap CILEN_LQR - dup 0< if
	 2nip  true  exit
      then				( val opt a n )
      >r  getc rot <> swap		( val err a )
      getc CILEN_LQR <> rot or		( val a err )
      -rot getw PPP_LQR <> rot or	( val a err )
      -rot getl rot <> rot or		( a err )
      r> swap
   else
      2drop false
   then
;
: ackcichap   ( a1 n1 digest opt neg -- a2 n2 error? )
   c@ if
      >r 2swap r> -rot			( digest opt a1 n1 )
      CILEN_CHAP - dup 0< if
	 2nip  true  exit
      then
      >r  getc rot <> swap		( digest err a )
      getc CILEN_CHAP <> rot or		( digest a err )
      swap getw PPP_CHAP <> rot or	( digest a err )
      -rot getc rot <> rot or		( a err )
      r> swap
   else
      2drop false
   then
;
\ Ack our CIs.
\ This should not modify any state if the Ack is bad.
: lcp_ackci   ( a n -- good? )
   lcp-got >r
   
   \ CIs must be in exactly the same order that we sent.
   \ Check packet length and CI length at each step.
   \ If we find any deviations, then this packet is bad.
   CI_MRU r@ >mru w@  r@ >neg_mru  ackcishort if  r> 3drop  false  exit  then
   CI_ASYNCMAP r@ >asyncmap @ r@ >neg_asyncmap
   ackcilong if  r> 3drop  false  exit  then
   CI_AUTHTYPE r@ >chap_mdtype c@ r@ >neg_chap 
   ackcichap if  r> 3drop  false  exit  then
   r@ >neg_chap c@ 0= if
      CI_AUTHTYPE PPP_PAP r@ >neg_upap ackcishort if  r> 3drop  false  exit  then
   then
   CI_QUALITY r@ >lqr_period @ r@ >neg_lqr
   ackcilqr if  r> 3drop  false  exit  then
   r@ >magicnumber @  CI_MAGICNUMBER  r@ >neg_magicnumber
   ackcilong if  r> 3drop  false  exit  then
   CI_PCOMPRESSION  r@ >neg_pcompression  ackcivoid if  r> 3drop  false  exit  then
   CI_ACCOMPRESSION r@ >neg_accompression ackcivoid if  r> 3drop  false  exit  then
   nip r> drop			( n )
   \ If there are any remaining CIs, then this packet is bad.
   0=
;
: nakcivoid?   ( a n opt neg -- a n nak? )
   dup >r
   lcp-got + c@ if
      >r over be-w@ wbsplit r> = swap CILEN_VOID = and
      over CILEN_VOID >= and  if
	 CILEN_VOID /string
	 true lcp-nope r@ + c!
	 true
      else
	 false
      then
   else
      drop false
   then
   r> drop
;
: nakcishort?   ( a n opt neg -- a n short nak? )
   dup >r
   lcp-got + c@ if
      >r over be-w@ wbsplit r> = swap CILEN_SHORT = and
      over CILEN_SHORT >= and  if
	 >r  2+ getw  r> CILEN_SHORT -  swap
	 true lcp-nope r@ + c!
	 true
      else
	 0 false
      then
   else
      false
   then
   r> drop
;
: nakcilong?   ( a n opt neg -- a n long nak? )
   dup >r
   lcp-got + c@ if					( a n opt )
      >r over be-w@ wbsplit r> = swap CILEN_LONG = and
      over CILEN_LONG >= and  if			( a n )
	 >r  2+ getl  r> CILEN_LONG -  swap		( a n long )
	 true lcp-nope r@ + c!
	 true
      else						( a n )
	 0 false
      then
   else							( a n opt )
      false
   then
   r> drop
;
: nakcilqr?   ( a n opt neg -- a n short long nak? )
   dup >r
   lcp-got + c@ if					( a n opt )
      >r over be-w@ wbsplit r> = swap CILEN_LQR = and
      over CILEN_LQR >= and  if				( a n )
	 >r  2+ getw swap getl swap			( w l a )
	 r> CILEN_LQR -  2swap				( a n w l )
	 true lcp-nope r@ + c!
	 true
      else						( a n )
	 0 0 false
      then
   else							( a n opt )
      0 false
   then
   r> drop
;
: bad-nak   ( -- )
   \ ." lcp_nakci received bad Nak!" cr
;
\ Peer has sent a NAK for some of our CIs.
\ This should not modify any state if the Nak is bad
\ or if LCP is in the OPENED state.
: lcp_nakci   ( a n -- good? )
   lcp-nope /lcp erase
   lcp-got lcp-try /lcp move

   \ Any Nak'd CIs must be in exactly the same order that we sent.
   \ Check packet length and CI length at each step.
   \ If we find any deviations, then this packet is bad.
   
   \ We don't care if they want to send us smaller packets than
   \ we want.  Therefore, accept any MRU less than what we asked for,
   \ but then ignore the new value when setting the MRU in the kernel.
   \ If they send us a bigger MRU than what we asked, accept it, up to
   \ the limit of the default MRU we'd get if we didn't negotiate.
   CI_MRU 0 >neg_mru nakcishort? if		( a n short )
      dup lcp-want >mru w@ <= over DEFMRU < or if
	 dup lcp-try >mru w!
      then
   then
   drop
   
   \ Add any characters they want to our (receive-side) asyncmap.
   CI_ASYNCMAP 0 >neg_asyncmap nakcilong? if			( a n long )
      dup lcp-try >asyncmap dup @ rot or swap !			( a n long )
   then
   drop								( a n )

   \ If they've nak'd our authentication-protocol, check whether
   \ they are proposing a different protocol, or a different
   \ hash algorithm for CHAP.
   lcp-got dup >neg_chap c@  swap >neg_upap c@ or if		( a n )
      >r							( a )  ( r: n )
      getc CI_AUTHTYPE = >r getc dup CILEN_SHORT >= r> and
      r@ CILEN_SHORT >= and if					( a cilen ) ( r: n )
	 swap getw rot swap					( a cilen short )
	 over CILEN_SHORT = over PPP_PAP = and if		( a cilen short )
	    2drop						( a )
	    \ If they are asking for PAP, then they don't want to do CHAP.
	    \ If we weren't asking for CHAP, then we were asking for PAP,
	    \ in which case this Nak is bad.
	    lcp-got >neg_chap c@ 0= if				( a )  ( r: n )
	       bad-nak  r> 2drop  false exit
	    then
	    false lcp-got >neg_chap c!				( a )
	 else							( a cilen short )
	    over CILEN_CHAP = swap PPP_CHAP = and if		( a cilen )
	       drop getc  lcp-got >neg_chap c@ if		( a char )
		  \ We were asking for CHAP/MD5; they must want a different
		  \ algorithm.  If they can't do MD5, we'll have to stop
		  \ asking for CHAP.
		  lcp-got >chap_mdtype c@ <> if			( a )
		     \ ." lcp_nakci got chap nak due to mdtype differences" cr
		     false lcp-got >neg_chap c!
		  then						( a )
	       else						( a char )
		  drop						( a )
		  \ Stop asking for PAP if we were asking for it.
		  false lcp-got >neg_upap c!
	       then						( a )
	    else						( a cilen )
	       \ We don't recognize what they're suggesting.
	       \ Stop asking for what we were asking for.
	       lcp-got >neg_chap c@ if
		  false lcp-got >neg_chap c!
	       else
		  false lcp-got >neg_upap c!
	       then						( a cilen )
	       + CILEN_SHORT -					( a' )
	    then						( a )
	 then							( a )
      then							( a )
      r>							( a n )
   then								( a n )
   
   \ Peer shouldn't send Nak for protocol compression or
   \ address/control compression requests; they should send
   \ a Reject instead.  If they send a Nak, treat it as a Reject.
   lcp-got >neg_chap c@ 0= if
      CI_AUTHTYPE 0 >neg_upap nakcishort? if			( a n short )
	 0 lcp-try >neg_upap c!
      then
      drop
   then								( a n )
   
   \ If they can't cope with our link quality protocol, we'll have
   \ to stop asking for LQR.  We haven't got any other protocol.
   \ If they Nak the reporting period, take their value. XXX?
   CI_QUALITY 0 >neg_lqr nakcilqr? if				( a n short long )
      over PPP_LQR <> if
	 false lcp-try >neg_lqr c!
      else
	 dup lcp-try >lqr_period !
      then
   then								( a n short long )
   2drop							( a n )

   \ Check for a looped-back line.
   CI_MAGICNUMBER 0 >neg_magicnumber nakcilong? if
      magic lcp-try >magicnumber !
      true to looped_back
   then
   drop
   
   CI_PCOMPRESSION 0 >neg_pcompression nakcivoid? if
      false lcp-try >neg_pcompression c!
   then
   
   CI_ACCOMPRESSION 0 >neg_accompression nakcivoid? if
      false lcp-try >neg_accompression c!
   then

   \ There may be remaining CIs, if the peer is requesting negotiation
   \ on an option that we didn't include in our request packet.
   \ If we see an option that we requested, or one we've already seen
   \ in this packet, then this packet is bad.
   \ If we wanted to respond by starting to negotiate on the requested
   \ option(s), we could, but we don't, because except for the
   \ authentication type and quality protocol, if we are not negotiating
   \ an option, it is because we were told not to.
   \ For the authentication type, the Nak from the peer means
   \ `let me authenticate myself with you' which is a bit pointless.
   \ For the quality protocol, the Nak means `ask me to send you quality
   \ reports', but if we didn't ask for them, we don't want them.
   \ An option we don't recognize represents the peer asking to
   \ negotiate some option we don't support, so ignore it.
   ( a n )
   begin						( a n )
      dup CILEN_VOID >
   while
      >r getc swap getc	r>				( citype a cilen n )
      over - dup 0< if
	 bad-nak 4drop r> drop false exit
      then
      
      >r tuck + 2- >r					( citype cilen )
      swap case
	 CI_MRU of
	    CILEN_SHORT <> lcp-got >neg_mru c@ or
	    lcp-nope >neg_mru c@ or if
	       bad-nak  2r> r>  3drop  false exit
	    then
	 endof
	 CI_ASYNCMAP of
	    CILEN_LONG <> lcp-got >neg_asyncmap c@ or
	    lcp-nope >neg_asyncmap c@ or if
	       bad-nak  2r> r>  3drop  false exit
	    then
	 endof
	 CI_AUTHTYPE of
	    drop lcp-got >neg_chap c@ lcp-nope >neg_chap c@ or
	    lcp-got >neg_upap c@ lcp-nope >neg_upap c@ or  or if
	       bad-nak  2r> r>  3drop  false exit
	    then
	 endof
	 CI_MAGICNUMBER of
	    CILEN_LONG <> lcp-got >neg_magicnumber c@ or
	    lcp-nope >neg_magicnumber c@ or if
	       bad-nak  2r> r>  3drop  false exit
	    then
	 endof
	 CI_PCOMPRESSION of
	    CILEN_VOID <> lcp-got >neg_pcompression c@ or
	    lcp-nope >neg_pcompression c@ or if
	       bad-nak  2r> r>  3drop  false exit
	    then
	 endof
	 CI_ACCOMPRESSION of
	    CILEN_VOID <> lcp-got >neg_accompression c@ or
	    lcp-nope >neg_accompression c@ or if
	       bad-nak  2r> r>  3drop  false exit
	    then
	 endof
	 CI_QUALITY of
	    CILEN_LQR <> lcp-got >neg_lqr c@ or
	    lcp-nope >neg_lqr c@ or if
	       bad-nak  2r> r>  3drop  false exit
	    then
	 endof
      endcase
      r> r>
   repeat						( a n )
   
   \ If there is still anything left, this packet is bad.
   if
      bad-nak  r> 2drop false exit
   then
   drop
   
   \ OK, the Nak is good.  Now we can update state.
   lcp-state OPENED <> if
      looped_back if
	 1 lcp-try >numloops +!
	 lcp-try >numloops @ lcp_loopbackfail >= if
	    \ ." Serial line is looped back." cr
	    lcp_close
	 then
      else
	 0  lcp-try >numloops !
	 lcp-try lcp-got /lcp move
      then
   then
   true
;

: rejcivoid   ( a n opt neg -- a n )
   dup >r
   lcp-got + c@ if					( a n opt )
      >r over be-w@ wbsplit r> = swap CILEN_VOID = and
      over CILEN_VOID >= and if				( a n )
	 CILEN_VOID /string
	 false lcp-try r@ + c!
      then
   else							( a n opt )
      drop
   then
   r> drop
;
: rejcishort?   ( a n opt val neg -- a n err? )
   dup >r
   lcp-got + c@ if					( a n opt val ) ( r: neg )
      >r						( a n opt ) ( r: neg val )
      >r over be-w@ wbsplit r> = swap CILEN_SHORT = and
      over CILEN_SHORT >= and if			( a n ) ( r: neg val )
	 CILEN_SHORT - swap getw r> <> rot swap		( a n err? ) ( r: neg )
	 false lcp-try r@ + c!
      else
	 r> drop false   
      then
   else
      2drop false
   then
   r> drop
;
: rejcilong?   ( a n opt val neg -- a n err? )
   dup >r
   lcp-got + c@ if					( a n opt val ) ( r: neg )
      >r
      >r over be-w@ wbsplit r> = swap CILEN_LONG = and
      over CILEN_LONG >= and if				( a n ) ( r: neg opt )
	 CILEN_LONG - swap 2+ getl r> <> rot swap	( a n err? ) ( r: neg )
	 false lcp-try r@ + c!
      else						( a n ) ( r: neg opt )
	 r> drop false
      then
   else							( a n opt val ) ( r: neg )
      2drop false
   then
   r> drop
;
: rejcilqr?   ( a n opt val neg -- a n err? )
   dup >r
   lcp-got + c@ if					( a n opt val ) ( r: neg )
      >r
      >r over be-w@ wbsplit r> = swap CILEN_LQR = and
      over CILEN_LQR >= and if				( a n ) ( r: neg val )
	 CILEN_LQR - swap 2+ getc PPP_LQR <>
	 swap getl r> <>  rot or  rot swap		( a n err? ) ( r: neg )
	 false lcp-try r@ + c!
      else						( a n ) ( r: neg val )
	 r> drop false
      then
   else							( a n opt val ) ( r: neg )
      2drop false
   then
   r> drop
;
: rejcichap?   ( a n opt val digest neg -- a n err? )
   dup >r
   lcp-got + c@ if					( a n opt val digest ) ( r: neg )
      >r >r						( a n opt ) ( r: neg digest val )
      >r over be-w@ wbsplit r> = swap CILEN_CHAP = and
      over CILEN_CHAP >= and if				( a n ) ( r: neg digest val )
	 CILEN_CHAP - swap 2+ getw r> <>		( n a err ) ( r: neg digest )
	 swap getc r> <>  rot or  rot swap		( a n err? ) ( r: neg )
	 false lcp-try r@ + c!
      else						( a n ) ( r: neg digest val )
	 2r> 2drop false
      then
   else							( a n opt val digest ) ( r: neg )
      3drop false
   then
   r> drop
;
: bad-rej   ( a n -- false )
   \ ." lcp_rejci received bad Reject " cr
   2drop false
;
\ Peer has Rejected some of our CIs.
\ This should not modify any state if the Reject is bad
\ or if LCP is in the OPENED state.
: lcp_rejci   ( a n -- good? )
   lcp-got lcp-try /lcp move

   \ Any Rejected CIs must be in exactly the same order that we sent.
   \ Check packet length and CI length at each step.
   \ If we find any deviations, then this packet is bad.
   CI_MRU lcp-got >mru w@ 0 >neg_mru
   rejcishort? if  bad-rej exit  then
   CI_ASYNCMAP lcp-got >asyncmap @ 0 >neg_asyncmap
   rejcilong? if  bad-rej exit  then
   CI_AUTHTYPE PPP_CHAP lcp-got >chap_mdtype c@ 0 >neg_chap
   rejcichap? if  bad-rej exit  then
   lcp-got >neg_chap c@ 0= if
      CI_AUTHTYPE PPP_PAP 0 >neg_upap rejcishort? if  bad-rej exit  then
   then
   CI_QUALITY  lcp-got >lqr_period @ 0 >neg_lqr
   rejcilqr? if  bad-rej exit  then
   CI_MAGICNUMBER lcp-got >magicnumber @ 0 >neg_magicnumber
   rejcilong? if  bad-rej exit  then
   CI_PCOMPRESSION  0 >neg_pcompression    rejcivoid
   CI_ACCOMPRESSION 0 >neg_accompression   rejcivoid
   						( a n )
   \ If there are any remaining CIs, then this packet is bad.
   dup if   bad-rej exit  then			( a n )
   2drop
   
   \ Now we can update state.
   lcp-state OPENED <>  if  lcp-try lcp-got /lcp move  then
   true
;

: suggest-chap   ( -- )
   CI_AUTHTYPE put-nakp-char
   CILEN_CHAP put-nakp-char
   PPP_CHAP put-nakp-short		\ suggest CHAP
   lcp-allow >chap_mdtype c@ put-nakp-char
;
: suggest-pap   ( -- )
   CI_AUTHTYPE put-nakp-char
   CILEN_SHORT put-nakp-char
   PPP_PAP put-nakp-short
;
: wants-pap   ( -- result )
   lcp-his >neg_chap c@ if	\ we've already accepted CHAP
      \ ." lcp_reqci rejecting AUTHTYPE PAP"
      CONFREJ
   else
      lcp-allow >neg_upap c@ 0= if			\ we don't want to do PAP
	 suggest-chap
	 CONFNAK
      else
	 true lcp-his >neg_upap c!
	 CONFACK
      then
   then
;
: wants-chap   ( a -- result )
   lcp-his >neg_upap c@ if	\ we've already accepted PAP
      \ ." lcp_reqci rejecting AUTHTYPE CHAP"
      drop CONFREJ exit
   then						( a )
   
   lcp-allow >neg_chap c@ 0= if	( a )	\ we don't want to do CHAP
      suggest-pap				( a )
      drop CONFNAK exit
   then						( a )
   
   c@  dup lcp-allow >chap_mdtype c@  <>  if	( digest )
      drop
      suggest-chap
      CONFNAK
   else						( digest )
      true lcp-his >neg_chap c!
      lcp-his >chap_mdtype c!			( )
      CONFACK
   then
;
: wants-auth   ( a -- result )
   \ Authtype must be PAP, MSCHAP (if enabled), or CHAP.
   \ Note of if both ao >neg_upap and ao >neg_chap are set,
   \ and the peer sends a Configure-Request with two
   \ authenticate-protocol requests, one for CHAP and one
   \ for PAP, then we will reject the second request.
   \ Whether we end up doing CHAP or PAP depends then on
   \ the ordering of the CIs in the peer's Configure-Request.
   getw  dup PPP_PAP = if			( a cishort )
      2drop wants-pap exit
   then						( a cishort )
   
   PPP_CHAP = if				( a )
      wants-chap exit
   then						( a )
   drop						( )
   
   \ We don't recognize the protocol they're asking for.
   \ Nak it with something we're willing to do.
   lcp-allow >neg_chap c@ if
      suggest-chap
   else
      suggest-pap
   then
   CONFNAK
;
: lcp-reqci-mru   ( a cilen -- result )
   CILEN_SHORT <>
   lcp-allow >neg_mru c@ 0=  or if		( a )
      drop CONFREJ exit
   then
   
   \ He must be able to receive at least our minimum.
   \ No need to check a maximum.  If he sends a large number,
   \ we'll just ignore it.
   be-w@  dup MINMRU < if			( cishort )
      drop
      CI_MRU put-nakp-char
      CILEN_SHORT put-nakp-char
      MINMRU put-nakp-short		\ Give him a hint
      CONFNAK exit
   then						( cishort )
   
   true lcp-his >neg_mru c!	\ remember that he sent an MRU
   lcp-his >mru w!		\ and the value
   CONFACK
;
: lcp-reqci-async   ( a cilen -- result )
   CILEN_LONG <>
   lcp-allow >neg_asyncmap c@ 0=  or if			( a )
      drop CONFREJ exit
   then							( a )

   \ Asyncmap must have set at least the bits
   \ which are set in lcp-allow >asyncmap.
   be-l@  dup invert lcp-allow >asyncmap @ and if	( cilong )
      CI_ASYNCMAP put-nakp-char
      CILEN_LONG put-nakp-char
      lcp-allow >asyncmap @ or put-nakp-short
      CONFNAK exit
   then							( cilong )
   
   true lcp-his >neg_asyncmap c!
   lcp-his >asyncmap !
   CONFACK
;
: lcp-reqci-auth   ( a cilen -- result )
   CILEN_SHORT < if					( a )
      drop CONFREJ exit
   then							( a )
   
   lcp-allow >neg_upap c@
   lcp-allow >neg_chap c@ or 0= if			( a )
      \ ." we're not willing to authenticate" cr
      CONFREJ exit
   then							( a )
   wants-auth						( result )
;
: lcp-reqci-lqr   ( a cilen -- result )
   CILEN_LQR <>
   lcp-allow >neg_lqr c@ 0=  or if
      drop CONFREJ exit
   then							( a )
   
   \ Check the protocol
   be-w@ PPP_LQR <> if					( )
      CI_QUALITY put-nakp-char
      CILEN_LQR  put-nakp-char
      PPP_LQR    put-nakp-short
      lcp-allow >lqr_period @ put-nakp-long
      CONFNAK
   else
      CONFACK
   then
;
: lcp-reqci-magic   ( a cilen -- result )
   CILEN_LONG <>
   lcp-allow >neg_magicnumber c@ 
   lcp-got >neg_magicnumber c@ or 0=  or if		( a )
      drop CONFREJ exit
   then							( a )
   
   \ He must have a different magic number.
   be-l@  dup lcp-got >magicnumber @ =
   lcp-got >neg_magicnumber c@ and if			( cilong )
      drop
      CI_MAGICNUMBER put-nakp-char
      CILEN_LONG put-nakp-char
      magic put-nakp-long
      CONFNAK
   else							( cilong )
      true lcp-his >neg_magicnumber c!
      lcp-his >magicnumber !
      CONFACK
   then
;
: lcp-reqci-pcomp   ( a cilen -- result )
   nip CILEN_VOID <>
   lcp-allow >neg_pcompression c@ 0=  or if
      CONFREJ
   else
      true lcp-his >neg_pcompression c!
      true to comp_proto
      CONFACK
   then
;
: lcp-reqci-accomp   ( a cilen -- result )
   nip CILEN_VOID <>
   lcp-allow >neg_accompression c@ 0=  or if
      CONFREJ
   else
      true lcp-his >neg_accompression c!
      true to comp_ac
      CONFACK
   then
;
: lcp-reqci-sw   ( a cilen citype -- citype result )
   dup >r
   case
      CI_MRU of						( a cilen )
	 lcp-reqci-mru					( result )
      endof
      CI_ASYNCMAP of					( a cilen )
	 lcp-reqci-async				( result )
      endof
      CI_AUTHTYPE of
	 lcp-reqci-auth
      endof
      CI_QUALITY of
	 lcp-reqci-lqr
      endof
      CI_MAGICNUMBER of
	 lcp-reqci-magic
      endof
      CI_PCOMPRESSION of
	 lcp-reqci-pcomp
      endof
      CI_ACCOMPRESSION of
	 lcp-reqci-accomp
      endof
      ( default )					( a cilen citype )
      >r
      2drop						( )
      \ ." lcp_reqci got unknown option " r@ . cr
      CONFREJ
      r>
   endcase
   r> swap							( citype result )
;
\ Check the peer's requested CIs and send appropriate response.
\ Returns of CONFACK, CONFNAK or CONFREJ and input packet modified
\ appropriately.  If reject_if_disagree is non-zero, doesn't return
\ CONFNAK; returns CONFREJ if it can't return CONFACK.
: lcp_reqci   ( a n1 reject_if_disagree -- n2 result )
   to reject_if_disagree			( a n )
   CONFACK >r				\ Final packet return code
   
   \ Reset all his options.
   lcp-his /lcp erase

   \ Process all his options.
   nak_buffer nakp !
   over						( a n next )
   dup rejp !
   begin  over  while
      dup to cip
      2dup 1+ c@ 2 rot between 0=		( a n next bad? )
      2 pick 2 < or if			\ Reject till end of packet
	 \ ." lcp_reqci got bad CI length! " cr	( a n next )
	 nip 0 swap			\ Don't loop again
	 0 CONFREJ				( a n next' citype status )
      else
	 dup >r
	 tuck 1+ c@ /string swap		( a n next' )
	 r> getc swap getc rot			( a n next' next cilen citype )
	 lcp-reqci-sw				( a n next' citype status )
      then
      dup CONFNAK = if
	 swap CI_MAGICNUMBER <>
	 reject_if_disagree  and if
	    drop CONFREJ
	 else
	    r@ CONFREJ <> if
	       r> drop CONFNAK >r
	    then
	 then
      else
	 nip
      then					( a n next' status )
      CONFREJ = if
	 r> drop CONFREJ >r
	 rejp @ cip <> if		\ Need to move rejected CI?
	    cip rejp @ over 1+ c@ move
	 then
	 cip 1+ c@ rejp +!
      then
   repeat				( a n next )
   nip
   r@ case
      CONFACK of			( a next )
	 swap -				( len )
      endof
      CONFNAK of			( a next )
	 \ Copy the Nak'd options from the nak_buffer to the caller's buffer.
	 drop
	 nak_buffer swap
	 nakp @ nak_buffer - >r
	 r@ move
	 r>				( len )
      endof
      CONFREJ of			( a next )
	 drop rejp @ swap -		( len )
      endof
   endcase
   r>					( len ret )
;

\ LCP has terminated the link; go to the Dead phase and take the
\ physical layer down.
: link_terminated   ( -- )
   phase 0= if  exit  then	\ 0 is PHASE_DEAD

   0 to phase			\ 0 is PHASE_DEAD
   ." Connection terminated." cr
   false to ppp-is-open   abort
;

\ LCP has finished with the lower layer.
: lcp_finished   ( -- )
   link_terminated
;

\ A Protocol-Reject was received.
: lcp_protrej   ( -- )
   lcp-fsm  fsm_protreject
;

\ Demultiplex a Protocol-Reject.
: demuxprotrej   ( protocol -- )
   \ Upcall the proper Protocol-Reject routine.
   case
      PPP_LCP   of  lcp_protrej   endof
      PPP_IPCP  of  ipcp_protrej  endof
      PPP_PAP   of  upap_protrej  endof
      PPP_CHAP  of  chap_protrej  endof
      \ PPP_CCP of  ccp_protrej	  endof
      ( default )
      \ ." demuxprotrej: Protocol-Reject for unrecognized protocol " dup .h  cr
   endcase
;

\ Receive an Protocol-Reject.
\ Figure out which protocol is rejected and inform it.
: lcp_rprotrej   ( a n -- )
   2 <  if  drop  exit  then		( a )
   
   be-w@				( proto )
   
   \ Protocol-Reject packets received in any state other than the LCP
   \ OPENED state SHOULD be silently discarded.
   lcp-state dup OPENED <> if	( proto state )
      \ ." Protocol-Reject discarded, LCP in state " dup . cr
      2drop  exit
   then					( proto state )
   drop demuxprotrej			\ Inform protocol
;

\ LCP has received a reply to the echo
: lcp_received_echo_reply   ( inp len id -- )
   drop				( inp len )
   \ Check the magic number - don't count replies from ourselves.
   dup 4 <  if  2drop  exit  then
   
   drop be-l@			( magic )
   lcp-got >magicnumber @ = 
   lcp-got >neg_magicnumber c@ and  if  exit  then  \ rec'd own echo reply

   \ Reset the number of outstanding echo frames
   0 to lcp_echos_pending
;

\ Handle a LCP-specific code.
: lcp_extcode   ( a n code id -- handled? )
   swap case
      PROTREJ of			( a n id )
	 nip lcp_rprotrej  true
      endof
      ECHOREQ of			( a n id )
	 lcp-state OPENED = if
	    lcp-got >magicnumber @  3 pick ( inp ) swap be-l!
	    >r  ECHOREP swap  r>  lcp-fsm fsm_send
	 else
	    3drop
	 then  true
      endof
      ECHOREP of			( a n id )
	 lcp_received_echo_reply  true
      endof
      DISCREQ of			( a n id )
	 3drop  true
      endof
      ( default ) >r			( a n id )
      3drop false
      r>
   endcase
;
    
\ timer

\ Time to shut down the link because there is nothing out there.
: lcp_linkfailure   ( -- )
   lcp-state OPENED = if
      \ ." Excessive lack of response to LCP echo frames." cr
      lcp_close		\ Reset connection
   then
;

variable pkt			\ a short packet...
\ Send an echo request frame to the peer
: lcp_sendechorequest   ( -- )
   \ Detect the failure of the peer at this point.
   lcp_echo_fails if
      lcp_echos_pending dup 1+ to lcp_echos_pending
      lcp_echo_fails >= if
	 lcp-fsm lcp_linkfailure
	 0 to lcp_echos_pending
      then
   then
   
   \ Make and send the echo request frame.
   lcp-state OPENED = if
      lcp-got >neg_magicnumber c@ if
	 lcp-got >magicnumber @
      else
	 0
      then  pkt be-l!
      pkt 4 ECHOREQ
      lcp_echo_number dup 1+ to lcp_echo_number h# ff and 
      lcp-fsm fsm_send
   then
;

\ forward reference
defer lcp_echocheck

\ Timer expired on the LCP echo
: lcp_echotimeout   ( -- )
   lcp_echo_timer_running if
      false to lcp_echo_timer_running
      lcp_echocheck
   then
;

\ Timer expired for the LCP echo requests from this process.
: (lcp_echocheck)   ( -- )
   lcp_sendechorequest
   
   \ Start the timer for the next interval.
   ['] lcp_echotimeout lcp-fsm lcp_echo_interval timeout
   true to lcp_echo_timer_running
;
' (lcp_echocheck) to lcp_echocheck

\ external
   
\ Start the timer for the LCP frame
: lcp_echo_lowerup   ( -- )
   \ Clear the parameters for generating echo frames
   0 to lcp_echos_pending
   0 to lcp_echo_number
   false to lcp_echo_timer_running
   
   \ If a timeout interval is specified then start the timer
   lcp_echo_interval if
      lcp-fsm  lcp_echocheck
   then
;

\ Stop the timer for the LCP frame
: lcp_echo_lowerdown   ( -- )
   lcp_echo_timer_running if
      ['] lcp_echotimeout lcp-fsm untimeout
      false to lcp_echo_timer_running
   then
;

\ The link is established.
\ Proceed to the Dead, Authenticate or Network phase as appropriate.
: link_established   ( -- )
   2 to phase			\ 2 is PHASE_AUTHENTICATE
   0							( auth )
   lcp-his >neg_chap c@ if
      chap-name lcp-his >chap_mdtype c@ chap_authwithpeer
      4 or			\ CHAP_WITHPEER
   else
      lcp-his >neg_upap c@ if
	 pap-id pap-password upap_authwithpeer
	 1 or			\ UPAP_WITHPEER
      then
   then							( auth )
   dup to auth_pending
   0= if
      network_phase
   then
;

\ LCP has come up.
\ Start UPAP, IPCP, etc.
: lcp_up   ( -- )
   lcp-his >r
   r@ >neg_magicnumber c@ if
      0 r@ >magicnumber !
   then
   r@  lcp-got >r
   r@ >neg_magicnumber c@ if
      0 r@ >magicnumber !
   then
   >r							( rs: ho go ho )
   
   \ Set our MTU to the smaller of the MTU we wanted and
   \ the MRU our peer wanted.  If we negotiated an MRU,
   \ set our MRU to the larger of value we wanted and
   \ the value we got in the negotiation.
   r@ >neg_mru c@ if  r@ >mru w@  else  PPP_MRU  then
   lcp-allow >mru w@ min				( mru )
   r@ >neg_asyncmap c@ if  r@ >asyncmap  else  -1  then
   r@ >neg_pcompression c@ r> >neg_accompression c@
   ppp_send_config
							( )  ( rs: ho go )
   \ If the asyncmap hasn't been negotiated, we really should
   \ set the receive asyncmap to ffff.ffff, but we set it to 0
   \ for backwards contemptibility.
   r@ >neg_mru c@ if
      r@ >mru w@ lcp-want >mru w@ max
   else
      PPP_MRU
   then
   r@ >neg_asyncmap c@ if  r@ >asyncmap @  else  0  then
   r@ >neg_pcompression c@  r> >neg_accompression c@
   ppp_recv_config					( )  ( rs: ho )
   
   r@ >neg_mru c@ if
      r@ >mru w@ to peer_mru
   then
   r> drop
   
   chap_lowerup		\ Enable CHAP
   upap_lowerup			\ Enable UPAP

   ipcp-fsm fsm_lowerup		\ Enable IPCP
\   ccp-fsm fsm_lowerup		\ Enable CCP
   lcp_echo_lowerup		\ Enable echo messages

   link_established
;

\ LCP has gone DOWN.
\ Alert other protocols.
: lcp_down   ( -- )
   lcp_echo_lowerdown
   \ ccp-fsm  fsm_lowerdown
   ipcp-fsm fsm_lowerdown
   
   chap_lowerdown
   upap_lowerdown

   \ PPP_MRU -1 0 0    ppp_send_config
   \ PPP_MRU  0 0 0    ppp_recv_config
   PPP_MRU to peer_mru
   
   link_down
;

create lcp-callbacks
   ]
   lcp_resetci lcp_cilen lcp_addci lcp_ackci lcp_nakci lcp_rejci lcp_reqci
   lcp_up lcp_down lcp_finished lcp_protrej lcp_extcode
   [

\ Initialize LCP.
: lcp_init   ( -- )
   random to magic
   lcp-fsm
   PPP_LCP over >protocol !
   lcp-callbacks over >callbacks /fsm_callbacks move
   fsm_init
   
   lcp-want
   dup /lcp erase
   DEFMRU over >mru w!
   true over >neg_magicnumber c!
   true over >neg_pcompression c!
   true over >neg_accompression c!
   CHAP_DIGEST_MD5 over >chap_mdtype c!
   drop
   
   lcp-allow
   dup /lcp erase
   MAXMRU over >mru w!
   true over >neg_mru c!
   true over >neg_asyncmap c!
   \ false over >neg_chap c!
   true over >neg_chap c!
   true over >neg_upap c!
   true over >neg_magicnumber c!
   true over >neg_pcompression c!
   true over >neg_accompression c!
   CHAP_DIGEST_MD5 over >chap_mdtype c!
   drop
   
   xmit_accm 32 erase
   h# 60000000    xmit_accm 3 la+ !
;

\ Send a Protocol-Reject for some protocol.
: lcp_sprotrej   ( a n -- )
   \ Send back the protocol and the information field of the
   \ rejected packet.  We only get here if LCP is in the OPENED state.
   PROTREJ  lcp-fsm next-id  lcp-fsm  fsm_send
;

\ The lower layer is up.
: lcp_lowerup   ( -- )
   \ xmit_accm ppp_set_xaccm
   \ PPP_MRU h# ffffffff 0 0 ppp_send_config
   \ PPP_MRU h# 00000000 0 0 ppp_recv_config
   PPP_MRU to peer_mru
   xmit_accm @   lcp-allow >asyncmap !
   
   lcp-fsm  fsm_lowerup
;

\ The lower layer is down.
: lcp_lowerdown   ( -- )   lcp-fsm  fsm_lowerdown  ;

\ Input LCP packet.
: lcp_input   ( a n -- )
   lcp-state -rot		( oldstate a n )
   lcp-fsm fsm_input			( oldstate )
   REQSENT =  lcp-state ACKSENT =  and if
      \ The peer will probably send us an ack soon and then
      \ immediately start sending packets with the negotiated
      \ options.  So as to be ready when that happens, we set
      \ our receive side to accept packets as negotiated now.
      lcp-got >r
      r@ >neg_asyncmap c@ dup if
	 drop  r@ >asyncmap
      then
      r@ >neg_pcompression c@
      r> >neg_accompression c@
      PPP_MRU	ppp_recv_config		\ XXX arg order?
   then
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
