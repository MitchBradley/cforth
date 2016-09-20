" "  " 8"  " /spi" begin-package

" sd" name
my-address my-space 1 reg

: bits-in  ( n -- bits )  " bits-in" $call-parent  ;
: out-in  ( out -- bits )  " out-in" $call-parent  ;

0 instance value deblocker

0 instance value offset-low     \ Offset to start of partition
0 instance value offset-high

0 instance value label-package

\ Sets offset-low and offset-high, reflecting the starting location of the
\ partition specified by the "my-args" string.

: init-label-package  ( -- okay? )
   0 to offset-high  0 to offset-low
   my-args  " disk-label"  $open-package to label-package
   label-package  if
      0 0  " offset" label-package $call-method to offset-high to offset-low
      true
   else
      ." Can't open disk label package"  cr  false
   then
;

: block-size  ( -- n )  /sd-block  ;
: max-transfer  ( -- n )  /sd-block  ;

: read-blocks  ( adr block# #blocks -- #written )
   1 <> abort" Bad #blocks"      ( adr block# )
   block-size swap read-single   ( )
   1
;
: write-blocks  ( adr block# #blocks -- #written )
   1 <> abort" Bad #blocks"      ( adr block# )
   block-size swap write-single   ( )
   1
;

: seek  ( d.offset -- error? )
   deblocker 0=  if  2drop true  exit  then
   offset-low offset-high d+  " seek"  deblocker $call-method
;
: read  ( addr len -- actual-len )
   deblocker 0=  if  2drop 0  exit  then
    " read"  deblocker $call-method
;
: write ( addr len -- actual-len )
   deblocker 0=  if  2drop 0  then
   " write" deblocker $call-method
;
: size  ( -- d )
   deblocker 0=  if  0.  exit  then
   " size" deblocker $call-method
;

: close  ( -- )
   label-package  if  label-package close-package  then
   deblocker  if  deblocker close-package  then
;

0 value open-count
: open  ( -- )
   my-unit " set-address" $call-parent
   0 true #100000 " setup" $call-parent  0=  if  false exit  then

   open-count 0=  if
      ['] bits-in to spi-bits-in
      ['] out-in to spi-out-in

      ['] sd-init catch  if  close false exit  then
   then

   " "  " deblocker" $open-package  to deblocker
   deblocker 0=  if  false exit  then

   my-args  " disk-label"  $open-package  to label-package
   label-package  if
      0 0  " offset" label-package $call-method  to offset-high  to offset-low
   else
\     ." Can't open disk label package"  cr
      open-count 0=  if  close  then
      false exit
   then

   open-count 1+ to open-count
   true
;

end-package
