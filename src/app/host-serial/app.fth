fl ../../cforth/printf.fth

: sha256  ( dst-adr src-adr src-len -- )
   sha256-open >r           ( dst-adr src-adr len  r: context )
   swap r@ sha256-update    ( dst-adr   r: context )
   r> sha256-close          ( )
;

[ifdef] libusb_init
fl usbtools.fth
fl usbdfu.fth
[then]

" app.dic" save
