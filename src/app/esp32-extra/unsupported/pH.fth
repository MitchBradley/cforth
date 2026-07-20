\ pH Measurement
\ Assumes:
\ Standard pH probe with sensitivity of 59.16 mV at 25 C
\ Amplifier has Unity gain
\ Probe is biased to 1.0V so 1.0V out is pH 7
\ Connected to ADC1 channel 6 on ESP32

\ The ADC has a 0.1V bias such that count 0 is equivalent to 0.1V
\ At atten 2 setting, the maximum count 2047 occurs at 1.9V
\ The gain factor is thus (1.9V - 0.1V)/2048

: counts>V  ( counts -- f.volts )
   float  f# 2048 f/  f# 1.8 f*  f# 0.1 f+
;

\ Modify this via calibration so an ADC reading of 1.0V gives this value
f# 6.75  fvalue foffset

: pH-factor  ( -- f.V )  \ Should be scaled according to temperature
   f# 0.05916
;

6 value pH-adc-channel

: read-pH*10  ( -- ph*10 )
   pH-adc-channel adc@   ( counts )
   counts>V              ( f.volts )
   f# 1.0 fswap f-       ( f.deltaV )
   pH-factor f/          ( f.delta-pH )
   foffset f+            ( f.pH )
   f# 10. f*             ( f.pH*10 )
   fround int            ( pH*10 )
;

: init-pH  ( -- )
   2 adc-width!   \ 11 bit precision
   2 pH-adc-channel adc-atten!  \ 2 is for 6dB attenuation - range from 0 - 1.8V
;
