\ See license at end of file
purpose: Load PPP

fload ${BP}/ofw/ppp/const.fth
fload ${BP}/ofw/ppp/vars.fth
fload ${BP}/ofw/ppp/utility.fth

fload ${BP}/ofw/ppp/fcs.fth
fload ${BP}/ofw/ppp/framing.fth

fload ${BP}/ofw/ppp/timeout.fth

fload ${BP}/ofw/ppp/fsm.fth
fload ${BP}/ofw/ppp/ipcp.fth
\ fload ${BP}/ofw/ppp/ccp.fth

fload ${BP}/ofw/ppp/auth.fth
fload ${BP}/ofw/ppp/upap.fth
fload ${BP}/ofw/ppp/chap.fth
fload ${BP}/ofw/ppp/lcp.fth

fload ${BP}/ofw/ppp/ip.fth
fload ${BP}/ofw/ppp/main.fth
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
