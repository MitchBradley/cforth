fl ../../cforth/printf.fth

: sha256  ( dst-adr src-adr src-len -- )
   sha256-open >r           ( dst-adr src-adr len  r: context )
   swap r@ sha256-update    ( dst-adr   r: context )
   r> sha256-close          ( )
;

\ Progress reports for downloading
\ These can be overridden with graphical versions
defer show-phase  ( adr len -- )
: text-show-phase  ( adr len -- )  type cr  ;
' text-show-phase to show-phase

defer set-progress-range  ( high low -- )
: text-set-range  ( high low -- )  2drop  ;
' text-set-range to set-progress-range

defer show-progress
: text-show-progress  ( n -- )  .x (cr  ;
' text-show-progress to show-progress

defer progress-done
: text-progress-done  ( -- )  cr  ;
' text-progress-done to progress-done


[ifdef] libusb_init
fl usbtools.fth
fl usbdfu.fth
[then]

" app.dic" save
