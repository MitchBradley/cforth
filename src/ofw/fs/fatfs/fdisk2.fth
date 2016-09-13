\ See license at end of file
purpose: Display FDISK partition information

\ Partition map display and creation:
\
\ Interfaces for use by programs:
\
\   $.partitions    ( adr len -- )
\	Displays the partition map of the device named by "adr len"
\
\   $partition ( #mbytes adr len -- )
\       Creates a partition map on the device named by "adr len".
\       The new map has a single valid partition, set to "bootable",
\       of type "FAT16", beginning at logical block 1, of size
\       "#mbytes" times 2048 blocks.
\
\ User interfaces:
\
\   .partitions <name>
\	Like  $.partitions  except that the device name is taken from the
\	command line instead of from the stack.
\
\   fat-partition <name>   ( #mbytes -- )
\       Like  $partition  except that the device name is taken from the
\       command line instead of from the stack, sanity checking is performed,
\       and user confirmation is required.

headerless

0 value sector-buf
h# 200 constant /sector
0 value disk-dev
fload ${BP}/ofw/disklabel/showgpt.fth	\ GUID Partition table decoding

0 value partition#
0 value partition-offset
true value primary?

: fat32?  ( partition-type -- flag )
   dup h# b = swap h# c = or
;

: .pheader  ( -- )
." Partition  Region   Boot  Format    Size (MB)"
cr
cr
;

: .0x  ( n -- )
   push-hex
   dup 9 <=  if  6 u.r  else  ."   0x" (.2) type  then  \ Type field
   3 spaces
   pop-base
;
: (.1partition)  ( adr -- )
   dup d# 12 + le-l@ 0=  if  drop exit  then		\ Empty entry
   primary? 0=  if  dup 4 + c@ 5 =  if  drop exit  then  then	\ Logical extension entry
   push-decimal
   partition# dup 5 u.r 6 spaces 1+ to partition#
   primary?  if  ." Primary"  else  ." Logical"  then	\ Primary/Logical partition
   dup c@  if  ."   Yes  "  else  ."   No   "  then	\ Boot indicator
   dup 4 + c@  case
      0     of  ."  Free      "  endof
      1     of  ."  FAT-12    "  endof
      4     of  ."  FAT-16<32M"  endof  \ <32 MByte FAT16 partition
      5     of  ."  Extended  " partition# 1- to partition#  endof  \ extended partition
      6     of  ."  FAT-16>32M"  endof  \ >32 MByte FAT16 partition
      h# b  of  ."  FAT-32    "  endof
      h# c  of  ."  FAT-32 LBA"  endof
      h# e  of  ."  FAT-16 LBA"  endof
      h# 83 of  ."  ext2      "  endof  \ Linux EXT2
      h# ee of  ."  GUID      "  endof
      dup .0x
   endcase
\   dup 1 + .hsc
\   dup 5 + .hsc

\   dup 8 + le-l@  9 u.r 			\ Start block
   2 spaces
   d# 12 + le-l@  d# 1024 + d# 2048 / 6 u.r	\ Size in MB
   cr
   pop-base
;

: (.partitions)  ( block-adr -- )
   dup h# 1be +          ( adr partadr )
   4 0  do               ( adr partadr )
      dup (.1partition)  ( adr partadr )
      dup 4 + c@ case    ( adr partadr )
         5 of            ( adr partadr )
            d# 8 + le-l@ partition-offset +                  ( adr part-offset )
            primary?  if  dup to partition-offset  then      ( adr part-offset )
            /sector um* " seek" disk-dev $call-method drop   ( adr )
            dup /sector " read" disk-dev $call-method  drop  ( adr )
            false to primary?                                ( adr )
            recurse unloop exit                              ( -- )
         endof           ( adr partadr )
         h# ee of        ( adr partadr )
            .gpt         ( adr partadr )
            leave        ( adr partadr )
         endof           ( adr partadr )
      endcase            ( adr partadr )
      h# 10 +            ( adr partadr' )
   loop                  ( adr partadr )
   2drop                 ( )
;

: free-buf  ( -- )  sector-buf /sector free-mem  ;
: open-partition-map  ( adr len -- )
   string2 pack >r
   " :0" r@ $cat
   r> count  open-dev dup 0= abort" Can't open disk"  to disk-dev
   /sector alloc-mem to sector-buf
;
: close-partition-map  ( -- )
   free-buf
   disk-dev close-dev
;
: +buf  ( offset -- adr )  sector-buf +  ;
headers
: $.partitions  ( adr len -- )
   open-partition-map
   sector-buf /sector  " read" disk-dev $call-method drop
   true to primary?  1 to partition#  0 to partition-offset
   .pheader
   sector-buf (.partitions)
   close-partition-map
;
alias ($.partitions) $.partitions
: .partitions  ( "name" -- )  parse-word $.partitions  ;

headerless
\ Create and format partition
: compute-cluster-size  ( #mbytes fat32? -- spc )
   if
      dup d# 8192 <  if  4
      else dup d# 16384 <  if  8
      else dup d# 32768 <  if  d# 16
      else d# 64
      then then then
   else
      dup d# 128 <  if  2
      else dup d# 256 <  if  4
      else dup d# 512 <  if  8
      else dup d# 1024 <  if  d# 16
      else dup d# 2048 <  if  d# 32
      else dup d# 4096 <  if  d# 64
      else d# 128
      then then then then then then
   then
   nip d# 1024 * /sector /
;
false value type32?
: init-bpb  ( #mbytes type name$ -- )
   ." Initializing file system ..." cr

   string2 pack >r  " :1//fat-file-system:<NoFile>" r@ $cat r> count  select-dev
   fat32? to type32?
   dup type32? compute-cluster-size swap 2>r	( R: spc #mbytes )
   1 h# 40 h# 20 			( #hid-sec #heads sec/trk ) ( R: spc #mbytes )
   r> h# 10.0000 /sector */		( #hid-sec #heads sec/trk #secs ) ( R: spc )
   dup r@ / swap >r			( #hid-sec #heads sec/trk #clusters ) ( R: spc #secs )
   type32?  if
      4 *
   else
      dup h# 1000 <  if  d# 12 * 8 /  else  2 *  then
   then
					( #hid-sec #heads sec/trk bytes/fat ) ( R: spc #secs )
   /sector u/mod swap  if  1+  then	( #hid-sec #heads sec/trk sec/fat ) ( R: spc #secs )
   h# f8 r> d# 512 r> /sector type32?	( #hid-sec #heads sec/trk sec/fat media #secs #dirents spc bps fat32? )
   " (init-disk)" $call-self
   unselect-dev
;

headers
: $partition  ( #mbytes type name$ -- )
   2dup 2>r
   open-partition-map           ( #mbytes type )
   sector-buf /sector erase
   h# 1fe +buf  h# 55 over c!  h# aa swap 1+ c!

   h# 80  h# 1be +buf  c!       \ Bootable
   dup >r
   ( .. type )  h# 1c2 +buf c!  \ Set type  ( #mbytes )

   \ We don't bother with the cylinder/head/sector numbers, because they
   \ rarely matter anymore, and we don't have a good way to find them.

   h# 10  h# 1c6 +buf le-l!         \ Begin the partition at logical block 16

   dup >r
   ( #mbytes )  d# 2048 *  ( #blocks )  h# 1ca +buf le-l!

   sector-buf /sector  " write"  disk-dev $call-method
   /sector <>  if  ." Partition map write failed" cr  then

   close-partition-map

   r> r> 2r>			( #mbytes type name$ )
   init-bpb
;

headerless
: do-partition  ( #mbytes type name$ -- )
   depth 2 <  abort" Usage: <#mbytes> partition <device-name>"
   ." This operation will erase the partition map on the device" cr
   4 spaces  2dup  type  cr
   ." and replace it with one that has a single "
   2 pick  case
      6      of  ." FAT16 "  endof
      h#  b  of  ." FAT32 " endof
      h#  c  of  ." FAT32 " endof
      h# 41  of  ." 0x41 " endof
      ." type " dup .x
   endcase
   ." partition" cr
   ." of size (decimal) " 3 pick  .d  ." MBytes." cr
   cr
   ." Proceed? [y/n] "
   key dup emit cr  upc  ascii Y  <>  if   ( #mbytes type name$ )
      2drop 2drop
      ." Existing partition map left intact" cr
   else
      $partition  ." New partition map written to disk" cr
   then
;
: fat-partition  ( #mbytes "name" -- )  6 safe-parse-word do-partition  ;
: fat32-partition  ( #mbytes "name" -- )  h# c safe-parse-word do-partition  ;
: 41-partition  ( #mbytes "name" -- )  h# 41 safe-parse-word do-partition  ;

headers
: init-nt-disk  ( -- )
   cr ." 		Windows NT Disk Initialization" cr cr
   " /scsi" " show-children" execute-device-method drop cr

   ." Enter the target number of the disk you wish to initialize: "
   key dup emit cr  ascii 0 -			( disk# )
   dup <# u#  " /disk@" hold$ u#>		( disk# name$ )
   dup alloc-mem swap 2dup 2>r move 2r>		( disk# name$ )
   2dup open-partition-map			( disk# name$ )
   " size" disk-dev $call-method		( disk# name$ d.size )
   close-partition-map  drop h# 100000 /	( disk# name$ mbytes )
   -rot 6 -rot do-partition			( disk# )
   <# " )rdisk(0)partition(1)" hold$  u#  " multi(0)scsi(0)disk(" hold$ u#>
   " SYSTEMPARTITION" $setenv
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
