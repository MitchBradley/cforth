\ See license at end of file
purpose: PPP IP

\ incoming packets are saved in a single large buffer, each
\ preceded by a 16-bit count

defer get_input

inpacket_max 4 * constant /ipin_bufs
/ipin_bufs buffer: ipin_bufs
0 value ipin
: ipin-sane   ( -- )
   ipin ipin_bufs u< if  ipin_bufs to ipin  then
   ipin ipin_bufs /ipin_bufs + u> if
      ipin_bufs /ipin_bufs + to ipin
   then
;
: ip-any?   ( -- any? )   ipin ipin_bufs u>  ;
: iproom   ( -- n )   ipin_bufs /ipin_bufs + ipin -  ;
: $ipin-add   ( a n -- )
   iproom dup 2 > if		( a n room )
      2- min
      ipin over putw
      2dup + to ipin
      swap move
   else
      3drop
   then
;
: $ipin-del   ( -- )
   ipin_bufs getw dup 2+ >r +  ipin_bufs		( second first )
   ipin over - r@ -					( second first len )
   move  ipin r> - to ipin
;
: $ipin   ( -- a n )   ipin_bufs getw  ;
: ip_input   ( a n -- )
   ppp-is-open 0=  if  2drop exit  then
   ipin-sane
   $ipin-add
;
: read   ( a n -- actual )
   ipin-sane
   get_input
   ip-any? if
      2dup erase
      over d# 12 + h# 800 swap be-w!
      d# 14 /string
      ipin_bufs getw rot min
      >r swap r@ move
      $ipin-del
      r> d# 14 +
   else
      2drop -2
   then
\   dup 0> if   ." r" dup .  then
;
variable ipid
: nextid   ( -- n )
   1 ipid +!   ipid c@
;
: write   ( a n -- actual )
   d# 14 /string
   peer_mru HEADERLEN - umin >r				( a )
   PPP_IP outpacket_buf makeheader			( a b )
   r@ move
   outpacket_buf r@ PPP_HDRLEN + ppp-write drop
   r> d# 14 +
\   dup 0> if   ." w" dup .  then
;
: load  ( adr -- len )
   " obp-tftp" find-package  if      ( adr phandle )
      my-args  rot  open-package     ( adr ihandle|0 )
   else                              ( adr )
      0                              ( adr 0 )
   then                              ( adr ihandle|0 )

   dup  0=  if  ." Can't open obp-tftp support package" abort  then
                                     ( adr ihandle )

   >r
   " load" r@ $call-method           ( len )
   r> close-package
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
