\ Example event loop for periodic ADC sampling

\ Exponential smoothing filter
#10000 value filter-denom
 #9000 value filter-alpha
0 value smoothed-adc
: filter  ( new-value -- filtered value )
   filter-denom filter-alpha - *    ( new-value'*denom )
   smoothed-adc filter-alpha *  +   ( smoothed-value*denom )
   filter-denom /                   ( smoothed-value' )  \ Rounded division
   dup to smoothed-adc              ( filtered-value )
;

#300 value adc-ms     \ The sampling period in milliseconds

0 value next-adc-time

: set-next-adc-time  ( -- )  get-msecs adc-ms + to next-adc-time  ;
: adc-time?  ( -- flag )  get-msecs next-adc-time - 0>=  ;
: check-adc  ( -- )
   adc-time?  if
      set-next-adc-time
      adc@ dup ." Current: " .d     ( val )
      ." filtered " filter  .d  cr  ( )
   then
;

#800 value led-ms     \ The sampling period in milliseconds

0 value next-led-time
0 value led-state

: set-next-led-time  ( -- )  get-msecs led-ms + to next-led-time  ;
: led-time?  ( -- flag )  get-msecs next-led-time - 0>=  ;

: check-led  ( -- )
   led-time?  if
      set-next-led-time
      led-state led-gpio gpio-pin!
      led-state 0= to led-state
   then
;

: test  ( -- )
   init-led
   set-next-led-time

   0 init-adc
   set-next-adc-time     \ Set up for first periodic sample
   adc@ drop             \ Discard the first sample which is often suspect
   adc@ to smoothed-adc  \ Prime the smoothed value with the current value

   begin
      check-led \ Blink
      check-adc \ Handle the ADC every so often
      wfi       \ The processor idles here until the next timer tick
   key? until   \ Exit when a key is pressed
;
