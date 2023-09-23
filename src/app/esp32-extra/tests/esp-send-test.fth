needs enow-send$    enow_send.fth

\ create esp218_mac  $A8 c, $21 c, $84 c, $4F c, $89 c, $F0 c,
\ start-esp-now esp218_mac add-peer    char X sp@ 1 esp218_mac enow-send$ drop

: escape? ( - flag )    key?     if key #27 =     else 0    then ;

: esp-send-test ( - )
   start-esp-now to_all_mac add-peer
   0
    begin  esp-wifi-start
           1+ dup sp@ cell to_all_mac enow-send$  cr .
           10 ms  \ Need at least 6 ms to send data and prevent a buffer overflow
           esp-wifi-stop    100 ms    escape?
     until drop ;

esp-send-test


