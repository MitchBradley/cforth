\ See license at end of file
\ Initializes a disk, creating an empty MS-DOS file system.

private

create ibm-jmp  h# eb c,  h# 34 c,  h# 90 c,  0 c,

create fat32-jmp  h# eb c,  h# 58 c,  h# 90 c,  0 c,

: set-params16
( #hidden-sectors #sides sec/trk sec/fat media-desc #sectors #dirents spc bps 
  -- )
   ibm-jmp     bp_branch 3 cmove  \  0  branch-to-boot instruction
   " Forthmax" bp_name swap cmove \  3  system name string
               bp_bps lew!        \  b  bytes/sector
               bp_spc c!          \  d  sectors/cluster
   1           bp_res lew!        \  e  #reserved-sectors
   2           bp_nfats c!        \ 10  #FATs
               bp_ndirs lew!      \ 11  #directory-entries
   dup h# 10000 <  if
               bp_nsects lew!     \ 13  total-#sectors (including reserved ones)
   else
               bp_xnsects lel!    \ 20  total #sectors (4 bytes)
   then
               bp_media c!        \ 15  media descriptor ("magic" number)
               bp_spf lew!        \ 16  sectors/FAT
               bp_spt lew!        \ 18  sectors/track
               bp_nsides lew!     \ 1a  #sides (#heads)
               bp_nhid lel!       \ 1c  #hidden-sectors
;
: set-params32
( #hidden-sectors #sides sec/trk sec/fat media-desc #sectors #dirents spc bps 
  -- )
   fat32-jmp   bp_branch 3 cmove  \  0  branch-to-boot instruction
   " Forthmax" bp_name swap cmove \  3  system name string
               bp_bps lew!        \  b  bytes/sector
               bp_spc c!          \  d  sectors/cluster
   ( #dirents ) drop
   20          bp_res lew!        \  e  #reserved-sectors
   2           bp_nfats c!        \ 10  #FATs
               bp_xnsects lel!    \ 20  total #sectors (4 bytes)
               bp_media c!        \ 15  media descriptor ("magic" number)
	       bp_bspf lel!	  \ 24  big sectors/FAT
               bp_spt lew!        \ 18  sectors/track
               bp_nsides lew!     \ 1a  #sides (#heads)
               bp_nhid lel!       \ 1c  #hidden-sectors
   2	       bp_rdirclus lel!	  \ 2c  root directory starting cluster
   1	       bp_fsinfos lew!	  \ 30  file system info sector
;
: fill-sectors  ( sector# #sectors byte -- )
   /sector alloc-mem                 ( sector# #sectors byte adr )
   tuck /sector  rot fill            ( sector# #sectors adr )
   -rot bounds  ?do                  ( adr )
      i 1 2 pick write-sectors if  /sector free-mem


         "CaW ". ." sector"  abort  then  ( adr )
   loop                              ( adr )
   /sector free-mem
;
public	\ Called with $call-self
: (init-disk)
   ( #hid-sectors #sides sec/trk sec/fat media-desc #sectors #dirents
     spc bps fat32? -- )

   over >r >r
   dos-lock

   uncache-device   \ force BPB refresh for the next time
   0 dv_cwd-cl l!   \ Go to root directory on this device

   dup alloc-mem dup bpb ! over erase
  
   r@  if  set-params32  else  set-params16  then
   bpb>device
   r> r>			( fat32? bps )

   bpb @ over 1- + h# aa over c! 1- h# 55 swap c!
   0 1 bpb @ write-sectors	( fat32? bps error? )
   rot  if	\ Write file system info sector
      alloc-fssector
      fssector @ 2 pick erase
      over /fsinfo - /n - fssector @ + fsinfo !
      fssignature0 fssector @ 4 cmove
      fssignature  fs_sig 4 cmove
      bp_nsects lew@ ?dup 0=  if  bp_xnsects lel@ then
      bp_res lew@ -  bp_spc c@ / 2-  fs_#freeclusters lel!
      3 fs_freecluster# lel!
      fssector @ 2 pick 1- + h# aa over c! 1- h# 55 swap c!
      1 1 fssector @ write-sectors or	( bps error? )
      free-fssector
   then

   bpb @ rot free-mem
   if  "CaW ". ." sector 0"  abort  then

   0 bps w!    \ Force reread
   ?read-bpb   \ Now read back the BIOS parameter block

   \ Clear the FATs. (0 means "free cluster")
   fat-sector0 w@  spf l@ 2*  ( assume 2 FATs )  0  fill-sectors

   media c@ h# 0fff.ff00 or  0 cluster!
   fat-eof  1 cluster!
   fat-type c@ fat32 =  if  fat-eof 2 cluster!  then
   ?flush-fat-cache

   \ Clear the root directory.
   init-dir   \ Invalidate the directory cache
   rdirclus l@  ?dup  if
      1 cl>sector 0 fill-sectors
   else
      dir-sector0 w@ #dir-sectors w@ 0  fill-sectors
   then
   
   \ XXX We should put a label in the root directory.

   dos-unlock
;

[ifdef] format-floppies

public

\ Extra high density floppy; 2.88MB total space (3-1/2")
\ 512-byte sectors, 8.5K x 2 FATs, 7K root directory, 2 sectors/cluster
: 3ed-fl-init  ( -- )
   2ed-den
   0  2  d# 36  d# 9  h# f0  d# 5760  d# 224  2  d# 512  0  false  (init-disk)
;

\ PC/AT style high density floppy; 1.44MB total space (3-1/2")
\ 512-byte sectors, 4.5K x 2 FATs, 7K root directory, 1 sectors/cluster
: 3hd-fl-init  ( -- )
   2hd-den
   0  2  d# 18  9  h# f0  d# 2880  d# 224  1  d# 512  0  false  (init-disk)
;
[then]

[ifdef] format-hard-disks

public

variable  c-kbytes d# 5120 c-kbytes ! \ ** 1/17/91 cpt 

\ Hard disk, using 5 Mbytes of the disk for DOS file system space
\ 1K sectors, 6K x 2 FATs (enough to map <3 Mbytes of disk space),
\ 256 root directory entries (8K), ?M total space, 1 sector/cluster
: hd-init  ( -- )  \ 10 sects/FAT               
   0  7  9  c-kbytes @ 2* d# 1024 /mod swap  if  1+  then
                   h# f8  c-kbytes @  d# 256  1  d# 1024  false  (init-disk)
;
[then]

[ifdef] format-floppies

public

: format-1.44  ( -- )  3hd-format 3hd-fl-init  ;
: format-2.88  ( -- )  3ed-format 3ed-fl-init  ;
[then]
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
