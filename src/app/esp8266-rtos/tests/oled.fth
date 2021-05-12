fl ${CBP}/lib/fb.fth
fl ${CBP}/lib/font5x7.fth
fl ${CBP}/lib/ssd1306.fth
0 constant i2c-master-mode
: init-wemos-oled  ( -- )
   \ These are the commonly used I2C pins on Wemos D1 Mini shields.
   \ SCL  SDA
   pin-d1 pin-d2 i2c-open abort" I2C open failed"
   ssd-init
;

: test-wemos-oled  ( -- )
   init-wemos-oled
   #20 0  do  i (u.)  fb-type "  Hello" fb-type  fb-cr  loop
;
