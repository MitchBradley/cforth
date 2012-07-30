\ See license at end of file
\ purpose: Host to EC SPI protocol - subset that just does EC commands - no upstream, no FLASH programming

\ See http://wiki.laptop.org/go/XO_1.75_HOST_to_EC_Protocol

\ Channel#(port#) Meaning
\ 0              Invalid
\ 1              Switch to Command Mode
\ 2              Command response
\ 3              Keyboard
\ 4              Touchpad
\ 5              Event
\ 6              EC Debug

-1 value ec-byte
: enque  ( data channel# -- )  2 =  if  to ec-byte  then  ;
: deque?  ( channel# -- false | data true )
   2 <>  if  false exit  then           ( )
   ec-byte -1 =  if  false exit  then  ( )
   ec-byte true  -1 to ec-byte   ( data true )
;
: init-queues  ( -- )  -1 to ec-byte  ;

h# 037000 value ssp-base  \ Default to SSP3
: ssp-sscr0  ( -- adr )  ssp-base  ;
: ssp-sscr1  ( -- adr )  ssp-base  4 +  ;
: ssp-sssr   ( -- adr )  ssp-base  8 +  ;
: ssp-ssdr   ( -- adr )  ssp-base  h# 10 +  ;

: ssp3-clk-on  7 h# 015058 io!   3 h# 015058 io!  ;

\ Wait until the CSS (Clock Synchronization Status) bit is 0
: wait-clk-sync  ( -- )
   begin  ssp-sssr io@ h# 400.0000 and  0=  until
;

: init-ssp-in-slave-mode  ( -- )
   ssp3-clk-on
   h# 07 ssp-sscr0 io!   \ 8-bit data, SPI normal mode
   h# 1300.0010 ssp-sscr1 io!  \ SCFR=1, slave mode, early phase
   \ The enable bit must be set last, after all configuration is done
   h# 87 ssp-sscr0 io!   \ Enable, 8-bit data, SPI normal mode
   wait-clk-sync
;

2 value ssp-rx-threshold
: set-ssp-fifo-threshold  ( n -- )  to ssp-rx-threshold  ;

: .ssr  ssp-sssr io@  .  ;
: rxavail  ( -- n )
   ssp-sssr io@  dup 8 and  if   ( val )
      d# 12 rshift h# f and  1+
   else
      drop 0
   then
;
: prime-fifo  ( -- )
   ssp-rx-threshold  0  ?do  0 ssp-ssdr io!  loop
;
: rxflush  ( -- )
   begin  ssp-sssr io@  8 and  while  ssp-ssdr io@ drop  repeat
;
: ssp-ready?  ( -- flag )  rxavail  ssp-rx-threshold  >=  ;

false value debug?
\ Set the direction on the ACK and CMD GPIOs
: init-gpios  ( -- )
   ec-spi-cmd-gpio# gpio-dir-out
   ec-spi-ack-gpio# gpio-dir-out
;
: clr-cmd  ( -- )  ec-spi-cmd-gpio# gpio-clr  ;
: set-cmd  ( -- )  ec-spi-cmd-gpio# gpio-set  ;
: clr-ack  ( -- )  ec-spi-ack-gpio# gpio-clr  ;
: set-ack  ( -- )  ec-spi-ack-gpio# gpio-set  ;
: fast-ack  ( -- )  set-ack clr-ack  debug?  if  ." ACK " cr  then  ;
: slow-ack  ( -- )  d# 10 ms  set-ack d# 10 ms  clr-ack  ;
defer pulse-ack  ' fast-ack to pulse-ack

0 value cmdbuf
0 value cmdlen

0 value command-finished?

0 value cmd-time-limit
: cmd-timeout?   ( -- flag )
   get-msecs  cmd-time-limit  -  0>=
;
: set-cmd-timeout  ( -- )
   get-msecs d# 1000 +  to cmd-time-limit
;

defer do-state  ' noop to do-state
defer upstream

: enter-upstream-state  ( -- )
   2 set-ssp-fifo-threshold
   ['] upstream to do-state
;
: command-done  ( -- )
   true to command-finished?
   enter-upstream-state
   prime-fifo
   pulse-ack
;

\ Discard 'len' bytes from the Rx FIFO.  Used after a send
\ operation to get rid of the bytes that were received as
\ a side effect.
: clean-fifo  ( len -- )  0  ?do  ssp-ssdr io@ drop  loop  ;

: response  ( -- )
   command-done
;
: switched  ( -- )
   \ Unload the spurious (result of sending command) rx bytes from the FIFO
   cmdlen clean-fifo
   command-done
;
: handoff-command  ( -- )
   debug?  if  ." CMD: "  then
   cmdlen 0  do
      cmdbuf i + c@
      debug?  if  dup .  then
      ssp-ssdr io!
   loop
   debug?  if  cr  then
   cmdlen set-ssp-fifo-threshold
   clr-cmd
   ['] switched to do-state            ( )
   pulse-ack
;
: ?do-ack  ( -- )
   \ If there is more data in the FIFO, it means that the EC
   \ timed out and "inferred" an ACK, so we don't ACK until
   \ the FIFO is empty.
   ssp-ready? 0=  if  prime-fifo pulse-ack  then
;
: (upstream)  ( -- )
   ssp-ssdr io@  ssp-ssdr io@              ( channel# data )
   debug? if
      ." UP: " over . dup . cr
   then
   over case                               ( channel# data )
      0 of  2drop ?do-ack  endof           ( channel# data )  \ Invalid
      1 of  2drop handoff-command   endof  ( channel# data )  \ Switched
      ( default )                          ( channel# data channel# )
         enque  ?do-ack                    ( channel# )
   endcase
;
' (upstream) to upstream
: open-ec  ( -- )
   init-gpios
   init-ssp-in-slave-mode
   rxflush
   init-queues
   clr-cmd
   prime-fifo
   clr-ack  \ Tell EC that it is okay to send
   enter-upstream-state
;
: close-ec  ( -- )  set-ack  ;

: poll  ( -- )
   ssp-ready?  if  do-state  then
\  debug?  if  key?  if  key drop debug-me  then  then
;
: cancel-command  ( -- )  \ Called when the command child times out
   clr-cmd
   ['] upstream to do-state      
   prime-fifo
   pulse-ack
;

: drain  ( -- )
   begin  ssp-ready?  while  poll  repeat
;
: no-data-command  ( cmdadr cmdlen -- )
   to cmdlen   to cmdbuf
   false to command-finished?

   set-cmd-timeout
   ['] do-state behavior ['] upstream =  if
      drain
      set-cmd
   else
      handoff-command
   then
   begin                   ( )
      poll                 ( )
      cmd-timeout? throw   ( )
      command-finished?    ( done? )
   until
;

8 buffer: ec-cmdbuf
d# 16 buffer: ec-respbuf
: expected-response-length  ( -- n )  ec-cmdbuf 1+ c@ h# f and  ;

0 value #results
: set-cmdbuf  ( [ args ] #args #results cmd-code slen -- )
   >r                      ( [ args ] #args #results cmd-code r: slen )
   ec-cmdbuf 8 erase       ( [ args ] #args #results cmd-code )
   ec-cmdbuf c!            ( [ args ] #args #results )
   to #results             ( [ args ] #args )
   dup ec-cmdbuf 1+ c!     ( [ args ] #args  r: slen )
   r> ec-cmdbuf 2+ c!      ( [ args ] #args  r: )
   h# f and                ( [ args ] #args' )
   dup 5 >  abort" Too many EC command arguments"
   ec-cmdbuf 3 +   swap  bounds  ?do  i c!  loop  ( )
;
: timed-get-results  ( -- b )
   get-msecs  d# 50 +   begin         ( limit )
      2 deque?  if                    ( limit b )
         nip exit                     ( -- b )
      then                            ( limit )
      poll                            ( limit )
      dup get-msecs - 0<              ( limit )
   until                              ( limit )
   drop
   true abort" EC command result timeout"
;
   
: ec-command-buf  ( [ args ] #args #results cmd-code -- result-buf-adr )
   0 set-cmdbuf                            ( )

   ec-cmdbuf 8 no-data-command             ( )

   ec-respbuf    #results  bounds  ?do     ( )
      timed-get-results i c!               ( )
   loop                                    ( )

   ec-respbuf                              ( result-buf-adr )
;
: ec-command  ( [ args ] #args #results cmd-code -- [ results ] )
   ec-command-buf                    ( result-buf-adr )
   #results bounds  ?do  i c@  loop  ( [ results ] )
;

: do-ec-cmd  ( [ args ] #args #results cmd-code -- [ results ] )  ec-command  ;

: ec-cmd  ( cmd -- )   0 0 rot do-ec-cmd  ;
: ec-cmd-b@  ( cmd -- b )   0 1 rot do-ec-cmd          ;
: ec-cmd-w@  ( cmd -- w )   0 2 rot do-ec-cmd  bwjoin  ;
: ec-cmd-l@  ( cmd -- l )   0 4 rot do-ec-cmd  bljoin  ;
: ec-cmd-b!  ( b cmd -- )   1 0 rot do-ec-cmd  ;
: ec-cmd-w!  ( w cmd -- )   >r wbsplit 2 0 r> do-ec-cmd  ;
: ec-cmd-l!  ( l cmd -- )   >r lbsplit 4 0 r> do-ec-cmd  ;

: board-id@      ( -- n )  open-ec  h# 19 ec-cmd-w@  close-ec  ;
: power-off      ( -- n )  open-ec  h# 4c ec-cmd  close-ec  begin wfi again  ;
warning off
: bye            ( -- n )  open-ec  h# 4b ec-cmd  close-ec  begin wfi again  ;
warning on


\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
