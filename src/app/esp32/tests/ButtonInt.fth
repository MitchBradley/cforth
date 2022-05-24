[ifdef]   -ButtonInt.fth bye  [then]
marker    -ButtonInt.fth cr lastacf .name #19 to-column .( 23-05-2022 )

#33 constant InputButton
0   value &ulValReceived
0   value qGpioHandle

: WaitforGpioQueue ( TickMaxWait - flag ) &ulValReceived qGpioHandle  xQueueReceive  ;

: debounce ( - )
    #175 ms  2 &ulValReceived qGpioHandle  xQueueReceive
      if   begin   #15 WaitforGpioQueue   0= until
      then ;

: WaitForButton ( - flag msEsp )
    debounce portMAX_DELAY  WaitforGpioQueue &ulValReceived @ ;

: InitButton ( - )
    cell #25 CreateGpioQue    to &ulValReceived    to qGpioHandle
    InputButton gpio-is-input-pullup
    GPIO_INTR_NEGEDGE qGpioHandle InputButton init-handler ;

 : testbutton
    cr ."  Waiting for button on GPIO: " InputButton .d
       5 0 do  cr ." Button.. "  WaitForButton   ." MS after boot: " . drop
       loop ;

decimal InitButton testbutton
\ \s
