marker -dth22.fth  cr lastacf .name .( 25-5-2021 )


0 value Ticks1Sec
: FTickTime     ( RtcTicks - ) ( f: - time )  s>d d>f f# 1e0 Ticks1Sec s>d d>f f/ f* ;
: SetTicks1Sec  ( - )  #1000000000 pm_rtc_clock_cali_proc #1000 * #12 rshift / to ticks1sec ;

s" 16bit>32bit" $find  0= [if]
: 16bit>32bit ( signed16bits - signed32bits )  dup $7FFF >  if  $FFFF0000 or  then ;
[then]  drop


vocabulary DHT22  also DHT22 definitions


 #5 constant Dht22Pin  \ DHT22

#4000 constant MinimalTimeoutDht22

  0 constant GPIO_LOW
#-1 constant GPIO_HIGH
 #2 constant QUEUE_TYPE_COUNTING_SEMAPHORE
 #3 constant GPIO_INTR_ANYEDGE    \ GPIO interrupt type : both rising and falling edge

\ Timings when the RTC clock is not changed:
 #3 constant minl0  \ 16 us
 #8 constant maxl0  \ 43 us
 #9 constant minl1  \ 49 us
#17 constant maxl1  \ 92 us

#90 constant /xQueueLength
 #3 cells constant /itemsize       \ cell 0 is used in C for the itemsize

  0 value &ulValReceived
  0 value prev_&ulValReceived

  0 value check-sum
  0 value humidity      \ 10* 16bit
  0 value temperature   \ 10* 16bit sighned

  variable qGpioHandle
  variable Qnr
  variable #errors

: xQueueCreate ( itemsize qlength -- qHandle )
               \ itemsize: The number of bytes each item in the queue will require.
               \ qlength: The maximum number of items that the queue can contain.
   QUEUE_TYPE_COUNTING_SEMAPHORE -rot xQueueGenericCreate  #10 vTaskDelay  ;

: init-handler ( pin - )
     0 gpio_install_isr_service  abort" gpio_install_isr_service failed"
     dup gpio-is-output-open-drain
     qGpioHandle @ over  pulse_isr_qhandler_add abort" gpio_isr_qhandler_add failed"
     GPIO_INTR_ANYEDGE  over   gpio_set_intr_type  abort" gpio_set_intr_type failed"
     drop  ;

: CreateGpioQue    ( - )  /itemsize /xQueueLength   xQueueCreate  qGpioHandle ! ;
: WaitforGpioQueue ( msMaxWait - flag )  &ulValReceived qGpioHandle @ xQueueReceive ;
: HighLow@         ( &ulValReceived - flag )  #2 cells + @ ;
: RtcTick@         ( &ulValReceived - tick )  cell+ @ ;

: FilterPulse   ( - -1|0|1 )
   &ulValReceived RtcTick@  prev_&ulValReceived -
   dup minl0 maxl0 between
    if drop 0
    else minl1 maxl1 between
         if 1
         else -1
         then
    then ;

\ P = Pulse state
\ D = Duration previous pulse in Rtc ticks
\ B = Calculated bit of the pulse
\ Pulse = Rtc pulse duration in FP notation.
: .qraw  ( - )
    cr   Qnr @ 1 =
      if  cr ."   #  RtcTick P   D B   Pulse" cr
      then
    1 Qnr +! Qnr @ 3 u.r space &ulValReceived  RtcTick@ .   &ulValReceived HighLow@ abs .
    &ulValReceived RtcTick@  prev_&ulValReceived - dup 2 u.r  space FilterPulse .
    space space  FTickTime fe. ;

: FilterPulses  (  - -1|0|1 )  \ findPulse
   &ulValReceived HighLow@ 0=
     if    FilterPulse  \ decimal .qraw  \ To see the pulse durations
     else  -1
     then ;

: DumpQue ( - )
  base @ decimal cpu_freq@ . cr
  Qnr off #2 &ulValReceived qGpioHandle @ xQueueReceive
      if   begin  &ulValReceived RtcTick@ to prev_&ulValReceived
                  1 WaitforGpioQueue
                   FilterPulses drop .qraw
           0= until
      else   ." Empty"
      then   base !  ;

: EmptyQue ( - )
  Qnr off 2 &ulValReceived qGpioHandle @ xQueueReceive
      if   begin  &ulValReceived RtcTick@ to prev_&ulValReceived
                  2 WaitforGpioQueue
           0= until
      then ;

: DeQueueEntry  ( - flag ) \ new prev_&ulValReceived
    &ulValReceived RtcTick@ to prev_&ulValReceived   1 WaitforGpioQueue ;

: DequeueNumber ( #pulses - n )
    0 swap 0
      do   DeQueueEntry 0=
              if   drop FilterPulses leave
              then
           FilterPulses dup 0>=
              if    swap 1 lshift or
              else  drop
              then
      loop ;

: DequeueNumbers ( - )
    Qnr off
     #5 DequeueNumber drop \ skip start signal and the status bit
    #32 DequeueNumber to humidity
    #32 DequeueNumber to temperature
    #16 DequeueNumber to check-sum ;

: SendLowPulse ( ms - )
    GPIO_LOW  Dht22Pin gpio-pin! ms
    GPIO_HIGH Dht22Pin gpio-pin! ;

: CalcCheck-sum ( - check-sum )
    humidity  8 rshift humidity  $FF and +
    temperature  8 rshift temperature  $FF and + + $FF and ;

: Dht22Error? ( - Error ) CalcCheck-sum check-sum - ;

also forth definitions

: (ReadDht22) ( - flag )
   EmptyQue 18 SendLowPulse DequeueNumbers Dht22Error? dup
    if  1 #errors +!   then
   0= ;

: ReadDht22 ( - )
   SetTicks1Sec 3 0
      do   (ReadDht22)   if   leave   then
           MinimalTimeoutDht22  ms
      loop ;

: #.#  ( n - )
   base @ swap decimal
   s>d  tuck dabs <# # [char] . hold #s rot sign #> type
   base ! ;

: init-dht22
   /itemsize allocate drop to &ulValReceived CreateGpioQue
   Dht22Pin init-handler SetTicks1Sec
   #100 ms ReadDht22 #1000 ms  #errors off  ;

: .dht22  ( - )
    Dht22Error? 0=
     if   temperature  16bit>32bit #.#  ." C  "   humidity  #.# ." %  "
     else ." Error Dht22 "
     then ;

: .dht22Check  ( - )
    .dht22  ." check-sum:" check-sum .
    humidity  8 rshift humidity  $FF and +
    temperature  8 rshift temperature  $FF and + + dup $FF and ."  calculated:" .
    check-sum - $FF and ."  error:" . ;

: dht22-test ( - )
  cpu_freq@ .d   0
    begin
        MinimalTimeoutDht22 ms cr 1+ dup .d ." --> "
        (ReadDht22) drop .dht22Check #errors @ .d  key?
    until drop ;

previous previous

0 [if]  \ use:

 init-dht22
 ReadDht22 .dht22 cr
 ReadDht22 .dht22Check
\ dht22-test
\ also DHT22 EmptyQue 18 SendLowPulse DumpQue

[then]
\ \s
