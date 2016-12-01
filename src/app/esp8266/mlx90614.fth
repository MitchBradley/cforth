\ Driver for Melexis MLX90614 Non-Contact Infra Red Thermometer TO-39

$5a value mlx-slave

: mlx-w@  ( reg -- val )  mlx-slave 0 i2c-le-w@  ;

\ read flags; bit 4 is power-on-reset (typical 150ms) active low
: flags@  ( -- flags )  f0 mlx-w@  ;

\ get raw data from ir sensor
: raw@  ( -- b )  4 mlx-w@  ;

\ get temperature ambient, in units of 0.02 degrees kelvin
: ta@  ( -- TaK0.02 )  6 mlx-w@  ;

\ get temperature object, in units of 0.02 degrees kelvin
: to@  ( -- ToK0.02 )  7 mlx-w@  ;

\ convert to millidegrees celcius
: k>c  ( K0.02 -- mC )  #20  * #273150 -  ;

\ format or print a millidegrees celcius value as degrees celcius
: (.c)  ( mC -- $ )  push-decimal  <# u# u# u# '.' hold u#s u#> pop-base  ;
: .c  ( mC -- )  (.c)  type space  ;

\ print temperatures
: .ambient  ta@  k>c  .c  ;
: .object  to@  k>c  .c  ;

: watch-temperature
   begin
      get-ticks .d  flags@ . raw@ . .ambient  .object  cr
      d# 100 ms
      key?
   until
;
