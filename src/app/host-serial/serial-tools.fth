$bad1 value comport

: get-com#  ( -- )
   ." COM: "
   here 4 accept  ( #bytes )
   here swap push-decimal $number pop-base abort" bad number"
   to comport
;

0 value serial-ih
: open-serial
   comport $bad1 =  if  get-com#  then
   comport open-com to serial-ih
   serial-ih 0< abort" Can't open serial port"
;
: set-rts-dtr  ( rts dtr -- )  serial-ih set-modem  ;

8 buffer: serbuf
: serial-write  ( adr len -- )  serial-ih write-com drop  ;
0 value needing  0 value thisadr
: timed-serial-read  ( adr len ms -- actual )  serial-ih timed-read-com  ;
: serial-read-exact  ( adr len -- )
   to needing  to thisadr
   begin  needing  while
      thisadr needing d# 5000 timed-serial-read  ( thislen )
      dup 0=  abort" Read timed out"     ( thislen )
      dup thisadr + to thisadr           ( thislen )
      needing swap - to needing          ( )
   repeat
;
: serial-put  ( b -- )  serbuf c!  serbuf 1 serial-write  ;
: skey-avail?  ( -- false | char true )
   serbuf 1 #10 timed-serial-read 1 =  if
      serbuf c@  true
   else
      false
   then
;

: consume  ( -- )  begin  skey-avail?  while  drop  repeat  ;

: rdisplay  ( -- )
   ." Displaying serial output" cr
   begin
      skey-avail?  if  ( char )
         \ The character value c0 is an ACK from the tethering
         \ protocol, indicating that the other end is in a
         \ command loop.
         dup h# c0 =  if
            ." Tethered" cr  drop exit
         else
            dup $d = if drop $a then emit
         then
      then
      key?  if
        key  dup [char] ~ =  if  drop exit  then
        serial-put
      then
   again
;

#128 buffer: target-line
0 value #target-line
: 'target-line  ( -- adr )  target-line #target-line +  ;
: line-full?  ( -- flag )  #target-line #128 =  ;
: +target-line  ( -- )   #target-line 1+ to #target-line  ;
: -target-line  ( -- )   #target-line 1- 0 max  to #target-line  ;
: target-line$  ( -- adr len )  target-line #target-line  ;

#500 value target-line-timeout

\ Gets the next newline-terminated line from the target device.
\ The terminator, possibly preceded by a carriage return, is included in the buffer
\ If timeout expires there will not be a terminator in the buffer, but the length
\ might not be 0
: get-target-line  ( timeout -- adr len timeout? )
   to target-line-timeout
   0 to #target-line
   begin
      line-full?  if
         target-line$ false exit
      then

      'target-line 1  target-line-timeout  timed-serial-read  1 <>  if
         target-line$ true exit
      then

      +target-line

      'target-line 1- c@  $0a =  if
         target-line$ false exit
      then
   again
;

\ True if small$ appears at the beginning of large$
: initial-substring?  ( small$ large$ -- flag )
   2 pick  <  if  3drop false exit  then   ( small$ large-adr )
   over compare 0=
;

: ok$  " ok "  ;
: stm-ok$  " OK "  ;
defer prompt$  ' stm-ok$ to prompt$

\ Reads either a newline-terminated line or an "OK " prompt from the target
\ Returns true if the beginning of the line was "OK "
\ Returns the line and false if a newline-terminator or a timeout occurred
: get-target-line-or-prompt  ( timeout -- true | adr len false )
   to target-line-timeout
   0 to #target-line
   begin
      line-full?  if
         target-line$ false  exit
      then

      'target-line 1 target-line-timeout timed-serial-read  1 <>  if
         target-line$  false  exit
      then

      +target-line

      prompt$  target-line$ initial-substring?  if
         true exit
      then

      'target-line 1- c@  $0a =  if
         target-line$ false exit
      then
   again
;

\ Discard any output from the STM that is not a prompt
: discard-until-prompt  ( -- )
   begin
      #100 get-target-line-or-prompt  0=
   while     ( adr len )
      2drop  ( )
   repeat    ( )
;
#100 buffer: response-buf

\ Send a command string to the STM, discard its echo, and receive
\ a single line of output from the command.
: send-cmd-1response  ( adr len -- response$ )
   serial-write  " "n" serial-write
   #100 get-target-line-or-prompt  abort" Command not echoed"  ( adr len )
   2drop
   #100 get-target-line-or-prompt  if   ( )
      " "
   else                                 ( adr len )
      tuck response-buf swap move       ( len )
      response-buf swap                 ( response$ )
      discard-until-prompt              ( response$ )
   then                                 ( result$ )
;
alias ss send-cmd-1response

\ Removes a CR-LF or a LF from the end of the buffer, if present
: -crlf  ( adr len -- adr len' )
   dup  if                               ( adr len )
      2dup + 1- c@  $0a =  if  1-  then  ( adr len' )
   then                                  ( adr len )
   dup  if                               ( adr len )
      2dup + 1- c@  $0d =  if  1-  then  ( adr len' )
   then                                  ( adr len )
;

\ Reads lines from the target until either a prompt is seen, a
\ timeout occurs, or #lines lines is read.  Returns true if a prompt
\ was seen, otherwise false.  If verbose? is true, non-prompt lines are
\ displayed as they are read.
: wait-target-prompt  ( verbose? timeout #lines -- prompted? )
   0  ?do                                  ( verbose? timeout )
      dup get-target-line-or-prompt  if    ( verbose? timeout )
         2drop true  unloop exit           ( -- true )
      then                                 ( verbose? timeout adr len )
      3 pick  if  type  else  2drop  then  ( verbose? timeout )
   loop                                    ( verbose? timeout )
   2drop false                             ( false )
;

: grab-tether  ( -- )
   begin
      skey-avail?  if   ( char )
         case
            \ The character value c0 is an ACK from the tethering
            \ protocol, indicating that the other end is in a
            \ command loop.
            h# c0  of  ." Tethered" cr  exit  endof
            '?'    of  'q' serial-put         endof
            ( default ) dup emit
         endcase
      then
      key?  if
        key  dup [char] ~ =  if  drop exit  then
        serial-put
      then
   again

;
: display  ( -- )
   ." Displaying serial output" cr
   begin
      skey-avail?  if   ( char )
         \ The character value c0 is an ACK from the tethering
         \ protocol, indicating that the other end is in a
         \ command loop.
         dup h# c0 =  if
            ." Tethered" cr  drop exit
         else
            emit
         then
      then
      key?  if
        key  dup [char] ~ =  if  drop exit  then
        serial-put
      then
   again
;

\ This is a software copy of the FTDI bit control byte.
\ Its high nibble is the input/output mask for CBUS0-3 (1 is output)
\ and its low nibble is the CBUS0-3 output value when in output mode.
\ We start with 0 assuming that all CBUS pins are input mode, which
\ is a reasonable, but not guaranteed, assumption for the initial state.
\ It is unclear whether you can ask the chip that initial state.
\ The first call to ft-bit-change affecting a given CBUS bit will
\ set that CBUS pin to the appropriate mode and value.
0 value ft-bits

: ft-bit-change  ( new-bits-mask affected-bits-mask -- )
   tuck and                 ( affected-bits-mask new-bits-mask' )
   swap invert ft-bits and  ( new-bits-mask old-bits' )
   or  to ft-bits           ( )
   ft-bits  serial-ih ft-setbits abort" ft-setbits failed"
;

\ Control the power switch on a modified FTDI dongle.
: ftdi-power-on   ( -- )  $88 $88 ft-bit-change  ;
: ftdi-power-off  ( -- )  $80 $88 ft-bit-change  ;
