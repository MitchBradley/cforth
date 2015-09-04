\ Interface to USB-RLY16 relay board

-1 value relay-fid
: ?open-usb-relays  ( -- )
   relay-fid 0<  if
      -1 h-open-com to relay-fid
      #19200 relay-fid baud
   then
;
0 buffer: relay-buf
: usb-relay!  ( char -- )  relay-buf c!  relay-buf 1 relay-fid h-write-file drop  ;
: usb-relays-on   ( -- )  'd' usb-relay!  ;
: usb-relays-off  ( -- )  'n' usb-relay!  ;
: usb-relay-on   ( relay# -- )  'e' + usb-relay!  ;
: usb-relay-off  ( relay# -- )  'o' + usb-relay!  ;

: use-rly16  ( -- )
   ['] ?open-usb-relays  to ?open-relays
   ['] usb-relay-on      to relay-on
   ['] usb-relay-off     to relay-off
;
