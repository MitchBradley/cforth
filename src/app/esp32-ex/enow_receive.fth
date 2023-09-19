[ifdef]   -enow_receive.fth   bye  [then]
marker    -enow_receive.fth cr lastacf .name #19 to-column .( 24-05-2022 )

[ifndef]   esp-channel

1 constant esp-channel

: start-esp-now ( - ) \ Works if NOT connected to a wifi of a router/accespoint
    esp-channel esp-now-open  if ." esp-now-open failed" then
    esp-now-init              if ." esp-now-init failed" then ;

[then]

0         value    qHandleEnow      0 value    &ulValReceivedQueEnow

: .mac    ( &mac - )   6 bounds      do i c@ (.) type loop    space ;

: ReadQueueEnow ( MaxTicksToWait - flag )
   &ulValReceivedQueEnow qHandleEnow xQueueReceive ;

0 value >MacSender    0 value >LcountPayload    0 value >Payload

: set-pointers ( &ulValReceived - )
             dup to &ulValReceivedQueEnow    dup to >MacSender
   2 cells + dup to >LcountPayload        cell + to >Payload ;

: init-rcv-enow ( - )
    #3 cells get-max-payload-size + \ itemsize for: MacH MacL  LCount Playload
    #10                             \ QueueLength
    CreateGpioQue set-pointers
    dup to qHandleEnow set-esp-now-callback-rcv ;
\ \s
