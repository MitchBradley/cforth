\ USB Diagnostic Firmware Update (DFU)

$80 constant USB_ENDPOINT_IN
$00 constant USB_ENDPOINT_OUT
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
   l->n
;
: dfu-in   ( len data index value req -- res )  USB_ENDPOINT_IN  dfu-control  ;
: dfu-out  ( len data index value req -- res )  USB_ENDPOINT_OUT dfu-control  ;
: dfu-clear-status  ( -- )
   0 0 0 0 DFU_CLRSTATUS dfu-out 0< abort" Clear status failed"
;
false value verbose-status?
: (dfu-get-status)  ( -- state )
   begin
      6 dfu-status 0 0 DFU_GETSTATUS dfu-in  ( #bytes )
      dup 6 =  if                            ( #bytes )
         verbose-status?  if  dfu-status 6 cdump cr  then

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
: set-next-status-time   ( -- )
   dfu-status 1+ 3b@  dup  if
      verbose-status?  if  ." Time " dup .d cr  then
      get-msecs +
   then
   to next-status-ms
;

  2 constant DFU_IDLE_STATE
  4 constant DOWNLOAD_BUSY_STATE
  5 constant DOWNLOAD_IDLE_STATE
  7 constant DFU_MANIFEST_STATE
#10 constant DFU_ERROR_STATE

: dfu-get-status  ( -- state )
   (dfu-get-status)                      ( state )
   dup DFU_ERROR_STATE =  if             ( state )
      drop                               ( )
      \ dfu-status c@  #10  <>  if       ( )
      \    \ #10 means that the main (non-DFU) firmware is corrupt -
      \    \ which is a common situation when initially programming it
      \    ." DFU get status error - status " dfu-status c@ .x cr
      \ then                             ( )
      #100 ms  dfu-clear-status  #100 ms
      (dfu-get-status)                   ( state )
   then                                  ( state )
   set-next-status-time                  ( state )
;

: .status  ( -- )  dfu-get-status dfu-status drop  6 cdump cr  ;

\ This gets back to idle from states like upload and download
: dfu-abort-to-idle  ( -- )
   0 0 0 0 DFU_ABORT dfu-out 0< abort" Abort command error"
   dfu-get-status DFU_IDLE_STATE <> abort" Did not enter IDLE state"
;

: claim+alt+status  ( -- state )
   0 dfu-handle libusb_claim_interface abort" Error claiming interface"
   0 0 dfu-handle libusb_set_interface_alt abort" Error setting alt"
   dfu-get-status
;

: release  ( -- )
   0 dfu-handle libusb_release_interface abort" Error releasing interface"
;

: /ep0  ( -- n )  dev-desc >dev-/ep0 c@  ;
: #configurations  ( -- n )  dev-desc >#configurations c@  ;

0 value cfg-desc
0 value ifce-desc

$40 buffer: ifce-string
0 value /ifce-string

0 value dfu-flash-base
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

: parse-mem-layout  ( adr len -- )
   regions  if  2drop exit  then          ( adr len )
   " /" lex  0= abort" Lex1"  drop 2drop  ( rem$ )
   " /" lex  0= abort" Lex2"  drop        ( rem$ head$ )
   2 /string                              ( rem$' )  \ Drop 0x
   push-hex $number pop-base abort" Number"  to dfu-flash-base  ( rem$ )
   here to regions  0 to #regions         ( rem$ )
   begin  " ," lex   while                ( rem$ head$ char )
      drop set-regions                    ( rem$ )
   repeat                                 ( rem$ )
   set-regions                            ( )
;

0 value dfu-desc
: dfu-version  ( -- n )
   dfu-desc  if
      dfu-desc c@ 7 =  if
          $0100
      else
         dfu-desc 7 + w@
      then
   else
      0
   then
;
: transfer-size  ( -- n )
   dfu-desc  if
      dfu-desc 5 + w@
   else
      0
   then
;

$21 constant DT_DFU
: search-dfu-descriptor  ( extra$ -- )
   begin  dup 2 >=  while       ( extra$ )
      over c@  >r               ( extra$ r: thislen )
      r@ 0=  if                 ( extra$ r: thislen )
         r> 3drop false exit    ( -- false )
      then                      ( extra$ r: thislen )
      over 1+ c@  DT_DFU =  if  ( extra$ r: thislen )
         r> 2drop to dfu-desc   ( )
         exit                   ( )
      then                      ( extra$ r: thislen )
      r> /string                ( extra$' )
   repeat                       ( extra$ )
   2drop                        ( )
;

0 value alt-array
0 value #alts
: set-alts  ( index -- )
   cfg-desc >'interfaces swap na+ @  dup  if   ( adr )
      dup >'alt-interfaces @  to alt-array     ( adr )
      >#alt-interfaces @      to #alts         ( )
   else                          ( adr )
      drop  0 to #alts  exit     ( -- )
   then                          ( )
;

: set-ifce  ( index -- )
   alt-array swap /interface-descriptor * +  to ifce-desc
;
: check-dfu-in-cfg  ( -- )
   cfg-desc >config-'extra @  ?dup  if
      cfg-desc >config-#extra int@  search-dfu-descriptor
   then
;
: check-dfu-in-alt  ( -- )
   dfu-desc  if  exit  then

   ifce-desc >class c@ $fe =  ifce-desc >subclass c@ $01 =  and  if
      ifce-desc >interface-'extra @  ?dup  if
         ifce-desc >interface-#extra int@  search-dfu-descriptor
      then
   then
;

$40 buffer: desc-str-buf
: get-string  ( index -- $ )
   ?dup  if
      $40 desc-str-buf  rot  dfu-handle  libusb_get_string_descr_ascii  ( len )
      dup 0<  if
         ." get-string failed" cr
         drop 0
      then
      desc-str-buf swap
   else
      " "
   then
;

false value verbose-scan?
: scan-interfaces  ( -- )
   \ Loop over interfaces
   cfg-desc >#interfaces c@  0  ?do
      i set-alts
      verbose-scan?  if  ." Interface " i .  cr  then

      \ Loop over alternate settings
      #alts 0  ?do
         i set-ifce

         \ Get the string for this alternate setting
         ifce-desc >interface-sindex c@  dup  if  ( sindex )
            $40 ifce-string  rot  dfu-handle      ( len adr sindex handle )
            libusb_get_string_descr_ascii         ( strlen )
         then                                     ( strlen )
         to /ifce-string                          ( )

         \ If this is a DFU device (protocol 2), check the extra field
         \ for a DFU tag containing the transfer size, and also parse
         \ the memory layout from the string.  Once those items have been
         \ found, subsequent calls to the parsers will exit immediately.
         ifce-desc >protocol c@ 2 =  if
            check-dfu-in-alt
            ifce-string /ifce-string parse-mem-layout
         then

         verbose-scan? if
            ."   protocol " ifce-desc >protocol c@ .d
            ifce-string /ifce-string type cr
         then

      loop
      verbose-scan?  if  cr  then
   loop
;

: dfu-setup  ( vid pid -- )
   init-libusb
   \ Open the device (currently hardwired to the STM DFU ID)
   swap 0 libusb_open_device_with_vid_pid to dfu-handle
   dfu-handle 0= abort" Cannot open device in DFU mode.  Hold the Y key while plugging it in."

   \ Get the device descriptor
   dfu-handle libusb_get_device to dfu-dev
   dev-desc  dfu-dev libusb_get_device_descriptor  abort" Can't get dev descriptor"

   \ Display the device name and serial number
   dev-desc >manufacturer-sindex c@ get-string type  ."  "
   dev-desc >product-sindex      c@ get-string type  ."  "
   dev-desc >sn-sindex           c@ get-string type  cr

   0 sp@  0 dfu-dev  libusb_get_config_descriptor abort" Can't get config descriptor"
   ( cfg-descr ) to cfg-desc

   \ Get the configuration descriptor and grovel through its interfaces
   \ and alternate settings looking for information that we need, including
   \ the transfer size and the region map

   cfg-desc >'interfaces @              ( adr )
   dup >'alt-interfaces @ to alt-array  ( adr )
   >#alt-interfaces int@ to #alts       ( )

   scan-interfaces

   transfer-size 0= abort" Did not find transfer size"
   regions 0= abort" Did not find the FLASH region map"

   \ Put the device into IDLE state in readiness for further operations
   claim+alt+status  2 <>  if
      dfu-clear-status
      release
      claim+alt+status 2 <>  abort" Can't put DFU into idle state"
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


\ DfuSe devices use transaction numbers 0 and 1 for special commands
\ like set-address and erase

2 value transaction0

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

\needs le-l!  : le-l!  ( l adr -- )  >r  lbsplit  r@ 3 + c! r@ 2+ c! r@ 1+ c! r> c!  ;

0 value base-adr

\ Set the base address for the next download or upload sequence.
\ The next state is DOWNLOAD_IDLE
: dfu-set-address  ( address -- )
   cmd-buf 1+ le-l!  5 $21 dfu-command
   dup to base-adr
;

: dfu-erase-region  ( adr -- )  cmd-buf 1+ le-l!  5 $41 dfu-command  ;
: dfu-mass-erase  ( -- )  1 $41 dfu-command  ;
: dfu-read-unprotect  ( -- )  1 $92 dfu-command  ;

: dfu-chunk  ( len adr transaction -- #bytes )
   (dfu-down)  dup  0<  if   ( error )
      ." Download failed, libusb error " .d cr
      abort
   then                      ( #bytes )

   0  begin                           ( #bytes state )
      drop                            ( #bytes )
      dfu-get-status                  ( #bytes state )
      dup  DOWNLOAD_IDLE_STATE =      ( #bytes state flag )
      over DFU_ERROR_STATE     = or   ( #bytes state flag )
      over DFU_MANIFEST_STATE  = or   ( #bytes state flag )
   until                              ( #bytes state )

   DFU_MANIFEST_STATE =  if                   ( #bytes )
      ." Running new code" cr                 ( #bytes )
\ The "manifest state" comment is more accurate, but not user-friendly
\     ." Transition to manifest state" cr     ( #bytes )
   then                                       ( #bytes )

   dfu-status c@  ?dup  if                    ( #bytes )
      ." Download failed with status " .  cr  ( #bytes )
      abort
   then                                       ( #bytes )
;

\ FLASH regions, possibly with different erasure sizes
: region-size  ( i -- )  regions swap 2* la+ l@  ;

\ Find the region containing adr
: >region#-  ( adr -- n )
   dfu-flash-base                  ( adr fadr )
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
   dfu-flash-base                  ( adr fadr )
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
   dfu-flash-base swap 0  ?do   ( end# start# adr )
      i region-size +           ( end# start# adr' )
   loop                         ( end# start# adr )
;

: dfu-read-chunk  ( adr len offset -- actual )
   swap transfer-size min  -rot   ( thislen adr offset )
   base-adr -  transfer-size /    ( thislen adr index )
   transaction0 +  dfu-up         ( actual )
;

: dfu-write-chunk  ( adr len offset -- actual )
   swap transfer-size min  -rot   ( thislen adr offset )
   base-adr -  transfer-size /    ( thislen adr index )
   transaction0 + dfu-chunk       ( actual )
;

\needs 3dup  : 3dup  2 pick  2 pick  2 pick  ;

\ Read len bytes into memory at adr from device address offset
: dfu-read   ( adr len offset -- )
   dup dfu-set-address       ( adr len offset )
   dfu-abort-to-idle  \ dfu-set-address sets state to DOWNLOAD_IDLE

   begin  over 0>  while     ( adr len offset )
      3dup dfu-read-chunk    ( adr len offset  actual-len )
      dup 0< abort" Error"
      tuck +  >r /string r>  ( adr' len' offset' )
   repeat                    ( adr len offset )
   3drop                     ( )
   dfu-abort-to-idle         ( )
;

\ Write len bytes from memory at adr to device address offset
\ The device area must have already been erased.
: dfu-write   ( adr len offset -- )
   dup dfu-set-address       ( adr len offset )

   begin  over 0>  while     ( adr len offset )
      dup show-progress      ( adr len offset )
      3dup dfu-write-chunk   ( adr len offset  actual-len )
      dup 0<   if  ." Error " dup .d ."   "  .status  cr abort  then
      tuck +  >r /string r>  ( adr' len' offset' )
   repeat                    ( adr len offset )
   3drop                     ( )
   dfu-abort-to-idle         ( )
;

: dfu-erase-regions  ( start# end# -- )
   swap  dup >region-base      ( end# start# adr )
   -rot  ?do                   ( adr )
      dup show-progress        ( adr )
      dup dfu-erase-region     ( adr )
      i region-size +          ( adr' )
   loop                        ( adr )
   drop
;

\ Erase FLASH erasure regions to include the range flash-adr,len
: dfu-erase  ( flash-adr len -- )
   over dfu-flash-base u< abort" Start address less than FLASH base"  ( adr len )
   over >region#- -rot      ( start-region# adr len )
   + >region#+              ( start-region# end-region# )
   dfu-erase-regions        ( )
;

: dfu-program  ( adr len  flash-adr -- )
   " Erasing ... "  show-phase            ( adr len  flash-adr )
   2dup swap dfu-erase                    ( adr len  flash-adr )
   progress-done

   " Programming ... " show-phase         ( adr len  flash-adr )
   2dup swap bounds set-progress-range    ( adr len  flash-adr )
   dfu-write                              ( adr len  flash-adr )
   progress-done

   " Complete" show-phase                 ( )
;

: dfu-leave  ( -- )
   dfu-flash-base dfu-set-address
   0 0 2  dfu-chunk
;
