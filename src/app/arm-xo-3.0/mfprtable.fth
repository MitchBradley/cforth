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
   0 sleep1 af,      \ GPIO_09 - CAM_PWRDN
   0 sleep1 af,      \ GPIO_10 - CAM_RST
   0 sleep0 af,      \ GPIO_11 - VID2
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
   3 sleep1 +pull-up af,   \ GPIO_47 - G_SENSOR_SDL (TWSI6)
   3 sleep1 +pull-up af,   \ GPIO_48 - G_SENSOR_SDA
   0 sleep0 af,            \ GPIO_49 - (PWM2) DBC (as gpio, for now)
   no-update,              \ GPIO_50 - Not connected (TP114)
   no-update,              \ GPIO_51 - Not connected (TP59)
   no-update,              \ GPIO_52 - Not connected (TP113)
   2 sleep1 +twsi af,      \ GPIO_53 - RTC_SCK (TWSI2) if R124 populated
   2 sleep1 +twsi af,      \ GPIO_54 - RTC_SDA (TWSI2) if R125 populated
   no-update,              \ GPIO_55 - Not connected (TP51)
   0 sleepi af,            \ GPIO_56 - BOOT_DEV_SEL
   0 sleep0 af,            \ GPIO_57 - WLAN_PD#
   0 sleep0 af,            \ GPIO_58 - WLAN_RESET#

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

   0 sleepi +pull-up af, \ GPIO_96  - EXT_MIC_PLUG w80 S1
   0 sleepi af,      \ GPIO_97  - HP_PLUG w80 S1
   no-update,        \ GPIO_98  - Not connected
   0 sleepi af,      \ GPIO_99  - TOUCH_SCR_INT w80 S1
   0 sleepi af,      \ GPIO_100 - DCONSTAT0 w40 S1
   0 sleepi af,      \ GPIO_101 - DCONSTAT1 w40 S1
   no-update,        \ GPIO_102 - Not connected (CL3)
   1 sleep0 af,      \ GPIO_103 - EC_EDI_DO
   1 sleep1 af,      \ GPIO_104 - EC_EDI_CS#
   1 sleepi af,      \ GPIO_105 - EC_EDI_DI
   1 sleep1 af,      \ GPIO_106 - EC_EDI_CLK
   1 sleep- af,      \ GPIO_107 - (ND_IO[4]) - SOC_TPD_DAT

   1 sleep1 af,      \ GPIO_108 - CAM_SDL - Use as GPIO, bitbang w5 S0 (CL2), CHG_SDA (CL3)
   1 sleep1 af,      \ GPIO_109 - CAM_SDA - Use as GPIO, bitbang w5 S0 (CL2), CHG_SCL (CL3)

   1 sleep1 +pull-up af, \ GPIO_110 - DCON_SDA w5 S0 (CL2), CHRG_AC_OK (CL3)
   2 sleep0 +fast af,    \ GPIO_111 - eMMC_D0
   2 sleep0 +fast af,    \ GPIO_112 - eMMC_CMD
   3 sleep1 +fast af,    \ GPIO_113 - (SM_RDY)  - MSD_CMD aka SD1_CMD (externally pulled up) (CL2), N/C (CL3)
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
   0 sleep1 +pull-up af, \ GPIO_125 - EC_SPI_ACK

   0 sleep1 af,       \ GPIO_126 - EN_+5V_USB_OTG#
   0 sleep1 af,       \ GPIO_127 - EN_+5V_USB#
   0 sleepi af,       \ GPIO_128 - EB_MODE#
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

   1 sleep0 af,      \ GPIO_142 - DCONLOAD (CL2), SEC_TRG (CL3)
   1 sleep0 af,      \ GPIO_143 - MIC_AC#/DC
   1 sleep1 af,      \ GPIO_144 - (ND_CS1#) - CAM_PWRDN (not connected until C1) (not connected on CL3)
   no-update,        \ GPIO_145 - Not connected
   1 sleep- af,      \ GPIO_146 - HUB_RESET# (CL2), ULPI_HUB_RESET# (CL3)

   0 sleep0 af,       \ GPIO_147 - ND_WE_N - Not connected (TP122)
   1 sleep- af,       \ GPIO_148 - ND_RE_N - SOC_EN_KBD_PWR# (CL2) (N/C on CL3)
   1 sleep0 af,       \ GPIO_149 - eMMC_RST#
   1 sleep0 af,       \ GPIO_150 - EN_CAM_PWR - Must be 0 in sleep state for camera off
   2 sleep0 +fast af, \ GPIO_151 - eMMC_CLK
   1 sleep0 af,       \ GPIO_152 - (SM_BELn) - Not connected (TP40)
   1 sleep0 af,       \ GPIO_153 - (SM_BEHn) - Not connected (TP105)
   1 sleepi af,       \ GPIO_154 - (SM_INT) - EC_IRQ#
   1 sleep0 +pull-dn af, \ GPIO_155 - (EXT_DMA_REQ0) - EC_SPI_CMD
   no-update,         \ GPIO_156 - PRI_TDI (JTAG)
   no-update,         \ GPIO_157 - PRI_TDS (JTAG)
   no-update,         \ GPIO_158 - PRI_TDK (JTAG)
   no-update,         \ GPIO_159 - PRI_TDO (JTAG)
   1 sleepi af,       \ GPIO_160 - (ND_RDY[1]) - SOC_TPD_CLK (CL2) (N/C on CL3)
   1 sleep1 af,       \ GPIO_161 - DCON_SCL (CL2), PWR_LMT_ON# (CL3)
   2 sleep0 +fast af, \ GPIO_162 - eMMC_D6
   2 sleep0 +fast af, \ GPIO_163 - eMMC_D4
   2 sleep0 +fast af, \ GPIO_164 - eMMC_D2
   2 sleep0 +fast af, \ GPIO_165 - eMMC_D7
   2 sleep0 +fast af, \ GPIO_166 - eMMC_D5
   2 sleep0 +fast af, \ GPIO_167 - eMMC_D3
   2 sleep0 +fast af, \ GPIO_168 - eMMC_D1
here mfpr-table - /w / constant #mfprs
