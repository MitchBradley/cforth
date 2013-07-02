purpose: Board-specific setup details - pin assigments, etc.

: set-gpio-directions  ( -- )
   3  h# 38 clock-unit-pa +  io!  \ Enable clocks in GPIO clock reset register
   
   d#   1 gpio-dir-out	\ CAM1_RST_N
   d#   2 gpio-dir-out	\ CAM2_RST_N
   d#   3 gpio-dir-out	\ MPCIE33EN
\  d#   4 gpio-dir-out	\ BB_WAKE_N
\  d#   6 gpio-dir-out	\ BB_ENABLE
\  d#   7 gpio-dir-out	\ BB_RST_N
   d#   8 gpio-dir-out	\ DVC1
   d#   9 gpio-dir-out	\ DVC2
   d#  15 gpio-dir-out	\ GPS_RST
   d#  57 gpio-dir-out	\ WIFI_PD_N
   d#  58 gpio-dir-out	\ WIFI_RST_N
   d#  62 gpio-dir-out	\ CAM2_PWREN
   d#  63 gpio-dir-out	\ LED_B
   d#  64 gpio-dir-out	\ CAM1_PWDN
   d#  68 gpio-dir-out	\ CAM2_PWDN
   d#  74 gpio-dir-out	\ LED_O_N
   d#  76 gpio-dir-out	\ LED_R_N
   d#  77 gpio-dir-out	\ LED_G
   d#  82 gpio-dir-out	\ VBUS_EN
   d#  84 gpio-dir-out	\ LDO_EN
   d#  86 gpio-dir-out	\ TP_RST
   d#  88 gpio-dir-out	\ 5V_ON
\  d#  89 gpio-dir-out	\ VPP_EN
\  d#  90 gpio-dir-out	\ VCC_EN
   d#  96 gpio-dir-out	\ HSIC_RST_N
\  d# 128 gpio-dir-out	\ LCD_RST_N
\  d# 129 gpio-dir-out	\ MPCIESHDN_N
\  d# 149 gpio-dir-out	\ MMC3_RST
;

\ 0 +lpm-edge-fall af, \ *PMIC - XXX funny number

: gpios-for-nand  ( -- )
   h# c0 d# 111 af!
   h# c0 d# 112 af!
   d# 169 d# 162  do  h# c0 i af!  loop
;
: gpios-for-emmc  ( -- )
   h# c2 d# 111 af!
   h# c2 d# 112 af!
   d# 169 d# 162  do  h# c2 i af!  loop
;
