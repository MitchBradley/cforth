\ 3950 B constant B 25/100 - 3950K

\ T in degrees Kelvin
\ T0 = 298 = 273 + 25
\ R = R0 exp(B * (1/T - 1/T0))
0 [if]
C  R/R25 alpha%/degK
00 3.20  5.0
05 2.50  4.9

10 1.97  4.7  50 deg F
15 1.56  4.6
20 1.25  4.5
25 1.00  4.4
30 0.80  4.2
35 0.65  4.1
40 0.53  4.0  104 deg F

45 0.44  3.9
50 0.36  3.8
55 0.30  3.7
60 0.25  3.6
65 0.21  3.5
https://www.adafruit.com/datasheets/103_3950_lookuptable.pdf
\ Over the range of 
[then]

