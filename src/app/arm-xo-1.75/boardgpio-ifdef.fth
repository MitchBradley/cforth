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
[ifdef] cl3
   d# 49 gpio-out-clr             \ (PWM2) DBB (CL3)
[then]
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
   cam-rst-gpio# gpio-out-clr \ CAM_RST

[ifndef] cl2-a1
   ec-edi-cs-gpio#   gpio-out-set \ EC_EDI_CS#
   ec-edi-mosi-gpio# gpio-dir-out \ EC_EDI_MOSI
   ec-edi-clk-gpio#  gpio-dir-out \ EC_EDI_CLK
   cam-scl-gpio# gpio-dir-out \ CAM_SCL
   cam-sda-gpio#  gpio-dir-out \ CAM_SDA
[ifdef] cl3
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
[then]

   mic-ac/dc-gpio# gpio-out-clr  \ MIC_AC#/DC
[ifdef] cam-pwrdn-gpio#
   cam-pwrdn-gpio# gpio-out-clr \ CAM_PWRDN
[then]
   emmc-rst-gpio# gpio-out-clr  \ eMMC_RST#
   cam-pwr-gpio# gpio-out-clr   \ EN_CAM_PWR
[ifdef] cl3
   d# 161 gpio-out-set  \                 PWR_LMT_ON# (CL3)
[then]
[then]
;

create mfpr-table
   0 sleepi +pull-dn af,   \ GPIO_00 - Memsize0 (TP201 on B) (start with them pulled down for A and B revs)
   0 sleepi +pull-dn af,   \ GPIO_01 - Memsize1 (TP199 on B)
   no-update,        \ GPIO_02 - Not connected (TP54)
   no-update,        \ GPIO_03 - Not connected (TP53)
   0 sleep1 af,      \ GPIO_04 - COMPASS_SCL (bitbang) (CL2), CAM_SCL (CL3)
   0 sleep1 af,      \ GPIO_05 - COMPASS_SDA (bitbang) (CL2), CAM_SDA (CL3)
   0 sleepi af,      \ GPIO_06 - G_SENSOR_INT
   0 sleepi af,      \ GPIO_07 - AUDIO_IRQ#
   0 sleep0 af,      \ GPIO_08 - AUDIO_RESET#
[ifdef] cl3
   0 sleep1 af,      \ GPIO_09 - CAM_PWRDN
   0 sleep1 af,      \ GPIO_10 - CAM_RST
[else]
   0 sleepi af,      \ GPIO_09 - COMPASS_INT
   0 sleep0 af,      \ GPIO_10 - LED_STORAGE
[then]
   0 sleep0 af,      \ GPIO_11 - VID2
[ifdef] cl3
   3 sleepi af,      \ GPIO_12 - PIXDATA7
   3 sleepi af,      \ GPIO_13 - PIXDATA6
   3 sleepi af,      \ GPIO_14 - PIXDATA5
   3 sleepi af,      \ GPIO_15 - PIXDATA4
   3 sleepi af,      \ GPIO_16 - PIXDATA3
   3 sleepi af,      \ GPIO_17 - PIXDATA2
   3 sleepi af,      \ GPIO_18 - PIXDATA1
   3 sleepi af,      \ GPIO_19 - PIXDATA0
   3 sleepi af,      \ GPIO_20 - CAM_HSYNC
   3 sleepi af,      \ GPIO_21 - CAM_VSYNC
   3 sleepi af,      \ GPIO_22 - PIXMCLK
   3 sleepi af,      \ GPIO_23 - PIXCLK
[else] \ !cl3
   no-update, \ GPIO_12 - Not connected (TP52)
   no-update, \ GPIO_13 - Not connected (TP116)
   no-update, \ GPIO_14 - Not connected (TP64)
[ifdef] cl2-a1
   no-update, \ GPIO_15 - Not connected (TP55)
   0 sleepi af,      \ GPIO_16 - KEY_IN_1
   0 sleepi af,      \ GPIO_17 - KEY_IN_2
   0 sleepi af,      \ GPIO_18 - KEY_IN_3
   0 sleepi af,      \ GPIO_19 - KEY_IN_4
   0 sleepi af,      \ GPIO_20 - KEY_IN_5
   no-update, \ GPIO_21 - Not connected (TP63)
   no-update, \ GPIO_22 - Not connected (TP118)
   no-update, \ GPIO_23 - Not connected (TP61)
[else] \ !cl2-a1
[ifdef] use_mmp2_keypad_control
   0 sleepi af,      \ GPIO_15 - KEY_ROTATE
   1 sleepi af,      \ GPIO_16 - KEY_R_UP (using KP_DKIN0)
   1 sleepi af,      \ GPIO_17 - KEY_R_RT (using KP_DKIN1)
   1 sleepi af,      \ GPIO_18 - KEY_R_DN (using KP_DKIN2)
   1 sleepi af,      \ GPIO_19 - KEY_R_UP (using KP_DKIN3)
   1 sleepi af,      \ GPIO_20 - KEY_L_UP (using KP_DKIN4)
   1 sleepi af,      \ GPIO_21 - KEY_L_RT (using KP_DKIN5)
   1 sleepi af,      \ GPIO_22 - KEY_L_DN (using KP_DKIN6)
   1 sleepi af,      \ GPIO_23 - KEY_L_LF (using KP_DKIN7)
[else] \ !use_mmp2_keypad_control
   0 sleepi af,      \ GPIO_15 - KEY_ROTATE
   0 sleepi af,      \ GPIO_16 - KEY_R_UP (using gpio)
   0 sleepi af,      \ GPIO_17 - KEY_R_RT (using gpio)
   0 sleepi af,      \ GPIO_18 - KEY_R_DN (using gpio)
   0 sleepi af,      \ GPIO_19 - KEY_R_UP (using gpio)
   0 sleepi af,      \ GPIO_20 - KEY_L_UP (using gpio)
   0 sleepi af,      \ GPIO_21 - KEY_L_RT (using gpio)
   0 sleepi af,      \ GPIO_22 - KEY_L_DN (using gpio)
   0 sleepi af,      \ GPIO_23 - KEY_L_LF (using gpio)
[then] \ use_mmp2_keypad_control
[then] \ cl2-a1
[then] \ cl3
   1 sleep1 af,      \ GPIO_24 - I2S_SYSCLK   (Codec) \ wastes 40 mW if S0
   1 sleep1 af,      \ GPIO_25 - I2S_BITCLK   (Codec) \ wastes 2 mW if S0
   1 sleep0 af,      \ GPIO_26 - I2S_SYNC     (Codec)
   1 sleep1 af,      \ GPIO_27 - I2S_DATA_OUT (Codec) \ wastes 3 mW if S0
   1 sleepi af,      \ GPIO_28 - I2S_DATA_IN  (Codec) \ wastes 13 mW if S1
   1 sleep- af,      \ GPIO_29 - UART1_RXD  (debug board)
   1 sleep- af,      \ GPIO_30 - UART1_TXD  (debug board)
   0 sleepi af,      \ GPIO_31 - SD_CD# AKA SD2_CD# (via GPIO)
   no-update,        \ GPIO_32 - Not connected (TP58)
   0 sleep0 af,      \ GPIO_33 - LCDVCC_EN (CL3)
   0 sleep0 af,      \ GPIO_34 - EN_WLAN_PWR
   0 sleep0 af,      \ GPIO_35 - Not connected (TP129)
   no-update,        \ GPIO_36 - Not connected (TP115)
   1 sleepi af,      \ GPIO_37 - SDDA_D3
   1 sleepi af,      \ GPIO_38 - SDDA_D2
   1 sleepi af,      \ GPIO_39 - SDDA_D1
   1 sleepi af,      \ GPIO_40 - SDDA_D0
   1 sleep0 af,      \ GPIO_41 - SDDA_CMD
   1 sleep0 af,      \ GPIO_42 - SDDA_CLK
   3 sleepi +pull-up-alt         af,   \ GPIO_43 - SPI_MISO  (SSP1) (OFW Boot FLASH)
   3 sleep0 +pull-up-alt +medium af,   \ GPIO_44 - SPI_MOSI
   3 sleep1 +pull-up-alt +medium af,   \ GPIO_45 - SPI_CLK
   3 sleep1 +pull-up-alt +medium af,   \ GPIO_46 - SPI_FRM
   3 sleep1 +pull-up af, \ GPIO_47 - G_SENSOR_SDL (TWSI6)
   3 sleep1 +pull-up af, \ GPIO_48 - G_SENSOR_SDA
[ifdef] cl3
\  3 sleep0 af,      \ GPIO_49 - (PWM2) DBC
   0 sleep0 af,      \ GPIO_49 - (PWM2) DBC (as gpio, for now)
[else]
   no-update, \ GPIO_49 - Not connected (TP62)
[then]
   no-update, \ GPIO_50 - Not connected (TP114)
   no-update, \ GPIO_51 - Not connected (TP59)
   no-update, \ GPIO_52 - Not connected (TP113)
[ifdef] cl2-a1
   no-update, \ GPIO_53 - Not connected if nopop R124 to use TWSI6 for RTC
   no-update, \ GPIO_54 - Not connected if nopop R125 to use TWSI6 for RTC
[else]
   2 sleep1 +twsi af,      \ GPIO_53 - RTC_SCK (TWSI2) if R124 populated
   2 sleep1 +twsi af,      \ GPIO_54 - RTC_SDA (TWSI2) if R125 populated
\   0 af,      \ GPIO_53 - RTC_SCK
\   0 af,      \ GPIO_54 - RTC_SDA
[then]
   no-update, \ GPIO_55 - Not connected (TP51)
[ifdef] cl2-a1
   no-update, \ GPIO_56 - Not connected (TP60)
[else]
   0 sleepi af,      \ GPIO_56 - BOOT_DEV_SEL
[then]
   0 sleep0 af,      \ GPIO_57 - WLAN_PD#
   0 sleep0 af,      \ GPIO_58 - WLAN_RESET#

[ifdef] cl3
   2 sleep0 +fast af,      \ GPIO_59 - ULPI_D7
   2 sleep0 +fast af,      \ GPIO_60 - ULPI_D6
   2 sleep0 +fast af,      \ GPIO_61 - ULPI_D5
   2 sleep0 +fast af,      \ GPIO_62 - ULPI_D4
   2 sleep0 +fast af,      \ GPIO_63 - ULPI_D3
   2 sleep0 +fast af,      \ GPIO_64 - ULPI_D2
   2 sleep0 +fast af,      \ GPIO_65 - ULPI_D1
   2 sleep0 +fast af,      \ GPIO_66 - ULPI_D0
   2 sleep0 +fast af,      \ GPIO_67 - ULPI_STP
   2 sleep0 +fast af,      \ GPIO_68 - ULPI_NXT
   2 sleep0 +fast af,      \ GPIO_69 - ULPI_DIR
   2 sleep0 +fast af,      \ GPIO_70 - ULPI_CLK
[else]
   1 sleep0 af,      \ GPIO_59 - PIXDATA7 \ Each wastes ~15 mW if S1
   1 sleep0 af,      \ GPIO_60 - PIXDATA6
   1 sleep0 af,      \ GPIO_61 - PIXDATA5
   1 sleep0 af,      \ GPIO_62 - PIXDATA4
   1 sleep0 af,      \ GPIO_63 - PIXDATA3
   1 sleep0 af,      \ GPIO_64 - PIXDATA2
   1 sleep0 af,      \ GPIO_65 - PIXDATA1
   1 sleep0 af,      \ GPIO_66 - PIXDATA0
   1 sleepi af,      \ GPIO_67 - CAM_HSYNC  \ Wastes 40 mW if S1
   1 sleepi af,      \ GPIO_68 - CAM_VSYNC  \ Wastes 40 mW if S1
   1 sleep0 af,      \ GPIO_69 - PIXMCLK
   1 sleep0 af,      \ GPIO_70 - PIXCLK     \ Wastes 40 mW if S1
[then]

   0 sleepi af,      \ GPIO_71 - SOC_KBD_CLK  \ Was EC_SCL (TWSI3) w6 S0
   0 sleep- af,      \ GPIO_72 - SOC_KBD_DAT  \ Was EC_SDA         w6 S0
   0 sleep0 af,      \ GPIO_73 - SEC_TRG      \ Was CAM_RST on A3

   1 sleep0 af,      \ GPIO_74 - GFVSYNC 
   1 sleep0 af,      \ GPIO_75 - GFHSYNC
   1 sleep0 af,      \ GPIO_76 - GFDOTCLK
   1 sleep0 af,      \ GPIO_77 - GF_LDE
   1 sleep0 af,      \ GPIO_78 - GFRDATA0
   1 sleep0 af,      \ GPIO_79 - GFRDATA1
   1 sleep0 af,      \ GPIO_80 - GFRDATA2
   1 sleep0 af,      \ GPIO_81 - GFRDATA3
   1 sleep0 af,      \ GPIO_82 - GFRDATA4
   1 sleep0 af,      \ GPIO_83 - GFRDATA5
   1 sleep0 af,      \ GPIO_84 - GFGDATA0
   1 sleep0 af,      \ GPIO_85 - GFGDATA1
   1 sleep0 af,      \ GPIO_86 - GFGDATA2
   1 sleep0 af,      \ GPIO_87 - GFGDATA3
   1 sleep0 af,      \ GPIO_88 - GFGDATA4
   1 sleep0 af,      \ GPIO_89 - GFGDATA5
   1 sleep0 af,      \ GPIO_90 - GFBDATA0
   1 sleep0 af,      \ GPIO_91 - GFBDATA1
   1 sleep0 af,      \ GPIO_92 - GFBDATA2
   1 sleep0 af,      \ GPIO_93 - GFBDATA3
   1 sleep0 af,      \ GPIO_94 - GFBDATA4
   1 sleep0 af,      \ GPIO_95 - GFBDATA5

[ifdef] cl2-a1
   no-update, \ GPIO_96  - Not connected (TP112)
\  no-update, \ GPIO_97  - Not connected (R100 nopop) if we use TWSI2 for RTC
\  no-update, \ GPIO_98  - Not connected (R106 nopop) if we use TWSI2 for RTC
\  2 af,      \ GPIO_97  - RTC_SCK (TWSI6) if R100 populated
\  2 af,      \ GPIO_98  - RTC_SDA (TWSI6) if R106 populated
   0 sleep1 af,      \ GPIO_97  - RTC_SCK (bitbang) if R100 populated
   0 sleep1 af,      \ GPIO_98  - RTC_SDA (bitbang) if R106 populated
[else]
   0 sleepi +pull-up af, \ GPIO_96  - EXT_MIC_PLUG w80 S1
   0 sleepi af,      \ GPIO_97  - HP_PLUG w80 S1
   no-update, \ GPIO_98  - Not connected
[then]
   0 sleepi af,      \ GPIO_99  - TOUCH_SCR_INT w80 S1
   0 sleepi af,      \ GPIO_100 - DCONSTAT0 w40 S1
   0 sleepi af,      \ GPIO_101 - DCONSTAT1 w40 S1
[ifdef] cl2-a1
   no-update, \ GPIO_102 - (USIM_CLK) - Not connected (TP48)
   no-update, \ GPIO_103 - (USIM_IO) - Not connected (TP50)

   0 sleepi af,      \ GPIO_104 - ND_IO[7]
   0 sleepi af,      \ GPIO_105 - ND_IO[6]
   0 sleepi af,      \ GPIO_106 - ND_IO[5]
[else]
[ifdef] cl3
   no-update,        \ GPIO_102 - Not connected (CL3)
[else]
   1 sleep0 af,      \ GPIO_102 - CAM_RST  \ B1 and later
[then]
   1 sleep0 af,      \ GPIO_103 - EC_EDI_DO
   1 sleep1 af,      \ GPIO_104 - EC_EDI_CS#
   1 sleepi af,      \ GPIO_105 - EC_EDI_DI
   1 sleep1 af,      \ GPIO_106 - EC_EDI_CLK
[then]
   1 sleep- af,      \ GPIO_107 - (ND_IO[4]) - SOC_TPD_DAT

   1 sleep1 af,      \ GPIO_108 - CAM_SDL - Use as GPIO, bitbang w5 S0 (CL2), CHG_SDA (CL3)
   1 sleep1 af,      \ GPIO_109 - CAM_SDA - Use as GPIO, bitbang w5 S0 (CL2), CHG_SCL (CL3)

[ifdef] cl2-a1
   1 sleep0 af,      \ GPIO_110 - (ND_IO[13]) - Not connected (TP43)
   1 sleep0 af,      \ GPIO_111 - (ND_IO[8])  - Not connected (TP108)
   0 sleepi af,      \ GPIO_112 - ND_RDY[0]
[else]
   1 sleep1 +pull-up af, \ GPIO_110 - DCON_SDA w5 S0 (CL2), CHRG_AC_OK (CL3)
   2 sleep0 +fast af,    \ GPIO_111 - eMMC_D0
   2 sleep0 +fast af,    \ GPIO_112 - eMMC_CMD
[then]
   3 sleep1 +fast af,      \ GPIO_113 - (SM_RDY)  - MSD_CMD aka SD1_CMD (externally pulled up) (CL2), N/C (CL3)
   1 sleep- af,      \ GPIO_114 - G_CLK_OUT - Not connected (TP93)

   4 sleep- af,      \ GPIO_115 - UART3_TXD (J4)
   4 sleep- af,      \ GPIO_116 - UART3_RXD (J4)
   3 sleep- af,      \ GPIO_117 - UART4_RXD - Not connected on A1 (TP117)
   3 sleep- af,      \ GPIO_118 - UART4_TXD - Not connected on A1 (TP56)
   3 sleep0 af,      \ GPIO_119 - SDI_CLK  (SSP3) w70 S1
   3 sleep1 af,      \ GPIO_120 - SDI_CS#  w70 S0
   3 sleep0 af,      \ GPIO_121 - SDI_MOSI w80 S1
   3 sleepi af,      \ GPIO_122 - SDI_MISO

   1 sleep- af,      \ GPIO_123 - SLEEP_IND

   0 sleepi af,          \ GPIO_124 - DCONIRQ (CL2), USB_OTG_OC# (CL3)
\  0 af,                 \ GPIO_125 - EC_SPI_ACK
   0 sleep1 +pull-up af, \ GPIO_125 - EC_SPI_ACK

[ifdef] cl3
   0 sleep1 af,       \ GPIO_126 - EN_+5V_USB_OTG#
   0 sleep1 af,       \ GPIO_127 - EN_+5V_USB#
[else]
   3 sleep0 +fast af, \ GPIO_126 - MSD_DATA2 AKA SD1_DATA2
   3 sleep0 +fast af, \ GPIO_127 - MSD_DATA0 AKA SD1_DATA0
[then]
   0 sleepi af,       \ GPIO_128 - EB_MODE#
[ifdef] cl3
   0 sleep1 af,       \ GPIO_129 - EN_LCD_PWR
   0 sleep1 af,       \ GPIO_130 - LCD_RESET#
   0 sleepi af,       \ GPIO_131 - Not connected
   0 sleepi af,       \ GPIO_132 - Not connected
   0 sleepi af,       \ GPIO_133 - Not connected
   0 sleepi af,       \ GPIO_134 - Not connected
   0 sleep1 af,       \ GPIO_135 - STBY#
   0 sleepi af,       \ GPIO_136 - Not connected
   0 sleepi af,       \ GPIO_137 - Not connected (TP111)
   0 sleep1 af,       \ GPIO_138 - LCDVCC_EN
   0 sleepi af,       \ GPIO_139 - Not connected
   0 sleepi af,       \ GPIO_140 - Not connected
   0 sleepi af,       \ GPIO_141 - Not connected
[else]
   0 sleepi af,       \ GPIO_129 - LID_SW#
   3 sleep0 +fast af, \ GPIO_130 - MSD_DATA3 AKA SD1_DATA3
   1 sleep0 +fast af, \ GPIO_131 - SD_DATA3 AKA SD2_DATA3
   1 sleep0 +fast af, \ GPIO_132 - SD_DATA2 AKA SD2_DATA2
   1 sleep0 +fast af, \ GPIO_133 - SD_DATA1 AKA SD2_DATA1
   1 sleep0 +fast af, \ GPIO_134 - SD_DATA0 AKA SD2_DATA0
   3 sleep0 +fast af, \ GPIO_135 - MSD_DATA1 AKA SD1_DATA1
\  1 sleep0 +fast +pull-up af, \ GPIO_136 - SD_CMD AKA SD2_CMD
   1 sleep1 +fast af,      \ GPIO_136 - SD_CMD AKA SD2_CMD - CMD is pulled up externally
   no-update,         \ GPIO_137 - Not connected (TP111)
   3 sleep0 +fast af, \ GPIO_138 - MSD_CLK AKA SD1_CLK
   1 sleep0 +fast af, \ GPIO_139 - SD_CLK AKA SD2_CLK
   no-update,         \ GPIO_140 - Not connected if R130 is nopop
\  1 sleep1 af,       \ GPIO_140 - (SD_CD# if R130 is populated)
   1 sleepi af,       \ GPIO_141 - SD_WP# AKA SD2_WP#
[then]

[ifdef] cl2-a1
   no-update, \ GPIO_142 - (USIM_RSTn) - Not connected (TP49)
   0 sleep1 af,      \ GPIO_143 - ND_CS0#
[else]
   1 sleep0 af,      \ GPIO_142 - DCONLOAD (CL2), SEC_TRG (CL3)
   1 sleep0 af,      \ GPIO_143 - MIC_AC#/DC
[then]
   1 sleep1 af,      \ GPIO_144 - (ND_CS1#) - CAM_PWRDN (not connected until C1) (not connected on CL3)
[ifdef] cl2-a1
   1 sleep0 af,      \ GPIO_145 - EN_CAM_PWR
[else]
   no-update, \ GPIO_145 - Not connected
[then]
   1 sleep- af,      \ GPIO_146 - HUB_RESET# (CL2), ULPI_HUB_RESET# (CL3)

   0 sleep0 af,      \ GPIO_147 - ND_WE_N - Not connected (TP122)
   1 sleep- af,      \ GPIO_148 - ND_RE_N - SOC_EN_KBD_PWR# (CL2) (N/C on CL3)
[ifdef] cl2-a1
   0 sleep0 af,      \ GPIO_149 - ND_CLE
   0 sleep0 af,      \ GPIO_150 - ND_ALE
   1 sleep0 af,      \ GPIO_151 - DCONLOAD
[else]
   1 sleep0 af,       \ GPIO_149 - eMMC_RST#
   1 sleep0 af,       \ GPIO_150 - EN_CAM_PWR - Must be 0 in sleep state for camera off
   2 sleep0 +fast af, \ GPIO_151 - eMMC_CLK
[then]
   1 sleep0 af,       \ GPIO_152 - (SM_BELn) - Not connected (TP40)
   1 sleep0 af,       \ GPIO_153 - (SM_BEHn) - Not connected (TP105)
   1 sleepi af,       \ GPIO_154 - (SM_INT) - EC_IRQ#
   1 sleep0 +pull-dn af, \ GPIO_155 - (EXT_DMA_REQ0) - EC_SPI_CMD
   no-update,         \ GPIO_156 - PRI_TDI (JTAG)
   no-update,         \ GPIO_157 - PRI_TDS (JTAG)
   no-update,         \ GPIO_158 - PRI_TDK (JTAG)
   no-update,         \ GPIO_159 - PRI_TDO (JTAG)
   1 sleepi af,       \ GPIO_160 - (ND_RDY[1]) - SOC_TPD_CLK (CL2) (N/C on CL3)
[ifdef] cl2-a1
   1 sleep0 af,       \ GPIO_161 - ND_IO[12] - Not connected (TP 44)
   1 sleep1 af,       \ GPIO_162 - (ND_IO[11]) - DCON_SCL
   1 sleep1 +pull-up af,    \ GPIO_163 - (ND_IO[10]) - DCON_SDA
   1 sleep0 af,       \ GPIO_164 - (ND_IO[9]) - Not connected (TP106)
   0 sleep0 af,       \ GPIO_165 - ND_IO[3]
   0 sleep0 af,       \ GPIO_166 - ND_IO[2]
   0 sleep0 af,       \ GPIO_167 - ND_IO[1]
   0 sleep0 af,       \ GPIO_168 - ND_IO[0]
[else]
   1 sleep1 af,       \ GPIO_161 - DCON_SCL (CL2), PWR_LMT_ON# (CL3)
   2 sleep0 +fast af, \ GPIO_162 - eMMC_D6
   2 sleep0 +fast af, \ GPIO_163 - eMMC_D4
   2 sleep0 +fast af, \ GPIO_164 - eMMC_D2
   2 sleep0 +fast af, \ GPIO_165 - eMMC_D7
   2 sleep0 +fast af, \ GPIO_166 - eMMC_D5
   2 sleep0 +fast af, \ GPIO_167 - eMMC_D3
   2 sleep0 +fast af, \ GPIO_168 - eMMC_D1
[then]

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
