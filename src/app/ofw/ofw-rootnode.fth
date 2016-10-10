\ Platform-specific Open Firmware driver

$200 constant pagesize

: ram-range  ( -- start end )  origin pagesize round-down  rp0 @ pagesize round-up  ;

fload ${BP}/ofw/core/memops.fth		\ Call memory node methods

\ The ESP8266 RTC is just a counter

: time&date  ( -- sec min hr dy mth yr )
   'calendar-time   ( adr )
   6 0  do  dup @ swap na1+  loop  ( sec min hr dy mth yr-1900 adr' )
   drop  #1900 +    ( sec min hr dy mth yr )
;
: now  ( -- s m h )  time&date 3drop  ;
: today  ( -- d m y )  time&date >r >r >r  3drop r> r> r>  ;

[ifdef] ext2fs-support
\needs unix-seconds>  fload ${BP}/ofw/fs/unixtime.fth	\ Unix time calculation
\needs ($crc16)       fload ${BP}/forth/lib/crc16.fth
support-package: ext2-file-system
   fload ${CBP}/ofw/fs/ext2fs/ext2fs.fth	\ Linux file system
end-support-package
[then]

[ifdef] ntfs-support
support-package: nt-file-system
   fload ${BP}/ofw/fs/ntfs/loadpkg.fth	\ NT file system reader
end-support-package
[then]

[ifdef] ufs-support
support-package: ufs-file-system
   fload ${BP}/ofw/fs/ufs/loadpkg.fth	\ Unix file system
end-support-package
[then]

[ifdef] zipfs-support
support-package: zip-file-system
   fload ${BP}/ofw/fs/zipfs.fth		\ Zip file system
end-support-package
[then]

support-package: fat-file-system
   fload ${CBP}/ofw/fs/fatfs/loadpkg.fth	\ FAT file system reader
end-support-package

support-package: disk-label
   fload ${CBP}/ofw/disklabel/loadpkg.fth	\ Disk label package
end-support-package

fload ${BP}/ofw/fs/fatfs/fdisk2.fth	\ Partition map administration

6 buffer: mac-addr
1 value wifi#
: system-mac-address  ( -- adr 6 )  " "(01 02 03 04 05 06)"  ;

0 [if]
def-load-base ' load-base set-config-int-default

true ' fcode-debug? set-config-int-default
\ false  ' auto-boot?    set-config-int-default

" com1" ' output-device set-config-string-default
" com1" ' input-device set-config-string-default
[then]

0 value load-limit	\ Top address of area at load-base



: root-map-in  ( phys len -- virt )  drop  ;  \ Physical addressing
: root-map-out  ( virt len -- )  2drop  ;

fl ${BP}/ofw/core/memlist.fth     \ Resource list common routines
fl ${BP}/ofw/core/showlist.fth

dev /
extend-package

1 " #address-cells" integer-property
1 " #size-cells" integer-property

" PC" model
" Windows PC" encode-string  " architecture" property
" PC" encode-string  " banner-name" property

hex

\ Static methods
: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

\ Not-necessarily-static methods
: open  ( -- true )  true  ;
: close  ( -- )  ;

: map-in   ( phys size -- virt )  drop  ;
: map-out  ( virtual size -- )  2drop  ;

: dma-range  ( -- start end )  ram-range  ;

\ Used with "find-node" to locate a physical memory node containing
\ enough memory in the DMA range.
\ We first compute the intersection between the memory piece and the
\ range reachable by DMA.  If the regions are disjoint, then ok-high
\ will be (unsigned) less than ok-low.  We then subtract ok-low from
\ ok-high to give the (possibly negative) size of the intersection.
: in-range?  ( size mem-low mem-high range-low range-high -- flag )
   rot umin -rot              ( size min-high mem-low mem-high )
   umax                       ( size min-high max-low )
   - <=                       ( flag )
;

: dma-ok?  ( size node-adr -- size flag )
   node-range				 ( size mem-adr mem-len )
   over +                                ( size mem-adr mem-end )

   3dup dma-range in-range?  if          ( size mem-adr mem-end )
      2drop true exit                    ( size true )
   then                                  ( size mem-adr mem-end )

   2drop false                           ( size false )
;


\ Find an available physical address range suitable for DMA.  This word
\ doesn't actually claim the memory (that is done later), but simply locates
\ a suitable range that can be successfully claimed.
: find-dma-address  ( size -- true | adr false )
   " physavail" memory-node @ $call-method  	( list )
   ['] dma-ok?  find-node is next-node  drop	( size' )
   next-node 0=  if  drop true exit  then	( size' )
   next-end                                     ( size mem-end )
   dma-range                                    ( size mem-end range-l,h )
   nip umin  swap -   false		        ( adr false )
;

: dma-alloc  ( size -- virt )
   pagesize round-up                            ( size' )

   \ Locate a suitable physical range
   dup  find-dma-address  throw			( size' phys )

   \ Claim it
   over 0  mem-claim				( size' phys )

   nip                                          ( addr )
;
warning off

: dma-free  ( virt size -- )
   pagesize round-up				( virt size' )
   mem-release					( )
;

: dma-map-in  ( virt size cache? -- phys )
   2drop    \ There is no data cache and virt==phys
;
: dma-map-out  ( virt phys size -- )  3drop  ;
: dma-sync     ( virt phys size -- )  3drop  ;
: dma-push     ( virt phys size -- )  3drop  ;
: dma-pull     ( virt phys size -- )  3drop  ;
warning on

finish-device

device-end
headerless

fl ${BP}/ofw/core/clntphy1.fth
fl ${BP}/ofw/core/allocph1.fth
fl ${BP}/ofw/core/availpm.fth

: (memory?)  ( padr -- flag )  ram-range within  ;
' (memory?) to memory?

\ Call this after the system-mac-address is determined, which is typically
\ done near the end of the probing process.
: set-system-id  ( -- )
   system-mac-address  dup  if        ( adr 6 )
      " /" find-device                ( adr 6 )

      \ Convert the six bytes of the MAC address into a string of the
      \ form 0NNNNNNNNNN, where N is an uppercase hex digit.
      push-hex                        ( adr 6 )

      <#  bounds  swap 1-  ?do        ( )
         i c@  u# u#  drop            ( )
      -1 +loop                        ( )
      0 u# u#>                        ( adr len )

      2dup upper                      ( adr len )  \ Force upper case

      pop-base                        ( adr len )

      encode-string  " system-id"  property   ( )

      device-end
   else
      2drop
   then
;
headers

\ End of rootnode stuff

support-package: dropin-file-system
   fload ${BP}/ofw/fs/dropinfs.fth	\ Dropin file system
end-support-package

" /openprom" find-device
   " MitchBradley,3.0" encode-string " model" property
device-end

fl ${CBP}/ofw/filenv.fth

: install-options  ( -- )
   " /file-nvram" open-dev  to nvram-node
   nvram-node 0=  if
      ." The configuration EEPROM is not working" cr
   then
   config-valid?  if  exit  then
   ['] init-config-vars catch drop
;
stand-init: Pseudo-NVRAM
   install-options
;
