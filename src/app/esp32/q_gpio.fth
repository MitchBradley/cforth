[ifdef]   -q_gpio.fth bye  [then]
marker    -q_gpio.fth cr lastacf .name #19 to-column .( 23-05-2022 )

1 constant GPIO_INTR_POSEDGE  \ GPIO interrupt type : rising edge
2 constant GPIO_INTR_NEGEDGE  \ GPIO interrupt type : falling edge
3 constant GPIO_INTR_ANYEDGE  \ GPIO interrupt type : both rising and falling edge

$ffffffff constant portMAX_DELAY    2   constant QUEUE_TYPE_COUNTING_SEMAPHORE

: init-handler (  Edge qHandle GpioPin - )
    0 gpio_install_isr_service
      if ." gpio_install_isr_service failed. " quit then
    tuck gpio_isr_qhandler_add drop
    gpio_set_intr_type
      if ." gpio_set_intr_type failed. " quit then  ;

\ itemsize: The number of bytes each item in the queue will require.
\ qlength:  The maximum number of items that the queue can contain.
: xQueueCreate ( itemsize qlength -- qHandleEnow )
   QUEUE_TYPE_COUNTING_SEMAPHORE -rot xQueueGenericCreate 10 vTaskDelay  ;

: CreateGpioQue ( /itemsizeQGpio /xQueueLengthQGpio - qGpioHandle &ulValReceived )
   2dup * allocate drop >r xQueueCreate r> ;

\ \s
