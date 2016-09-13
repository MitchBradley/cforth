\ See license at end of file
purpose: disk-label package

headers

: offset  ( d1 -- d2 )  sector-offset /sector um*  d+  ;

headerless

\ Recognizers for various filesystem types

: dropin?  ( -- flag )  sector-buf  " OBMD" comp 0=  ;
: zip?  ( -- flag )  sector-buf  " PK" comp 0=  ;


0 0 2value filename

\ Sets size-high and size-low to the total size of the disk in bytes,
\ as determined by the parent's "#blocks" and "block-size" methods.
: get-disk-size  ( -- )
   " #blocks" ['] $call-parent catch  if
      2drop
   else   ( #blocks )
      " block-size" $call-parent  um*
      to size-high  to size-low
   then
;

\ It would be nice if this word could be in partition.fth, but it can't
\ because of interactions between FDISK and UFS partition maps.
: fdisk-map  ( -- )
   0 to extended-offset
   #part 0>  if
      \ An explicit partition number was specified.  Select that partition.
      find-partition
   else		\ Use default FDISK partition

      \ If the arguments specified a partition letter (a..h), try to find
      \ an FDISK partition that contains a UFS partition map, then select
      \ the specified sub-partition.
      ufs-partition  if
         0 ['] is-ufs?  (find-partition) abort" No UFS partition"
      else
         0 ['] bootable?  (find-partition)  if
            \ If no bootable partition was found, use the first one
            1 to #part  find-partition
         then
      then
   then

[ifdef] ufs-support
   \ If the partition type is UFS and a filename is specified, select
   \ one of the UFS sub-partitions.  Otherwise use the raw partition.
   partition-type ufs-type =  if
      filename nip  if  ufs-map  then
   then
[then]
;

: select-partition  ( -- )
   \ If parse-partition set #part to -2, it already mapped the partition
   #part -2 =  if  exit  then

   \ Partition 0 is the raw disk, in which case we leave sector-offset at 0
   \ and avoid reading the disk.  Otherwise, we try to determine what sort
   \ of partition map the disk has, if any, and from that determine the
   \ offset to the beginning of the specified partition.
   #part 0=  if  get-disk-size exit  then
   
   \ Get the first sector into the buffer so we can examine it
   0 read-sector

   \ If we find certain things in the first sector, we need not bother
   \ with partitions, and we ignore the partition specification
   fat? unpartitioned?  and  if  get-disk-size exit  then
   dropin?  if  get-disk-size exit  then
   zip?     if  get-disk-size exit  then

[ifdef] hfs-support
   mac-disk?  if  mac-map exit  then
[then]

   gpt?  if  gpt-map exit  then

   fdisk?  if  fdisk-map exit  then

   \ We check for ISO 9660 after the ones above, because they can be
   \ recognized from the first sector, whereas for ISO 9660 we must
   \ look at offset 32K (sector 64).

   iso-9660?  if  exit  then

[ifdef] ufs-support
   \ If this disk has a UFS partition map that is not subordinate to
   \ an FDISK map and either a UFS partition letter or a filename is
   \ specified, select one of the UFS sub-partitions.

   ufs?  if
      ufs-partition 0<>  filename nip 0<> or  if  ufs-map exit  then
   then
[then]

   2 read-sector  ext2?  if
      ext2fs-type to partition-type
      get-disk-size exit
   then

   \ Nothing we tried worked.
   abort
;

: choose-file-system  ( -- package-name$ )
   \ Execute found-iso-9660? (an instance value) before changing my-self !
   partition-type iso-type =  if  " iso9660-file-system" exit  then

[ifdef] hfs-support
   hfs-partition?  if  " hfs-file-system" exit  then
   \ XXX handle boot portion of HFS partition, one of these days
   \ ( filename$ ) 2dup " %BOOT" $=  if
   \    ( change sector-offset and size.low,high ) ...
[then]

   2 read-sector
   ext2?  if  
      partition-type ext2fs-type <>  if
         ." Warning: Filesystem is ext2/3, but partition type is 0x"  
         partition-type .x ." (should be 0x83)."  cr
      then
      " ext2-file-system" exit
   then

[ifdef] ufs-support
   partition-type ufs-type    =  if  " ufs-file-system"    exit  then
[then]
   partition-type minix-type  =  if  " minix-file-system"  exit  then

   0 read-sector   \ Get the first sector of the selected partition
   dropin?  if  " dropin-file-system" exit  then
   zip?     if  " zip-file-system"    exit  then
   fat?     if
      partition-type ext2fs-type =  if
         ." Warning: Filesystem is FAT, but partition type is 0x83 (ext2/3)." cr
      then
      " fat-file-system"    exit
   then
   ntfs?    if  " nt-file-system"     exit  then

   ." Error: Unknown file system" cr
   abort
;

\ If the arguments include a filename, we determine the type of filesystem
\ that the disk or partition contains and interpose a handler for that
\ type, passing it the filename.
: select-file  ( -- )
   filename nip 0=  if  exit  then

   choose-file-system  find-package  0=  if  abort  then  ( phandle )
   filename rot  interpose
;

\ partition$ syntax:
\ null:     use default partition
\ <digit>:  FDISK partition number
\ <letter>: UFS partition letter (a..h)
\ <digit><letter>: UFS partition embedded within FDISK partition
\ -<decimal-digits>: The last N blocks of the disk

\ partition# is one of:
\ -1, meaning the default partition, i.e. no partition was specified
\  0, meaning the raw disk
\ >0, meaning an explicit partition

\ In addition, ufs-partition is set to the UFS partition letter (a..h)
\ if the string appears to contain a letter.

: decode-partition  ( adr len -- rem$ )
   \ If the string parses as a decimal number, it's a partition# if
   \ positive or the last N blocks if negative
   2dup push-decimal $number pop-base 0=  if   ( adr len n )
      dup 0<  if                               ( adr len n )
         /sector um*                           ( adr len d.partition-size )
         get-disk-size  size-low size-high     ( adr len d.partition-size d.disk-size )
         2over d-  /sector um/mod nip          ( adr len d.partition-size partition-sector )
         to sector-offset                      ( adr len d.partition-size )
         to size-high to size-low              ( adr len )
         -2 to #part                           ( adr len )   \ Tell select-partition
      else                                     ( adr len n )
         to #part                              ( adr len )
      then                                     ( adr len )
      drop 0                                   ( adr 0 )
      exit                                     ( rem$ -- )
   then                                      ( adr len )

   \ If the first character of the string is a decimal number, it's a partition #,
   \ possibly followed by UFS partition letter
   over c@  ascii 0 ascii 9 between  if      ( adr len )
      over c@  ascii 0 -  to #part           ( adr len )
      1 /string                              ( adr' len' )
      dup  0=  if  exit  then                ( adr len )
   then

[ifdef] ufs-support
   \ If the first character is "a".."h", it's a UFS partition letter
   over c@ lcc  ascii a ascii h between  if  ( adr len )
      over c@  to ufs-partition              ( adr len )
      1 /string                              ( adr' len' )
      dup  0=  if  exit  then                ( adr len )
   then					     ( adr len )
[then]
;
: parse-partition  ( -- )
   null$ to filename  null$ to partition-name$  -1 to #part  0 to ufs-partition

   my-args				     ( adr len )

   \ An empty arg string is treated as a null partition and a null filename
   dup  0=  if  2drop exit  then	     ( adr len )

   \ If the string contains a comma, the first half is the partition name
   " ," lex  if                              ( tail$ head$ delim )
      drop  2dup to partition-name$          ( tail$ head$ )
      decode-partition  2drop                ( tail$ )
      to filename                            ( )
      exit                                   ( -- )
   then                                      ( adr len )

   decode-partition                          ( rem$ )

   \ The remainder of the string, if any, is the filename
   to filename
;

: try-open  ( -- )
   " block-size" $call-parent to /sector
   sector-alloc
   parse-partition	( )
   select-partition     ( )

   \ Establish initial position at beginning of partition
   0 0 offset  " seek" $call-parent drop        ( )

   select-file          ( )
;

headers
\ In order to simplify the error handling logic, instead of passing
\ flags around, we just abort when a fatal error occurs.  The "catch"
\ intercepts the abort and returns the appropriate flag value.
: open  ( -- okay? )  ['] try-open  catch  0=  ;
: close  ( -- )  sector-buf  if  sector-free  then  ;
: size  ( -- d )  size-low size-high  ;
: load  ( adr -- len )
   \ This load method is used only for type 41 (IBM "PREP") partitions
   partition-type h# 41  <>  if  drop 0  exit  then

   0 0          " seek" $call-parent drop   ( adr )
   dup d# 1024  " read" $call-parent drop   ( adr )
   dup d# 516 + le-l@   d# 1024  /string    ( adr' additional-length )
   " read" $call-parent  d# 1024 +          ( len' )
;
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
