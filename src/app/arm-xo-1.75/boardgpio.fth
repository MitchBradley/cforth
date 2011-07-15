purpose: Board-specific setup details - pin assigments, etc.

: set-gpio-directions  ( -- )
   3  h# 38 clock-unit-pa +  l!  \ Enable clocks in GPIO clock reset register
   
   d# 01 gpio-dir-out  \ EN_USB_PWR
   d# 04 gpio-dir-out  \ COMPASS_SCL
   d# 05 gpio-dir-out  \ COMPASS_SDA
   d# 08 gpio-dir-out  \ AUDIO_RESET#
   d# 10 gpio-dir-out  \ LED_STORAGE
   d# 11 gpio-dir-out  \ VID2
   d# 33 gpio-dir-out  \ EN_MSD_PWR
   d# 34 gpio-dir-out  \ EN_WLAN_PWR
   d# 35 gpio-dir-out  \ EN_SD_PWR
   d# 57 gpio-set      \ WLAN_PD#
   d# 57 gpio-dir-out  \ WLAN_PD#
   d# 58 gpio-set      \ WLAN_RESET#
   d# 58 gpio-dir-out  \ WLAN_RESET#
   d# 73 gpio-dir-out  \ CAM_RST

   d# 125 gpio-set     \ EC_SPI_ACK
   d# 125 gpio-dir-out \ EC_SPI_ACK
   d# 146 gpio-dir-out \ HUB_RESET#
   d# 148 gpio-clr     \ SOC_EN_KBD_PWR#
   d# 148 gpio-dir-out \ SOC_EN_KBD_PWR#
   d# 155 gpio-clr
   d# 155 gpio-dir-out \ EC_SPI_CMD
[ifdef] cl2-a1
   d# 97 gpio-dir-out  \ RTC_SCK
   d# 98 gpio-dir-out  \ RTC_SDA
   d# 145 gpio-dir-out \ EN_CAM_PWR
   d# 151 gpio-dir-out \ DCONLOAD
   d# 162 gpio-dir-out \ DCON_SCL
   d# 163 gpio-dir-out \ DCON_SDA
[else]
   d#  53 gpio-set     \ RTC_SCK
   d#  53 gpio-dir-out \ RTC_SCK
   d# 104 gpio-set     \ EC_EDI_CS#
   d# 104 gpio-dir-out \ EC_EDI_CS#
   d# 105 gpio-dir-out \ EC_EDI_MOSI
   d# 106 gpio-dir-out \ EC_EDI_CLK
   d# 110 gpio-dir-out \ DCON_SDA
   d# 142 gpio-dir-out \ DCONLOAD
   d# 143 gpio-clr     \ MIC_AC#/DC
   d# 143 gpio-dir-out \ MIC_AC#/DC
   d# 149 gpio-clr     \ eMMC_RST#
   d# 149 gpio-dir-out \ eMMC_RST#
   d# 150 gpio-clr     \ EN_CAM_PWR
   d# 150 gpio-dir-out \ EN_CAM_PWR
   d# 161 gpio-dir-out \ DCON_SCL
[then]
;

create mfpr-table
   no-update, \ GPIO_00 - Not connected (TP57)
   0 af,      \ GPIO_01 - EN_USB_PWR
   no-update, \ GPIO_02 - Not connected (TP54)
   no-update, \ GPIO_03 - Not connected (TP53)
   0 af,      \ GPIO_04 - COMPASS_SCL (bitbang)
   0 af,      \ GPIO_05 - COMPASS_SDA (bitbang)
   0 af,      \ GPIO_06 - G_SENSOR_INT
   0 af,      \ GPIO_07 - AUDIO_IRQ#
   0 af,      \ GPIO_08 - AUDIO_RESET#
   0 af,      \ GPIO_09 - COMPASS_INT
   0 af,      \ GPIO_10 - LED_STORAGE
   0 af,      \ GPIO_11 - VID2
   no-update, \ GPIO_12 - Not connected (TP52)
   no-update, \ GPIO_13 - Not connected (TP116)
   no-update, \ GPIO_14 - Not connected (TP64)
[ifdef] cl2-a1
   no-update, \ GPIO_15 - Not connected (TP55)
   0 af,      \ GPIO_16 - KEY_IN_1
   0 af,      \ GPIO_17 - KEY_IN_2
   0 af,      \ GPIO_18 - KEY_IN_3
   0 af,      \ GPIO_19 - KEY_IN_4
   0 af,      \ GPIO_20 - KEY_IN_5
   no-update, \ GPIO_21 - Not connected (TP63)
   no-update, \ GPIO_22 - Not connected (TP118)
   no-update, \ GPIO_23 - Not connected (TP61)
[else]
   0 af,      \ GPIO_15 - KEY_ROTATE
   1 af,      \ GPIO_16 - KEY_R_UP (using KP_DKIN0)
   1 af,      \ GPIO_17 - KEY_R_RT (using KP_DKIN1)
   1 af,      \ GPIO_18 - KEY_R_DN (using KP_DKIN2)
   1 af,      \ GPIO_19 - KEY_R_UP (using KP_DKIN3)
   1 af,      \ GPIO_20 - KEY_L_UP (using KP_DKIN4)
   1 af,      \ GPIO_21 - KEY_L_RT (using KP_DKIN5)
   1 af,      \ GPIO_22 - KEY_L_DN (using KP_DKIN6)
   1 af,      \ GPIO_23 - KEY_L_LF (using KP_DKIN7)
[then]
   1 af,      \ GPIO_24 - I2S_SYSCLK   (Codec)
   1 af,      \ GPIO_25 - I2S_BITCLK   (Codec)
   1 af,      \ GPIO_26 - I2S_SYNC     (Codec)
   1 af,      \ GPIO_27 - I2S_DATA_OUT (Codec)
   1 af,      \ GPIO_28 - I2S_DATA_IN  (Codec)
   1 af,      \ GPIO_29 - UART1_RXD  (debug board)
   1 af,      \ GPIO_30 - UART1_TXD  (debug board)
   0 af,      \ GPIO_31 - SD_CD# AKA SD2_CD# (via GPIO)
   no-update, \ GPIO_32 - Not connected (TP58)
   0 af,      \ GPIO_33 - EN_MSD_PWR AKA EN_SD1_PWR
   0 af,      \ GPIO_34 - EN_WLAN_PWR
   0 af,      \ GPIO_35 - EN_SD_PWR AKA EN_SD2_PWR
   no-update, \ GPIO_36 - Not connected (TP115)
   1 af,      \ GPIO_37 - SDDA_D3
   1 af,      \ GPIO_38 - SDDA_D2
   1 af,      \ GPIO_39 - SDDA_D1
   1 af,      \ GPIO_40 - SDDA_D0
   1 af,      \ GPIO_41 - SDDA_CMD
   1 af,      \ GPIO_42 - SDDA_CLK
   3 af,      \ GPIO_43 - SPI_MISO  (SSP1) (OFW Boot FLASH)
   3 af,      \ GPIO_44 - SPI_MOSI
   3 af,      \ GPIO_45 - SPI_CLK
   3 af,      \ GPIO_46 - SPI_FRM
   3 pull-up, \ GPIO_47 - G_SENSOR_SDL (TWSI6)
   3 pull-up, \ GPIO_48 - G_SENSOR_SDA
   no-update, \ GPIO_49 - Not connected (TP62)
   no-update, \ GPIO_50 - Not connected (TP114)
   no-update, \ GPIO_51 - Not connected (TP59)
   no-update, \ GPIO_52 - Not connected (TP113)
[ifdef] cl2-a1
   no-update, \ GPIO_53 - Not connected if nopop R124 to use TWSI6 for RTC
   no-update, \ GPIO_54 - Not connected if nopop R125 to use TWSI6 for RTC
[else]
   2 af,      \ GPIO_53 - RTC_SCK (TWSI2) if R124 populated
   2 af,      \ GPIO_54 - RTC_SDA (TWSI2) if R125 populated
\   0 af,      \ GPIO_53 - RTC_SCK
\   0 af,      \ GPIO_54 - RTC_SDA
[then]
   no-update, \ GPIO_55 - Not connected (TP51)
[ifdef] cl2-a1
   no-update, \ GPIO_56 - Not connected (TP60)
[else]
   0 af,      \ GPIO_56 - BOOT_DEV_SEL
[then]
   0 af,      \ GPIO_57 - WLAN_PD#
   0 af,      \ GPIO_58 - WLAN_RESET#

   1 af,      \ GPIO_59 - PIXDATA7
   1 af,      \ GPIO_60 - PIXDATA6
   1 af,      \ GPIO_61 - PIXDATA5
   1 af,      \ GPIO_62 - PIXDATA4
   1 af,      \ GPIO_63 - PIXDATA3
   1 af,      \ GPIO_64 - PIXDATA2
   1 af,      \ GPIO_65 - PIXDATA1
   1 af,      \ GPIO_66 - PIXDATA0
   1 af,      \ GPIO_67 - CAM_HSYNC
   1 af,      \ GPIO_68 - CAM_VSYNC
   1 af,      \ GPIO_69 - PIXMCLK
   1 af,      \ GPIO_70 - PIXCLK

   0 af,      \ GPIO_71 - SOC_KBD_CLK  \ Was EC_SCL (TWSI3)
   0 af,      \ GPIO_72 - SOC_KBD_DAT  \ Was EC_SDA 
   0 af,      \ GPIO_73 - CAM_RST (use as GPIO out)

   1 af,      \ GPIO_74 - GFVSYNC
   1 af,      \ GPIO_75 - GFHSYNC
   1 af,      \ GPIO_76 - GFDOTCLK
   1 af,      \ GPIO_77 - GF_LDE
   1 af,      \ GPIO_78 - GFRDATA0
   1 af,      \ GPIO_79 - GFRDATA1
   1 af,      \ GPIO_80 - GFRDATA2
   1 af,      \ GPIO_81 - GFRDATA3
   1 af,      \ GPIO_82 - GFRDATA4
   1 af,      \ GPIO_83 - GFRDATA5
   1 af,      \ GPIO_84 - GFGDATA0
   1 af,      \ GPIO_85 - GFGDATA1
   1 af,      \ GPIO_86 - GFGDATA2
   1 af,      \ GPIO_87 - GFGDATA3
   1 af,      \ GPIO_88 - GFGDATA4
   1 af,      \ GPIO_89 - GFGDATA5
   1 af,      \ GPIO_90 - GFBDATA0
   1 af,      \ GPIO_91 - GFBDATA1
   1 af,      \ GPIO_92 - GFBDATA2
   1 af,      \ GPIO_93 - GFBDATA3
   1 af,      \ GPIO_94 - GFBDATA4
   1 af,      \ GPIO_95 - GFBDATA5

[ifdef] cl2-a1
   no-update, \ GPIO_96  - Not connected (TP112)
\  no-update, \ GPIO_97  - Not connected (R100 nopop) if we use TWSI2 for RTC
\  no-update, \ GPIO_98  - Not connected (R106 nopop) if we use TWSI2 for RTC
\  2 af,      \ GPIO_97  - RTC_SCK (TWSI6) if R100 populated
\  2 af,      \ GPIO_98  - RTC_SDA (TWSI6) if R106 populated
   0 af,      \ GPIO_97  - RTC_SCK (bitbang) if R100 populated
   0 af,      \ GPIO_98  - RTC_SDA (bitbang) if R106 populated
[else]
   0 pull-up, \ GPIO_96  - EXT_MIC_PLUG
   0 af,      \ GPIO_97  - HP_PLUG
   no-update, \ GPIO_98  - Not connected
[then]
   0 af,      \ GPIO_99  - TOUCH_SCR_INT
   0 af,      \ GPIO_100 - DCONSTAT0
   0 af,      \ GPIO_101 - DCONSTAT1
[ifdef] cl2-a1
   no-update, \ GPIO_102 - (USIM_CLK) - Not connected (TP48)
   no-update, \ GPIO_103 - (USIM_IO) - Not connected (TP50)

   0 af,      \ GPIO_104 - ND_IO[7]
   0 af,      \ GPIO_105 - ND_IO[6]
   0 af,      \ GPIO_106 - ND_IO[5]
[else]
   1 af,      \ GPIO_102 - reserved
   1 af,      \ GPIO_103 - EC_EDI_DO
   1 af,      \ GPIO_104 - EC_EDI_CS#
   1 af,      \ GPIO_105 - EC_EDI_DI
   1 af,      \ GPIO_106 - EC_EDI_CLK
[then]
   1 af,      \ GPIO_107 - (ND_IO[4]) - SOC_TPD_DAT

   1 af,      \ GPIO_108 - CAM_SDL - Use as GPIO, bitbang
   1 af,      \ GPIO_109 - CAM_SDA - Use as GPIO, bitbang

[ifdef] cl2-a1
   1 af,      \ GPIO_110 - (ND_IO[13]) - Not connected (TP43)
   1 af,      \ GPIO_111 - (ND_IO[8])  - Not connected (TP108)
   0 af,      \ GPIO_112 - ND_RDY[0]
[else]
   1 pull-up, \ GPIO_110 - DCON_SDA
   2 +fast af, \ GPIO_111 - eMMC_D0
   2 +fast af, \ GPIO_112 - eMMC_CMD
[then]
   3 +fast af,      \ GPIO_113 - (SM_RDY)  - MSD_CMD aka SD1_CMD (externally pulled up)
   1 af,      \ GPIO_114 - G_CLK_OUT - Not connected (TP93)

   4 af,      \ GPIO_115 - UART3_TXD (J4)
   4 af,      \ GPIO_116 - UART3_RXD (J4)
   3 af,      \ GPIO_117 - UART4_RXD - Not connected on A1 (TP117)
   3 af,      \ GPIO_118 - UART4_TXD - Not connected on A1 (TP56)
   3 af,      \ GPIO_119 - SDI_CLK  (SSP3)
   3 af,      \ GPIO_120 - SDI_CS#
   3 af,      \ GPIO_121 - SDI_MOSI
   3 af,      \ GPIO_122 - SDI_MISO

   3 af,      \ GPIO_123 - 32 KHz_CLK_OUT - Not connected (TP92)

   0 af,      \ GPIO_124 - DCONIRQ
\  0 af,      \ GPIO_125 - EC_SPI_ACK
   0 pull-up, \ GPIO_125 - EC_SPI_ACK

   3 +fast af, \ GPIO_126 - MSD_DATA2 AKA SD1_DATA2
   3 +fast af, \ GPIO_127 - MSD_DATA0 AKA SD1_DATA0
   0 af,      \ GPIO_128 - EB_MODE#
   0 af,      \ GPIO_129 - LID_SW#
   3 +fast af, \ GPIO_130 - MSD_DATA3 AKA SD1_DATA3
   1 +fast af, \ GPIO_131 - SD_DATA3 AKA SD2_DATA3
   1 +fast af, \ GPIO_132 - SD_DATA2 AKA SD2_DATA2
   1 +fast af, \ GPIO_133 - SD_DATA1 AKA SD2_DATA1
   1 +fast af, \ GPIO_134 - SD_DATA0 AKA SD2_DATA0
   3 +fast af, \ GPIO_135 - MSD_DATA1 AKA SD1_DATA1
\  1 +fast pull-up, \ GPIO_136 - SD_CMD AKA SD2_CMD
   1 +fast af,      \ GPIO_136 - SD_CMD AKA SD2_CMD - CMD is pulled up externally
   no-update, \ GPIO_137 - Not connected (TP111)
   3 +fast af, \ GPIO_138 - MSD_CLK AKA SD1_CLK
   1 +fast af, \ GPIO_139 - SD_CLK AKA SD2_CLK
   no-update, \ GPIO_140 - Not connected if R130 is nopop
\  1 af,      \ GPIO_140 - (SD_CD# if R130 is populated)
   1 af,      \ GPIO_141 - SD_WP# AKA SD2_WP#

[ifdef] cl2-a1
   no-update, \ GPIO_142 - (USIM_RSTn) - Not connected (TP49)
   0 af,      \ GPIO_143 - ND_CS0#
[else]
   1 af,      \ GPIO_142 - DCONLOAD
   1 af,      \ GPIO_143 - MIC_AC#/DC
[then]
   0 af,      \ GPIO_144 - ND_CS1#
[ifdef] cl2-a1
   1 af,      \ GPIO_145 - EN_CAM_PWR
[else]
   no-update, \ GPIO_145 - Not connected
[then]
   1 af,      \ GPIO_146 - HUB_RESET#

   0 af,      \ GPIO_147 - ND_WE_N
   1 af,      \ GPIO_148 - ND_RE_N - SOC_EN_KBD_PWR#
[ifdef] cl2-a1
   0 af,      \ GPIO_149 - ND_CLE
   0 af,      \ GPIO_150 - ND_ALE
   1 af,      \ GPIO_151 - DCONLOAD
[else]
   1 af,      \ GPIO_149 - eMMC_RST#
   1 af,      \ GPIO_150 - EN_CAM_PWR
   2 +fast af, \ GPIO_151 - eMMC_CLK
[then]
   1 af,      \ GPIO_152 - (SM_BELn) - Not connected (TP40)
   1 af,      \ GPIO_153 - (SM_BEHn) - Not connected (TP105)
   0 af,      \ GPIO_154 - (SM_INT) - EC_IRQ#
   1 pull-dn, \ GPIO_155 - (EXT_DMA_REQ0) - EC_SPI_CMD
   no-update, \ GPIO_156 - PRI_TDI (JTAG)
   no-update, \ GPIO_157 - PRI_TDS (JTAG)
   no-update, \ GPIO_158 - PRI_TDK (JTAG)
   no-update, \ GPIO_159 - PRI_TDO (JTAG)
   1 af,      \ GPIO_160 - (ND_RDY[1]) - SOC_TPD_CLK
[ifdef] cl2-a1
   1 af,      \ GPIO_161 - ND_IO[12] - Not connected (TP 44)
   1 af,      \ GPIO_162 - (ND_IO[11]) - DCON_SCL
   1 pull-up, \ GPIO_163 - (ND_IO[10]) - DCON_SDA
   1 af,      \ GPIO_164 - (ND_IO[9]) - Not connected (TP106)
   0 af,      \ GPIO_165 - ND_IO[3]
   0 af,      \ GPIO_166 - ND_IO[2]
   0 af,      \ GPIO_167 - ND_IO[1]
   0 af,      \ GPIO_168 - ND_IO[0]
[else]
   1 af,      \ GPIO_161 - DCON_SCL
   2 +fast af, \ GPIO_162 - eMMC_D6
   2 +fast af, \ GPIO_163 - eMMC_D4
   2 +fast af, \ GPIO_164 - eMMC_D2
   2 +fast af, \ GPIO_165 - eMMC_D7
   2 +fast af, \ GPIO_166 - eMMC_D5
   2 +fast af, \ GPIO_167 - eMMC_D3
   2 +fast af, \ GPIO_168 - eMMC_D1
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
