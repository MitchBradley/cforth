\ See license at end of file
purpose: IPCP -- PPP IP Control Protocol

decimal

1	constant CI_ADDRS		\ IP Addresses
2	constant CI_COMPRESSTYPE	\ Compression Type
3	constant CI_ADDR

4	constant CILEN_COMPRESS		\ min length for compression protocol opt.
6	constant CILEN_VJ
6	constant CILEN_ADDR
10	constant CILEN_ADDRS

129	constant CI_MS_DNS1		\ Primary DNS value
131	constant CI_MS_DNS2		\ Secondary DNS value

16	constant MAX_STATES		\ from slcompress.h
h# 002d	constant IPCP_VJ_COMP		\ current value for VJ compression option
h# 0037	constant IPCP_VJ_COMP_OLD	\ obsolete value for VJ compression option 

\ IPCP options
struct
   4 field >ouraddr		\ Addresses in NETWORK BYTE ORDER
   4 field >hisaddr
   
   4 field >dnsaddr0
   4 field >dnsaddr1
   
   2 field >vj_protocol		\ protocol value to use in VJ option
   1 field >neg_addr 		\ Negotiate IP Address?
   1 field >old_addrs 		\ Use old (IP-Addresses) option?
   
   1 field >req_addr 		\ Ask peer to send IP address?
   1 field >neg_vj 		\ Van Jacobson Compression?
   1 field >old_vj 		\ use old (2 field) form of VJ option?
   1 field >accept_local 	\ accept peer's value for ouraddr
   
   1 field >accept_remote 	\ accept peer's value for hisaddr
   1 field >maxslotindex	\ values for RFC1332 VJ compression neg.
   1 field >cflag
   1 field >neg_dns 		\ Negotiate DNS Address?
constant /ipcp

/ipcp buffer: ipcp-want
/ipcp buffer: ipcp-allow
/ipcp buffer: ipcp-got
/ipcp buffer: ipcp-his
/ipcp buffer: ipcp-nope		\ options we've seen Naks for
/ipcp buffer: ipcp-try		\ options to request next time

0 value cis_received		\ # Conf-Reqs received

\ Frequently used phrases
: got-negaddr   ( -- negotiate? )   ipcp-got >neg_addr  c@  ;
: got-oldaddrs  ( -- oldaddrs? )    ipcp-got >old_addrs c@  ;
: got-negvj     ( -- negvj? )	    ipcp-got >neg_vj    c@  ;
: got-oldvj     ( -- oldvj? )	    ipcp-got >old_vj    c@  ;
: got-local     ( -- acc-local? )   ipcp-got >accept_local  c@  ;
: got-remote    ( -- acc-remote? )  ipcp-got >accept_remote c@  ;

: allow-negaddr   ( -- negotiate? )   ipcp-allow >neg_addr  c@  ;

: set-negaddr   ( opts -- )   true  swap >neg_addr c!  ;
: clr-negaddr   ( opts -- )   false swap >neg_addr c!  ;
: set-oldaddr   ( opts -- )   true  swap >old_addrs c!  ;
: clr-oldaddr   ( opts -- )   false swap >old_addrs c!  ;
: set-negvj     ( opts -- )   true  swap >neg_vj c!  ;
: clr-negvj     ( opts -- )   false swap >neg_vj c!  ;
: set-oldvj     ( opts -- )   true  swap >old_vj c!  ;
: clr-oldvj     ( opts -- )   false swap >old_vj c!  ;

: ciaddrlen   ( -- n )
   got-oldaddrs if  CILEN_ADDRS  else  CILEN_ADDR  then
;
: ciaddr      ( -- n )
   got-oldaddrs if  CI_ADDRS  else  CI_ADDR  then
;
: civjlen      ( -- n )
   got-oldvj if  CILEN_COMPRESS  else  CILEN_VJ  then
;


\ IP addresses

4 constant /i			\ Bytes per IP address
create unknown-ip-addr   h# 00 c,  h# 00 c,  h# 00 c,  h# 00 c,
: getip  ( a1 -- a2 'ip )  /i gets  ;
: putip  ( a1 'ip -- a2 )  /i puts  ;
: ip!  ( src dst -- )  /i move  ;
: ip=  ( ip-addr1  ip-addr2 -- flag  )   /i comp  0=  ;
: ip<> ( ip-addr1  ip-addr2 -- flag  )   ip= 0=  ;
: ip0=    ( adr-buf -- flag )  unknown-ip-addr  ip=   ;
: ip0<>   ( adr-buf -- flag )  unknown-ip-addr  ip<>  ;

: set-ouraddr   ( ipaddr config -- )   >ouraddr ip!  ;

\ print a network IP address.
: dec-byte  ( n -- )  u#s  ascii . hold  drop  ;
: .ip  ( buf -- )
   push-decimal                                                   ( buf )
   <#  dup /i + 1-  do  i c@ dec-byte  -1 +loop  0 u#>  1 /string ( adr len )
   pop-base
   type space
;

\ Input IPCP packet.
: ipcp_input   ( a n -- )   ipcp-fsm fsm_input  ;

\ A Protocol-Reject was received for IPCP.
\ Pretend the lower layer went down, so we shut up.
: ipcp_protrej   ( -- )   ipcp-fsm fsm_lowerdown  ;

\ Reset our CI.
: ipcp_resetci   ( -- )
   ipcp-want				( wo )
   dup >neg_addr c@  allow-negaddr  and
   over >req_addr c!
   dup >ouraddr ip0=  if
      true over >accept_local c!
   then
   dup >hisaddr ip0=  if
      true over >accept_remote c!
   then					( wo )
   ipcp-got /ipcp move
   
   0 to cis_received
;

\ Return length of our CI.
: ipcp_cilen   ( -- cilen )
   got-negaddr if  ciaddrlen  else  0  then
   got-negvj   if  civjlen  +  then
   ipcp-got >neg_dns c@ if  CILEN_ADDR +  then
;

\ Add our desired CIs to a packet.
: ipcp_addci   ( a n -- left-over )
   \ First see if we want to change our options to the old
   \ forms because we have received old forms from the peer.
   ipcp-want >neg_addr c@
   got-negaddr 0= and
   got-oldaddrs 0= and if
      \ use the old style of address negotiation
      ipcp-got set-negaddr
      ipcp-got set-oldaddr
   then
   ipcp-want >neg_vj c@
   got-negvj 0= and
   got-oldvj 0= and if
      \ try an older style of VJ negotiation
      cis_received if
	 \ use the old style only if the peer did
	 ipcp-his >neg_vj c@
	 ipcp-his >old_vj c@ and if
	    ipcp-got set-negvj
	    ipcp-got set-oldvj
	    ipcp-his >vj_protocol w@  ipcp-got >vj_protocol w!
	 then
      else
	 \ keep trying the new style until we see some CI from the peer
	 ipcp-got set-negvj
      then
   then						( a n )
   
   got-negaddr if
      ciaddrlen  2dup >= if			( a n addrlen )
	 rot					( n addrlen a )
	 ciaddr putc  over putc			( n addrlen a )
	 ipcp-got >ouraddr putip
	 got-oldaddrs if
	    ipcp-got >hisaddr putip
	 then
	 -rot  -				( a n )
      else					( a n addrlen )
	 drop
	 ipcp-got clr-negaddr
      then
   then						( a n )
    
   got-negvj if
      civjlen  2dup >= if			( a n vjlen )
	 rot					( n vjlen a )
	 CI_COMPRESSTYPE putc  over putc
	 ipcp-got >vj_protocol w@ putw
	 got-oldvj 0= if
	    ipcp-got >maxslotindex c@ putc
	    ipcp-got >cflag c@ putc
	 then
	 -rot  -				( a n )
      else
	 drop
	 ipcp-got clr-negvj
      then
   then						( a n )
   ipcp-got >neg_dns c@ if
      CILEN_ADDR 2dup >= if			( a n dnslen )
	 rot					( n dnslen a )
	 CI_MS_DNS1 putc  over putc		( n dnslen a )
	 ipcp-got >dnsaddr0 putip		( n dnslen a )
	 -rot  -				( a n )
      else
	 drop
	 false ipcp-got >neg_dns c!
      then
   then
   nip
;

: badack   ( -- false )
    \ ." ipcp_ackci got bad Ack!" cr
    false
;
\ Ack our CIs.
: ipcp_ackci   ( a n -- okay? )
   \ CIs must be in exactly the same order that we sent...
   \ Check packet length and CI length at each step.
   \ If we find any deviations, then this packet is bad.
   
   got-negaddr if
      ciaddrlen  dup >r  - dup 0< if
	 r> 3drop  badack exit
      then						( a n )
      
      swap getc  swap getc				( n citype a cilen )
      r> <>  rot ciaddr <> or if
	 2drop  badack exit
      then						( n a )
      
      getip  ipcp-got >ouraddr  ip<>  if		( n a )
	 2drop  badack exit
      then						( n a )
      
      got-oldaddrs if					( n a )
	 getip  ipcp-got >hisaddr  ip<>  if		( n a )
	    2drop  badack exit
	 then
      then
      swap						( a n )
   then
   
   got-negvj if
      civjlen  dup >r  - dup 0< if
	 r> 3drop  badack exit
      then
      
      swap getc  swap getc				( n citype a cilen )
      r> <>  rot CI_COMPRESSTYPE <> or if
	 2drop  badack exit
      then
      
      getw ipcp-got >vj_protocol w@ <> if
	 2drop  badack exit
      then
      
      got-oldvj 0= if
	 getc ipcp-got >maxslotindex c@ <> if
	    2drop  badack exit
	 then
	 
	 getc ipcp-got >cflag c@ <> if
	    2drop  badack exit
	 then
      then
      swap
   then							( a n )
   
   ipcp-got >neg_dns c@ if
      CILEN_ADDR  dup >r  - dup 0< if
	 r> 3drop  badack exit
      then						( a n )
      
      swap getc  swap getc				( n citype a cilen )
      r> <>  rot CI_MS_DNS1 <> or if
	 2drop  badack exit
      then						( n a )
      
      getip  ipcp-got >dnsaddr0  ip<>  if		( n a )
	 2drop  badack exit
      then
      swap						( a n )
   then
   
   \ If there are any remaining CIs, then this packet is bad.
   nip if
      badack exit
   then
   true
;

: badnak   ( -- false )
   \ ." ipcp_nakci got bad Nak!" cr
   false
;
\ Peer has sent a NAK for some of our CIs.
\ This should not modify any state if the Nak is bad
\ or if IPCP is in the OPENED state.
: ipcp_nakci   ( a n -- okay? )
   ipcp-nope /ipcp erase
   ipcp-got ipcp-try /ipcp move

   \ Any Nak'd CIs must be in exactly the same order that we sent.
   \ Check packet length and CI length at each step.
   \ If we find any deviations, then this packet is bad.
   
   \ Accept the peer's idea of {our,his} address, if different
   \ from our idea, only if the accept_{local,remote} flag is set.
   got-negaddr if
      ciaddrlen  >r					( a n)
      over 1+ c@  r@ =  over r@  >=  and  if		( a n)
	 over c@  ciaddr = if
	    r@ -
	    swap 2+ getip swap				( n 'cip1 a )
	    got-oldaddrs  if				( n 'cip1 a )
	       getip					( n 'cip1 a 'cip2 )
	       ipcp-nope set-oldaddr			( n 'cip1 a 'cip2 )
	    else					( n 'cip1 a )
	       unknown-ip-addr				( n 'cip1 a 'cip2 )
	    then					( n 'cip1 a 'cip2 )
	    ipcp-nope set-negaddr
	    rot dup ip0<>  got-local and  if			( n a '2 '1 )
	       \ We know our address
	       \ ." local IP address is " dup .ip cr
	       ipcp-try set-ouraddr				( n a 'cip2 )
	    else						( n a '2 '1 )
	       drop						( n a 'cip2 )
	    then						( n a 'cip2 )
	    dup ip0<>  got-remote and  if			( n a 'cip2 )
	       \ He knows his address
	       \ ." remote IP address is " dup .ip cr
	       ipcp-try >hisaddr ip!				( n a )
	    else						( n a 'cip2 )
	       drop						( n a )
	    then						( n a )
	    swap						( a n )
	 then							( a n )
      then							( a n )
      r> drop							( a n )
   then								( a n )
   
   \ Accept the peer's value of maxslotindex provided that it
   \ is less than what we asked for.  Turn off slot-ID compression
   \ if the peer wants.  Send old-style compress-type option if
   \ the peer wants.
   got-negvj if
      over 1+ c@ >r
      over c@ CI_COMPRESSTYPE =
      r@ CILEN_COMPRESS =  r@ CILEN_VJ = or  and		( a n flag )
      over r@ >= and if
	 ipcp-nope set-negvj
	 r@ -  swap 2+ getw					( n a cishort )
	 r@ CILEN_VJ = if
	    dup IPCP_VJ_COMP = if
	       drop						( n a )
	       ipcp-try clr-oldvj
	       getc swap getc			( n a cimaxslotindex cicflag )
	       0= if
		  false ipcp-try >cflag c!
	       then				( n a cimaxslotindex )
	       dup ipcp-got >maxslotindex c@ < if
		  ipcp-try >maxslotindex c!
	       else
		  drop  2+
		  ipcp-try clr-negvj
	       then
	    else						( n a cishort )
	       dup IPCP_VJ_COMP =  over IPCP_VJ_COMP_OLD = or if
		  ipcp-try set-oldvj
		  ipcp-try >vj_protocol w!
	       else
		  drop
		  ipcp-try clr-negvj
	       then
	    then
	 then
	 swap							( a n )
      then
      r> drop
   then								( a n )
   
   ipcp-got >neg_dns c@ if
      CILEN_ADDR  >r					( a n )
      over 1+ c@  r@ =  over r@  >=  and  if		( a n )
	 over c@  CI_MS_DNS1 = if
	    r@ -
	    swap 2+ getip swap				( n 'cip1 a )
	    swap dup ip0<>  if				( n a '1 )
	       ipcp-try >dnsaddr0 ip!				( n a )
	    else						( n a '1 )
	       drop						( n a )
	    then						( n a )
	    swap						( a n )
	 then							( a n )
      then							( a n )
      r> drop							( a n )
   then
   
   \ There may be remaining CIs, if the peer is requesting negotiation
   \ on an option that we didn't include in our request packet.
   \ If they want to negotiate about IP addresses, we comply.
   \ If they want us to ask for compression, we refuse.
   begin  dup CILEN_VOID >  while
      over >r  over c@ -rot   over 1+ c@ >r		( citype a n )  ( r: a cilen )
      r@ /string dup 0< if
	 2r> 5drop badnak exit
      then
      
      rot case
	 CI_COMPRESSTYPE of				( a n )
	    got-negvj  ipcp-nope >neg_vj c@  or
	    r@ CILEN_VJ <>  r@ CILEN_COMPRESS <> and  or if
	       2r> 4drop badnak exit
	    then
	    
	    ipcp-nope set-negvj
	 endof
	 CI_ADDRS of					( a n )
	    got-negaddr  got-oldaddrs and
	    ipcp-nope >old_addrs c@ or
	    r@ CILEN_ADDRS <> or if
	       2r> 4drop badnak exit
	    then
	    
	    ipcp-try set-negaddr
	    ipcp-try set-oldaddr
	    swap getip						( n a 'cip1 )
	    dup ip0<>  got-local and  if			( n a 'cip1 )
	       \ ." got local IP address " dup .ip cr
	       ipcp-try set-ouraddr
	    else
	       drop
	    then
	    getip						( n a 'cip2 )
	    dup ip0<>  got-remote and  if
	       ipcp-try >hisaddr ip!
	    else
	       drop
	    then
	    ipcp-nope set-oldaddr
	    swap
	 endof
	 CI_ADDR of					( a n )
	    got-negaddr  ipcp-nope >neg_addr c@ or  CILEN_ADDR r@ <> or if
	       2r> 4drop badnak exit
	    then
	    
	    ipcp-try clr-oldaddr
	    swap getip					( n a 'cip1 )
	    dup ip0<>  got-local and  if
	       \ ." received local IP address " dup .ip  cr
	       ipcp-try set-ouraddr
	    else
	       drop
	    then
	    swap
	    ipcp-try >ouraddr ip0<>  if
	       ipcp-try set-negaddr
	    then
	    ipcp-nope set-negaddr
	 endof
      endcase
      nip 2r> + swap					( a n )  ( r: )
   repeat
   
   \ If there is still anything left, this packet is bad.
   nip if   badnak exit  then

   \ OK, the Nak is good.  Now we can update state.
   ipcp-fsm >f_state c@ OPENED <> if
      ipcp-try ipcp-got /ipcp move
   then
   true
;

: badrej   ( -- false )
   \ ." ipcp_rejci got bad Reject!" cr
   false
;
\ Reject some of our CIs.
: ipcp_rejci   ( a n -- okay? )
   ipcp-got ipcp-try /ipcp move				( a n )

   \ Any Rejected CIs must be in exactly the same order that we sent.
   \ Check packet length and CI length at each step.
   \ If we find any deviations, then this packet is bad.
   got-negaddr if					( a n )
      ciaddrlen  >r
      swap getc  ciaddr =
      swap getc r@ = rot and				( n a flag )
      rot dup r@ >= rot and if				( a n )
	 r@ - swap getip				( n a 'ip )
	 \ Check rejected value.
	 ipcp-got >ouraddr ip<>  if			( n a )
	    r> 3drop badrej exit
	 then						( n a )
	 
	 got-oldaddrs if
	    getip					( n a 'ip )
	    \ Check rejected value.
	    ipcp-got >hisaddr ip<>  if
	       r> 3drop badrej exit
	    then					( n a )
	 then
	 
	 swap
	 ipcp-try clr-negaddr
      else
	 swap 2- swap
      then						( a n )
      r> drop
   then							( a n )
   
   got-negvj if						( a n )
      civjlen  >r
      over dup c@ CI_COMPRESSTYPE =  swap 1+ c@ r@ = and  over r@ >= and if
	 r> - swap 2+ getw				( n a cishort )
	 \ Check rejected value.  \
	 ipcp-got >vj_protocol w@ <> if
	    2drop badrej exit
	 then						( n a )
	 
	 got-oldvj 0= if
	    getc  ipcp-got >maxslotindex c@ <> if
	       2drop badrej exit
	    then
	    
	    getc  ipcp-got >cflag c@ <> if
	       2drop badrej exit
	    then
	 then
	 
	 swap						( a n )
	 ipcp-try clr-negvj
      else
	 r> drop
      then
   then							( a n )
   
   ipcp-got >neg_dns if					( a n )
      CILEN_ADDR  >r
      swap getc  CI_MS_DNS1 =
      swap getc r@ = rot and				( n a flag )
      rot dup r@ >= rot and if				( a n )
	 r@ - swap getip				( n a 'ip )
	 \ Check rejected value.
	 ipcp-got >dnsaddr0 ip<>  if			( n a )
	    r> 3drop badrej exit
	 then						( n a )
	 swap
	 false ipcp-try >neg_dns c!
      then						( a n )
      r> drop
   then							( a n )
   nip
   
   \ If there are any remaining CIs, then this packet is bad.
   if  badrej exit  then
   
   \ Now we can update state.
   ipcp-fsm >f_state c@ OPENED <> if
      ipcp-try ipcp-got /ipcp move
   then
   true
;
: ipcp-reqci-addrs   ( a cilen -- result )
   CILEN_ADDRS <>   allow-negaddr 0=  or if		( a )
      drop CONFREJ exit
   then							( a )

   \ If he has no address, or if we both have his address but
   \ disagree about it, then NAK it with our idea.
   \ In particular, if we don't know his address, but he does,
   \ then accept it.
   getip						( a 'cip )
   dup ipcp-want >hisaddr ip<>
   over ip0=  ipcp-want >accept_remote c@ 0=  or
   and if						( a 'cip1 )
      drop						( a )
      reject_if_disagree 0= if				( a )
	 ipcp-want >hisaddr   over /l -  ip!		( a )
      then
      drop CONFNAK exit
   then							( a 'cip1 )
   
   dup ip0=  ipcp-want >hisaddr ip0=  and if		( a 'cip1 )
      \ If neither we nor he knows his address, reject the option.
      2drop						( )
      false ipcp-want >req_addr c!
      CONFREJ exit
   then							( a 'cip1 )
   
   ipcp-his >hisaddr ip!				( a )
   \ If he doesn't know our address, or if we both have our 
   \ address but disagree about it, then NAK it with our idea.
   \ Parse desination address (ours)
   getip						( a 'cip2 )
   \ ." he says our address is "  dup .ip cr
   dup ipcp-his set-ouraddr				( a 'cip2 )
   dup ipcp-want >ouraddr ip<>  if			( a 'cip2 )
      dup ip0=  ipcp-want >accept_local c@ 0=  or  if	( a 'cip2 )
	 drop
	 reject_if_disagree 0=  if			( a )
	    ipcp-want >ouraddr  over /l -  ip!
	 then						( a )
	 drop CONFNAK					( result )
      else						( a 'cip2 )
	 \ ." accept peer's idea " cr
	 ipcp-got set-ouraddr				( a )
	 drop CONFACK
      then						( result )
   else							( a 'cip2 )
      2drop CONFACK
   then							( result )
   ipcp-his set-negaddr
   ipcp-his set-oldaddr
;
: ipcp-reqci-addr   ( a cilen -- result )
   CILEN_ADDR <>   allow-negaddr 0=  or if		( a )
      drop CONFREJ exit
   then							( a )
   
   \ If he has no address, or if we both have his address but
   \ disagree about it, then NAK it with our idea.
   \ In particular, if we don't know his address, but he does,
   \ then accept it.
   getip						( a 'cip1 )
   dup ipcp-want >hisaddr ip<>
   over ip0=  ipcp-want >accept_remote c@ 0=  or
   and if						( a 'cip1 )
      drop						( a )
      reject_if_disagree 0= if
	 ipcp-want >hisaddr  over /l -  ip!
      then
      drop CONFNAK exit
   then							( a 'cip1 )
   
   dup ip0=  ipcp-want >hisaddr ip0=  and  if		( a 'cip1 )
      \ If neither we nor he knows his address, reject the option.
      2drop						( )
      false ipcp-want >req_addr c!
      CONFREJ
   else						( a 'cip1 )
      ipcp-his >hisaddr ip!				( a )
      ipcp-his set-negaddr				( a )
      drop CONFACK
   then
;
: ipcp-reqci-comp   ( a cilen -- result )
   dup CILEN_VJ <>  over CILEN_COMPRESS <> and
   ipcp-allow >neg_vj c@ 0=  or if			( a cilen )
      2drop CONFREJ exit
   then							( a cilen )
   
   swap getw						( cilen a cishort )
   2 pick CILEN_COMPRESS =  over IPCP_VJ_COMP_OLD = and
   over IPCP_VJ_COMP = or 0= if				( cilen a cishort )
      3drop CONFREJ exit				( result )
   then							( cilen a cishort )
   
   ipcp-his set-negvj
   ipcp-his >vj_protocol w!				( cilen a )
   swap CILEN_VJ = if					( a )
      getc						( a maxslotindex )
      dup ipcp-his >maxslotindex c!
      ipcp-allow >maxslotindex c@ > if			( a )
	 reject_if_disagree 0= if
	    ipcp-allow >maxslotindex c@ over 1- c!
	 then
	 CONFNAK
      else						( a )
	 CONFACK
      then						( a result )
      swap getc						( result a cflag )
      dup ipcp-his >cflag c!
      ipcp-allow >cflag c@ 0= and if			( result a )
	 nip CONFNAK swap
	 reject_if_disagree 0= if
	    ipcp-want >cflag c@  over 1- c!
	 then
      then						( result a )
      drop
   else							( a )
      ipcp-his set-oldvj
      1 ipcp-his >cflag c!
      MAX_STATES 1- ipcp-his >maxslotindex c!
      drop CONFACK
   then
;
: ipcp-reqci-dns1   ( a cilen -- result )
   \ If we do not have a DNS address then we cannot send it
   CILEN_ADDR <>  ipcp-want >dnsaddr0 ip0=  or if	( a )
      drop CONFREJ
   else							( a )
      dup ipcp-want >dnsaddr0  ip= if			( a )
	 drop CONFACK
      else						( a )
	 ipcp-want >dnsaddr0 swap ip!			( )
	 CONFNAK
      then
   then
;
: ipcp-reqci-dns2   ( a cilen -- result )
   \ If we do not have a DNS address then we cannot send it
   CILEN_ADDR <>  ipcp-want >dnsaddr0 ip0=  or if	( a )
      drop CONFREJ
   else							( a )
      dup ipcp-want >dnsaddr1  ip= if			( a )
	 drop CONFACK
      else
	 ipcp-want >dnsaddr1 swap ip!			( )
	 CONFNAK
      then
   then
;
: ipcp-reqci-sw   ( a cilen citype -- result )
   case
      CI_ADDRS of						( a cilen )
	 ipcp-reqci-addrs					( result )
      endof
      CI_ADDR of						( a cilen )
	 ipcp-reqci-addr					( result )
      endof
      CI_COMPRESSTYPE of					( a cilen )
	 ipcp-reqci-comp					( result )
      endof
      CI_MS_DNS1 of	\ Microsoft DNS				( a cilen )
	 ipcp-reqci-dns1
      endof
      CI_MS_DNS2 of						( a cilen )
	 ipcp-reqci-dns2
      endof
      ( default )
      >r							( a cilen )
      \ ." ipcp_reqci got unknown option " r@ . cr
      2drop CONFREJ
      r>
   endcase							( a result )
;
0 value ucp
: ipcp-reqci-status   ( a n next status result -- a n next result )
   >r
   dup CONFACK = r@ CONFACK <> and 0= if			( a n next status )
      dup CONFNAK = reject_if_disagree 0= and r@ CONFREJ = and 0= if
	 dup CONFNAK = if
	    reject_if_disagree if
	       drop CONFREJ
	    else						( a n next status )
	       r@ CONFACK = if
		  r> drop CONFNAK >r
		  3 pick to ucp		\ backup \ XXX should this be r@ to ucp ???
	       then
	    then
	 then							( a n next status )
	 dup CONFREJ =  r@ CONFREJ <>  and if			( a n next status )
	    r> drop CONFREJ >r
	    3 pick to ucp		\ backup
	 then							( a n next status )
	 ucp cip <> if
	    cip ucp over 1+ c@ move
	 then
	 cip 1+ c@ ucp + to ucp
      then
   then								( a n next status )
   drop r>
;
: ipcp-reqci-finish   ( a result -- n okay? )
   \ If we aren't rejecting this packet, and we want to negotiate
   \ their address, and they didn't send their address, then we
   \ send a NAK with a CI_ADDR option appended.  We assume the
   \ input buffer is long enough that we can append the extra
   \ option safely.
   >r
   r@ CONFREJ <> ipcp-his >neg_addr c@ 0= and
   ipcp-want >req_addr c@ and  reject_if_disagree 0= and if
      r@ CONFACK = if
	 r> drop CONFNAK >r
	 dup to ucp			\ reset pointer
	 false ipcp-want >req_addr c!	\ don't ask again
      then
      ucp CI_ADDR putc  CILEN_ADDR putc   ipcp-want >hisaddr putip
      to ucp
   then
   ucp swap -			\ Compute output length
   r>				\ Return final code
;
\ Check the peer's requested CIs and send appropriate response.
\ Returns of CONFACK, CONFNAK or CONFREJ and input packet modified
\ appropriately.  If reject_if_disagree is non-zero, doesn't return
\ CONFNAK; returns CONFREJ if it can't return CONFACK.
: ipcp_reqci   ( a n1 reject_if_disagree -- n2 okay? )
   to reject_if_disagree
   over to ucp
   CONFACK >r				\ Final packet return code
   
   \ Reset all his options.
   ipcp-his /ipcp erase

   \ Process all his options.
   over						( a n next )
   begin  over  while				( a n next )
      dup to cip
      2dup 1+ c@ 2 rot between 0=		( a n next bad? )
      2 pick 2 < or if			\ Reject till end of packet
	 \ ." ipcp_reqci got bad CI length! " cr	( a n next )
	 nip 0 swap			\ Don't loop again
	 CONFREJ				( a n next status )
      else					( a n next )
	 dup >r
	 tuck 1+ c@ /string swap		( a n next' )
	 r> getc swap getc rot			( a n next' next cilen citype )
	 ipcp-reqci-sw				( a n next' status )
      then
      r> ipcp-reqci-status >r			( a n next' )
   repeat					( a n next )
   2drop					( a )
   r> ipcp-reqci-finish
;

\ IPCP has come UP.
\ Configure the IP network interface appropriately and bring it up.
: ipcp_up   ( -- )
   show-states? if  cr  then
   
   \ We must have a non-zero IP address for both ends of the link.
   ipcp-his >neg_addr c@ 0= if
      ipcp-want >hisaddr  ipcp-his >hisaddr  ip!
   then
   ipcp-his >hisaddr ip0=  if
      ." Could not determine remote IP address" cr
      ipcp-fsm fsm_close
      exit
   then
   
   ipcp-got >ouraddr ip0= if
      ." Could not determine local IP address" cr
      ipcp-fsm fsm_close
      exit
   then
   
\   ." local  IP address " ipcp-got >ouraddr .ip cr
\   ." remote IP address " ipcp-his >hisaddr .ip cr
   true to ppp-is-open
;


\ IPCP has gone DOWN.
\ Take the IP network interface down, clear its addresses
\ and delete routes through it.
: ipcp_down      ( -- )   false to ppp-is-open  ;

: ipcp_extcode   ( a n code id -- handled? )   4drop false  ;

create ipcp-callbacks
   ]
   ipcp_resetci ipcp_cilen ipcp_addci ipcp_ackci ipcp_nakci ipcp_rejci ipcp_reqci
   ipcp_up ipcp_down noop ipcp_protrej ipcp_extcode
   [

\ Initialize IPCP.
: ipcp_init   ( -- )
   ipcp-fsm
   PPP_IPCP over >protocol !
   ipcp-callbacks over >callbacks /fsm_callbacks move
   fsm_init

   ipcp-want /ipcp erase
   ipcp-want set-negaddr
   true ipcp-want >neg_dns c!
   \ ipcp-want
   \ dup set-negvj
   \ IPCP_VJ_COMP over >vj_protocol w!
   \ MAX_STATES 1- over >maxslotindex c!
   \ 1 over >cflag c!
   \ drop
   
   \ max slots and slot-id compression are currently hardwired to 16 and 1
   ipcp-allow /ipcp erase
   ipcp-allow set-negaddr
   true ipcp-allow >neg_dns c!
   \ ipcp-allow
   \ dup set-negvj
   \ MAX_STATES 1- over >maxslotindex c!
   \ 1 over >cflag c!
   \ drop
;

external
: point-to-point?  ( -- 'his-ip 'my-ip true )
   ipcp-his >hisaddr  ipcp-got >ouraddr  true
;
[ifdef] use-auto-dns
: dns-servers   ( -- false | 'dns-ip1 'dns-ip0 true )
   ipcp-got >dnsaddr0 ip0= if
      ipcp-got >dnsaddr1 ip0= if   false exit   then
      
      unknown-ip-addr ipcp-got >dnsaddr1 true exit
   then
   
   ipcp-got >dnsaddr1 ip0= if
      unknown-ip-addr
   else
      ipcp-got >dnsaddr1
   then
   ipcp-got >dnsaddr0 true
;
[else]
: ?bad-ip  ( flag -- )  abort" Bad host name or address"  ;
: $>ip  ( adr len buf -- )
   push-decimal
   4  bounds  do
      [char] . left-parse-string  $number ?bad-ip
      dup  d# 256 >=  ?bad-ip
      i c!
   loop
   pop-base
   2drop
;

: ip-or-unknown  ( name$ buf -- 'ip )
   >r $ppp-info  dup 0=  if       ( name$ r: buf )
      r> 3drop  unknown-ip-addr   ( 'ip )
   else                           ( name$ r: buf )
      r@ $>ip  r>                 ( 'ip )
   then
;
8 buffer: ip-buf
: dns-servers  ( -- 'dns-ip1 'dns-ip0 true )
   " dns-server1" ip-buf 4 + ip-or-unknown
   " dns-server0" ip-buf     ip-or-unknown
   dup ip0=  if  swap  then
   dup ip0=  if  2drop false  else  true  then 
;
[then]
: domain-name  ( -- name$ )  " domain-name" $ppp-info  ;

headers
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
