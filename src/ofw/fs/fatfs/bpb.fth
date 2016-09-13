\ See license at end of file
purpose: Data structures describing the overall media layout parameters

hex

\ DOS 2.x and 3.2 and Windows 95 BIOS Parameter Block

private

variable bpb

: bfield  \ name  ( bpb-offset size -- bpb-offset' )
   create over , +   does>  @ bpb @ +
;

struct  \ bpb
   3 bfield bp_branch	\  0  "branch to boot code" instruction 
   8 bfield bp_name	\  3  System name
   2 bfield bp_bps	\  b  bytes/sector        (leword)
   1 bfield bp_spc	\  d  sectors/cluster
   2 bfield bp_res	\  e  #reserved-sectors   (leword)
   1 bfield bp_nfats	\ 10  #FATs
   2 bfield bp_ndirs	\ 11  #directory-entries  (leword)
   2 bfield bp_nsects	\ 13  total-#sectors (with reserved) (leword)
   1 bfield bp_media	\ 15  media descriptor ("magic" number)
   2 bfield bp_spf	\ 16  sectors/FAT         (leword)
   2 bfield bp_spt	\ 18  sectors/track       (leword)
   2 bfield bp_nsides	\ 1a  #sides (#heads)     (leword)
   4 bfield bp_nhid	\ 1c  #hidden-sectors                  (lelong)
   4 bfield bp_xnsects	\ 20  total#sectors if bp_nsects is 0  (lelong)

   \ Windows95 FAT32 BPB entries
   4 bfield bp_bspf	\ 24  big sectors/FAT	  (lelong)
   2 bfield bp_flags	\ 28  extended flags	  (leword)
   2 bfield bp_fsver	\ 2a  file system version (leword)
   4 bfield bp_rdirclus	\ 2c  root directory starting cluster  (lelong)
   2 bfield bp_fsinfos	\ 30  file system info sector	       (leword)
   2 bfield bp_bkboots	\ 32  backup boot sector  (leword)
   c bfield bp_reserved	\ 34  reserved
   
   \ The rest of the sector contains boot code, and a magic number (55aa)
   \ in the last 2 bytes.  (aa is in the last byte).
aligned
constant   /bpb

create fssignature0 h# 52 c, h# 52 c, h# 61 c, h# 41 c,
create fssignature  h# 72 c, h# 72 c, h# 41 c, h# 61 c,
variable fssector
variable fsinfo

: fsfield  \ name  ( fsinfo-offset size -- fsinfo-offset' )
   create over , +   does>  @ fsinfo @ +
;

struct  \ fsinfo
   /n fsfield fs_sig		\ signature
   /n fsfield fs_#freeclusters	\ # of free clusters	(lelong)
   /n fsfield fs_freecluster#	\ next free cluster #	(lelong)
3 /n * fsfield fs_reserved
constant  /fsinfo
 
instance variable current-device  -1 current-device !

: dfield \ name ( dev-offset size -- dev-offset')
   create over , +  does>  @ current-device @ +
;

struct \ device
/n dfield fat-cache         \ Address of the FAT cache for this device
/n dfield fat-sector        \ First sector of the FAT that is in the cache
/n dfield spf		    \ Sectors per fat     (from BPB)
/n dfield rdirclus	    \ Root directory starting cluster
/n dfield max-cl#           \ last cluster on device (0.. ** 9/28/90 cpt)
/n dfield cl-sector0        \ device relative start sector of cluster 0
/n dfield dv_cwd-cl         \ Working directory starting cluster
/w dfield sectors/fat-cache \ Size of the FAT cache for this device
/w dfield fat-dirty         \ Does the FAT need to be flushed to disk?
/w dfield cl#/fat-cache     \ Number of cluster entries in the FAT cache
/w dfield fat-sector0       \ device relative start sector of FAT 1
/w dfield dir-sector0       \ device relative start sector of root dir.
/w dfield #dir-sectors      \ of root directory
/w dfield bps		    \ Bytes per sector    (from BPB)
/w dfield fsinfos	    \ File system info sector #  (from BPB)
/c dfield spc		    \ Sectors per cluster (from BPB)
/c dfield media		    \ Media type (f8 for hard disk, f0 for 3.5" floppy)
/c dfield fat-type	    \ Bytes per cluster number
/c dfield fsinfos-dirty	    \ Does the file system info need to be written to disk?
constant /device

d# 12 constant fat12
d# 16 constant fat16
d# 32 constant fat32

: +fs-#free  ( incr -- )
   fs_#freeclusters  dup lel@                ( incr adr n )
   dup h# ffffffff =  if  3drop exit  then   ( incr adr n )
   rot +  swap lel!
   true fsinfos-dirty c!
;
: fs-free#!  ( cluster# -- )  fs_freecluster# lel!  true fsinfos-dirty c!  ;


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
