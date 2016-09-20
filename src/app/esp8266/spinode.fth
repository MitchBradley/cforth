" "  " 60000100"  " /" begin-package

" spi" name
my-address my-space  $100 reg

1 " #address-cells" integer-property
1 " #size-cells" integer-property

: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

#8 constant hw-cs-pin
0 instance value cs-pin

: open  ( -- okay? )  true  ;
: close  ( -- )
\ It's better not to close the SPI because that makes the lines float,
\ which can confuse the card
\    spi-close
;

: set-address  ( pin# -- )
   dup hw-cs-pin =  if  drop -1  then
   to cs-pin
;
: setup  ( datamode msbfirst? frequency -- okay? )
   cs-pin  ['] spi-open  catch  if  4drop false  else  true  then  ;
;

: bits-in  ( n -- bits )  spi-bits@  ;
: out-in   ( outbuf inbuf #bytes -- )  spi-transfer  ;

end-package
