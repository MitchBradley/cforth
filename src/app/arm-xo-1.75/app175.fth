create cl2-a2  \ OLPC XO-1.75

fl ../arm-xo-1.75/gpiopins.fth
fl ../arm-mmp2/mfprbits.fth
fl ../arm-xo-1.75/mfprtable.fth

\ h# 88028416 constant wanted-fuses

fl app.fth
