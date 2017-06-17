
#10 value ec-limit-low
#30 value ec-limit-high
#55 value pH-limit-low
#65 value pH-limit-high

0 value water-level \ %
0 value ec          \ USiemens
0 value pH*10       \ pH*10
0 value pressure    \ pascals
0 value humidity    \ %rh*1000
0 value temperature \ C*100

: hdr
   " <html><head><title>Empire Gardens Grow-o-matic</title>" tcp-transmit
   " <meta HTTP-EQUIV=Pragma CONTENT=no-cache>" tcp-transmit
   " <meta HTTP-EQUIV=Expires CONTENT=-1>" tcp-transmit
   " <style>" tcp-transmit
   " input,button,td,caption{font:30px sans-serif;} .l{font-weight:bold;text-align:right;}" tcp-transmit
   " input,button{color:green;} button{width:100%;}" tcp-transmit
   " caption{color:blue; text-align:left}" tcp-transmit
   " </style>" tcp-transmit
   " </head><body>" tcp-transmit
;
: footer
   " </body></html>"r"n" tcp-transmit
;
: brk  ( -- )  " <br>" tcp-transmit  ;
: table-begin ( caption$ -- )
   " <table>" tcp-transmit
   dup  if
      " <caption>" tcp-transmit  tcp-transmit  " </caption>" tcp-transmit
   else
      2drop
   then
;
: table-end ( -- ) " </table>" tcp-transmit ;
: save$  ( adr len -- adr1 len1 )  pad pack count  ;
: n.nn$  ( n -- $ )
   push-decimal
   <# u# u# '.' hold u#s u#>
   pop-base
   save$
;
: n.n$  ( n -- $ )
   push-decimal
   <# u# '.' hold u#s u#>
   pop-base
   save$
;
: atmospheres
   " <tr><td class=l>Pressure: </td><td>"  tcp-transmit
   pressure #100 #101324 */ n.nn$ tcp-transmit
   "  atm</td></tr>" tcp-transmit
;
: temp&humidity  ( -- )
   push-decimal
   " <tr><td class=l>Temperature: </td><td>" tcp-transmit  temperature n.nn$ tcp-transmit " C</td></tr>" tcp-transmit
   " <tr><td class=l>Humidity: </td><td>"    tcp-transmit  humidity    n.nn$ tcp-transmit " %</td></tr>" tcp-transmit
\  atmospheres
   pop-base
;
: conductivity  ( -- )
   " <tr><td class=l>Conductivity: </td><td>" tcp-transmit  ec n.nn$ tcp-transmit  "  uSiemens</td></tr>" tcp-transmit
;

: water  ( -- )
   " <tr><td class=l>Water Headroom: </td><td>" tcp-transmit
   push-decimal  water-level (.)  tcp-transmit  pop-base
   "  mm</td></tr>" tcp-transmit
;
: ph-sensor  ( -- )
   " <tr><td class=l>pH: </td><td>" tcp-transmit
   pH*10 0 max n.n$ tcp-transmit
   " </td></tr>" tcp-transmit
;
: pump-links  ( -- )
   " <tr><td><a href=""/?spray=pulse""><button>Spray</button></a></td>" tcp-transmit
       " <td><a href=""/?nutrient=pulse""><button>Nutrients</button></a></td>" tcp-transmit
       " <td><a href=""/?recirculate=pulse""><button>Recirculate</button></a></td></tr>" tcp-transmit
   " <tr><td><a href=""/?phup=pulse""><button>pH Up</button></a></td>" tcp-transmit
       " <td><a href=""/?phdown=pulse""><button>pH Down</button></a></td>" tcp-transmit
       " <td><a href=""/?water=pulse""><button>Water</button></a></td></tr>" tcp-transmit
;
: configure  ( -- )
   " <form>" tcp-transmit
   " Settings" table-begin
   " <tr><td>pH Low: <input type=text name=phlow size=4 value=" tcp-transmit ph-limit-low n.n$ tcp-transmit
\   " pH Low: <input type=range name=phlow min=3.0 max=7.0 step=0.1 value=" tcp-transmit ph-limit-low n.n$ tcp-transmit
   " >&nbsp;</td><td>" tcp-transmit
   " pH High: <input type=text name=phhigh size=4 value=" tcp-transmit ph-limit-high n.n$ tcp-transmit
   " ></td></tr>" tcp-transmit
   " <tr><td>EC Low: <input type=text name=eclow size=4 value=" tcp-transmit ec-limit-low n.n$ tcp-transmit
   " >&nbsp;</td><td>" tcp-transmit
   " EC High: <input type=text name=echigh size=4 value=" tcp-transmit ec-limit-high n.n$ tcp-transmit
   " ></td></tr>" tcp-transmit
   " <tr><td><input type=submit value=""SetLimits""></td>" tcp-transmit
   " <td></td></tr>" tcp-transmit
   table-end
   " </form>" tcp-transmit
;

decimal
: convert-ph  ( f -- n ) f# 10E0 f* int   0 max  #140 min  ;
: convert-ec  ( f -- n ) f# 10E0 f* int   #05 max  #60 min  ;

vocabulary url-commands
also url-commands definitions
: spray  ( val$ -- )  ." Spray: " type cr  ;
: water  ( val$ -- )  ." Water: " type cr  ;
: phup   ( val$ -- )  ." pH Up: " type cr  ;
: phdown ( val$ -- )  ." pH Down: " type cr  ;
: nutrients  ( val$ -- )  ." Nutrients: " type cr  ;
: recirculate  ( val$ -- )  ." Recirculate: " type cr  ;
: phlow  ( val$ -- )
   fnumber  0=  if  ( f )  convert-ph to ph-limit-low  then
;
: phhigh  ( val$ -- )
   fnumber  0=  if  ( f )  convert-ph to ph-limit-high  then
;
: eclow  ( val$ -- )
   fnumber  0=  if  ( f )  convert-ec to ec-limit-low  then
;
: echigh  ( val$ -- )
   fnumber  0=  if  ( f )  convert-ec to ec-limit-high  then
;
previous definitions


: execute-arg ( val$ name$ -- )
   ['] url-commands search-wordlist if
      execute
   else
      2drop
   then
;
: handle-arg ( arg$ -- )
   '=' left-parse-string execute-arg
;
: handle-url-params  ( -- )
   url-args$ dup 0=  if  2drop exit  then  ( params$ )
   begin  dup  while                      ( param$ )
      '&' left-parse-string  handle-arg   ( rem$ )
   repeat                                 ( rem$ )
   2drop
;

: do-homepage  ( -- )
   handle-url-params
   hdr

   " Readings" table-begin
   ph-sensor temp&humidity conductivity water
   table-end
   brk

   " Controls" table-begin
   pump-links
   table-end
   brk

   configure
   footer
;

' do-homepage to homepage

fl sht21.fth
fl vl6180x.fth

: read-temperature  ['] sht21-temp@     catch  0=  if  to temperature  then  ;
: read-humidity     ['] sht21-humidity@ catch  0=  if  to humidity     then  ;
: read-water        ['] vl-distance     catch  0=  if  to water-level  then  ;
0 value counter
: periodic
   counter case
      0 of  read-temperature  endof
      5 of  read-humidity     endof
      #10 of  read-water     endof
   endcase
   counter 1+  dup #15 =  if  drop 0  then  to counter
;
' periodic to handle-timeout

:noname  " OpenWrt-Bradley" ;  to wifi-sta-ssid
:noname  " BunderditBaby"   ;  to wifi-sta-password

: go 
   #27 #14 i2c-open
   init-vl6180x
   wifi-sta-on
   http-listen
   serve-http
;
