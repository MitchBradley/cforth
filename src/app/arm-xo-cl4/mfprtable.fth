create mfpr-table
   0 sleepi +pull-dn af,	\ GPIO_00 - Memsize0 (TP201 on B) (start with them pulled down for A and B revs)
   0 sleepi +pull-dn af,	\ GPIO_01 - Memsize1 (TP199 on B)
   0 sleepi af,			\ GPIO_02 - BOOT_DEV_SEL
   0 sleepi af,			\ GPIO_03 - SOC_SEL
   0 sleep1 af,			\ GPIO_04 - HDMI_SCL
   0 sleep1 af,			\ GPIO_05 - HDMI_DAT
   0 sleepi af,			\ GPIO_06 - G_SENSOR_INT
   0 sleepi af,			\ GPIO_07 - AUDIO_IRQ#
   0 sleep0 af,			\ GPIO_08 - AUDIO_RESET#
   no-update,			\ GPIO_09 - Not connected (TP72)
   0 sleep0 +pull-dn af,	\ GPIO_10 - LED_STORAGE
   no-update,			\ GPIO_11 - Not connected (TP44)
   0 sleepi +pull-sel af,	\ GPIO_12 - TOUCH_HD#
   0 sleepi af,			\ GPIO_13 - HP_PLUG
   0 sleepi af,			\ GPIO_14 - HDMI_HP_DET
   0 sleepi af,			\ GPIO_15 - KEY_ROTATE
   0 sleepi af,			\ GPIO_16 - KEY_R_UP (using gpio)
   0 sleepi af,			\ GPIO_17 - KEY_R_RT (using gpio)
   0 sleepi af,			\ GPIO_18 - KEY_R_DN (using gpio)
   0 sleepi af,			\ GPIO_19 - KEY_R_UP (using gpio)
   0 sleepi af,			\ GPIO_20 - KEY_L_UP (using gpio)
   0 sleepi af,			\ GPIO_21 - KEY_L_RT (using gpio)
   0 sleepi af,			\ GPIO_22 - KEY_L_DN (using gpio)
   0 sleepi af,			\ GPIO_23 - KEY_L_LF (using gpio)
   5 sleep1 af,			\ GPIO_24 - I2S_SYSCLK   (Codec) \ wastes 40 mW if S0
   1 sleep1 af,			\ GPIO_25 - I2S_BITCLK   (Codec) \ wastes 2 mW if S0
   1 sleep0 af,			\ GPIO_26 - I2S_SYNC     (Codec)
   1 sleep1 af,			\ GPIO_27 - I2S_DATA_OUT (Codec) \ wastes 3 mW if S0
   1 sleepi af,			\ GPIO_28 - I2S_DATA_IN  (Codec) \ wastes 13 mW if S1
   1 sleep- af,			\ GPIO_29 - UART1_RXD  (debug board)
   1 sleep- af,			\ GPIO_30 - UART1_TXD  (debug board)
   0 sleepi af,			\ GPIO_31 - SD_CD# AKA SD2_CD# (via GPIO)
   no-update,			\ GPIO_32 - Not connected (TP58)
   no-update,			\ GPIO_33 - Not connected (TP60)
   0 sleep0 af,			\ GPIO_34 - EN_WLAN_PWR
   0 sleepi af,			\ GPIO_35 - WLAN_WAKE (WLAN_PD# on C1 and earlier)
   0 sleep1 af,			\ GPIO_36 - WLAN_RESET#
   1 sleepi af,			\ GPIO_37 - SDDA_D3 (MMC2)
   1 sleepi af,			\ GPIO_38 - SDDA_D2 (MMC2)
   1 sleepi af,			\ GPIO_39 - SDDA_D1 (MMC2)
   1 sleepi af,			\ GPIO_40 - SDDA_D0 (MMC2)
   1 sleep0 af,			\ GPIO_41 - SDDA_CMD (MMC2)
   1 sleep0 af,			\ GPIO_42 - SDDA_CLK (MMC2)
   3 sleepi +pull-up-alt         af,	\ GPIO_43 - SPI_MISO  (SSP1) (OFW Boot FLASH)
   3 sleep0 +pull-up-alt +medium af,	\ GPIO_44 - SPI_MOSI
   3 sleep1 +pull-up-alt +medium af,	\ GPIO_45 - SPI_CLK
   3 sleep1 +pull-up-alt +medium af,	\ GPIO_46 - SPI_FRM
   3 sleep1 +pull-up af,	\ GPIO_47 - G_SENSOR_SDL (TWSI6)
   3 sleep1 +pull-up af,	\ GPIO_48 - G_SENSOR_SDA
   no-update,			\ GPIO_49 - Not connected (TP62)
   no-update,			\ GPIO_50 - Not connected (TP114)
   no-update,			\ GPIO_51 - Not connected (TP59)
   no-update,			\ GPIO_52 - Not connected (TP113)
   2 sleep1 +twsi af,		\ GPIO_53 - RTC_SCK (TWSI2)
   2 sleep1 +twsi af,		\ GPIO_54 - RTC_SDA (TWSI2)
   no-update,			\ GPIO_55 - Not connected (TP71)
   no-update,			\ GPIO_56 - Not connected (TP77)
   no-update,			\ GPIO_57 - Not connected (TP78)
   no-update,			\ GPIO_58 - Not connected (TP79)

   4 sleep0 af,			\ GPIO_59 - PIXDATA7 \ Each wastes ~15 mW if S1
   4 sleep0 af,			\ GPIO_60 - PIXDATA6
   4 sleep0 af,			\ GPIO_61 - PIXDATA5
   4 sleep0 af,			\ GPIO_62 - PIXDATA4
   4 sleep0 af,			\ GPIO_63 - PIXDATA3
   4 sleep0 af,			\ GPIO_64 - PIXDATA2
   4 sleep0 af,			\ GPIO_65 - PIXDATA1
   4 sleep0 af,			\ GPIO_66 - PIXDATA0
   4 sleepi af,			\ GPIO_67 - CAM_HSYNC  \ Wastes 40 mW if S1
   4 sleepi af,			\ GPIO_68 - CAM_VSYNC  \ Wastes 40 mW if S1
   4 sleep0 af,			\ GPIO_69 - PIXMCLK
   4 sleep0 af,			\ GPIO_70 - PIXCLK     \ Wastes 40 mW if S1

   0 sleepi af,			\ GPIO_71 - SOC_KBD_CLK  \ Was EC_SCL (TWSI3) w6 S0
   0 sleep- af,			\ GPIO_72 - SOC_KBD_DAT  \ Was EC_SDA         w6 S0
   0 sleep0 af,			\ GPIO_73 - SEC_TRG      \ Was CAM_RST on A3

   1 sleep0 af,			\ GPIO_74 - GFVSYNC 
   1 sleep0 af,			\ GPIO_75 - GFHSYNC
   1 sleep0 af,			\ GPIO_76 - GFDOTCLK
   1 sleep0 af,			\ GPIO_77 - GF_LDE
   1 sleep0 af,			\ GPIO_78 - GFRDATA0
   1 sleep0 af,			\ GPIO_79 - GFRDATA1
   1 sleep0 af,			\ GPIO_80 - GFRDATA2
   1 sleep0 af,			\ GPIO_81 - GFRDATA3
   1 sleep0 af,			\ GPIO_82 - GFRDATA4
   1 sleep0 af,			\ GPIO_83 - GFRDATA5
   1 sleep0 af,			\ GPIO_84 - GFGDATA0
   1 sleep0 af,			\ GPIO_85 - GFGDATA1
   1 sleep0 af,			\ GPIO_86 - GFGDATA2
   1 sleep0 af,			\ GPIO_87 - GFGDATA3
   1 sleep0 af,			\ GPIO_88 - GFGDATA4
   1 sleep0 af,			\ GPIO_89 - GFGDATA5
   1 sleep0 af,			\ GPIO_90 - GFBDATA0
   1 sleep0 af,			\ GPIO_91 - GFBDATA1
   1 sleep0 af,			\ GPIO_92 - GFBDATA2
   1 sleep0 af,			\ GPIO_93 - GFBDATA3
   1 sleep0 af,			\ GPIO_94 - GFBDATA4
   1 sleep0 af,			\ GPIO_95 - GFBDATA5

   0 sleepi +pull-up af,	\ GPIO_96  - EXT_MIC_PLUG w80 S1
   0 sleep1 af,			\ GPIO_97  - EN_eMMC_PWR#
   0 sleep1 af,			\ GPIO_98  - TOUCH_RST#
   0 sleepi af,			\ GPIO_99  - TOUCH_SCR_INT w80 S1
   0 sleepi af,			\ GPIO_100 - DCONSTAT0 w40 S1
   0 sleepi af,			\ GPIO_101 - DCONSTAT1 w40 S1
   1 sleep0 af,			\ GPIO_102 - CAM_RST  \ B1 and later
   1 sleep0 af,			\ GPIO_103 - EC_EDI_DO
   1 sleep1 af,			\ GPIO_104 - EC_EDI_CS#
   1 sleepi af,			\ GPIO_105 - EC_EDI_DI
   1 sleep1 af,			\ GPIO_106 - EC_EDI_CLK
   1 sleep- af,			\ GPIO_107 - (ND_IO[4]) - SOC_TPD_DAT

   \ Set to GPIOs initially (MMC3 is function 2) to avoid leakage current
   1 sleep0 af,			\ GPIO_108 - eMMC_D7 (MMC3)
   1 sleep0 af,			\ GPIO_109 - eMMC_D6
   1 sleep0 af,			\ GPIO_110 - eMMC_D2
   1 sleep0 af,			\ GPIO_111 - eMMC_D3

   4 sleep0 af,			\ GPIO_112 - SD1_DATA3 (MMC5)

   1 sleep1 +pull-up af,	\ GPIO_113 - EC_SPI_ACK

   1 sleep- af,			\ GPIO_114 - G_CLK_OUT - Not connected (TP93)

   0 sleep1 af,			\ GPIO_115 - SD_PWROFF (as of XO-4 C1)
   0 sleep0 af,			\ GPIO_116 - SD_1.8VSEL (as of XO-4 C1)
   3 sleep0 af,			\ GPIO_117 - TOUCH_BSL_TXD
   3 sleepi af,			\ GPIO_118 - TOUCH_BSL_RXD
   3 sleep0 af,			\ GPIO_119 - SDI_CLK  (SSP3) w70 S1
   3 sleep1 af,			\ GPIO_120 - SDI_CS#  w70 S0
   3 sleep0 af,			\ GPIO_121 - SDI_MOSI w80 S1
   3 sleepi af,			\ GPIO_122 - SDI_MISO

   0 sleep0 af,			\ GPIO_123 - VID2

   no-update,			\ GPIO_124 - Not connected (TP61)
   no-update,			\ GPIO_125 - Not connected (TP63)

   0 sleepi af,			\ GPIO_126 - DCON_IRQ#
   1 sleep- af,			\ GPIO_127 - UART2_RXD
   1 sleep- af,			\ GPIO_128 - UART2_TXD
   0 sleepi af,			\ GPIO_129 - LID_SW#
   0 sleepi af,			\ GPIO_130 - EB_MODE#
   1 sleep0 af,			\ GPIO_131 - SD2_DATA3
   1 sleep0 af,			\ GPIO_132 - SD2_DATA2
   1 sleep0 af,			\ GPIO_133 - SD2_DATA1
   1 sleep0 af,			\ GPIO_134 - SD2_DATA0
   1 sleep0 +fast af,		\ GPIO_135 - SD2_CLK
   1 sleep1 af,			\ GPIO_136 - SD2_CMD - CMD is pulled up externally
   no-update,			\ GPIO_137 - Not connected (TP64)
   no-update,			\ GPIO_138 - Not connected (TP65)
   0 sleep0 af,			\ GPIO_139 - TOUCH_TCK
   no-update,			\ GPIO_140 - Not connected (TP67)
   1 sleepi +pull-up af,	\ GPIO_141 - SD2_WP#

   1 sleep0 af,			\ GPIO_142 - DCONLOAD
   1 sleep0 af,			\ GPIO_143 - MIC_AC#/DC
   1 sleep0 af,			\ GPIO_144 - eMMC_RST#

   \ Set to GPIOs initially (MMC3 is function 2) to avoid leakage current
   1 sleep0 af,			\ GPIO_145 - eMMC_CMD (MMC3)
   1 sleep0 +fast af,		\ GPIO_146 - eMMC_CLK

   4 sleep0 af,			\ GPIO_147 - SD1_DATA2
   1 sleep- af,			\ GPIO_148 - HUB_RESET#
   4 sleep0 af,			\ GPIO_149 - SD1_DATA1
   1 sleep0 af,			\ GPIO_150 - EN_CAM_PWR - Must be 0 in sleep state for camera off
   4 sleep0 af,			\ GPIO_151 - SD1_DATA1
   4 sleep0 +fast af,		\ GPIO_152 - SD1_CLK
   4 sleep0 af,			\ GPIO_153 - SD1_CMD

   1 sleepi af,			\ GPIO_154 - (SM_INT) - EC_IRQ#
   1 sleep0 +pull-dn af,			\ GPIO_155 - (EXT_DMA_REQ0) - EC_SPI_CMD
   no-update,			\ GPIO_156 - PRI_TDI (JTAG)
   no-update,			\ GPIO_157 - PRI_TDS (JTAG)
   no-update,			\ GPIO_158 - PRI_TDK (JTAG)
   no-update,			\ GPIO_159 - PRI_TDO (JTAG)
   1 sleepi af,			\ GPIO_160 - (ND_RDY[1]) - SOC_TPD_CLK

   \ Set to GPIOs initially (MMC3 is function 2) to avoid leakage current
   1 sleep0 af,			\ GPIO_161 - eMMC_D5 (MMC3)
   1 sleep0 af,			\ GPIO_162 - eMMC_D6
   1 sleep0 af,			\ GPIO_163 - eMMC_D4
   1 sleep0 af,			\ GPIO_164 - eMMC_D2

   1 sleep0 af,			\ GPIO_165 - CAM_SCL
   1 sleep0 af,			\ GPIO_166 - CAM_SDA
   1 sleep0 af,			\ GPIO_167 - DCON_SDA
   1 sleep0 af,			\ GPIO_168 - DCON_SCL
   0 sleep0 af,			\ GPIO_169 - (TWSI4_SCL) TOUCH_SCR_SCL
   0 sleep0 af,			\ GPIO_170 - (TWSI4_SDA) TOUCH_SCR_SDA
   no-update,			\ GPIO_171 - Not connected
here mfpr-table - /w / constant #mfprs
