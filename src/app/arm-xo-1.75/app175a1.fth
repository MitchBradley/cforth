create cl2-a1  \ OLPC XO-1.75 A1

fl ../arm-xo-1.75/gpiopins-a1.fth
fl ../arm-mmp2/mfprbits.fth
fl ../arm-xo-1.75/mfprtable-a1.fth

h# 88028416 constant wanted-fuses

fl app.fth
