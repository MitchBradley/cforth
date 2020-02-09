purpose: Board-specific setup details - pin assigments, etc.

: gpio-out-clr  ( gpio# -- )  dup gpio-clr  gpio-dir-out  ;
: gpio-out-set  ( gpio# -- )  dup gpio-set  gpio-dir-out  ;

: set-gpio-directions  ( -- )
   3  h# 38 clock-unit-pa +  io!  \ Enable clocks in GPIO clock reset register
   
[ifdef] hdmi-scl-gpio#
   hdmi-scl-gpio#       gpio-dir-out
   hdmi-sda-gpio#       gpio-dir-out
[then]

[ifdef] compass-scl-gpio#
   compass-scl-gpio#    gpio-dir-out
   compass-sda-gpio#    gpio-dir-out
[then]

\  d# 01 gpio-dir-out  \ EN_USB_PWR

   audio-reset-gpio#    gpio-dir-out

[ifdef] led-storage-gpio#
   led-storage-gpio#    gpio-dir-out
[then]

[ifdef] mmp3
   vid2-gpio#           gpio-out-set
[else]
   vid2-gpio#           gpio-out-clr
[then]

   en-wlan-pwr-gpio#    gpio-dir-out
[ifdef] wlan-pd-gpio#
   wlan-pd-gpio#        gpio-out-set
[then]
   wlan-reset-gpio#     gpio-out-set
   sec-trg-gpio#        gpio-out-clr

   usb-hub-reset-gpio#  gpio-dir-out

[ifdef] soc-en-kbd-pwr-gpio#
   soc-en-kbd-pwr-gpio# gpio-out-clr
[then]

   ec-spi-cmd-gpio#     gpio-out-clr
   ec-spi-ack-gpio#     gpio-out-set

[ifdef] dcon-load-gpio#
   dcon-load-gpio#      gpio-dir-out
   dcon-scl-gpio#       gpio-dir-out
   dcon-sda-gpio#       gpio-dir-out
[then]

   rtc-scl-gpio#        gpio-out-set
   cam-rst-gpio#        gpio-out-clr

[ifdef] ec-edi-cs-gpio#
   ec-edi-cs-gpio#      gpio-out-set
   ec-edi-mosi-gpio#    gpio-dir-out
   ec-edi-clk-gpio#     gpio-dir-out
[then]

[ifdef] cam-scl-gpio#
   cam-scl-gpio#        gpio-dir-out
   cam-sda-gpio#        gpio-dir-out
[then]

[ifdef] mic-ac/dc-gpio#
   mic-ac/dc-gpio#      gpio-out-clr
[then]

[ifdef] cam-pwrdn-gpio#
   cam-pwrdn-gpio#      gpio-out-clr
[then]

[ifdef] emmc-rst-gpio#
   emmc-rst-gpio#       gpio-out-clr
[then]

[ifdef] en-emmc-pwr-gpio#
   en-emmc-pwr-gpio#    gpio-out-set
[then]

[ifdef] cam-pwr-gpio#
   cam-pwr-gpio#        gpio-out-clr
[then]

[ifdef] sd-pwroff-gpio#
   sd-pwroff-gpio#      gpio-out-set  \ Power initially off (1)
[then]

[ifdef] sd-1.8vsel-gpio#
   sd-1.8vsel-gpio#     gpio-out-clr  \ Default to 3.3V (0)
[then]
;
