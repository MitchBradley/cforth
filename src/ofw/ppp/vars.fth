\ See license at end of file
purpose:  Variables

decimal

false value show-states?
\ true     to show-states?

false value show-packets?
\ true     to show-packets?

\ Global variables.
0 value	phase		\ Current state of link - see values below
1500 value peer_mru	\ currently negotiated peer MRU (per unit)

\ Flags
0 value comp_ac
0 value comp_proto
0 value ppp-is-open
0 value hungup		\ Physical layer has disconnected

\ Buffers 
PPP_MRU PPP_HDRLEN + constant inpacket_max
inpacket_max buffer: inpacket_buf	\ buffer for incoming packet
inpacket_max buffer: outpacket_buf	\ buffer for outgoing packet

0 value cip			\ thumb
0 value reject_if_disagree
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
