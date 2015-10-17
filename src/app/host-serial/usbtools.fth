\ USB tools based on libusb

0 value #devs
0 value devs

: init-libusb  ( -- )  0 libusb_init abort" libusb init failed"  ;

: get-devs
   init-libusb

   pad 0 libusb_get_device_list to #devs

   #devs /n* alloc-mem to devs
   pad @  devs  #devs /n*  move
;

\needs .2x : .2x  ( n -- )  push-hex  <# u# u# u#> pop-base  type   ;
\needs .4x : .4x  ( n -- )  push-hex  <# u# u# u# u# u#> pop-base  type  ;

#18 buffer: dev-desc
: desc-b@  ( n -- b )  dev-desc + c@  ;
: desc-w@  ( n -- w )  dev-desc + w@  ;
: desc-l@  ( n -- w )  dev-desc + l@  ;
: .devs  ( -- )
   #devs 0  ?do
      dev-desc  devs i na+ @  libusb_get_device_descriptor  abort" Can't get dev descriptor"
      ." VID.PID "  8 desc-w@ .4x  ." ." #10 desc-w@ .4x
      ." /EP0 "  7 desc-b@ .2x
      4 desc-b@  if
         ."   Class " 4 desc-b@ .2x ." ." 5 desc-b@ .2x ." ." 6 desc-b@ .2x
      then
      cr
   loop
;
0 value vidpid
: #matches  ( vid pid -- n )
   wljoin to vidpid
   0
   #devs 0  ?do  ( n )
      dev-desc  devs i na+ @  libusb_get_device_descriptor  abort" Can't get dev descriptor"
      8 desc-l@ vidpid =  if  1+  then
   loop
;

$80 constant USB_ENDPOINT_IN
$80 constant USB_ENDPOINT_OUT
1 5 << constant USB_REQUEST_TYPE_CLASS
1 constant USB_RECIPIENT_INTERFACE

#100 value dfu-timeout
0 value dfu-handle
0 value dfu-dev
6 buffer: dfu-status

0 constant DFU_DETACH
1 constant DFU_DNLOAD
2 constant DFU_UPLOAD
3 constant DFU_GETSTATUS
4 constant DFU_CLRSTATUS
5 constant DFU_GETSTATE
6 constant DFU_ABORT

: dfu-control  ( len data index value req in/out -- res )
   2>r 2>r 2>r dfu-timeout  2r> 2r> 2r>
   USB_REQUEST_TYPE_CLASS or USB_RECIPIENT_INTERFACE or
   dfu-handle libusb_control_transfer
;
: dfu-in   ( len data index value req -- res )  USB_ENDPOINT_IN  dfu-control  ;
: dfu-out  ( len data index value req -- res )  USB_ENDPOINT_OUT dfu-control  ;
: dfu-clear-status  ( -- )
   0 0 0 0 DFU_CLRSTATUS dfu-out 0< abort" Clear status failed"
;
: (dfu-get-status)  ( -- state )
   begin
      6 dfu-status 0 0 DFU_GETSTATUS dfu-in  ( #bytes )
      dup 6 =  if                            ( #bytes )
         drop  dfu-status 4 + c@  exit       ( -- state )
      then                                   ( #bytes )
      dup 0<>  if                            ( #bytes )
         ." dfu-get-status failed - #bytes = " .x cr
         abort
      then                                   ( #bytes )
      drop                                   ( )
      \ Retry 0-byte returns
   again
;
: 3b@  ( adr -- n )  >r r@ c@ r@ 1+ c@ r> 2+ c@ 0 bljoin  ;

0 value next-status-ms
: wait-status   ( -- )
   next-status-ms  if
      next-status-ms get-msecs -  ( wait )
      0 max  ?dup  if  ." wait" cr ms  then
   then
;
: set-next-status   ( -- )
   dfu-status 1+ 3b@  dup  if
      ." Timeout " dup .d cr
      get-msecs +
   then
   to next-status-ms
;

: dfu-get-status  ( -- state )
   (dfu-get-status)                ( state )
   ." S0 " dfu-status 6 cdump

  dup #10 =  if                    ( state )
      drop                            ( )
      dfu-status c@  #10  <>  if      ( )
         \ #10 means that the main (non-DFU) firmware is corrupt -
         \ which is a common situation when initially programming it
         ." DFU get status error - status " dfu-status c@ .x cr
      then                            ( )
      #100 ms
      dfu-clear-status
      #100 ms
      (dfu-get-status)
      ." S1 " dfu-status 6 cdump
   then                               ( state )
   set-next-status
;

: claim+alt+status  ( -- state )
   0 dfu-handle libusb_claim_interface abort" Error claiming interface"
   0 0 dfu-handle libusb_set_interface_alt abort" Error setting alt"
   dfu-get-status
;
: release  ( -- )
   0 dfu-handle libusb_release_interface abort" Error releasing interface"
;
: .status  ( -- )  dfu-get-status dfu-status drop  6 cdump cr  ;

: /ep0  ( -- n )  7 desc-b@  ;
: #configurations  ( -- n )  #17 desc-b@  ;

0 constant struct
: field  ( offset n -- )  create over , + does> @ +  ;

struct
   1 field >length
   1 field >dtype
  /w field >bcdusb
   1 field >dev-class
   1 field >dev-subclass
   1 field >dev-protocol
   1 field >dev-/ep0
  /w field >vid
  /w field >pid
   1 field >manufacturer-sindex
   1 field >product-sindex
   1 field >sn-sindex
   1 field >#configurations
constant /device-descriptor

struct
   2+
  /w field >total-length
   1 field >#interfaces
   1 field >config-value
   1 field >config-sindex
   1 field >config-attributes
   1 field >max-power
  /n round-up
  /n field >'interfaces
  /n field >config-'extra
  /n field >config-#extra
constant /config-descriptor

struct
\   1 field >length
\   1 field >dtype
  2+
   1 field >interface#
   1 field >alt-setting
   1 field >#endpoints
   1 field >class
   1 field >subclass
   1 field >protocol
   1 field >interface-sindex
  /n round-up
  /n field >'endpoints
  /n field >interface-'extra
  /n field >interface-#extra
constant /interface-descriptor

struct
\   1 field >length
\   1 field >dtype
  2+
   1 field >ep#
   1 field >ep-attributes
  /w field >ep-/packet
   1 field >interval
   1 field >refresh
   1 field >synch-address
  /n round-up
  /n field >ep-'extra
  /n field >ep-#extra
constant /ep-descriptor

0 value cfg
0 value ifce
$40 buffer: ifce-string
0 value /ifce-string

0 value membase
0 value regions
0 value #regions
: dec#  ( adr len -- )  push-decimal $number pop-base abort" NumberR"  ;
: region-type&size  ( adr len -- type size )  \ e.g. 064Kg
   " KM" lex 0= abort" LexS"   ( rem$ head$ char )
   >r  dec# #1024 * r>         ( rem$ n char )
   'M' =  if  #1024 *  then    ( rem$ size )
   >r drop c@  r>              ( type size )
;
: set-regions  ( adr len -- )
   " *" lex 0= abort" LexR" drop        ( rem$ head$ )
   dec#  dup #regions + to #regions     ( rem$ nregions )
   -rot  region-type&size               ( nregions type size )
   rot  0  ?do   dup l, over l,  loop   ( type size )
   2drop
;

: parse-mem-layout  ( -- )
   ifce-string /ifce-string               ( adr len )
   " /" lex  0= abort" Lex1"  drop 2drop  ( rem$ )
   " /" lex  0= abort" Lex2"  drop        ( rem$ head$ )
   2 /string                              ( rem$' )  \ Drop 0x
   push-hex $number pop-base abort" Number"  to membase  ( rem$ )
   here to regions  0 to #regions         ( rem$ )
   begin  " ," lex   while                ( rem$ head$ char )
      drop set-regions                    ( rem$ )
   repeat                                 ( rem$ )
   set-regions                            ( )
;

: dfu-setup  ( -- )
   $df11 $483 0 libusb_open_device_with_vid_pid to dfu-handle
   dfu-handle 0= abort" Cannot open device in DFU mode.  Hold the Y key while plugging it in."

   dfu-handle libusb_get_device to dfu-dev
   dev-desc  dfu-dev libusb_get_device_descriptor  abort" Can't get dev descriptor"
   
   7 desc-b@ to /ep0

   pad 0 dfu-dev libusb_get_config_descriptor abort" Can't get config descriptor"
   pad @ to cfg

   cfg >'interfaces @ @ to ifce
   $40 ifce-string  ifce >interface-sindex c@  dfu-handle libusb_get_string_descr_ascii to /ifce-string

   ifce-string /ifce-string type cr
   parse-mem-layout

   claim+alt+status
." C0 " dup . cr
2 <>  if
      dfu-clear-status
      release
      claim+alt+status
." C1 " dup . cr
 2 <>  abort" Can't put DFU into idle mode"
   then
;

: dfu-up  ( len adr transaction -- #bytes )
   0 swap   ( len adr interface transaction )
   DFU_UPLOAD dfu-in
;

: (dfu-down)  ( len adr transaction -- status )
   0 swap   ( len adr interface transaction )
   DFU_DNLOAD dfu-out
;

  2 constant DFU_IDLE_STATE
  4 constant DOWNLOAD_BUSY_STATE
  5 constant DOWNLOAD_IDLE_STATE
  7 constant DFU_MANIFEST_STATE
#10 constant DFU_ERROR_STATE

5 buffer: cmd-buf
: dfu-command  ( len cmd -- )
   cmd-buf c!                          ( len )
   cmd-buf 0 (dfu-down)  0<  if        ( res )
      ." Command " cmd-buf c@ .x ." failed" cr
      abort
   then

   dfu-get-status DOWNLOAD_BUSY_STATE <>
   abort" Expecting DOWNLOAD_BUSY after special command"

   dfu-get-status drop
;
: dfu-chunk  ( len adr transaction -- #bytes )
   (dfu-down)  dup  0< abort" Download failed"   ( #bytes )

   begin
      dfu-get-status
      dup  DOWNLOAD_IDLE_STATE <>
      over DFU_ERROR_STATE     <> or
      over DFU_MANIFEST_STATE  <> or
   while             ( state )
      drop #200 ms
   repeat            ( state )

   DFU_MANIFEST_STATE =  if  ." Transition to manifest state" cr  then

   dfu-status c@  ?dup  if
      ." Download failed with status " .  cr
      abort
   then
;
\needs le-l!  : le-l!  ( l adr -- )  >r  lbsplit  r@ 3 + c! r@ 2+ c! r@ 1+ c! r> c!  ;
: dfu-set-address  ( address -- )  cmd-buf 1+ le-l!  5 $21 dfu-command  ;
: dfu-erase-region  ( adr -- )  cmd-buf 1+ le-l!  5 $41 dfu-command  ;
: dfu-mass-erase  ( -- )  1 $41 dfu-command  ;
: dfu-read-unprotect  ( -- )  1 $92 dfu-command  ;

: dfu-abort-to-idle  ( -- )
   0 0 0 0 DFU_ABORT dfu-out 0< abort" Abort command error"
   dfu-get-status DFU_IDLE_STATE <> abort" Did not enter IDLE state"
;

: region-size  ( i -- )  regions swap 2* la+ l@  ;

\ Find the region containing adr
: >region#-  ( adr -- n )
   membase                         ( adr fadr )
   #regions 0  ?do                 ( adr fadr )
      i region-size +              ( adr fadr' )
      2dup u<  if                  ( adr fadr' )
         2drop i unloop exit       ( adr fadr' )
      then                         ( adr fadr' )
   loop                            ( adr fadr' )
   2drop #regions
;

\ Find the first region whose start address is >= adr
: >region#+  ( adr -- n )
   membase                         ( adr fadr )
   #regions 0  ?do                 ( adr fadr )
      \ If adr falls right at the beginning of a region
      \ it is the right one
      2dup =  if                   ( adr fadr' )
         2drop i unloop exit       ( adr fadr' )
      then                         ( adr fadr' )

      i region-size +              ( adr fadr' )

      \ If adr is less than the end of a region, the
      \ next one is the right one.
      2dup u<  if                  ( adr fadr' )
         2drop i 1+ unloop exit    ( adr fadr' )
      then                         ( adr fadr' )
   loop                            ( adr fadr' )
   2drop #regions
;

: >region-base   ( region# -- )
   membase swap 0  ?do   ( end# start# adr )
      i region-size +    ( end# start# adr' )
   loop                  ( end# start# adr )
;

: dfu-erase-regions  ( start# end# -- )
   swap  dup >region-base      ( end# start# adr )
   -rot  ?do                   ( adr )
      dup dfu-erase-region     ( adr )
      dup (cr .x               ( adr )
      i region-size +          ( adr' )
   loop                        ( adr )
   drop
;

: dfu-erase  ( flash-adr len -- )
   over membase u< abort" Start address less than FLASH base"  ( adr len )
   over >region#- -rot      ( start-region# adr len )
   + >region#+              ( start-region# end-region# )
   dfu-erase-regions        ( )
;


0 [if]
\needs show-phase  : show-phase  type cr  ;
: dfu-flash-section  ( flash-adr -- )
   " Erasing ... "  show-phase            ( flash-adr )
   dup /bin-file dfu-erase                ( flash-adr )

   " Programming ... " show-phase         ( flash-adr )
   bin-file-buf                           ( flash-adr adr )
   /bin-file  /flash-page round-up        ( flash-adr adr len )
   2 pick over bounds  set-progress-range ( flash-adr adr len )
   rot dfu-write                          ( )

   " Complete" show-phase                 ( )
;

$0800.0000 value dl-base
: dfu-download  ( -- )
   ..
   dfu-abort-to-idle
   dl-base dfu-set-address
   2 0 0 dfu-chunk
;
[then]
