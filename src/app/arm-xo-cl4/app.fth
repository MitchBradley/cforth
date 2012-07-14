create cl4  \ OLPC XO-CL4

fl ../arm-xo-cl4/gpiopins.fth
fl ../arm-mmp2/mfprbits.fth
fl ../arm-xo-cl4/mfprtable.fth

fl ../arm-xo-1.75/drivers.fth
fl ../arm-xo-1.75/memtest.fth

: board-config  ( -- )
   \ Add board-revision-specific setup as necessary
;

: late-init
   thermal

   \ Select the 1 GHz operating point - op5 - only if both the board
   \ and the SoC are rated for operation at that speed.
   1 gpio-pin@  rated-speed 2 =  and  if  op5  else  op4  then

   init-dram
;

fl ../arm-xo-1.75/ofw.fth

\ Run this at startup
: app  ( -- )
   init-drivers
   board-config
   early-activate-cforth?  0=  if  ofw  then
   ." Skipping OFW" cr
   hex protect-fw quit
;

" app.dic" save
