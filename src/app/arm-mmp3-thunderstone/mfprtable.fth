create mfpr-table
   0 +medium af,            \ ,GPIO_00 - CAM1_RST_N
   1 +medium af,            \ *GPIO_01 - CAM2_RST_N
   0 +medium af,            \ *GPIO_02 - GPIO keypad (HOME)
   0 +medium af,            \ ,GPIO_03 -  MPCIE33EN
   0 +medium af,            \ ,GPIO_04 -  BB_WAKE_N
   0 +medium af,            \ ,GPIO_05 -  BB_ENABLE
   no-update,               \ ,GPIO_06 -  n/c
   0 +medium af,            \ ,GPIO_07 -  BB_RST_N
   0 +medium af,            \ ,GPIO_08 -  DVC1
   0 +medium af,            \ ,GPIO_09 -  DVC2
   0 +medium af,            \ ,GPIO_10 -  FSYNC
   0 +medium af,            \ ,GPIO_11 -  HUB_INT
   no-update,               \ ,GPIO_12 -  n/c
   no-update,               \ ,GPIO_13 -  n/c
   0 +pull-dn af,           \ *GPIO_14 - GPS_ON
   0 +pull-dn af,           \ *GPIO_15 - GPS_RST
   no-update,               \ ,GPIO_16 -  n/c
   no-update,               \ ,GPIO_17 -  n/c
   no-update,               \ ,GPIO_18 -  n/c
   no-update,               \ ,GPIO_19 -  n/c
   0 +medium af,            \ *GPIO_20 - GPIO keypad - DKIN4
   0 +medium af,            \ ,GPIO_21 -  FM_IRQ
   0 +medium af,            \ *GPIO_22 - GPIO keypad - DKIN6
   0 +medium af,            \ *GPIO_23 - GPIO for SSPA1 I2S
   1 +medium af,            \ *GPIO_24 - I2S_SYSCLK   (Codec) (n/c on schematic)
   1 +medium af,            \ *GPIO_25 - I2S_BITCLK   (Codec)
   1 +medium af,            \ *GPIO_26 - I2S_SYNC     (Codec)
   1 +medium af,            \ *GPIO_27 - I2S_DATA_OUT (Codec)
   1 +medium af,            \ *GPIO_28 - I2S_DATA_IN  (Codec)
   1 +medium af,            \ ,GPIO_29 -  UART1_RXD  (BT)
   1 +medium af,            \ ,GPIO_30 -  UART1_TXD  (BT)
   1 +medium af,            \ ,GPIO_31 -  UART1_CTS  (BT)
   1 +medium af,            \ ,GPIO_32 -  UART1_RTS  (BT)
   1 +medium af,            \ ,GPIO_33 -  SSPA2_CLK
   1 +medium af,            \ ,GPIO_34 -  SSPA2_FRM
   1 +medium af,            \ ,GPIO_35 -  SSPA2_TXD
   1 +medium af,            \ ,GPIO_36 -  SSPA2_RXD
   1 +fast +pull-up af,     \ *GPIO_37 - MMC2_DAT3 (WIB card)
   1 +fast +pull-up af,     \ *GPIO_38 - MMC2_DAT2
   1 +fast +pull-up af,     \ *GPIO_39 - MMC2_DAT1
   1 +fast +pull-up af,     \ *GPIO_40 - MMC2_DAT0
   1 +fast +pull-up af,     \ *GPIO_41 - MMC2_CMD
   1 +fast          af,     \ *GPIO_42 - MMC2_CLK
   3 +medium af,            \ ,GPIO_43 - SSP1_RXD (thunderstone.c has 1,slow TWSI2_SCL)
   3 +medium af,            \ ,GPIO_44 - SSP1_TXD (thunderstone.c has 1,slow TWSI2_SDA)
   3 +medium af,            \ ,GPIO_45 - SSP1_CLK
   3 +medium af,            \ ,GPIO_46 - SSP1_FRM
   1 +medium af,            \ *GPIO_47 - UART2_RXD (GPS)
   1 +medium af,            \ *GPIO_48 - UART2_TXD (GPS)
   1 +medium af,            \ *GPIO_49 - UART2_CTS
   1 +medium af,            \ *GPIO_50 - UART2_RTS
   1 +medium af,            \ *GPIO_51 - UART3_RXD
   1 +medium af,            \ *GPIO_52 - UART3_TXD
   5 +slow +pull-dn af,     \ *GPIO_53 - PWM3
   4 +pull-up af,           \ *GPIO_54 - HDMI_CEC
   0 +medium af,            \ ,GPIO_55 -  WL_BT_WAKE
   0 +medium af,            \ ,GPIO_56 -  WLAN_WAKE
   0 +medium af,            \ *GPIO_57 - GPIO WIFI_PD_N
   0 +medium af,            \ *GPIO_58 - GPIO WIFI_RST_N

   0 +medium af,            \ ,GPIO_59 - HDMI_DET
   0 +medium af,            \ ,GPIO_60 - USIM_DET
   0 +medium af,            \ ,GPIO_61 - VBUS_FLT_N
   0 +medium af,            \ ,GPIO_62 - CAM2_PWREN
   0 +medium af,            \ ,GPIO_63 - LED_B
   0 +medium af,            \ ,GPIO_64 - CAM1_PWDN
   0 +medium af,            \ ,GPIO_65 - GYRO_INT_L3G_1
   0 +medium af,            \ ,GPIO_66 - GYRO_INT_L3G_2
   0 +medium af,            \ ,GPIO_67 - PCIE_GPIO0
   0 +medium af,            \ *GPIO_68 - CAM2_PWDN
   0 +medium af,            \ ,GPIO_69 - PCIE_GPIO1
   0 +medium af,            \ ,GPIO_70 - MPU_INT

   1 +slow  af,             \ *GPIO_71 - TWSI3_SCL
   1 +slow  af,             \ *GPIO_72 - TWSI3_SDA
   4 +fast  af,             \ *GPIO_73 - CAM1_MCLK

   0 +medium af,            \ ,GPIO_74 - LED_O_N
   no-update,               \ ,GPIO_75 - n/c
   0 +medium af,            \ ,GPIO_76 - LED_R_N
   0 +medium af,            \ ,GPIO_77 - LED_G
   5 +medium af,            \ *GPIO_78 - SSP4_CLK
   5 +medium af,            \ *GPIO_79 - SSP4_FRM
   5 +medium af,            \ *GPIO_80 - SSP4_TXD
   5 +medium af,            \ *GPIO_81 - SSP4_RXD
   0 +medium af,            \ *GPIO_82 - VBUS_EN
   0 +medium af,            \ ,GPIO_83 - FLASH_EN
   0 +medium af,            \ *GPIO_84 - GPIO (for PWM3) LDO_EN
   0 +medium af,            \ *GPIO_85 - GPIO TS_IO_EN
   0 +medium af,            \ ,GPIO_86 - TP_RST
   no-update,               \ ,GPIO_87 - n/c
   0 +medium af,            \ ,GPIO_88 - 5V_ON
   0 +medium af,            \ ,GPIO_89 - VPP_EN
   0 +medium af,            \ ,GPIO_90 - VCC_EN
   0 +medium af,            \ ,GPIO_91 - GPIO_ISPCLK
   0 +medium af,            \ ,GPIO_92 - GPIO_ISPDAT
   0 +medium af,            \ ,GPIO_93 - PROX_INT
   no-update,               \ ,GPIO_94 - n/c
   no-update,               \ ,GPIO_95 - n/c

   0 sleep0 af,             \ *GPIO_96  - HSIC_RST_N
   2 +slow af,              \ *GPIO_97  - TWSI6_SCL
   2 +slow af,              \ *GPIO_98  - TWSI_SDA
   4 +slow af,              \ *GPIO_99  - TWSI5_SCL
   4 +slow af,              \ *GPIO_100 - TWSI5_SDA
   0 +medium af,            \ *GPIO_101 - GPIO TS INT
   no-update,               \ ,GPIO_102 - n/c
   no-update,               \ ,GPIO_103 - n/c
   0 +medium af,            \ *GPIO_104 - DFI_D7
   0 +medium af,            \ *GPIO_105 - DFI_D6
   0 +medium af,            \ *GPIO_106 - DFI_D5
   0 +medium af,            \ *GPIO_107 - DFI_D4

   2 +fast +pull-up af,     \ *GPIO_108 - MMC3_DAT7
   2 +fast +pull-up af,     \ *GPIO_109 - MMC3_DAT6

   2 +fast +pull-up af,     \ *GPIO_110 - MMC3_DAT2
   2 +fast +pull-up af,     \ *GPIO_111 - MMC3_DAT3
   0 +medium af,            \ *GPIO_112 - ND_RDY0
   no-update,               \ ,GPIO_113 - n/c
   no-update,               \ ,GPIO_114 - n/c

   2 +medium af,            \ ,GPIO_115 - HSI_TX_WAKE
   2 +medium af,            \ ,GPIO_116 - HSI_TX_READY
   2 +medium af,            \ ,GPIO_117 - HSI_TX_FLAG
   2 +medium af,            \ ,GPIO_118 - HSI_TX_DATA
   2 +medium af,            \ ,GPIO_119 - HSI_RX_WAKE
   2 +medium af,            \ ,GPIO_120 - HSI_RX_READY
   2 +medium af,            \ ,GPIO_121 - HSI_RX_FLAG
   2 +medium af,            \ ,GPIO_122 - HSI_RX_DATA

   0 +medium af,            \ ,GPIO_123 - LOW_BATT

   no-update,               \ ,GPIO_124 - n/c
   no-update,               \ ,GPIO_125 - n/c

   0 +medium af,            \ ,GPIO_126 - ACC_INT_LSM_1
   0 +medium af,            \ ,GPIO_127 - ACC_INT_LSM_2
   0 +fast   af,            \ *GPIO_128 - LCD_RST
   0 +medium af,            \ ,GPIO_129 - MPCIESHDN_N
   0 +medium af,            \ ,GPIO_130 - MPCIE_PG
   1 +fast +pull-up af,     \ *GPIO_131 - MMC1_DAT3
   1 +fast +pull-up af,     \ *GPIO_132 - MMC1_DAT2
   1 +fast +pull-up af,     \ *GPIO_133 - MMC1_DAT1
   1 +fast +pull-up af,     \ *GPIO_134 - MMC1_DAT0
   1 +fast af,              \ *GPIO_135 - MMC1_CLK
   1 +fast +pull-up af,     \ *GPIO_136 - MMC1_CMD

   no-update,               \ ,GPIO_137 - n/c
   no-update,               \ ,GPIO_138 - n/c
   0 +medium af,            \ ,GPIO_139 - USB_VBUS_DET
   1 +fast +pull-up af,     \ *GPIO_140 - MMC1_CD
   1 +fast +pull-up af,     \ *GPIO_141 - MMC1_WP

   no-update,               \ ,GPIO_142 - n/c
   0 +medium af,            \ *GPIO_143 - ND_nCS0
   0 +medium af,            \ *GPIO_144 - ND_nCS1
   2 +fast +pull-up af,     \ *GPIO_145 - MMC3_CMD
   2 +fast          af,     \ *GPIO_146 - MMC3_CLK

   0 +medium af,            \ *GPIO_147 - ND_nWE
   0 +medium af,            \ *GPIO_148 - ND_nRE
   1 +fast +pull-up af,     \ ,GPIO_149 - MMC3_RST (not in thunderstone.c)
   0 +medium af,            \ *GPIO_150 - ND_ALE

   no-update,               \ ,GPIO_151 - n/c
   no-update,               \ ,GPIO_152 - n/c
   no-update,               \ ,GPIO_153 - n/c
   no-update,               \ ,GPIO_154 - n/c
   no-update,               \ ,GPIO_155 - n/c
   no-update,               \ ,GPIO_156 - PRI_TDI
   no-update,               \ ,GPIO_157 - PRI_TMS
   no-update,               \ ,GPIO_158 - PRI_TCK
   no-update,               \ ,GPIO_159 - PRI_TMS
   0 +medium af,            \ *GPIO_160 - ND_RDY1
   2 +fast +pull-up af,     \ *GPIO_161 - MMC3_DAT5
   2 +fast +pull-up af,     \ *GPIO_162 - MMC3_DAT1
   2 +fast +pull-up af,     \ *GPIO_163 - MMC3_DAT4
   2 +fast +pull-up af,     \ *GPIO_164 - MMC3_DAT0

   0 +medium af,            \ *GPIO_165 - DFI_D3
   0 +medium af,            \ *GPIO_166 - DFI_D2
   0 +medium af,            \ *GPIO_167 - DFI_D1
   0 +medium af,            \ *GPIO_168 - DFI_D0

   0 +slow   af,            \ *GPIO_169 - TWSI4_SCL
   0 +slow   af,            \ *GPIO_170 - TWSI4_SDA
   no-update,               \ ,GPIO_171 - n/c
here mfpr-table - /w / constant #mfprs
