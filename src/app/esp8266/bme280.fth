\ Driver for BME280 temperature, humidity, barometric pressure sensor in I2C mode

$76 value bme-slave  \ or $77

: bme-b@  ( reg# -- b )  bme-slave 0 i2c-b@  ;
: bme-b!  ( b reg# -- )  bme-slave i2c-b! abort" PCA9685 write failed" ;
: rcv3  ( -- l )  false i2c-byte@  false i2c-byte@  false i2c-byte@  swap rot 0  bljoin  ;
: bme-read-setup  ( reg# -- )
   bme-slave i2c-start-write abort" BME fail"
   false bme-slave i2c-start-read abort" BME fail"
;
: bme-read-pth  ( -- pressure temperature humidity )
   $f7 bme-read-setup
   rcv3 rcv3   ( pressure temperature )
   false i2c-byte@  true i2c-byte@ swap bwjoin
;
$1e buffer: bme-compensation
: comp-b!  ( byte index -- )  bme-compensation + c!  ;
\ H1 and H3 are unsigned char but we store them as unsigned short
: bme-read-compensation  ( -- )
   \ T1..T3 P1..P9
   $88 bme-read-setup
   $18 0  do
      false i2c-byte@  i comp-b!
   loop
   true i2c-byte@  $18 comp-b!

   \ H1
   $a1 bme-b@  $18 comp-b!
   0 $19 comp-b!


   \ H2
   $e1 bme-read-setup   
   $1c $1a  do
      false i2c-byte@  i comp-b!
   loop
   \ H3
   true i2c-byte@  $1c comp-b!
   0 $1d comp-b!
;
: init-bme  ( -- )
   bme-read-compensation
   \ XXX do other stuff too?
;

0 [if]
// Returns temperature in DegC, resolution is 0.01 DegC. Output value of “5123” equals 51.23 DegC.
// t_fine carries fine temperature as global value
// t_fine is 
BME280_S32_t t_fine;
// T1 is offset, T2 is linear correction factor, T3 is quadratic correction factor
// the 4 lsbs of adc are all 0
BME280_S32_t BME280_compensate_T_int32(BME280_S32_t adc)
{
  BME280_S32_t var1, var2, T;
  var1 = < { [(adc>>3) – (T1<<1)] } * T2> >> 11;
  var2 = ((( ((adc>>4) – T1) * ((adc>>4) – T1)) >> 12) * T3) >> 14;
  t_fine = var1 + var2;
  T = (t_fine * 5 + 128) >> 8;
  return T;
}

// Returns pressure in Pa as unsigned 32 bit integer in Q24.8 format (24 integer bits and 8 fractional bits).
// Output value of “24674867” represents 24674867/256 = 96386.2 Pa = 963.862 hPa
BME280_U32_t BME280_compensate_P_int64(BME280_S32_t adc_P)
{
  BME280_S64_t var1, var2, p;
  var1 = t_fine – 128000;
  var2 = var1 * var1 * P6;
  var2 = var2 + ((var1*P5)<<17);
  var2 = var2 + ((P4)<<35);
  var1 = ((var1 * var1 * P3)>>8) + ((var1 * P2)<<12);
  var1 = (((1<<47)+var1))*(P1)>>33;
  if (var1 == 0) {
    return 0; // avoid exception caused by division by zero
  }
  p = 1048576-adc_P;
  p = (((p<<31)-var2)*3125)/var1;
  var1 = (((BME280_S64_t)P9) * (p>>13) * (p>>13)) >> 25;
  var2 = (((BME280_S64_t)P8) * p) >> 19;
  p = ((p + var1 + var2) >> 8) + (((BME280_S64_t)P7)<<4);
  return (BME280_U32_t)p;
}
// Returns humidity in %RH as unsigned 32 bit integer in Q22.10 format (22 integer and 10 fractional bits).
// Output value of “47445” represents 47445/1024 = 46.333 %RH
BME280_U32_t bme280_compensate_H_int32(BME280_S32_t adc_H)
{
  BME280_S32_t v_x1_u32r;
  v_x1_u32r = (t_fine – ((BME280_S32_t)76800));
  v_x1_u32r = (((((adc_H << 14) – (((BME280_S32_t)H4) << 20) – (((BME280_S32_t)H5) * v_x1_u32r)) +
  ((BME280_S32_t)16384)) >> 15) * (((((((v_x1_u32r * ((BME280_S32_t)H6)) >> 10) * (((v_x1_u32r * 
  a((BME280_S32_t)H3)) >> 11) + ((BME280_S32_t)32768))) >> 10) + ((BME280_S32_t)2097152)) *
  ((BME280_S32_t)H2) + 8192) >> 14));
  v_x1_u32r = (v_x1_u32r – (((((v_x1_u32r >> 15) * (v_x1_u32r >> 15)) >> 7) * ((BME280_S32_t)H1)) >> 4));
  v_x1_u32r = MAX(v_x1_u32r,0);
  v_x1_u32r = MIN(v_x1_u32r, 419430400);
  return (BME280_U32_t)(v_x1_u32r>>12);
}
[then]
