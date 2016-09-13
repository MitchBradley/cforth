\ See license at end of file
\ Extend a file by allocating more clusters and writing out cluster data.
\ 10/2/90 cpt : revised for 1 shot i/o on consecutive clusters

private

: (get-modtime)  ( -- s m h d m y )  de_time lew@ >hms  de_date lew@ >dmy  ;
: (set-modtime)  ( s m h d m y -- )  dmy> de_date lew!  hms> de_time lew!  ;
: (set-createtime)  ( s m h d m y -- )
   fat-type c@  fat32 =  if
      dmy> de_cdate lew! hms> de_ctime lew!  
   else
      3drop 3drop
   then
;
: (set-accessdate)  ( d m y -- )
   fat-type c@  fat32 =  if
      dmy> de_adate lew!  
   else
      3drop
   then
;

: update-dirent ( -- error? )
   fh_flags w@ fh_dirty and  if  \ Update directory entry if file has changed
      fh_diroff w@ fh_dircl @ fh_dev @ set-dirent ?dup if  exit  then
      fh_length l@ de_length lel!
      fh_first l@ file-cluster!
      now today  (set-modtime)
      de_attributes c@ at_archiv or  de_attributes c!
      write-dir-cl   ( error? )  ?dup  if  exit  then
      fh_flags w@ fh_dirty invert and  fh_flags w!
   then
   false
;
\ When a file is first created, it's "de_first" field is set to 0.

: extend-file  ( #needed-clusters -- #needed-clusters' error? )
\ Assumes that fh_physicalcl is the cluster# of the last valid cluster
\ in the file, or 0 if the file is empty

   0  begin  drop                                ( #cls' )
      to-last-cluster
      fh_prevphyscl l@ allocate-cluster if       ( #cls' cluster# )
         fh_prevphyscl l@ if                     ( #cls' cluster# )
            dup fh_prevphyscl l@ cluster!        ( #cls' cluster# )
         else
            dup fh_first l!                      ( #cls' cluster# )
            update-dirent if  drop true exit  then \ to remember got clusters
         then                                    ( #cls' cluster# )
         dup fh_physicalcl l!                    ( #cls' cluster# )
         1st-cl# @ #cont-cls @ + over = IF   
             drop #cont-cls 1+!          \ continuation case
         else 1st-cl# @ 0= IF 
                1st-cl# !  1 #cont-cls ! \ first cluster
             else  next-cl# !  then      \ next range's 1st
         then
         1-                                       ( #cls'-1 )         
         current-position /cluster + fh_length l! ( #cls'-1 )
         false                                    ( #cls'-1 false )
      else                                          
         3                                        ( #cls no-more-space-error )
      then
   over 0= over 0<> or next-cl# @ 0<> or until 
;

variable extended?

: dos-write  ( adr count 'fh -- #written false  |  true )
   fh !  fh_dev @ set-device               ( adr count )
   fh_flags w@ fh_dirty or fh_flags w!

   dup remaining !  dup requested !  swap bufadr !     ( #bytes )
   bytes>clusters                                      ( #needed-clusters )   
   1st-cl# off  #cont-cls off  next-cl# off
   extended? off
   
   begin   remaining @ 0>  while     ( #needed-clusters' )

      \ If we need more cluster(s) and
      \ we're at or beyond the end of the file, add new cluster(s)
      dup 0>
      current-position fh_length l@ >  last-cluster? or   and  if
         extend-file ?dup if  ?flush-fat-cache  nip  exit  then
         extended? on
      else \ same cluster?
          1st-cl# @ 0= if  
             fh_physicalcl l@ 1st-cl# !  1 #cont-cls !
          then
      then                           ( #needed-clusters' )
      
      \ Write the data
      1st-cl# @ #cont-cls @ bufadr @ write-clusters if
         ?flush-fat-cache  true exit
      then

      \ Adjust the length field unless extend-file already did it
      extended? @ 0=  if
         current-position remaining @ + fh_length l!
      then

      \ Continue with the rest of the transfer
      #cont-cls @ /cluster * dup bufadr +!  negate remaining +!

      next-cl# @ ?dup if
         1st-cl# !  1 #cont-cls !  next-cl# off
      else
         1st-cl# off  #cont-cls off
      then

      last-cluster? 0= if  to-next-cluster  then 
   repeat  drop ( )

   extended? @ if
      \ extended partial cluster length adjustment
      remaining @ fh_length l@  +  fh_length l!
   then
   fh_flags w@ fh_dirty or  fh_flags w! \ force dirent & FAT update in close

\ Flushing the FAT here causes excessive seeking.
\   ?flush-fat-cache

   requested @ remaining @ 0 max - ( bytes-tranferred )
   false
;

: dos-close  ( 'fh -- error? )
   fh !
   update-dirent ( error? )
   dup 0=  if  clear-fh  ?flush-fat-cache  then
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
