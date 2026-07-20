marker -wifi.fth lastacf .name #20 to-column .( 27-04-2026 )

needs init-HtmlPage tools/extra.fth

: .wifi-connect-error ( error -- )
   case
   #1 of ." Unspecified reason" endof
   #2 of ." Authentication failed" endof
   #3 of ." Deauthentication due to leaving" endof
   #4 of ." Disassociated due to inactivity" endof
   #5 of ." Too many associated station." endof
   #6 of ." Class 2 frame received from nonauthenticated STA" endof
   #7 of ." Class 3 frame received from nonassociated STA" endof
   #8 of ." Deassociated due to leaving" endof
   #9 of ." Association but not authenticated" endof
   #10 of ." Disassociated due to poor power capability" endof
   #11 of ." Disassociated due to unsupported channel" endof
   #12 of ." Disassociated due to BSS transition" endof
   #13 of ." Invalid Information Element (IE)" endof
   #14 of ." MIC failure" endof
   #15 of ." 4-way handshake timeout - check password" endof
   #16 of ." Group key update timeout" endof
   #17 of ." IE differs in 4-way handshake" endof
   #18 of ." Invalid group cipher" endof
   #19 of ." Invalid pairwise cipher" endof
   #20 of ." Invalid AKMP" endof
   #21 of ." Unsupported RSN IE version" endof
   #22 of ." Invalid RSN IE capabilitie." endof
   #23 of ." 8021X authentication failed" endof
   #24 of ." Cipher suite rejected" endof
   #25 of ." TDLS peer unreachable" endof
   #26 of ." TDLS unspecified" endof
   #27 of ." SSP requested disassociation" endof
   #28 of ." No SSP roaming agreement" endof
   #29 of ." Bad cipher or AKM" endof
   #30 of ." Not authorized in this location" endof
   #31 of ." Service change precludes T." endof
   #32 of ." Unspecified QoS reason" endof
   #33 of ." Not enough bandwidth" endof
   #34 of ." Missing ACK." endof
   #35 of ." Exceeded TXOP" endof
   #36 of ." Station leaving" endof
   #37 of ." End of Block Ack (BA)" endof
   #38 of ." Unknown Block Ack (BA)" endof
   #39 of ." Timeout" endof
   #46 of ." Peer initiated disassociation" endof
   #47 of ." AP initiated disassociation" endof
   #48 of ." Invalid FT action frame count" endof
   #49 of ." Invalid PMKID" endof
   #50 of ." Invalid MDE" endof
   #51 of ." Invalid FTE" endof
   #67 of ." Transmission link establishment failed" endof
   #68 of ." Alternative channel occupied" endof
   #200 of ." Beacon timeout - router not responding" endof
   #201 of ." No AP found" endof
   #202 of ." Authentication failed - check password" endof
   #203 of ." Association failed" endof
   #204 of ." Handshake timeout" endof
   #205 of ." Connection failed" endof
   #206 of ." AP TSF reset" endof
   #207 of ." Roaming" endof
   #208 of ." Association comeback time too long" endof
   #209 of ." SA query timeout" endof
   #210 of ." No AP found with compatible security" endof
   #211 of ." No AP found in auth mode threshold" endof
           ." Unknown reason: " dup (.) type
   endcase
   space
;
: (.d)  ( n -- )  push-decimal (.) pop-base  ;
: ipaddr$  ( 'ip -- $ )
   push-decimal <#       ( 'ip )
      3 bounds swap  do  ( )     \ IP address is in reverse byte order
         i c@  u#s drop  ( )     \ Convert a byte
         '.' hold        ( )
      -1 +loop           ( )
   0 u#>  pop-base       ( $ )
   1 /string             ( $' )  \ Discard leading .
;
: ipaddr@ ( -- 'ip ) pad 0 ip-info@ drop  pad  ; \ 1 for AP, 0 for STA
: .ipaddr ( 'ip -- ) ipaddr$ type  ;
: ip" ( -- adr cnt  ) ipaddr@ ipaddr$ ;
: .ip ( -- ) ip" type ;
: ip4Host ( adr cnt -- ) ip" #10 /string ;
: enter-wifi-settings ( passwordBuf ssidBuf - )
   2>r
   cr ." Setting up a WiFi connection. The SSID and password will"
   cr ." be saved in plain text in wifi_connect.fth on the MCU."
   cr ." Enter SSID:"  pad dup 50 accept r> place
   ." Enter Password:" pad dup 50 accept r> place
;
#3000 value wifi-timeout
0 value logon-loglevel
: set-wifi-loglevel ( -- )
   logon-loglevel
   dup s" esp_netif_handlers" log-level!
   dup s" wifi" log-level!
   dup s" phy_init" log-level!
   s" wifi_init" log-level!
;
0 [if] Optional authentication constants
0 constant WIFI_AUTH_OPEN
1 constant WIFI_AUTH_WEP
2 constant WIFI_AUTH_WPA_PSK
3 constant WIFI_AUTH_WPA2_PSK
4 constant WIFI_AUTH_WPA_WPA2_PSK
5 constant WIFI_AUTH_WPA2_ENTERPRISE
7 constant WIFI_AUTH_WPA3_PSK
8 constant WIFI_AUTH_WPA2_WPA3_PSK
[then]
8 value wifi_auth  \ for WPA3 and WPA2
: wifi-station-on  { &ss sscnt &pw pwcnt -- }
    ." Connecting... " set-wifi-loglevel base @ decimal ms@ wifi-connected@ 0= if
       &ss sscnt &pw pwcnt wifi-timeout wifi_auth wifi-open if
          ." connection failed,new attempt... " esp-wifi-stop #200 ms esp-wifi-start 
          &ss sscnt &pw pwcnt #4000 wifi_auth wifi-open dup if
             .wifi-connect-error
          else
             drop
          then
      then
   then
   space ms@ swap - . ." ms. " base ! ipaddr@ @ if
      ." Connected to: " .ip
   then
;
: set-wifi-cred ( -- )  \ Creates wifi_connect.fth on the MCU
   #40 allocate drop #40 allocate drop 2dup 2dup enter-wifi-settings  
   here #128 erase 
   >r s" parse-word " 2dup here place r> count here +place  s"  " here +place \ ssid placed    
   here +place count here +place \ password placed   
   free drop free drop 
   here count s" wifi_connect.fth" file-it   
;
: get-wifi-cred ( - ssid cnt pasword cnt )
   s" wifi_connect.fth" 0 pad ! pad #128 +file pad lcount evaluate 
;
: logon ( -- )
   s" wifi_connect.fth" file-exist? 0= if
      set-wifi-cred
   then
   get-wifi-cred wifi-station-on
;
alias wifi-sta-on logon
: check-ssid ( - flag )  
    get-wifi-cred 2drop #4000 ssid_available   \ Might take 4 seconds
;
: try-logon ( - flag )
   check-ssid if
      logon wifi-connected@
   else
      false
   then
;
: SleepIfNotConnected ( #sec-deep-sleep - )
   wifi-connected@ 0= if
      100 ms esp-wifi-stop cr  ." No connection. Entering sleep mode..."  DeepSleep
   else
      drop
   then
;
