\ See license at end of file
purpose: Point-to-Point Protocol main module

: init_vars   ( -- )
   0 to comp_ac
   0 to comp_proto
   0 to auth_pending
   0 to read-xt
   0 to ipin
   false to looped_back
   random to magic
;

: handle_input   ( a n protocol -- )
   case
      PPP_LCP    of  lcp_input      endof
      PPP_IPCP   of  ipcp_input	    endof
      PPP_PAP    of  upap_input	    endof
      PPP_CHAP   of  chap_input	    endof
      \ PPP_CCP  of  ccp_input	    endof
      \ PPP_CCPD of  ccp_datainput  endof
      PPP_IP     of  ip_input       endof
      ( default )
      >r
      -2 /string  lcp_sprotrej
      r>
   endcase
;
\ called when incoming data is available.
: (get_input)   ( -- )
   calltimeout				( )
   poll-packet  0=  if                  ( hangup? )
      if                                ( )
         ." Modem hangup" cr
         true to hungup
         lcp_lowerdown		\ serial link is no longer available
         link_terminated
      then
      exit
   then                                 ( a n )

   phase 4 =  if		\ 4 is PHASE_TERMINATE
      2drop
      lcp_lowerdown		\ serial link is no longer available
      link_terminated
      exit
   then
   
   dup PPP_HDRLEN < if   2drop  exit   then			( a n )
   
   \ check length of protocol field
   over c@ 1 and if
      1 /string over 1- c@
   else
      2 /string over 2- be-w@
   then								( a n protocol )
   
   \ Toss all non-LCP packets unless LCP is OPEN.
   dup PPP_LCP <> lcp-state OPENED <> 
   and if   3drop  exit  then					( a n protocol )

   handle_input
;
' (get_input) to get_input

: close   ( -- )
   clear-timeouts
   lcp_close
   close-com
   false to ppp-is-open
;

: open   ( -- okay? )
   init_vars
   0 to hungup
   0 to ppp-is-open
   init-framer

   \ Initialize
   lcp_init
   ipcp_init
   upap_init
   chap_init
   \ ccp_init
  
   \ Open the serial device
   open-com if   false exit   then
   
   lcp_lowerup
   lcp_open			\ Start protocol
   1 to phase			\ 1 is PHASE_ESTABLISH
   get-msecs d# 60000 +
   begin
      get-msecs over - 0<
   while
      phase 0=  hungup or  if	\ 0 is PHASE_DEAD
	 close
	 leave
      then
      get_input 
      ppp-is-open 
   until then             ( time-limit )
   drop
   ppp-is-open dup if
      d# 200 ms
   then
;

h# 80 buffer: tips
: tip  ( -- )
   begin
      key?  if
         key  dup 3 =  if  drop exit  then
         tips c!  tips 1 tty-write drop
      then
      tips h# 80 tty-read  dup 0> if
	 tips swap type
      else
	 drop
      then
   again
;
0 " #address-bits" integer-property
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
