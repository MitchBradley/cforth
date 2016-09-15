" "  " 8"  " /spi" begin-package

" sd" name
my-address my-space 1 reg

: bits-in  ( n -- bits )  " bits-in" $call-parent  ;
: out-in  ( out -- bits )  " out-in" $call-parent  ;

0 instance value deblocker


$200 constant block-size

: read-blocks  ( adr block# #blocks -- #written )
   dup >r  block-size *  ( adr block# #bytes  r: #blocks )
   swap read-multiple    ( r: #blocks )  
   r>
;
: write-blocks  ( adr block# #blocks -- #written )
   dup >r  block-size *  ( adr block# #bytes  r: #blocks )
   swap read-multiple    ( r: #blocks )  
   r>
;


: seek  ( d.offset -- error? )
   deblocker 0=  if  2drop true  exit  then
   " seek"  deblocker $call-method
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

: open  ( -- )
   my-unit " set-address" $call-parent
   0 true #100000 " setup" $call-parent  0=  if  false exit  then

   " "  " deblocker" $open-package  to deblocker
   deblocker 0=  if  false exit  then

   ['] bits-in to spi-bits-in
   ['] out-in to spi-out-in

   ['] sd-init catch  if  false exit  then
   true
;

: close  ( -- )
   deblocker  if  deblocker close-package  then
;

end-package
