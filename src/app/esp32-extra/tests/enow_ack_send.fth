[ifdef]   -enow_ack.fth   bye  [then]
marker    -enow_ack.fth cr lastacf .name #19 to-column .( 24-05-2022 )

needs init-rcv-enow enow_receive.fth
needs enow-send$    enow_send.fth

3 constant #attempts    #40 constant MaxTicksToWait

: enow-send-wait-ack$   { adr cnt esp_mac -- flag }
   cr 0 #attempts 0               \ It takes about 2-30 ms to send and to get a
     do   adr dup ? cnt esp_mac      \ confirmation for 1 32 bits number
          ms@ here !
              enow-send$ MaxTicksToWait ReadQueueEnow
          ms@ here @ -  . ." Ms. "
             if drop true leave
             else ." Retry "
             then
     loop ;

: escape? ( - flag )    key?     if key #27 =     else 0    then ;

: esp-send-test ( - )
   start-esp-now
   to_all_mac   add-peer \ sending
   init-rcv-enow         \ receiving
   0
    begin  esp-wifi-start
           1+ dup sp@ cell    to_all_mac
           enow-send-wait-ack$  0=
              if   ." Not confirmed"
              then
           drop
           10 ms  \ Need at least 6 ms to send data and prevent a buffer overflow
           esp-wifi-stop    100 ms    escape?
     until drop ;

 decimal esp-send-test

