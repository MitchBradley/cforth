\ Driver for BME280 temperature, humidity, barometric pressure sensor in I2C mode

$76 value bme-slave  \ or $77

: bme-b@  ( reg# -- b )  bme-slave 0 i2c-b@  ;
: bme-b!  ( b reg# -- )  bme-slave i2c-b! abort" PCA9685 write failed" ;

: bme-id@  ( -- id )  $d0 bme-b@  ;  \ The result should be $60
: bme-config@  ( -- b )  $f5 bme-b@  ;
: bme-config!  ( b -- )  $f5 bme-b!  ;

: rcv3  ( -- l )  false i2c-byte@  false i2c-byte@  false i2c-byte@  swap rot 0  bljoin  ;
: bme-read-setup  ( reg# -- )
   bme-slave i2c-start-write abort" BME fail"
   false bme-slave i2c-start-read abort" BME fail"
;
: bme-read-pth  ( -- pressure temperature humidity )
   $f7 bme-read-setup
   rcv3 4 rshift  rcv3 4 rshift  ( pressure temperature )
   false i2c-byte@  true i2c-byte@ swap bwjoin
;
\needs b->w   : b->w  ( b -- w )  dup $80 and  if  $ff00 or  then  ;
\needs le-w@  : le-w@  ( adr -- w )  dup c@ swap 1+ c@ bwjoin  ;
\needs le-w!  : le-w!  ( w adr -- )  >r wbsplit  r@ 1+ c!  r> c!  ;

$24 buffer: bme-compensation
: comp-b!  ( byte index -- )  bme-compensation + c!  ;
: comp-w!  ( word index -- )  bme-compensation + le-w!  ;

\ We store everything as a short
: bme-read-compensation  ( -- )
   \ T1..T3 P1..P9
   $88 bme-read-setup
   $17 0  do
      false i2c-byte@  i comp-b!
   loop
   true i2c-byte@  $17 comp-b!

   \ H1
   $a1 bme-b@  $18 comp-w!


   \ H2 (signed)
   $e1 bme-read-setup   
   $1c $1a  do
      false i2c-byte@  i comp-b!  \ bytes at $e1 and $e2
   loop

   \ H3 (unsigned)
   false i2c-byte@  $1c comp-w!   \ at $e3

   \ H4 (signed)
   false i2c-byte@  4 <<         ( e4-byte<<4 )
   false i2c-byte@  tuck         ( e5-byte e4-byte<<4 e5-byte )
   $f and or  $1e comp-w!        ( e5-byte )
   
   \ H5 (signed)
   4 >>                                 ( e5-byte[7:4]>>4 )
   false i2c-byte@ 4 << or $20 comp-w!  ( )
   
   \ H6 (signed)
   true i2c-byte@ b->w  $22 comp-w!
;
: bme-reset  ( -- )  $b6 $e0 bme-b!  ;
: bme-set-mode  ( mode pressure temp humidity -- )
   $f2 bme-b!   ( mode pressure temp )
   3 lshift or  2 lshift or  $f4 bme-b!
;
: init-bme  ( -- )
   bme-id@ $60 <> abort" BME280 ID mismatch"
   bme-read-compensation
   1 1 1 1 bme-set-mode   \ Forced sampling, 1x for each of p, t, h
;

: comp-w@  ( offset -- w )  bme-compensation + le-w@  ;
: comp-<w@  ( offset -- w )  comp-w@ w->n  ;
: dig-t1  ( -- uw )  0 comp-w@  ;
: dig-t2  ( -- w )  2 comp-<w@  ;
: dig-t3  ( -- w )  4 comp-<w@  ;
: dig-p1  ( -- w )  6 comp-w@  ;
: dig-p2  ( -- w )  8 comp-<w@  ;
: dig-p3  ( -- w )  $0a comp-<w@  ;
: dig-p4  ( -- w )  $0c comp-<w@  ;
: dig-p5  ( -- w )  $0e comp-<w@  ;
: dig-p6  ( -- w )  $10 comp-<w@  ;
: dig-p7  ( -- w )  $12 comp-<w@  ;
: dig-p8  ( -- w )  $14 comp-<w@  ;
: dig-p9  ( -- w )  $16 comp-<w@  ;
: dig-h1  ( -- w )  $18 comp-w@  ;
: dig-h2  ( -- w )  $1a comp-<w@  ;
: dig-h3  ( -- w )  $1c comp-w@  ;
: dig-h4  ( -- w )  $1e comp-<w@  ;
: dig-h5  ( -- w )  $20 comp-<w@  ;
: dig-h6  ( -- w )  $22 comp-<w@  ;

\ : u*scl  ( n1 n2 shift -- )  >r u* r> rshift  ;
: *scl  ( n1 n2 shift -- )  >r * r> >>a  ;
0 value tfine

: comp-temperature  ( n -- C*100 )
   dig-t1 4 lshift  -                ( x )
   dup dig-t2 $4000 */               ( x linear-term )
   swap dup $100000 */               ( linear-term  x^2 )
   dig-t3 $4000 */                   ( linear-term quadratic-term )
   + dup to tfine                    ( tfine )
   5 *  $80 +  8 rshift              ( C*100 )
;

\needs u/ : u/  ( u1 u2 -- u3 )  0 swap um/mod nip  ;

\ Pressure in Pa
: comp-pressure  { raw ; t tsq y z -- pa }
   \ t is an offset relative to 25 degrees C, scaled down 1 bit
   \ t = (((s32)tfine) >> 01) - (s32)64000;
   tfine 2/  #64000 -  to t

   \ tsq is x1^2, scaled down 2 more bits
   \ tsq = ((x1 >> 02) * (x1 >> 02)) >> 11;
   t 2 >>a  dup #11 *scl  to tsq

   \ y is  p6*tsq + p5*t + p4, again with scaling
   \ y = (tsq * ((s32)P6)) + ((t * ((s32)P5)) << 01)
   \ y = (y >> 02) + (((s32)P4) << 16);

   tsq dig-p6 *                     ( y )
   t dig-p5 * 2* +                  ( y' )
   2 >>a  dig-p4 #16 << +  to y     ( )

   \ z is  (p3*tsq + p2*t + 2^15) * p1
   \ z = ((P3 * (tsq >> 2)) >> 03;
   \ z += ((s32)P2) * t) >> 01;
   \ z >>= 18;
   \ z = (((32768 + z)) * ((s32)P1)) >> 15;

   tsq 2 >>a  dig-p3  3 *scl        ( n )
   t  dig-p2  1 *scl  +             ( n' )
   #18 >>a                          ( n' )
   $8000 +                          ( n' )
   dig-p1 #15 *scl  to z           ( )
  
   z 0=  if  drop -1 exit  then    ( )

   \ pressure = (((u32)(((s32)1048576) - uncomp_pressure_s32) - (y >> 12))) * 3125;
   #1048576 raw -                   ( p )
   y #12 >>a  -                     ( p' )
   #3125 *                          ( p' )

   \ Calculate 2 * p / z without overflow by applying the factor of 2
   \ at the appropriate time.
   dup $80000000 u<  if             ( p )
      \ pressure = (pressure << 01) / ((u32)z)
      2* z u/                       ( p' )
   else
      \ pressure = (pressure / (u32)z) * 2;
      z u/ 2*                       ( p' )
   then                             ( p )

   \ psq = ((pressure>>03) * (pressure>>03)) >> 13;
   dup 3 >> dup #13 *scl            ( p psq )

   \ x4 = ( {s32}P9 * ({s32}prsq )) >> 12;
   dig-p9 #12 *scl                  ( p psq*P9 )

   \ x5 = (({s32}(pressure >> 02)) * ({s32}P8)) >> 13;
   over 2 >>a  dig-p8 #13 *scl      ( p psq*P9 p*P8 )

   \ pressure = (u32)((s32)pressure + ((psq*P9 + p*P8 + P7) >> 04));
   + dig-p7 + 4 >>a  +              ( pressure )
;
[ifdef] float
0E0 fvalue ftfine
: fcoef  ( scale dig-pn -- f )  float fscale  ;
: fcomp-temperature  ( rawt -- ftemp )
   float #-14 fscale             ( frawt )
   #-10 dig-t1 fcoef f-          ( fofft )
   fdup  fdup f*                 ( fofft fofftsq )
   #-6 dig-t3 fcoef f*           ( fofft fquadratic )
   fswap dig-t2 float f*         ( fquadratic flinear )
   f+ to ftfine                  ( )
   ftfine 5120E f/               ( ftemp )
;
: fcomp-pressure  ( rawp -- fpa )
   ftfine -1 fscale  64000E f-        ( rawp fofft )
   fdup  fdup f*                      ( rawp fofft fofftsq )
   fover 1 dig-p5 fcoef f*            ( rawp fofft fofftsq fofftlinear )
   fover #-15 dig-p6 fcoef f*         ( rawp fofft fofftsq fofftlinear fofftquadratic )
   f+ -2 fscale                       ( rawp fofft fofftsq fv2 )
   #16 dig-p4 fcoef f+  f>r           ( rawp fofft fofftsq  r: fv2 )

   #-19 dig-p3 fcoef f*               ( rawp fofft fquadratic r: fv2 )
   fswap dig-p2 float f*  f+          ( rawp fv1 r: fv2 )
   #-35 fscale  1E0 F+                ( rawp fv1' r: fv2 )
   dig-p1 float f*                    ( rawp fv1 r: fv2 )
   fdup f0=  if                       ( rawp fv1 r: fv2 )
      drop fdrop fr> fdrop 0E0 exit   ( -- 0E0 )
   then                               ( rawp fv1 r: fv2 )
   1048576E0 float f-                 ( fv1 fp r: fv2 )
   fr> #-12 fscale f-                 ( fv1 fp' )
   6250E0 f*  fswap f/                ( fp' )
   fdup fdup f*                       ( fp fpsq )
   #-31 dig-p9 fcoef f*               ( fp fquadratic )
   fover #-15 dig-p8 fcoef f*         ( fp fquadratic flinear )
   f+  dig-p7 float f+  #-4 fscale    ( fp fquadratic+flinear+p7/ )
   f+                                 ( fpa )
;
: fcomp-humidity  ( rawh -- f%rh )
   ftfine 76800E f-               ( rawh fofft )
   fdup #-26 dig-h3 fcoef f*      ( rawh fofft fmul )
   1E0 f+                         ( rawh fofft fmul' )
   fover #-26 dig-h6 fcoef f* f*  ( rawh fofft fmul' )
   1E0 f+                      ( rawh fofft fmul' )
   #-16 dig-h2 fcoef f*        ( rawh fofft fmul' )
   fswap #-14 dig-h5 fcoef f*  ( rawh fmul fh )
   #6 dig-h4 fcoef f+          ( rawh fmul fh' )
   float fswap f-              ( fmul fh' )
   f*                          ( fh' )
   fdup #-16 dig-h1 fcoef f*   ( fh fh1 )
   1E0 fswap f-  f*            ( f%rh )
   100E0 fmin 0E0 fmax         ( f%rh' )
;
[then]
\ Returns %RelHum as unsigned Q22.10 (22 integer and 10 fractional bits).
\ Output value of “47445” represents 47445/1024 = 46.333 %RH

: comp-humidity  { raw ; t factor -- %rh*1024 }
   \ x = (t_fine – ((s32)76800));
   tfine [ 5120 15 * ] literal - to t   \ Offset from 15 degrees

   t dig-h6 #10 *scl             ( factor )
   t dig-h3 #11 *scl $8000 +  *  ( factor' )
   #10 rshift  $200000 +         ( factor' )
   dig-h2 *                      ( factor' )
   $2000 + #14 >>a               ( factor' )  \ Round
   to factor                     ( )

   raw #14 lshift                ( y )
   dig-h4 #20 lshift  -          ( y' )
   t dig-h5 *  -                 ( y' )
   $4000 + #15 >>a               ( y' )  \ Round

   factor *                      ( y' )

   dup #15 >>a dup 7 *scl        ( y ysq )
   dig-h1 4 *scl  -              ( y' )

   0 max  #419430400 min         ( y' )
   #12 >>                        ( %rh )   
;
: pht  ( -- pa C*100 %rh*1024 )
   1 1 1 1 bme-set-mode   \ Forced sampling, 1x for each of p, t, h
   bme-read-pth  ( p t h )
   swap comp-temperature >r  ( p h r: C*100 )
   swap comp-pressure        ( h pa r: C*100 )
   swap comp-humidity r>     ( pa %rh*1024 C*100 )
;
: .##  ( n -- )
   push-decimal
   <# u# u# '.' hold u#s u#> type
   pop-base
;
: >>round  ( n bits -- )  >r  1 r@ 1- lshift +  r> >>a  ;
: .bme  ( -- )
   pht         ( pa %rh*1024 C*100 )
   push-decimal
   .## ." C  "   ( pa %rh*1024 )
   #10 >>round (.) type ." %  "     ( pa )
   dup (.) type  ."  Pa  "          ( pa )
   #100 #101324 */  .## ."  atm"  cr
   pop-base
;

0 [if]
BME280_U32_t bme280_compensate_H_int32(BME280_S32_t adc_H)
{
  s32 y, f, g, ysq;

  y = (adc_H<<14) – ;
  y -= {s32}H4 << 20;
  y -= {s32}H5 * x;
  y += 16384; // Round
  y >>= 15;

  f = (x * {s32}H6) >> 10;
  f *= ((x * {s32}H3) >> 11) + (s32)32768;
  f >>= 10;
  f += (s32)2097152;

  y *= f;
  y *= (s32)H2;
  y += 8192;
  y >>= 14;

  ysq = ((y >> 15) * (y >> 15)) >> 7;
  g = (ysq * {s32}H1) >> 4;
  y -= g;

  y = MAX(y,0);
  y = MIN(y, 419430400);
  return (BME280_U32_t)(y>>12);
}
[then]
