\ See license at end of file
\ opening, seeking and reading the contents of an existing file.
\ 10/2/90 cpt: revised for reading continuous clusters in 1 shot.

private
: to-first-cluster  ( -- )
   0 fh_logicalcl l!
   fh_first l@ fh_physicalcl l!
   0 fh_prevphyscl l!
;

: last-cluster?  ( -- flag )
   fh_physicalcl l@ fat-end?  fh_physicalcl l@ 0=  or ;

: to-next-cluster  ( -- )
   fh_physicalcl l@  dup fh_prevphyscl l!  ( previous-physical-cluster# )
   cluster@ fh_physicalcl l!
   fh_logicalcl l@ 1+ fh_logicalcl l!
;

: to-last-cluster  ( -- )
   begin  last-cluster?  0=  while  to-next-cluster  repeat
;

: dos-seek  ( byte# fh -- error? )
   fh !   ( byte# )
   fh_dev @ set-device

   fh_clshift w@ >>   ( target-cl )

   \ Bail out early if we're already on the right cluster
   dup fh_logicalcl l@ = if  drop false  exit  then

   \ If we are seeking forward, start at the current position.  Otherwise
   \ start at the beginning of the file.

   dup fh_logicalcl l@ <= if  to-first-cluster  then

   \ Advance to the desired cluster, if it exists.
   begin  dup fh_logicalcl l@ <> while           ( target-cluster# )

      last-cluster?  if  drop true  exit   then   \ End of file?
      to-next-cluster
   repeat                                       ( target-cluster# )

   drop false
;

: log2  ( n -- log2-of-n )
   -1 swap  bits/cell 0  do
       1 >>  dup 0=  if  nip i swap leave  then
   loop  ( log n' )
   drop
;
: fh-open  ( 'dirent -- fh false | true )
   dirent !
   allocate-fh  if  fh !  else  true exit  then

   fh_isopen
   de_attributes c@ at_rdonly and  0=  if  fh_writeable or  then
   fh_flags w!

   current-device @  fh_dev !
   dir-cl @  fh_dircl !  \ Cluster containing the directory entry
   dirent @ dir-buf - fh_diroff w! \ Location of directory entry in its cluster
   ( fh_dircl ?  ) ( fh_diroff ? )
   file-cluster@  fh_first  l!
   de_length lel@ fh_length l!
   to-first-cluster
   /cluster  log2  fh_clshift w!
   fh @ false
;

: name-open  ( adr len mode -- fh false  | true )
   \ If the mode specifies writing, look for writeable normal files
   \ If mode is "read" (0), also find read-only files and subdirectories

   1 >=  if  0  else  at_rdonly  then
   at_system or  at_hidden or              ( adr len file-types )

   find-first  if  dirent @ fh-open  else  -1  then
;

variable remaining \ bytes
variable requested \ bytes
variable bufadr
VARIABLE 1st-cl#   \ marks 1st of an allocated cotinuous cluster range
VARIABLE #cont-cls \ marks # of clusters in the  ----  "  --------
VARIABLE next-cl#  \ marks next 1st cluster of non-continuous cluster range
                   \ (for read its used as a flag only)

: current-position  ( -- n )  fh_logicalcl l@ fh_clshift w@ <<  ;

: cl#-valid?  ( cl# -- flag )  2  max-cl# l@  between  ;

: dos-read  ( adr count 'fh -- #read false  |  true )
   fh !   fh_dev @ set-device                        ( adr count )

   dup remaining !  dup requested ! swap bufadr !     ( count )
   bytes>clusters                                     ( #cls-to-read )
   fh_physicalcl l@  dup 1st-cl# !  1 #cont-cls !     ( #cls phys-cl# )
   cl#-valid?  0=  next-cl# !              \ set if not in valid range!
                                                      ( #cls-to-read )
   begin
      dup 0>
      remaining @ 0>  and
      current-position fh_length l@ u<  and
      last-cluster? 0=  and
   while                                              ( #cls-remaining )
      to-next-cluster 
      1st-cl# @  #cont-cls @  +  fh_physicalcl l@  =  if
         \ increment counter only if not first loop
         next-cl# @  if  next-cl# off  else  #cont-cls 1+!  then
      else 
         next-cl# @ 0= if
            1st-cl# @  #cont-cls @  bufadr @  read-clusters  if  
               drop true  exit
            then
            #cont-cls @  /cluster *  dup bufadr +!  negate remaining +!
         then
         fh_physicalcl l@ 1st-cl# !  1 #cont-cls !  next-cl# off
      then
      1-  ( #cls-to-read-1 )
   repeat  drop
   
   remaining @ 0>  next-cl# @ 0=  and  1st-cl# @ cl#-valid?  and  if
      \ We did loop & there is real data
      remaining @  bytes>clusters          ( #clusters-left )
      1st-cl# @ over bufadr @ read-clusters  if  drop true exit  then
      /cluster *  negate  remaining +!
   then

   requested @  remaining @ -              ( bytes-tranferred )

   \ If the last cluster of the file has been read, account for the
   \ true length of the file
   current-position fh_length l@ u>  if    ( bytes-tranferred )
      current-position fh_length l@ -  -   ( bytes-valid )
   then                                    ( bytes-valid )

   false
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
