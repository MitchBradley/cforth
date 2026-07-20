[ifdef]   -ButtonInt.fth bye  [then]
marker -ButtonInt.fth cr lastacf .name #20 to-column .( 23-05-2022 )

needs CreateGpioQue q_gpio.fth

#27 constant InputButton
0   value &ulValReceived
0   value qGpioHandle

: WaitforGpioQueue ( TickMaxWait - flag ) &ulValReceived qGpioHandle  xQueueReceive  ;

: debounce ( - )
    #175 ms  2 &ulValReceived qGpioHandle  xQueueReceive
      if   begin   #15 WaitforGpioQueue   0= until
      then ;

: WaitForButton ( - flag msEsp )
    debounce -1  WaitforGpioQueue &ulValReceived @ ;
 
: InitButton ( - )
    cell #25 CreateGpioQue    to &ulValReceived    to qGpioHandle
    InputButton gpio-is-input-pullup
    GPIO_INTR_NEGEDGE qGpioHandle InputButton init-handler ;

 : testbutton  \ Waits until InputButton get low
    cr ."  Waiting for button on GPIO: " InputButton .d
       5 0 do  cr ." Button.. "  WaitForButton   ." MS after boot: " . drop
       loop ;

decimal InitButton testbutton
\ \s
