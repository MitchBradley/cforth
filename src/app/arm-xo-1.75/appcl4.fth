create cl4  \ OLPC XO-CL4

fl ../arm-xo-cl4/gpiopins.fth
fl ../arm-mmp2/mfprbits.fth
fl ../arm-xo-cl4/mfprtable.fth

\ h# 88028416 constant wanted-fuses

fl app.fth
