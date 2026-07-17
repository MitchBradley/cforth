marker -esp_receive_test.fth lastacf .name #20 to-column .( 17-05-2026 ) 

needs esp-now-add-peer espnow.fth  \ see ~/cforth/src/app/esp32-extra/

\ create mac133 $78 c, $62 c, $63 c, $BF c, $27 c, $48 c,

#27 dup constant gpio-pin gpio-is-output  

: .buffer ( &esp-now-data-buffer -- )
   cr 1 gpio-pin gpio-pin!
   ." From: " dup .macadress
   ."  Data: " >&CountPayload dup @ . lcount ." >"  type ." <"
   0 gpio-pin  gpio-pin!
;
: SendResponseBack ( -- ) 
   #1 false  &esp-now-data-buffer dup >r esp-now-add-peer
   #10 s" Packet received" r@ esp-now-send  drop
   r> esp-now-del-peer drop
;
: test-receiver ( -- )
   &esp-now-receive-buffer 0= if
      #1 #255 init-esp-receiver 
   then
   begin
      esp-now-read dup if
         .buffer SendResponseBack
      else
         drop #10 vtaskdelay
      then
      key?
   until
   key drop
; 

decimal test-receiver 
 
