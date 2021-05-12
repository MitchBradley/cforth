\ interrupt.fth
\ When a switch is used it makes several entries in a queue

decimal

14 constant InputButton  \ A switch on GPIO 14

$FFFFFFFF constant portMAX_DELAY

\ Queue types:
0 constant QUEUE_TYPE_BASE		 \ ( 0U )
1 constant QUEUE_TYPE_MUTEX 	         \ ( 1U )
2 constant QUEUE_TYPE_COUNTING_SEMAPHORE \ ( 2U )
3 constant QUEUE_TYPE_BINARY_SEMAPHORE	 \ ( 3U )
4 constant QUEUE_TYPE_RECURSIVE_MUTEX	 \ ( 4U )

\ Placements:
0 constant queueSEND_TO_BACK
1 constant queueSEND_TO_FRONT
2 constant queueOVERWRITE

16      constant /xQueueLength
1 cells constant /itemsize
create &ulValReceived /itemsize allot

: xQueueCreate ( itemsize qlength -- qHandle )
               \ itemsize: The number of bytes each item in the queue will require.
               \ qlength: The maximum number of items that the queue can contain.
   QUEUE_TYPE_COUNTING_SEMAPHORE -rot xQueueGenericCreate  10 vTaskDelay  ;

: QueueSend (  pvItemToQueue qHandle xTicksToWait_WhenFull  -- result )
   queueSEND_TO_BACK swap 2swap xQueueGenericSend  ;

 0 constant GPIO_INTR_DISABLE    \ Disable GPIO interrupt
 1 constant GPIO_INTR_POSEDGE    \ GPIO interrupt type : rising edge
 2 constant GPIO_INTR_NEGEDGE    \ GPIO interrupt type : falling edge
 3 constant GPIO_INTR_ANYEDGE    \ GPIO interrupt type : both rising and falling edge
 4 constant GPIO_INTR_LOW_LEVEL  \ Interrupt type : input low level trigger
 5 constant GPIO_INTR_HIGH_LEVEL \ Interrupt type : input high level trigger

cell value /itemsizeGpioQue
global qGpioHandle

: CreateGpioQue ( - )  /itemsizeGpioQue /xQueueLength   xQueueCreate  qGpioHandle ! ;

CreateGpioQue

: init-handler ( pin - )
     0 gpio_install_isr_service  abort" gpio_install_isr_service failed"
     dup gpio-is-input
     dup  gpio-is-input-pulldown  \ resistor=pullup
     qGpioHandle @ over  gpio_isr_qhandler_add abort" gpio_isr_qhandler_add failed"
     GPIO_INTR_ANYEDGE  over   gpio_set_intr_type  abort" gpio_set_intr_type failed"
     drop  ;

InputButton init-handler

: WaitforGpioQueue ( msMaxWait - flag ) &ulValReceived qGpioHandle @ xQueueReceive ;

: EmptyQue ( - )
   2 &ulValReceived qGpioHandle @ xQueueReceive
      if   begin   15 WaitforGpioQueue   0= until
      then ;

: WaitForButton ( - state msEsp )
    EmptyQue
      begin   portMAX_DELAY WaitforGpioQueue  until
    80 ms  \ needed for debouncing without a 100 nF capacitor over the switch
    InputButton gpio-pin@    &ulValReceived @  ;

: testbutton
   cr ."  Waiting for button on GPIO: " InputButton .d
     begin   WaitForButton  ." RES: "  . .  cr    key? until
             ." test ended."  ;

testbutton
