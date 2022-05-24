needs init-rcv-enow enow_receive.fth
needs enow-send$    enow_send.fth

[ifdef]   -enow_ack_rcv.fth   bye  [then]
marker    -enow_ack_rcv.fth  cr lastacf .name #19 to-column .( 24-05-2022 )

create esp220_mac  $78 c, $21 c, $84 c, $4F c, $D5 c, $2C c,

: escape?  ( - flag )  key?     if key #27 =     else 0    then ;
: send_ack ( - )       true sp@ cell >MacSender enow-send$  drop ;

: rcv_enow_ack  ( - )
   start-esp-now
   esp220_mac add-peer  \ sending
   init-rcv-enow        \ receiving through a que
        begin  portMAX_DELAY ReadQueueEnow
                  if  send_ack
                      cr >MacSender .mac >LcountPayload ? >Payload ?
                  then
               escape?
        until esp-wifi-stop ;

rcv_enow_ack
\ \s
