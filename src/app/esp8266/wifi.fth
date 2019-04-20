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
: ap-mode?  ( -- flag )  wifi-opmode@ 2 =  ;
: wifi-config  ( -- adr )
   pad ap-mode?  if
      wifi-ap-config@ drop
   else
      wifi-sta-config@ drop
   then
   pad
;
\ Station config structure
\ +0.b[32] is SSID
\ +32.b[64] is password
\ +96.b is bssid_set (0 to ignore bssid, 1 to match it)
\ +97.b[6] is bssid

\ AP config structure
\ +0.b[32] is SSID
\ +32.b[64] is password
\ +96.b is ssid_len
\ +97.b is channel
\ +100.l is auth_mode
\ +104.b is hidden
\ +105.b is max_connection
\ +106.w is beacon_interval
: ssid$  ( -- $ )  wifi-config cscount #32 min ;
: wifi-password$  ( -- $ )  wifi-config #32 + cscount  #64 min  ;
: .ssid  ( -- )
   ssid$ type
;

: ipaddr@  ( -- 'ip )
   pad  ap-mode? 1 and  wifi-ip-info@ drop  pad
;

: (.d)  ( n -- )  push-decimal (.) pop-base  ;
: .ipaddr  ( 'ip -- )
   3 0 do  dup c@ (.d) type ." ." 1+  loop  c@ (.d) type
;
: .ip/port  ( adr -- )
   dup 0=  if  drop ." (NULL)" exit  then
   ." Local: " dup 2 la+ .ipaddr ." :" dup 1 la+ l@ .d
   ." Remote: " dup 3 la+ .ipaddr ." :" l@ .d
;
0 [if]
: .conntype  ( n -- )
   case  0 of  ." NONE"  endof  $10 of  ." TCP" endof  $20 of ." UDP" endof  ( default ) dup .x endcase
;
: .connstate  ( n -- )
   case  0 of ." NONE" endof 1 of ." WAIT" endof 2 of ." LISTEN" endof 3 of ." CONNECT" endof
         4 of ." WRITE" endof 5 of ." READ" endof 6 of ." CLOSE" endof  dup .x
   endcase
;
: .espconn  ( adr -- )
   dup .  dup l@ .conntype space  dup 1 la+ l@ .connstate space dup 2 la+ l@ .ip/port  6 la+ l@ ." Rev: " .x cr
;
[then]
