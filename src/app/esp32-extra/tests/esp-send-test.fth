marker -esp-send-test.fth lastacf .name #20 to-column .( 17-05-2026 ) 
needs esp-now-add-peer espnow.fth  \ See ~/cforth/src/app/esp32-extra/

\ create mac233 $98 c, $62 c, $E3 c, $BF c, $27 c, $B8 c,

#255 value /esp-send-buffer \  Max #1470
1 value esp-now-channel
0 value &esp-send-buffer
variable #esp-sent 0 #esp-sent !

: .response ( -- )
   esp-now-read dup if
      ." From: " dup .macadress
      ."  Data: " >&CountPayload dup @ . lcount ." >"  type ." <"
   else
      drop ." No response"
   then
;
: esp-now-send$ ( mac-addr -- addr cnt )
   >r 1 #esp-sent dup @ (.) &esp-send-buffer place +! 
   s"  Hello ESP-NOW! "  &esp-send-buffer +place 
   #100 &esp-send-buffer count r> esp-now-send drop
; 
: send-test  ( mac-addr -- )
   >r &esp-now-receive-buffer 0= if 
      esp-now-channel #255 tuck init-esp-receiver
      allocate drop to &esp-send-buffer 
   then
   esp-now-channel false r@ esp-now-add-peer  
   begin 
      key? 0= 
   while
      cr r@ esp-now-send$ #100 vtaskdelay
      .response
      #900 vtaskdelay
   repeat
   r> esp-now-del-peer drop key drop 
;

decimal to_all_mac send-test  

