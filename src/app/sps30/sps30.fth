marker -sps30.fth  cr lastacf .name #19 to-column .( 05-12-2023 ) \ By J.v.d.Ven

0 value msg-board$   0 value sensor-web$

VOCABULARY SPS30 SPS30 DEFINITIONS DECIMAL

 #2 to uart_num
#26 constant rx-pin
#25 constant tx-pin

#10 floats constant /fdata      0 value &fdata  \ For the initial frame data
  0 value &CBdata-sps30                         \ For historical data
 -1 constant UART_PIN_NO_CHANGE

: init-uart-sps30 ( rx-pin tx-pin uart_num -- )
   to uart_num 2>r
   0 1 0 8 #115200 uart_num uart-param-config
          abort" uart-param-config failed"
   UART_PIN_NO_CHANGE UART_PIN_NO_CHANGE 2r> uart_num uart-set-pin
          abort" uart-set-pin failed"
   0 0 0 0 /RxBuf uart_num uart-driver-install
          abort" uart-driver-install failed" ;

create &code-list
\ Org   transferred
 $7E c, $7D c, $5E c,
 $7D c, $7D c, $5D c,
 $11 c, $7D c, $31 c,
 $13 c, $7D c, $33 c,

3 constant /code-line
4 /code-line * constant /code-list

: encode-sps30   ( char - coded$ cnt )
   1 swap  &code-list /code-list  bounds
       do  dup i c@ =
              if 2drop 2  i 1+ leave
              then
       /code-line +loop
   over 1 =
       if  pad  c! pad
       then
   swap  ;

create &start-frame $7E c, 00 c,     2 constant /start-frame

: end-frame ( - adr cnt )  &start-frame 1 ;

$00 constant start-measurement
$01 constant stop-measurement
$03 constant read-measured
$10 constant sleep
$11 constant wake-up
$56 constant start-fan-cleaning
$80 constant auto-cleaning-interval
$d0 constant device-information
$d1 constant read-version
$d2 constant read-device-status-register
$d3 constant reset

variable tsum
: +tsum        ( char - ) tsum +!  ;
: send-encoded ( char - ) dup +tsum  encode-sps30 send-tx ;
: chk          ( - InvertedChecksumByte ) tsum @ invert $FF and ;

: sendframe    ( byte1...byte0 #bytes cmd - )
   tsum off &start-frame /start-frame
   send-tx
       send-encoded           \ cmd
   dup send-encoded           \ length
   0
        ?do   send-encoded    \ data
        loop
   chk send-encoded           \ inverted checksum
   end-frame send-tx 25000 us ;

0 value &decoded-frame

: decode-char ( char - decoded-char )
   &code-list /code-list  bounds
       do   dup  i 2 + c@ =
            if   i   c@  leave
            then
   /code-line +loop nip ;

: decode-frame ( adr cnt - length-decode-frame ) \ 0 = invalid frame
   2dup
   -1 -rot &decoded-frame off   tsum off
   1 /string 2 -  bounds
        ?do   1+ i c@ dup $7D =
               if  drop i 1+ c@ decode-char 2
               else 1
               then
             over +tsum  swap 2 pick &decoded-frame + c!
        +loop
   -rot + 2 - c@ chk = and ;

: >data-sps30 ( $data-buffer  - &data-sps30 ) 3 + ;

: get-state ( - n )  &RxBuf >data-sps30 c@ ;

: .error-state ( error - )
   $7f and
      case
         $00 of ." No error" endof
         $01 of ." Wrong data length for this command (too much or little data)" endof
         $02 of ." Unknown command" endof
         $03 of ." No access right for command" endof
         $04 of ." Illegal command parameter or parameter out of allowed range" endof
         $28 of ." Internal function argument out of range" endof
         $43 of ." Command not allowed in current state" endof
      endcase   ;

: error-sps30? ( state - err )   $40 and ;

: get-frame ( - adr cnt|0 )
   read-rx dup 0>
      if  &RxBuf get-state dup 0<>
          if   dup error-sps30?
                 if   .error-state
                 else  drop
                 then  2drop pad 0
          else  drop swap decode-frame &decoded-frame swap
          then
      else  drop pad 0
      then  ;

: get-device-information ( info - adr cnt )
   1 device-information sendframe  get-frame  drop >data-sps30 count 1- ;

: get-version ( - adr cnt )
   0 read-version sendframe  get-frame ;

: get-status-register ( - n )
   0 1 read-device-status-register sendframe  get-frame  drop 4 + @ ;

: .version  ( adr - adr2 )
   1 swap 4  bounds
      ?do  1- i c@ dup (.) type  0> i pad !
             if dup 0=
                   if   [char] . emit
                   then
             else   leave
             then
      loop
   drop pad @ 1+ ;

: .device-information ( - )
   0 get-device-information  cr ." Product type: "  type
   3 get-device-information  cr ." Serial no   : " 1- type
   get-version drop cr
      ." Firmware    : V"  4 + .version
   cr ." Hardware    : V" .version
   cr ." SHDLC       : V" .version drop
   get-status-register cr ." Status reg. : "  2 base ! . decimal
   cr ;

: bw@ ( adr - n )  \ Fetch 16 bits fetch big-edian
   dup c@  8 lshift swap 1+ c@  or ;

: bl@ ( adr - n )  \ Fetch 32 bits big-endian
   dup  bw@ #16 lshift swap 2 + bw@ or ;

\ The SPS-30 uses big-endian IEEE754 float values

$7ff00000 0 pad 2! pad f@ fconstant Inf

: decode-significand  { sig -- }
   f# 1e0  f# 0e0   1 #23 lshift  0 #23
   do  dup sig and
        if  fover f+
        then
        fswap f# 2e0 f/ fswap 1 rshift
   -1 +loop drop fswap fdrop ;

\ https://en.wikipedia.org/wiki/Single-precision_floating-point_format#Converting_binary32_to_decimal
\ https://www.h-schmidt.net/FloatConverter/IEEE754.html

: IEEE754>  ( n - ) ( F - n )
   dup 0 #22 bits@     [ #23 1 #mask ] literal or
   decode-significand             \ Mantissa
   dup #23 #30 bits@  dup #255 =
       if     fdrop 2drop Inf
       else   dup 0=
                 if   over [ #23 1 #mask ] literal and 0>
                        if   1+    \ Denormalize
                        then
                 then   #127 -     \ Exponent
              s>f  f# 2e0 fswap f** f*
              [ #31 1 #mask ] literal and 0>
                 if   fnegate
                 then              \ sign
       then ;

\  4 set-precision $3ed040dc IEEE754> f. \ .4067
\ $402cee79 IEEE754> f. \ 2.7021

0 value last-cmd

: send-commend	   ( byte1...byte0 #bytes cmd - )
    dup to last-cmd sendframe get-frame  0=
        if    last-cmd ."  Sps30 Cmd: $" h. cr
        else  drop
        then  ;

: reset-sps30      ( - )              0 reset send-commend ;
: stopMeasurement  ( - )              0 stop-measurement   send-commend ;
: startMeasurement ( 16b|floats - ) 1 2 start-measurement  send-commend ;
: startCleaning    ( - )              0 start-fan-cleaning send-commend ;
: startSleep       ( -  )             0 sleep send-commend ;
: readMeasurement  ( -  adr cnt )     0 read-measured sendframe get-frame ;

: wakeUp           ( -  )
   $ff sp@ 1 send-tx drop
   0 wake-up sendframe
   50000 us  get-frame 2drop ;

: ReadAutoCleaning ( - n )
   0 1 auto-cleaning-interval sendframe get-frame  drop >data-sps30 count drop @  ;

: WriteAutoCleaning ( n - )  \ 604800=every week   86400=24Hrs   43200=12Hrs
   pad ! pad  4 + 5 1 do dup i - c@ swap loop drop   \ See the manual.
   0 5 auto-cleaning-interval sendframe get-frame  ;

: wait-status-reg ( - )
   #30 0
       do    get-status-register 0=
               if  leave
               then   #500000 us
   [char] . emit
       loop ;

: clear-fdata ( - )
   &fdata /fdata bounds
      do   f# 0.0e0 i f! [ 1 floats ] literal +loop  ;

11 value #fields

: clear-data-buffer-sps30 ( &CBdata-sps30 - )
   dup >r >&data-buffer @   r@ >max-records @ #fields floats * bounds
        do  f# 0e0 i f!    [ 1 floats ] literal
        +loop
   r> >cbuf-count off ;

0 value /CBdata-sps30

: init-res-sps30
    /RxBuf allocate drop to &RxBuf
    #256   allocate drop to &decoded-frame
    /fdata floats allocate drop to &fdata
    rx-pin tx-pin uart_num init-uart-sps30 #100 ms clear-fdata
    3 ( Minutes) min>fus to cycle-time                        \ In us Includes the sleep time
    4 ( Hours )  60 * cycle-time fus>fsec f>s
                 60 / 1 max / 2 max 1200 min to /CBdata-sps30 \ Size logging
   #11 to #fields
   #fields floats /CBdata-sps30 allocate-cbuffer to &CBdata-sps30
   &CBdata-sps30 clear-data-buffer-sps30 ;

0 fvalue start-tic

: init-sps30 ( - )
   &RxBuf 0=
      if   init-res-sps30
      then
   usf@ to start-tic
   wakeup reset-sps30
   cr ." Starting up. " #20 0
       do    get-status-register 0=
               if  leave
               then  #500000 us
       loop ;

: avg-fdata (  adr n #n -- )
   s>f  bounds
      ?do    i dup f@ fover f/ f!    [ 1 floats ] literal
      +loop
   fdrop ;

: +fdata ( adr n -- )
   #2 set-precision
   2drop #10 0
       do    &decoded-frame 4 + i cells + bl@ IEEE754>
             i floats &fdata + dup f@  f+  f!
       loop ;

create-timer: tSps30
#1  floats constant pm1.0-offset
#2  floats constant pm2.5-Offset
#3  floats constant pm4.0-Offset
#4  floats constant pm10-Offset
#5  floats constant nc0.5-Offset
#6  floats constant nc1.0-Offset
#7  floats constant nc2.5-Offset
#8  floats constant nc4.0-Offset
#9  floats constant nc10-Offset
#10 floats constant tps-Offset

: init-fmeasure ( - )
   clear-fdata 0 to fmeasure-complete
   #samples off  usf@ to tcycle
   tSps30 start-timer
   tTotal start-timer ;

create UdpPortESP   ," 8899"


: send-tmp$-msg-board$ ( - )
   tmp$ lcount msg-board$ UdpWrite ;

: send-pm2.5-msgBoard ( f: n - )
   fdup f# 10e0 f>
     if     fnegate f# 20e0  \ 10-50
     else   f# 100e0         \  0-10
     then   f*
   s" -2130706452 F0 M:" tmp$ lplace f>s (.) tmp$ +lplace
   s"  " tmp$ +lplace  send-tmp$-msg-board$ ;

: send-pm2.5-sensorweb ( f: n - )
   f# 100e0 f* fround f>s (.) tmp$ lplace s"  " tmp$ +lplace
   ip4Host tmp$ +lplace
   s"  pm25" tmp$ +lplace
   tmp$ lcount  sensor-web$  UdpWrite ;

: @old-PM25 ( #back - ) ( f: - oldPM25 )
  &CBdata-sps30 circular-range swap
  rot - max  &CBdata-sps30 >circular pm2.5-Offset + f@ ;

f# 3.e0 fvalue alarm-limit
#12 value alarm-cmp
variable alarm-off-cnt  #3 alarm-off-cnt !

: send-alarm-off ( - )
   s" -2130706452 F0 A:0" tmp$ lplace
   s"  @31" tmp$ +lplace  send-tmp$-msg-board$ ;

: send-alarm ( f: n - )
   alarm-cmp @old-PM25 ." Alarm-compare " f- alarm-limit f> dup .
    if    s" -2130706452 F0 A:1" tmp$ lplace
          s"  @31" tmp$ +lplace  send-tmp$-msg-board$
          #3 alarm-off-cnt !
    else  alarm-off-cnt @ 0>=
            if   send-alarm-off -1 alarm-off-cnt +!
            then
    then cr ;

: send-pm2.5 ( - )
  1 @old-PM25   fdup cr ." PM2.5: " f. cr
  fdup send-pm2.5-msgBoard
  fdup send-pm2.5-Sensorweb
       send-alarm  ;

: add-to-ring-buffer ( - )
   &fdata  &CBdata-sps30 >circular-head tuck 1 floats +  10 floats cmove>
   local-time-now  stages-
      if  ." Add record:" fdup .Time-from-UtcTics
      then  f!  &CBdata-sps30 incr-cbuf-count ;

: take-sample ( f: us-time -   )
   tSps30  tElapsed?
      if  .tcycle readMeasurement dup 0>
             if  +fdata  #samples @ #max-samples <=
                    if  1 #samples +! tSps30 start-timer
                        #samples @ #max-samples =
                           if  stopMeasurement
                               &fdata /fdata #max-samples avg-fdata add-to-ring-buffer
                               msg-board$ 0>
                                  if   send-pm2.5
                                  then
                               1 to fmeasure-complete
                           then
                    then
             else 2drop
             then
      then ;


\ ---- 1 measurement ----           \ *order

: take-samples  ( - )               \ *4
   fmeasure-complete 3 =  if  exit then
   time-1-sample take-sample ;

f# 30e6 fvalue warm-up-time

: warming-up  ( - )                 \ *3
   warm-up-time time-1-sample f- tSps30 tElapsed?
     if  tSps30 start-timer  ['] take-samples SetStage
     then ;

: wait-for-status-registor  ( - )   \ *2
   check-time get-status-register 0=
     if   tSps30 start-timer ['] warming-up SetStage
     then ;

: set-next-measurement-sps30 ( - ) \ To get to the next end of the cycle.
   cycle-time fdup  &CBdata-sps30 >cbuf-count @ 2 - s>f f* f+
   usf@ start-tic f- f- f# 1000e0 fmax fdup  fus>fms f>s
   dup #10000 >
      if    cr ." New results after:"  . ." ms"
      else  drop
      then
   to next-measurement ;

: start-measurements  ( - )         \ *1
   3 startMeasurement
   ['] wait-for-status-registor SetStage ;

: Wait-till-next-measurement ( - )  \ *5 After 1st-measurement only
   next-measurement tTotal tElapsed?
       if  .tcycle   stages-
              if  ." End "  .time cr
              then
           init-fmeasure ['] start-measurements SetStage
       then ;

: sleep-sensor ( - )                \ *5 After all other measurements
   next-measurement  tTotal tElapsed?
     if  .tcycle   stages-
            if  ." End " .time cr
            then
          wakeUp  init-fmeasure  ['] start-measurements SetStage
     then ;

: 1st-measurement  ( - )            \ *0
   f# 15e6 time-1-sample f-  tSps30 tElapsed?
     if   clear-fdata  check-time
          readMeasurement +fdata  add-to-ring-buffer
          stopMeasurement
          set-next-measurement-sps30
          ['] Wait-till-next-measurement SetStage
     then ;

: start-sleep ( - ) startSleep (sleeping-schedule)  ;

0 value CleaningDone

: start-cleaning ( - )
   CleaningDone 0=
      if   cr ." clean-schedule"
           wakeUp 3 startMeasurement  startCleaning
           14000 ms true to CleaningDone
           stopMeasurement
      then ;

: take-samples- ( - )  ;

: handle-sps30 ( - )
   'stage execute   fmeasure-complete 1 =
      if  warm-up-time f# 15e6 f>
               if  schedule
                   WaitForSleeping-
                     if   StopRunSchedule?  \ After start-sleep
                             if    (sleeping-schedule) exit \ ignores stages
                             else  0 to WaitForSleeping-
                             then
                     then schedule-entry
               then
          3 to fmeasure-complete set-next-measurement-sps30
          ['] sleep-sensor SetStage \ New stage
      then ;

FORTH DEFINITIONS

\ init-sps30  .device-information
\ \s
