\ See license at end of file
purpose: GUID Partition Table handler

d# 512 value /gpt-sector

32\ : read-gpt-sector  ( x.lba# -- )
32\    drop /gpt-sector um* " seek" disk-dev $call-method drop
32\    sector-buf /gpt-sector " read" disk-dev $call-method drop
32\ ;
0 value gpt-entries/sector

-1 value this-sector
: get-gpt-entry  ( partition# -- adr )
   gpt-entries/sector /mod    ( rem quot )
   dup this-sector <>  if     ( rem quot )
      dup to this-sector      ( rem quot )
      u>x partition-lba0 x+   ( rem lba# )
      read-gpt-sector         ( rem )
   else                       ( rem quot )
      drop                    ( rem )
   then                       ( rem )
   /gpt-entry * sector-buf +  ( adr )
;
: .gpt-bounds  ( adr -- )
   push-hex
   dup gpt-blk0 d# 12 ud.r space   ( adr )
   gpt-#blks    d# 10 ud.r space   ( )
   pop-base                        ( )
;   
: utf16-emit  ( w -- )
   wbsplit   if
      \ Emit "?" for code points we can't handle
      drop ." ?"
   else
      \ Don't emit nulls
      ?dup  if  emit  then
   then
;
: .gpt-name   ( adr -- )
   d# 56 +  d# 72 bounds  do
      i w@ utf16-emit
   /w +loop
;
string-array partition-type-guids
," 00000000-0000-0000-0000-000000000000" ," Unused entry"
," 024DEE41-33E7-11D3-9D69-0008C781F39F" ," MBR scheme"
," C12A7328-F81F-11D2-BA4B-00A0C93EC93B" ," EFI System"
," 21686148-6449-6E6F-744E-656564454649" ," BIOS Boot"
," E3C9E316-0B5C-4DB8-817D-F92DF00215AE" ," Windows Reserved"
," EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" ," Windows Basic data"
," 5808C8AA-7E8F-42E0-85D2-E1E90434CFB3" ," Windows LDM metadata"
," AF9B60A0-1431-4F62-BC68-3311714A69AD" ," Windows LDM data"
," DE94BBA4-06D1-4D40-A16A-BFD50179D6AC" ," Windows Recovery Environment"
," 37AFFC90-EF7D-4E96-91C3-2D7AE055B174" ," Windows IBM GPFS"
," 75894C1E-3AEB-11D3-B7C1-7B03A0000000" ," HP-UX Data"
," E2A1E728-32E3-11D6-A682-7B03A0000000" ," HP-UX Service"
," 0FC63DAF-8483-4772-8E79-3D69D8477DE4" ," Linux filesystem data"
," A19D880F-05FC-4D3B-A006-743F0F84911E" ," Linux RAID"
," 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F" ," Linux Swap"
," E6D6D379-F507-44C2-A23C-238F2A3DF928" ," Linux LVM"
," 8DA63339-0007-60C0-C436-083AC8230908" ," Linux Reserved"
," 83BD6B9D-7F41-11DC-BE0B-001560B84F0F" ," FreeBSD Boot"
," 516E7CB4-6ECF-11D6-8FF8-00022D09712B" ," FreeBSD Data"
," 516E7CB5-6ECF-11D6-8FF8-00022D09712B" ," FreeBSD Swap"
," 516E7CB6-6ECF-11D6-8FF8-00022D09712B" ," FreeBSD UFS"
," 516E7CB8-6ECF-11D6-8FF8-00022D09712B" ," FreeBSD Vinum volume manager"
," 516E7CBA-6ECF-11D6-8FF8-00022D09712B" ," FreeBSD ZFS"
," 48465300-0000-11AA-AA11-00306543ECAC" ," Apple HFS+"
," 55465300-0000-11AA-AA11-00306543ECAC" ," Apple UFS"
," 6A898CC3-1DD2-11B2-99A6-080020736631" ," Apple ZFS"
," 52414944-0000-11AA-AA11-00306543ECAC" ," Apple RAID"
," 52414944-5F4F-11AA-AA11-00306543ECAC" ," Apple RAID offline"
," 426F6F74-0000-11AA-AA11-00306543ECAC" ," Apple Boot"
," 4C616265-6C00-11AA-AA11-00306543ECAC" ," Apple Label"
," 5265636F-7665-11AA-AA11-00306543ECAC" ," Apple TV Recovery"
," 6A82CB45-1DD2-11B2-99A6-080020736631" ," Solaris Boot"
," 6A85CF4D-1DD2-11B2-99A6-080020736631" ," Solaris Root"
," 6A87C46F-1DD2-11B2-99A6-080020736631" ," Solaris Swap"
," 6A8B642B-1DD2-11B2-99A6-080020736631" ," Solaris Backup"
," 6A898CC3-1DD2-11B2-99A6-080020736631" ," Solaris /usr"
," 6A8EF2E9-1DD2-11B2-99A6-080020736631" ," Solaris /var"
," 6A90BA39-1DD2-11B2-99A6-080020736631" ," Solaris /home"
," 6A9283A5-1DD2-11B2-99A6-080020736631" ," Solaris Alternate sector"
," 6A945A3B-1DD2-11B2-99A6-080020736631" ," Solaris Reserved"
," 6A9630D1-1DD2-11B2-99A6-080020736631" ," Solaris Reserved"
," 6A980767-1DD2-11B2-99A6-080020736631" ," Solaris Reserved"
," 6A96237F-1DD2-11B2-99A6-080020736631" ," Solaris Reserved"
," 6A8D2AC7-1DD2-11B2-99A6-080020736631" ," Solaris Reserved"
," 49F48D32-B10E-11DC-B99B-0019D1879648" ," NetBSD Swap"
," 49F48D5A-B10E-11DC-B99B-0019D1879648" ," NetBSD FFS"
," 49F48D82-B10E-11DC-B99B-0019D1879648" ," NetBSD LFS"
," 49F48DAA-B10E-11DC-B99B-0019D1879648" ," NetBSD RAID"
," 2DB519C4-B10F-11DC-B99B-0019D1879648" ," NetBSD Concatenated"
," 2DB519EC-B10F-11DC-B99B-0019D1879648" ," NetBSD Encrypted"
," FE3A2A5D-4F32-41A7-B725-ACCC3285A309" ," ChromeOS kernel"
," 3CB8E202-3B7E-47DD-8A3C-7FF2A13CFCEC" ," ChromeOS rootfs"
," 2E0A753D-9E48-43B0-8337-B15192CB1B5E" ," ChromeOS future-use"
end-string-array

\ Convert the binary encoding of a GUID to the text encoding
\ The first three components are in native byte order - which I think
\ means little-endian for GPT GUIDs.  The last two components are big-endian.
d# 36 buffer: 'guid

: >guid$  ( adr -- adr len )
   push-hex    ( adr )
   dup le-l@  (.8)  'guid  swap move

   [char] - 'guid 8 + c!
   dup 4 + le-w@  (.4)  'guid d# 9 +  swap move

   [char] - 'guid d# 13 + c!
   dup 6 + le-w@  (.4)  'guid d# 14 +  swap move

   [char] - 'guid d# 18 + c!
   dup 8 + be-w@  (.4)  'guid d# 19 +  swap move

   [char] - 'guid d# 23 + c!
   d# 10 +   ( adr )
   6 0  do                            ( adr )
      dup i + c@  (.2)                ( adr $ )
      'guid d# 24 + i wa+  swap move  ( adr )
   loop                               ( adr )
   drop                               ( )

   pop-base                           ( )

   'guid d# 36 2dup upper             ( adr len )
;

d# 100 constant chromeos-kernel-index
0 value partition-type-index

: .gpt-type   ( adr -- )
   >guid$  2>r  0                               ( string#  r: guid$ )
   begin                                        ( string#  r: guid$ )
      dup ['] partition-type-guids              ( string# string# xt  r: guid$ )
   catch 0= while                               ( string# 'this r: guid$ )
      count  2r@ $=  if                         ( string# r: guid$ )
         dup to partition-type-index            ( string# r: guid$ )
         1+ partition-type-guids count type     ( r: guid$ )
         2r> 2drop exit                         ( -- )
      then                                      ( string# r: guid$ )
      2+                                        ( string#' r: guid$ )
   repeat                                       ( string# x r: guid$ )
   2r> type                                     ( string# x )
   2drop                                        ( )
;

: .gpt-extra  ( adr -- )
   partition-type-index chromeos-kernel-index =  if   ( adr )
      \ For ChromeOS Kernel, display  (success,tries,priority)
      h# 36 + le-w@  wbsplit                          ( tries|pri success )
      ."  (" (.) type ." ,"                           ( tries|pri )
      push-decimal                                    ( tries|pri )
      dup 4 rshift (.) type ." ,"                     ( tries|pri )
      h# f and (.) type ." )"                         ( )
      pop-base                                        ( )
   else                                               ( adr )
      drop                                            ( )
   then                                               ( )
;
: .gpt-partition  ( adr # -- )
   \ Skip unused entries
   over 8 0 bskip  0=  if  2drop exit  then  ( adr i )
   push-decimal 2 u.r space pop-base         ( adr )
   dup .gpt-bounds      ( adr )
   dup .gpt-name        ( adr )
\  dup .gpt-guid        ( adr )
   d# 50 to-column      ( adr )
   dup .gpt-type        ( adr )
   dup .gpt-extra       ( adr )
   drop  cr             ( )
;
: .gpt-partitions  ( -- )
   cr
   ."  #     FirstBlk    NumBlks Name                   Type"  cr
   ."  -     --------    ------- ----                   ----"  cr
   #gpt-partitions  0  do    ( )
      i  get-gpt-entry  i 1+ .gpt-partition  ( )
   loop                      ( )
;
: .gpt  ( -- )
   onex read-gpt-sector
   sector-buf gpt-magic comp  if
      ." Bad signature in GUID partition table header" cr
      exit
   then
   push-hex
\   ." FirstBlk: " sector-buf d# 40 le-x@ d.
\   ." LastBlk: " sector-buf d# 48 le-x@ d.
   pop-base
   sector-buf d# 72 + le-x@ to partition-lba0
   sector-buf d# 80 + le-l@ to #gpt-partitions
   sector-buf d# 84 + le-l@ to /gpt-entry
   /gpt-sector /gpt-entry /  to gpt-entries/sector
   .gpt-partitions
;
