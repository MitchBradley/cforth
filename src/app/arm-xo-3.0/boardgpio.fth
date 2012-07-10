purpose: Board-specific setup details - pin assigments, etc.

: gpio-out-clr  ( gpio# -- )  dup gpio-clr  gpio-dir-out  ;
: gpio-out-set  ( gpio# -- )  dup gpio-set  gpio-dir-out  ;

: set-gpio-directions  ( -- )
   3  h# 38 clock-unit-pa +  io!  \ Enable clocks in GPIO clock reset register
   
[ifdef] hdmi-scl-gpio#
   hdmi-scl-gpio# gpio-dir-out
   hdmi-sda-gpio# gpio-dir-out
[then]
[ifdef] compass-scl-gpio#
   compass-scl-gpio# gpio-dir-out
   compass-sda-gpio# gpio-dir-out
[then]

\   d# 01 gpio-dir-out  \ EN_USB_PWR
   audio-reset-gpio# gpio-dir-out  \ AUDIO_RESET#

[ifdef] led-storage-gpio#
   led-storage-gpio# gpio-dir-out  \ LED_STORAGE (CL2)
[then]
   vid2-gpio# gpio-dir-out         \ VID2
   en-wlan-pwr-gpio# gpio-dir-out  \ EN_WLAN_PWR
   d# 49 gpio-out-clr             \ (PWM2) DBB (CL3)
   wlan-pd-gpio# gpio-out-set     \ WLAN_PD#
   wlan-reset-gpio# gpio-out-set  \ WLAN_RESET#
   sec-trg-gpio# gpio-out-clr     \ SEC_TRG

   ec-spi-ack-gpio# gpio-set     \ EC_SPI_ACK
   ec-spi-ack-gpio# gpio-dir-out \ EC_SPI_ACK
   usb-hub-reset-gpio# gpio-dir-out \ HUB_RESET# (CL2), ULPI_HUB_RESET# (CL3)
[ifdef] soc-en-kbd-pwr-gpio#
   soc-en-kbd-pwr-gpio# gpio-clr     \ SOC_EN_KBD_PWR# (CL2), N/C (CL3)
   soc-en-kbd-pwr-gpio# gpio-dir-out \ SOC_EN_KBD_PWR#
[then]
   ec-spi-cmd-gpio# gpio-clr
   ec-spi-cmd-gpio# gpio-dir-out \ EC_SPI_CMD
[ifdef] dcon-load-gpio#
   dcon-load-gpio# gpio-dir-out \ DCONLOAD
   dcon-scl-gpio# gpio-dir-out  \ DCON_SCL
   dcon-sda-gpio#  gpio-dir-out \ DCON_SDA
[then]
   rtc-sck-gpio# gpio-out-set \ RTC_SCK
   cam-rst-gpio# gpio-out-cl  \ CAM_RST

   ec-edi-cs-gpio#   gpio-out-set \ EC_EDI_CS#
   ec-edi-mosi-gpio# gpio-dir-out \ EC_EDI_MOSI
   ec-edi-clk-gpio#  gpio-dir-out \ EC_EDI_CLK
   cam-scl-gpio# gpio-dir-out \ CAM_SCL
   cam-sda-gpio#  gpio-dir-out \ CAM_SDA
   d# 108 gpio-dir-out \ CHG_SDA (CL3)
   d# 109 gpio-dir-out \ CHG_SCL (CL3)
   d# 110 gpio-dir-out \ CHRG_AC_OK (CL3)
   d# 126 gpio-dir-out \ EN_+5V_USB_OTG#
   d# 127 gpio-dir-out \ EN_+5V_USB#
   d# 129 gpio-clr     \ EN_LCD_PWR
   d# 129 gpio-dir-out \ EN_LCD_PWR
   d# 130 gpio-clr     \ LCD_RESET#
   d# 130 gpio-dir-out \ LCD_RESET#
   d# 135 gpio-clr     \ STBY#
   d# 135 gpio-dir-out \ STBY#
\   d# 138 gpio-clr     \ LCDVCC_EN
\   d# 138 gpio-dir-out \ LCDVCC_EN

   mic-ac/dc-gpio# gpio-out-clr  \ MIC_AC#/DC
[ifdef] cam-pwrdn-gpio#
   cam-pwrdn-gpio# gpio-out-clr \ CAM_PWRDN
[then]
   emmc-rst-gpio# gpio-out-clr  \ eMMC_RST#
   cam-pwr-gpio# gpio-out-clr   \ EN_CAM_PWR
   d# 161 gpio-out-set  \                 PWR_LMT_ON# (CL3)
;

: init-mfprs
   d# 169 0  do
      mfpr-table i wa+ w@   ( code )
      dup 8 =  if           ( code )
         drop               ( )
      else                  ( code )
         i af!              ( )
      then
   loop
;
