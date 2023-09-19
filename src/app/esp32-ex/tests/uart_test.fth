0 value uart_num   #130 value /RxBuf   0   value &RxBuf
/RxBuf  allocate drop to &RxBuf

: send-tx ( adr cnt -  )
   tuck swap uart_num uart-write-bytes <> abort" uart-write-bytes failed" ;

: read-rx ( - #read )  0 /RxBuf &RxBuf uart_num  uart-read-bytes ;

-1 constant UART_PIN_NO_CHANGE

: init-extra-uart ( rx-pin tx-pin uart_num -- )
    to uart_num 2>r
    0 1 0 8 115200 uart_num uart-param-config
          abort" uart-param-config failed"
    UART_PIN_NO_CHANGE UART_PIN_NO_CHANGE 2r> uart_num uart-set-pin
          abort" uart-set-pin failed"
    0 0 0 0 /RxBuf uart_num uart-driver-install
          abort" uart-driver-install failed" ;

#26 #25 2 init-extra-uart
