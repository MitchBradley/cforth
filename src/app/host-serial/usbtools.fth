\ USB tools based on libusb

0 value #devs
0 value devs

: init-libusb  ( -- )  0 libusb_init abort" libusb init failed"  ;

: get-devs
   init-libusb

   0 sp@  ( 'list )  0 libusb_get_device_list ( list #devs )
   to #devs  to devs
;

\needs .2x : .2x  ( n -- )  push-hex  <# u# u# u#> pop-base  type   ;
\needs .4x : .4x  ( n -- )  push-hex  <# u# u# u# u# u#> pop-base  type  ;

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
  /w field >bcddevice
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
   /n field >'alt-interfaces
 /int field >#alt-interfaces
constant /interface-array

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
/int field >interface-#extra
  /n round-up
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
/int field >ep-#extra
  /n round-up
constant /ep-descriptor

/device-descriptor buffer: dev-desc

: .devs  ( -- )
   #devs 0  ?do
      dev-desc  devs i na+ @  libusb_get_device_descriptor  abort" Can't get dev descriptor"
      ." VID.PID "  dev-desc >vid w@ .4x  ." ." dev-desc >pid w@ .4x
      ."  /EP0 "  dev-desc >dev-/ep0 c@ .2x
      dev-desc >dev-class c@  if
         ."   Class "
         dev-desc >dev-class    c@ .2x  ." ."
         dev-desc >dev-subclass c@ .2x  ." ."
         dev-desc >dev-protocol c@ .2x
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
      dev-desc >vid l@ vidpid =  if  1+  then
   loop
;
