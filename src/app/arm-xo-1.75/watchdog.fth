\ See license at end of file
purpose: System reset using the watchdog timer

main-pmu-pa h# 200 + constant wdtpcr
: enable-wdt-clock
   main-pmu-pa h# 1020 +  dup io@  h# 10 or  swap io!  \ enable wdt 2 clock  PMUM_PRR_PJ
   wdtpcr io@  dup  h# 7 or wdtpcr io!  h# 3 or wdtpcr io!
;

h# 080000 value wdt-pa
: (wdt!)  ( value offset -- )  wdt-pa +  io!  ;
: wdt!  ( value offset -- )
   h# baba h# 9c (wdt!)   h# eb10 h# a0 (wdt!)  ( value offset )
   (wdt!)
;
: wdt@  ( offset -- value )  wdt-pa +  io@  ;
: wdt-reset  ( -- )
   enable-wdt-clock
   2 h# 68 wdt!   \ set match register
   3 h# 64 wdt!   \ match enable: enable counting, enable reset
   1 h# 98 wdt!   \ Reset counter
   begin  again
;

0 [if]
: test-wdt  ( -- )
   enable-wdt-clock
   h# 100  h# 68  wdt!  \ set match register
   1 h# 64 wdt!         \ match enable: enable counting, no reset yet
   h# 6c wdt@ .  d# 100 ms  h# 6c wdt@ .
;
[then]

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
