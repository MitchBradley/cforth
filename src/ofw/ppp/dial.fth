\ See license at end of file
purpose: Modem dialer package

false value debug-dial?
false instance value echo?

\ Z3 - reset to factory default profile 0
\ E0 - no echo
\ V0 - numeric result codes
\ X0 - small set of result codes
\ L1 - speaker volume low
\ M1 - speaker on until CONNECT

\ ATZ3
\ ATE0V0X0L1

\ Result codes for X0:
\ 0 OK
\ 1 CONNECT
\ 2 RING
\ 3 NO CARRIER
\ 4 ERROR

\needs select$ fload ${BP}/forth/lib/selstr.fth

0 0 2value modem$
0 0 2value phone#

\ : xyzel  ( -- )  " |ATZ|ATE1X0L1M2DT|+++|ATH"  ;

\ : ms  ( #ms -- ) dup 5 > if ." Delay " dup .d ." Milliseconds" cr  then ms ;

: choose$  ( default$ field$ field# -- $ )
   modem$  dup  if                      ( default$ field$ field# modem$ )
      select$ 2swap 2drop 2swap 2drop   ( $ )
   else                                 ( default$ field$ field# modem$ )
      3drop                             ( default$ field$ )
      $ppp-info                         ( default$ ppp-info$ )
      dup  if  2swap  then  2drop       ( $ )
   then
;
: init$       ( -- $ )  " ATZ"  " modem-init$"      0 choose$  ;
: dial$       ( -- $ )  " ATDT" " modem-dial$"      1 choose$  ;
: interrupt$  ( -- $ )  " +++"  " modem-interrupt$" 2 choose$  ;
: hangup$     ( -- $ )  " ATH"  " modem-hangup$"    3 choose$  ;

: rts-dtr-off    ( -- )  " rts-dtr-off"   $call-parent  ;
: rts-dtr-on     ( -- )  " rts-dtr-on"    $call-parent  ;
: use-irqs       ( -- )  " use-irqs"      $call-parent  ;
: use-polling    ( -- )  " use-polling"   $call-parent  ;
: install-abort  ( -- )  " install-abort" $call-parent  ;
: remove-abort   ( -- )  " remove-abort"  $call-parent  ;

: read   ( adr len -- actual )  " read"   $call-parent  ;
: write  ( adr len -- actual )  " write"  $call-parent  ;

: reset-delay  ( -- #ms )
   " reset-delay" my-parent ihandle>phandle    ( name$ phandle )
   get-package-property  if  d# 1000  else  get-encoded-int  then
;

d# 61 buffer: dial-cmd$
: +prefix  ( $1 prefix$ -- $2 )
   2 pick  over  >=  if                    ( $1 prefix$ )
      \ The string is long enough to contain the prefix
      2over 2over rot drop                ( $1 prefix$ adr1 prefix$ )

      \ If the string already begins with the prefix, don't modify it
      caps-comp 0=  if  2drop exit  then      
   then

   \ Concatenate the prefix and the string
   dial-cmd$ pack                     ( $1 adr )
   $cat  dial-cmd$ count  2dup upper  ( $2 )
;

1 buffer: ch

0 instance value timeout
: set-timeout  ( #msecs -- )  get-msecs + to timeout  ;

: getchar  ( -- char )
   begin
      get-msecs timeout - 0>  throw
      ch 1  read
   1 =  until
   ch c@
   echo?  if  dup emit  ( dup carret =  if  linefeed emit  then )  then
;

: timed-read  ( timeout-msecs -- char )
   dup 0< throw               ( timeout-msecs )
   set-timeout getchar
;

: eat  ( -- )  begin  5 ['] timed-read catch nip  until  ;

\ The character does not extend the current match, so we must adjust
\ the number matched.  For example, if the pattern string is "ininx"
\ and we have already matched "inin", but the next character is "i"
\ instead of "x", we go back to the state where we have matched "ini".
: resync  ( pattern$ #matched char -- adr len #matched' )
   >r  2 pick swap                       ( pattern$ adr n r: char )
   begin  dup  while                     ( pattern$ adr n r: char )
      1 /string                          ( pattern$ adr' n' r: char )
      2over 2over 2swap substring?  if   ( pattern$ adr' n' r: char )
         3 pick over + c@  r@  =  if     ( pattern$ adr' n' r: char )
            1+ nip r> drop  exit         ( pattern$ n' )
         then                            ( pattern$ adr' n' r: char )
      then                               ( pattern$ adr' n' r: char )
   repeat                                ( pattern$ adr' 0 r: char )
   2drop                                 ( pattern$ r: char )
   over c@  r>  =  if  1  else  0  then  ( pattern$ #matched' )
;
: expect  ( pattern$ timeout -- )
   set-timeout   0                             ( pattern$ #matched )
   \ Exit the loop when the entire string has been matched
   begin   2dup <>  while                      ( pattern$ #matched )
      2 pick over + c@  getchar                ( pattern$ #matched pchar char )

      \ The input character extends the match or causes a resync
      tuck =  if  drop 1+  else  resync  then  ( pattern$ #matched' )
   repeat                                      ( pattern$ #matched )
   3drop
;
: expect?  ( pattern$ timeout-ms -- timeout? )
   ['] expect catch  dup  if  nip nip nip  then
;

: send-char-echo  ( adr -- )
   dup 1 write drop               ( adr )
   begin                          ( adr )
      1 ['] timed-read catch  if  ( adr x )
         drop true                ( adr flag )
      else                        ( adr char )
         over c@ =                ( adr flag )
      then                        ( adr flag )
   until                          ( adr )
   drop
;

\ This version is used for the "+++" interrupt string, which has
\ some weird timing requirements
: (send)  ( $ -- )  bounds  ?do  i 1 write drop  d# 100 ms  loop  ;

: send  ( $ -- )  bounds  ?do  i 1 write drop  loop  " "r" write drop  ;

: wait-ok  ( #msecs -- timeout? )  " OK"r"n" rot expect?  ;
: interrupt-modem  ( -- timeout? )
   d# 1500 ms  interrupt$ (send)  d# 2000 wait-ok
;
: sw-hangup  ( -- )
   interrupt-modem  0=  if
      hangup$ send  d# 1000 wait-ok drop
   then
   rts-dtr-off		\ Hangup in a hardware way too
   d# 4000 ms		\ Give the other end time to see the hangup
;
: handshake  ( -- error? )
   init$ send  d# 5000  wait-ok  if
      interrupt-modem  if  true exit  then
      init$ send  d# 5000  wait-ok  if  true exit  then 
   then
   reset-delay ms	\ DIVA ISDN
   false
;
: hangup  ( -- )  sw-hangup  ;

d# 80 instance buffer: linebuf
: +byte  ( char -- )
   linebuf c@  d# 79 >=  if  drop exit  then  ( char )
   linebuf count + c!  linebuf c@ 1+ linebuf c!
;
: (get-line)  ( timeout -- )
   set-timeout
   0 linebuf c!
   begin
      getchar  case
         carret    of  exit  endof
         linefeed  of        endof
         ( default )  dup +byte
      endcase
   again
;

: get-line  ( timeout -- true | adr len false )
   ['] (get-line) catch  if  drop true exit  then
   linebuf count false
;

: run-login-script  ( -- )
   6 1  do
      i <# u# " expect$" hold$ u#>  $ppp-info         ( expect$ )
      dup  if  d# 20,000  expect  else  2drop  then   ( )

      i <# u# " send$" hold$ u#>  $ppp-info           ( send$ )
      dup  if  send  else  2drop  then                ( )
   loop
;

: login?  ( -- okay? )
   " script" $ppp-info          ( adr len )
   2dup  " Use Terminal Window" $=  if  2drop  itip  true exit  then
   " Run Login Script" $=  if  ['] run-login-script catch 0= exit  then
   true
;

: open  ( -- okay? )
   debug-dial?  if  true to echo?  then
   use-irqs

   my-args  [char] | split-string  to modem$  to phone#  ( )

   handshake  if
      ." Can't initialize modem" cr
      false exit
   then

   phone# dup  0=  if  2drop  " phone#" $ppp-info  then   ( phone#$ )

   dial$ +prefix send

   \ Eat the echoed dial command line
   d# 1000 get-line  if  false exit  then      ( adr len )
   2drop                                       ( )

   \ Instead of using expect, we get a line, so we can recognize
   \ errors (BUSY, etc) quickly, instead of waiting for a timeout.

   \ Wait for a response (CONNECT, BUSY, etc)
   d# 120,000 get-line  if  false exit  then   ( adr len )

   \ If the line is empty, it's an extra carriage return;
   \ get the next one.
   dup  0=  if
      2drop  d# 1000 get-line  if  false exit  then
   then

   " "n" d# 200 expect? drop		       ( adr len )  \ Eat the linefeed

   \ If not CONNECT, the result could be BUSY, NO DIALTONE, ERROR, etc
   " CONNECT" 2swap substring?  0=  if  false exit  then

   login?		( okay? )

   false to echo?
;
: close  ( -- )  debug-dial?  if  true to echo?  then  hangup  ;
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
