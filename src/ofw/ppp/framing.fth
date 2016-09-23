\ See license at end of file
purpose: PPP Framing

hex

0 value read-xt
[ifdef] testing
0 value ih-com
: open-com  ( -- error? )
   " com2:38400" open-dev to ih-com
   ih-com 0=
;

\ restore the terminal device and close it.
: close-com   ( -- )
   " close" ih-com $call-method
   -1 to ih-com 
;
\ : tty-read   ( a n -- actual )   " read" ih-com $call-method  ;
: tty-read   ( a n -- actual )   read-xt ih-com call-package  ;
: tty-write  ( a n -- actual )   " write" ih-com $call-method  ;

[else]
: open-com  ( -- false )  false  ;
: close-com  ( -- )  ;
\ : tty-read   ( a n -- actual )   " read"  $call-parent  ;
: tty-read   ( a n -- actual )   read-xt my-parent call-package  ;
: tty-write  ( a n -- actual )   " write" $call-parent  ;
[then]

\ Async-Control-Character-Maps
create rACCM  -1 ,
create tACCM  -1 ,  ( -1 , -1 , -1 , -1 , -1 , -1 , -1 , )

: bit@   ( n a -- bit )
   \ swap 20 /mod  rot +	\ uncomment this line for long tACCM
   @  1 rot lshift and
;

PPP_MRU 10 + 2* buffer: encode-buf
0 value encode-ptr
: +encode   ( c -- )
   encode-ptr c!   1 encode-ptr + to encode-ptr
;
: encode?   ( c -- encode? )
   dup 7d 7e between
   swap dup 20 < if  tACCM bit@ or  else drop then
;
: encoder   ( a1 n1 -- a2 n2 )
   encode-buf to encode-ptr
   7e +encode
   PPP_MRU min bounds ?do
      i c@ dup encode? if
	 7d +encode  20 xor
      then
      +encode
   loop
   7e +encode
   encode-buf encode-ptr over -
;
: add-fcs   ( a n1 -- a n2 )
   2dup fcs ffff xor  >r  2dup + r> swap le-w!  2+
;

PPP_MRU 10 + 2* buffer: outbuf
: ppp-write   ( a n -- actual )
   PPP_MRU min  over >r  4 /string  r>  be-l@ lwsplit  outbuf swap	( a n proto out ac )
   comp_ac if  drop  else  putw  then  swap			( a n out proto )
   dup h# ff00 and 0= comp_proto and if  putc  else  putw  then	( a n out )
   2dup + >r
   swap move
   outbuf r> over -  
   show-packets? if  ." S " dup 3 u.r  ." : " 2dup cdump cr  then  ( a n )
   add-fcs encoder tty-write
;


PPP_MRU d# 10 +  constant /inbuf
/inbuf  buffer: inbuf
0 value inptr
0 value current-fcs
false value escaping?
false value resyncing?
false value framed?

: (init-framer)  ( -- )
   0 to inptr
   false to framed?
   false to escaping?
   false to resyncing?
   h# ffff to current-fcs
;
: init-framer  ( -- )
   " read" my-parent ihandle>phandle find-method  if  to read-xt  then
   (init-framer) 
;

: +inbuf   ( byte -- )
   inptr /inbuf =  if    \ Packet too long; we must have lost a framing byte
      drop
      (init-framer)  true to resyncing?
      exit
   then
   dup  current-fcs update-fcs to current-fcs
   inbuf inptr + c!   1 inptr + to inptr
;
: 1decode   ( byte -- )
   resyncing?  if
      h# 7e =  if  false to resyncing?  then
      exit
   then

   dup h# 7e =  if
      drop  true to framed?  exit
   then

   escaping?  if
      h# 20 xor +inbuf  false to escaping?  exit
   then

   dup h# 7d = if
      drop  true to escaping?  exit
   then

   dup h# 20 <  if
      dup rACCM bit@  if  drop  else  +inbuf  then    exit
   then

   +inbuf
;

: packet-okay?  ( -- false | adr len true )
   inbuf  inptr  current-fcs				( adr len fcs )
   (init-framer)					( adr len fcs )
   
   \ Silently discard empty frames
   over 0=  if  3drop false exit  then			( adr len fcs )

   \ Discard frames with bad FCS
   \ We need to figure out some way to report this up to the IP layer
   \ for the benefit of the VJ header compression code, which needs to
   \ know when link errors occur.
   PPP_GOODFCS  <>  if					( adr len )
      \ ." FCS "
      2drop false exit
   then							( adr len )

   2-          \ Lose the FCS				( adr len )

   \ Discard too-short frames
   \ We should report these errors too
   dup 4 <  if						( adr len )
      ." RUNT "
      2drop false exit
   then							( adr len )

   \ Remove the address (0xff) and control (0x03) bytes, if any, from
   \ the start of the frame
   over " "(ff 03)" comp  0=  if			( adr len )
      2 /string						( adr' len' )
   then							( adr len )

   true							( adr len true )
;

variable the-byte
: poll-packet   ( -- hangup? false | adr len true )
   begin  the-byte 1 tty-read  dup 0>  while  ( 1 )
      drop
      the-byte c@ 1decode
      framed?  if  packet-okay?  if
         show-packets? if   ." R " dup 3 u.r  ." : "  2dup cdump cr  then
         true exit
      then  then
   repeat                                     ( read-result )

   \ Return hangup?=true when the line drops
   -1 =  if  true false exit  then            ( )

   \ Return hangup?=false while we are still polling
   false false
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
