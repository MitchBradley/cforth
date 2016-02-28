\ Driver for ADS1115 I2C 4-channel ADC

$48 value ads-slave  \ Could also be 49, 4a, 4b

: ads@  ( reg# -- value )  ads-slave 0 i2c-be-w@  dup -1 = abort" ads@ failed"  ;
: ads!  ( value reg# -- )  ads-slave i2c-be-w!  -1 = abort" ads! failed"  ;
: ads-config@  ( -- value )  1 ads@  ;
: ads-config!  ( value -- )  1 ads!  ;
: ads-conversion@  ( -- value )  0 ads@  ;
: ads-threshold!  ( high low -- )  2 ads!  3 ads!  ;


$8000 constant busy-bit
$8583 value ads-base-config  \ FS +- 2.048V, single-shot, 128 SPS, 8000 is start bit

\ This table can be edited to set different gains for different channels
\ 0: A0-A1  1: A0-A3  2: A1-A3  3: A2-A3  4: A0  5: A1  6: A2  7: A3
create ads-channels
  $8583 ,  \ 0   FS +- 2.048V, single-shot, 128 SPS
  $9583 ,  \ 1   FS +- 2.048V, single-shot, 128 SPS
  $a583 ,  \ 2   FS +- 2.048V, single-shot, 128 SPS
  $b583 ,  \ 3   FS +- 2.048V, single-shot, 128 SPS
  $c583 ,  \ 4   FS +- 2.048V, single-shot, 128 SPS
  $d583 ,  \ 5   FS +- 2.048V, single-shot, 128 SPS
  $e583 ,  \ 6   FS +- 2.048V, single-shot, 128 SPS
  $f583 ,  \ 7   FS +- 2.048V, single-shot, 128 SPS

: ads-channel@  ( n -- value )
   ads-channels swap na+ @  ads-config!
   begin  1 ms  ads-config@ busy-bit and  until
   ads-conversion@   
;
: init-ads  ( -- )  ;
