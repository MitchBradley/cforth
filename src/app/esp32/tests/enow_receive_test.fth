needs init-rcv-enow enow_receive.fth

[ifdef]   -enow_receive_test.fth   bye  [then]
marker    -enow_receive_test.fth cr lastacf .name #19 to-column .( 24-05-2022 )

: escape? ( - flag )    key?     if key #27 =     else 0    then ;

: rcv_enow  ( - )
   start-esp-now init-rcv-enow   \ Receiving through a que
        begin  portMAX_DELAY ReadQueueEnow
                  if  cr >MacSender .mac >LcountPayload ? >Payload ?
                  then
               escape?
        until esp-wifi-stop ;

rcv_enow
