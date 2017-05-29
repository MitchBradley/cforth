\ Driver for DS18B20 and DS18S20
5 value ds18x20-pin

: ow-crc8-ok?  ( len adr -- okay? )
   swap 1- swap      ( len-1 adr )
   2dup ow-crc8      ( len-1 adr crc )
   -rot              ( crc  len-1 adr )
   + c@  =           ( okay? )
;

8 buffer: ds18x20-addr
: is-ds18x20?  ( -- flag )
   8 ds18x20-addr  ow-crc8-ok?  if
      ds18x20-addr c@  dup $10 =  swap $28 =  or  if
         true exit
      then
   then
   false
;
: find-first-ds18x20  ( -- )
   1 ds18x20-pin ow-init
   begin  1 ds18x20-addr ow-search  while
      is-ds18x20?  if  drop exit  then
   repeat
   true abort" DS18B20 not found"
;

\needs bwjoin  : bwjoin  ( low high -- )  8 lshift or  ;
\needs le-w@  : le-w@  ( adr -- w )  dup c@ swap 1+ c@ bwjoin  ;
: ds18x20-command  ( cmd -- )
   ow-reset 0= abort" No Onewire presence pulse"
   ds18x20-addr ow-select
   ow-b!
;
: ds18x20-start  ( -- )  $44 ds18x20-command  ;

9 buffer: ds18x20-data
: ds18x20-temp@  ( -- t*16 )
   $be ds18x20-command
   9 ds18x20-data ow-read
   9 ds18x20-data ow-crc8-ok?  0=  abort" DS18B20 bad CRC"  \ Could retry
   ds18x20-data le-w@ w->n   ( temp )
   \ DS18B20 has four fractional bits, DS18S20 has only one
   ds18x20-addr c@ $28 <>  if  3 lshift  then  ( temp*16 )
;
: ds18x20-temp$  ( -- adr len )
   ds18x20-start #750 ms  ds18x20-temp@  ( temp*16 )
   #100 #16 */
   push-decimal  <# u# u# '.' hold u#s u#> pop-base
;
: .ds18x20-temp  ( -- )  ds18x20-temp$ type  ." C"  ;
: init-ds18x20  ( -- )  find-first-ds18x20  ;

0 [if]
0 value first-ds18x20
0 value end-ds18x20
: find-all-ds18x20s  ( -- )
   \ 1 is "hold line high" after write, for parasitic power.
   \ 0 didn't work for me even though my 18B20 has a separate power line.
   1 ds18x20-pin ow-init
   here to first-ds18x20
   begin  ds18x20-addr ow-search  while
      is-ds18x20?  if
         ds18x20-addr here move  8 allot
      then
   repeat
   here to end-ds18x20
;
: #ds18x20s  ( -- count )  end-ds18x20 first-ds18x20 -  8 /  ;
\ Use addresses from the array just created in place of ds18x20-addr
[then]
