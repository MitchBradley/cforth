create cl3  \ OLPC XO-3.0

fl ../arm-xo-3.0/gpiopins.fth
fl ../arm-mmp2/mfprbits.fth
fl ../arm-xo-3.0/mfprtable.fth

h# 90029410 constant wanted-fuses

fl ../arm-xo-1.75/app.fth
