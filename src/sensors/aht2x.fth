marker -aht2x.fth lastacf .name #20 to-column .( 15-07-2026 )

\ Quite simple compared to some other temperature sensors
\ aht2x.fth for Cforth. Testet on a AHT21B1_V1.1
\ /home/pi/apps/esp232/aht20

  0 value    aht2x-Rcv$        #24 constant /aht2x-Rcv
#25 value    aht2x-Sda         #26 value    aht2x-Scl
$38 constant aht2x-I2CAdr       -1 constant aht2x-Stop
2   constant GPIO_MODE_OUTPUT  f# 2e0 f# 20e0 f** fconstant (pow(2,20)

create aht2x_initialize$ #03 c, $be c, $08 c, $00 c,
create calibrate$        #01 c, $be c,
create aht2x_measure$    #03 c, $ac c, $33 c, $00 c,
create aht2x_softreset$  #01 c, $ba c,

: rw-aht2x          ( counted-cmd-buffer - ior )
   count  aht2x-Rcv$ /aht2x-Rcv  2dup erase
   aht2x-I2CAdr aht2x-Stop i2c-write-read ;

: aht2x-get-status  ( reg -- res ) aht2x-I2CAdr 1 i2c-b@ ;

: aht2x-wait-ready? ( -- ior )
   1 #10 0 do  
      0 aht2x-get-status $80 and if   
         leave drop 0   
      then  #20 ms
   loop ;

: aht2x_temperature ( f: -- temperature )
   aht2x-Rcv$ 3 + c@ $0f and #16 lshift
   aht2x-Rcv$ 4 + c@ #8 lshift or
   aht2x-Rcv$ 5 + c@ or s>f
   (pow(2,20) f/ f# 200e0 f* f# 50e0 f- ;

: aht2x_humidity    ( f: -- humidity )
   aht2x-Rcv$ 1 + c@ #12 lshift
   aht2x-Rcv$ 2 + c@ #4 lshift or
   aht2x-Rcv$ 3 + c@ #4 rshift or s>f
   (pow(2,20) f/  f# 100e0 f* ;

: aht2x-measure  ( -- ior )  ( f: -- temperature  humidity )
    aht2x_measure$ rw-aht2x #80 ms  aht2x_temperature  aht2x_humidity ;

: aht2x-data-check ( ior1 -- ior2 )  ( f: temp humid -- temp humid )
   fover f# -49e0 f< or    fdup f# 1e0 f< or ;

: aht2x-softreset   ( -- ior ) aht2x_softreset$ rw-aht2x #40 ms ;

: aht2x-init        ( -- ior )       \ 1 time only
   #200 ms /aht2x-Rcv allocate drop to aht2x-Rcv$   
   aht2x_initialize$  rw-aht2x #10 ms 
   abort" aht2x_initialize failed."  
   calibrate$ rw-aht2x drop aht2x-Rcv$ c@ $18 <> ;  

variable aht2x-errors aht2x-errors off

: get-aht2x-data    ( -- ior )   ( f: -- temperature humidity )
   aht2x-Rcv$ 0= if 
      aht2x-init   
      abort" aht2x-init failed."  
   then   
   aht2x-measure  3 0 do  
      aht2x-data-check 0= if   
         false unloop exit     
      then
      fdrop fdrop aht2x-measure 1 aht2x-errors +!         
   loop
   aht2x-data-check ;

\ \s
