\ Test for ADC
: test-adc  ( -- )
   ." Initializing ADC in TOUT mode" cr
   8 0 adc-init abort" ADC init failed"
   adc0@ .d cr

   adc-deinit
   ." Initializing ADC in VDD33 mode" cr
   ." This will probably fail unless you have pre-configured for that mode" cr
   8 1 adc-init abort" ADC init failed"
   adc0@ .d cr
   adc-deinit
;

   
