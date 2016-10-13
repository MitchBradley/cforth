\needs struct fl ../../lib/struct.fth
struct
   #32 field >ssid
   #64 field >password
   /c   field >ssid-len
   /c  field >channel
   2 +  \ Padding to align
   /l  field >authmode
   /c  field >ssid-hidden
   /c  field >max-connection
   /w  field >beacon-interval
constant /ap-config

: ?wifi-error  ( status -- )  1 <> abort" Wifi failed"  ;

: set-ap  ( ssid$ password$ channel# authmode -- )
   pad /ap-config erase      ( ssid$ password$ channel# authmode )
   pad >authmode l!          ( ssid$ password$ channel# )
   pad >channel c!           ( ssid$ password$ )
   pad >password swap move   ( ssid$ )
   dup  pad >ssid-len c!     ( ssid$ )
   pad >ssid swap move       ( )
   0  pad >ssid-hidden c!    ( )
   4  pad >max-connection c! ( )
   #100 pad >beacon-interval w!  ( )
   pad wifi-ap-config!  ?wifi-error
;
: set-ap-psk  ( ssid$ password$ channel# -- )  4 set-ap  ;
: set-ap-open  ( ssid$ channel# -- )  " "  rot  0 set-ap  ;

: ap-mode  ( -- )  2 wifi-opmode!  ;
: station-mode  ( -- )  1 wifi-opmode!  ;
: set-station  ( ssid$ password$ -- )
   pad #104 erase            ( ssid$ password$ )
   pad >password swap move   ( ssid$ )
   pad >ssid swap move       ( )
   pad wifi-sta-config!  ?wifi-error
;
: station-connect  ( ssid$ password$ -- )
   station-mode
   set-station wifi-sta-connect  ?wifi-error
   wifi-sta-dhcpc-start  ?wifi-error
   begin                  ( )
      wifi-sta-connect@   ( status )
      dup 1 =             ( status connecting? )
   while                  ( status )
      drop  #10 ms        ( )
   repeat                 ( status )
   wifi-sta-dhcpc-stop  ?wifi-error  ( status )
   case
      0 of  ." Idle!"    endof
      \ 1 is handled in the loop above
      2 of  ." Wrong password" cr   endof
      3 of  ." No AP found" cr    endof
      4 of  ." Connect failed" cr   endof
      5 of  exit  endof  \ Got IP; the okay case
      ( default )  ." Bad status: " dup .d cr  swap
   endcase
   abort
;
