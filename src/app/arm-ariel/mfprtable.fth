\ Ariel (Dell Wyse 3020) Pin Mux configuration
\
\ Copyright (C) 2020 Lubomir Rintel <lkundrak@v3.sk>

create mfpr-table
     no-update,                 \ PIN0
     no-update,                 \ PIN1
     no-update,                 \ PIN2
     no-update,                 \ PIN3
     no-update,                 \ PIN4
     no-update,                 \ PIN5
     no-update,                 \ PIN6
     no-update,                 \ PIN7
     no-update,                 \ PIN8
     no-update,                 \ PIN9
     no-update,                 \ PIN10
     no-update,                 \ PIN11
     no-update,                 \ PIN12
     no-update,                 \ PIN13
     no-update,                 \ PIN14
     no-update,                 \ PIN15
     no-update,                 \ PIN16
     no-update,                 \ PIN17
     no-update,                 \ PIN18
     no-update,                 \ PIN19
     no-update,                 \ PIN20
     no-update,                 \ PIN21
     no-update,                 \ PIN22
     no-update,                 \ PIN23
     no-update,                 \ PIN24
     no-update,                 \ PIN25
     no-update,                 \ PIN26
     no-update,                 \ PIN27
     no-update,                 \ PIN28
     no-update,                 \ PIN29
     no-update,                 \ PIN30
     no-update,                 \ PIN31
     no-update,                 \ PIN32
     no-update,                 \ PIN33
     no-update,                 \ PIN34
     no-update,                 \ PIN35
     no-update,                 \ PIN36
     no-update,                 \ PIN37
     no-update,                 \ PIN38
     no-update,                 \ PIN39
     no-update,                 \ PIN40
   2 +slow w,                   \ PIN41 - TWSI5
   2 +slow w,                   \ PIN42 - TWSI5
   3 +pull-up +medium w,        \ PIN43 - SSP1
   3 +medium w,                 \ PIN44 - SSP1
   3 +medium w,                 \ PIN45 - SSP1
   0 +medium w,                 \ PIN46 - GPIO46
   3 +slow w,                   \ PIN47 - TWSI6
   3 +slow w,                   \ PIN48 - TWSI6
     no-update,                 \ PIN49
     no-update,                 \ PIN50
     no-update,                 \ PIN51
     no-update,                 \ PIN52
     no-update,                 \ PIN53
     no-update,                 \ PIN54
   0 +pull-up-alt +pull-dn-alt +twsi w, \ PIN55 - GPIO55
   0 +pull-up-alt +pull-dn-alt w,       \ PIN56 - GPIO56
   0 +pull-up-alt +pull-dn-alt +twsi w, \ PIN57 - GPIO57
   0 +pull-up-alt +pull-dn-alt w,       \ PIN58 - GPIO58
     no-update,                 \ PIN59
     no-update,                 \ PIN60
     no-update,                 \ PIN61
     no-update,                 \ PIN62
     no-update,                 \ PIN63
     no-update,                 \ PIN64
     no-update,                 \ PIN65
     no-update,                 \ PIN66
     no-update,                 \ PIN67
     no-update,                 \ PIN68
     no-update,                 \ PIN69
     no-update,                 \ PIN70
   1 +slow w,                   \ PIN71 - TWSI3
   1 +slow w,                   \ PIN72 - TWSI3
     no-update,                 \ PIN73
   1 +slow w,                   \ PIN74  - LCD
   1 +slow w,                   \ PIN75  - LCD
   1 +pull-up +medium +slow w,  \ PIN76  - LCD
   1 +slow w,                   \ PIN77  - LCD
   1 +slow w,                   \ PIN78  - LCD
   1 +slow w,                   \ PIN79  - LCD
   1 +slow w,                   \ PIN80  - LCD
   1 +slow w,                   \ PIN81  - LCD
   1 +slow w,                   \ PIN82  - LCD
   1 +slow w,                   \ PIN83  - LCD
   1 +slow w,                   \ PIN84  - LCD
   1 +slow w,                   \ PIN85  - LCD
   1 +slow w,                   \ PIN86  - LCD
   1 +slow w,                   \ PIN87  - LCD
   1 +slow w,                   \ PIN88  - LCD
   1 +slow w,                   \ PIN89  - LCD
   1 +slow w,                   \ PIN90  - LCD
   1 +slow w,                   \ PIN91  - LCD
   1 +slow w,                   \ PIN92  - LCD
   1 +slow w,                   \ PIN93  - LCD
   1 +slow w,                   \ PIN94  - LCD
   1 +slow w,                   \ PIN95  - LCD
   1 +slow w,                   \ PIN96  - LCD
   1 +slow w,                   \ PIN97  - LCD
   1 +slow w,                   \ PIN98  - LCD
   1 +slow w,                   \ PIN99  - LCD
   1 +slow w,                   \ PIN100 - LCD
   1 +slow w,                   \ PIN101 - LCD
     no-update,                 \ PIN102
     no-update,                 \ PIN103
   0 w,                         \ PIN104 - NAND
   0 w,                         \ PIN105 - NAND
   0 w,                         \ PIN106 - NAND
   0 w,                         \ PIN107 - NAND
   2 +medium w,                 \ PIN108 - NONE
   2 +medium w,                 \ PIN109 - NONE
   2 +medium w,                 \ PIN110 - NONE
   2 +medium w,                 \ PIN111 - MMC3
   0 w,                         \ PIN112 - NAND
     no-update,                 \ PIN113
     no-update,                 \ PIN114
     no-update,                 \ PIN115
     no-update,                 \ PIN116
     no-update,                 \ PIN117
     no-update,                 \ PIN118
     no-update,                 \ PIN119
     no-update,                 \ PIN120
     no-update,                 \ PIN121
     no-update,                 \ PIN122
     no-update,                 \ PIN123
     no-update,                 \ PIN124
     no-update,                 \ PIN125
   0 +pull-up-alt w,            \ PIN126 - GPIO126
   0 +pull-up-alt w,            \ PIN127 - GPIO127
     no-update,                 \ PIN128
     no-update,                 \ PIN129
     no-update,                 \ PIN130
   1 +medium w,                 \ PIN131 - MMC1
   1 +medium w,                 \ PIN132 - MMC1
   1 +medium w,                 \ PIN133 - MMC1
   1 +medium w,                 \ PIN134 - MMC1
   1 +medium w,                 \ PIN135 - NONE
   1 +medium w,                 \ PIN136 - MMC1
     no-update,                 \ PIN137
     no-update,                 \ PIN138
     no-update,                 \ PIN139
   1 +pull-up w,                \ PIN140 - MMC1
   1 +pull-up w,                \ PIN141 - MMC1
     no-update,                 \ PIN142
   0 w,                         \ PIN143 - NAND
   0 w,                         \ PIN144 - NAND
   2 +medium w,                 \ PIN145 - NONE
   2 +medium w,                 \ PIN146 - NONE
   0 w,                         \ PIN147 - NAND
   0 w,                         \ PIN148 - NAND
   0 w,                         \ PIN149 - NAND
   0 w,                         \ PIN150 - NAND
   0 w,                         \ PIN151 - SMC
   0 w,                         \ PIN152 - SMC
     no-update,                 \ PIN153
   0 w,                         \ PIN154 - SMC_INT
     no-update,                 \ PIN155
     no-update,                 \ PIN156
     no-update,                 \ PIN157
     no-update,                 \ PIN158
     no-update,                 \ PIN159
     no-update,                 \ PIN160
   2 +medium w,                 \ PIN161 - NONE
   2 +medium w,                 \ PIN162 - MMC3
   2 +medium w,                 \ PIN163 - MMC3
   2 +medium w,                 \ PIN164 - MMC3
   0 w,                         \ PIN165 - NAND
   0 w,                         \ PIN166 - NAND
   0 w,                         \ PIN167 - NAND
   0 w,                         \ PIN168 - NAND
   0 +slow w,                   \ PIN169 - TWSI4_SCL
   0 +slow w,                   \ PIN170 - TWSI4_SDA
     no-update,                 \ PIN171
here mfpr-table - /w / constant #mfprs
