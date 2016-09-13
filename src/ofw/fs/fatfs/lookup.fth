\ See license at end of file
\ XXX perhaps we should cache a sector of the directory, rather than a cluster.
\ That would simplify the handling of end conditions in the root directory,
\ especially for writing.

\ Directory search utilities

\ FAT32 root directory is just like any subdirectory.  Only the subdirectory
\ paths are taken for FAT32 directory search.

decimal
private

\ Working drive
instance variable drive

\ The state of the current search is maintained in the following variables
\ We need two copies of this state, because we have to search subdirectories
\ while parsing the path name.

instance variable search-state

: lfield ( offset size -- offset')
   create over , + does> @ search-state @ +
;

struct   \ search-state
 /n lfield  search-cl     \ Cluster containing the next entry
 /n lfield  search-offset \ Offset of the next entry in its cluster
 /n lfield  search-dev    \ Device containing directory being searched
  8 lfield  search-name   \ pattern to compare with file names
  3 lfield  search-ext    \ pattern to compare with file extensions
  8 lfield  base-name     \ Actual filename, without path portion
  3 lfield  base-ext      \ Actual extension, without path portion
  1 lfield  bn-len        \ base name length
  1 lfield  be-len        \ base extension length
  1 lfield  search-attrib \ mask for file types to consider
constant /search-state

d# -200 constant cl#eof  \ Invalid cluster number to mark end of file

\ Starting cluster# of the directory containing the last found file
VARIABLE search-dir-cl

/search-state instance buffer: file-search-state

: characters-match?  ( filename-char pattern-char -- flag )
   dup ascii ? =  if  2drop true  else  =  then
;
: names-match?  ( -- flag ) \ Assumes dirent address already set
   true
   de_name  ( adr )
   search-name d# 11 bounds  do    ( flag adr' )
      dup c@  i c@  characters-match? 0=  if  nip false swap leave  then
      1+
   loop   ( flag adr )
   drop
;

\ Local variables used by the pattern parser "set-pattern"
variable buf-adr
variable buf-rem
variable pat-adr
variable pat-rem
: set-char  ( char -- )  buf-adr @ c!  1 buf-adr +!  -1 buf-rem +!  ;
: set-pattern  ( pattern-adr pattern-len  buf-adr buf-len -- )
   2dup blank  ( pattern-adr pattern-len  buf-adr buf-len )
   rot over min -rot  ( pattern-adr pattern-len'  buf-adr buf-len )
   buf-rem !  buf-adr !  pat-rem !  pat-adr !
   begin
      pat-rem @
   while
      pat-adr @ c@  1 pat-adr +!  -1 pat-rem +!
      dup ascii *  =  if
         drop  buf-adr @  buf-rem @  bounds  ?do  ascii ? i c!  loop
  buf-rem @  pat-rem @  >  if
     buf-rem @  pat-rem @  -  buf-adr +!  pat-rem @ buf-rem !
         then
      else
  upc set-char
      then
   repeat
;
: drive#  ( adr len -- adr' len' drive# )
[ifdef] notdef
   ascii : left-parse-string   rot  if
      rot c@  upc  dup  ascii A  ascii Z  between  if
         ascii A -
      else
         drop  drive @
      then
   else
      rot drop  drive @
   then                ( adr' len' )
[else]
   drive @
[then]
;
: dot-name?  ( adr len -- flag )  2dup  " ." $=  -rot  " .." $=  or  ;
: set-filename  ( adr len -- )

   2dup  dot-name?  if  \ . and .. are special cases
      " "
   else
      ascii . left-parse-string  2swap
   then                                ( name-adr name-len ext-adr ext-len )

   base-ext 3 BLANK  base-name 8 BLANK  \ Prime with blanks

   2dup dup be-len c! base-ext swap cmove
   search-ext 3 set-pattern    ( name-adr name-len )
   2dup dup bn-len c! base-name swap cmove
   search-name 8 set-pattern

   \ Convert all copies of the strings to upper case
   base-ext  be-len c@ upper   base-name bn-len c@ upper
   search-ext 3 upper  search-name 8 upper
;

\ Write-through directory cache.

\ h# 4000 constant /cluster-max
\ /cluster-max instance buffer: dir-buf
variable dir-dev   -1 dir-dev !
variable dir-cl  cl#eof dir-cl !

: cl>root-sectors  ( -cl# -- #sectors )  negate  spc c@ *  ;

: init-dir  ( -- )
   -1 dir-dev !		\ Marks the cache as empty
   rdirclus @ ?dup  0=  if  cl#eof  then  dir-cl !
;

\ Handle possible swap of removable media.
: ?media-changed  ( -- )
   DOS-LOCK  media-changed?  if  init-dir  then
;

\ Directory clusters numbers are funny, because the root directory is
\ outside the normal range of clusters and its size is not necessarily a
\ multiple of the cluster size.  We use positive numbers for clusters
\ in subdirectories, 0 for the first "cluster" in the root directory,
\ and negative numbers for subsequent "clusters" in the root directory.

\ Writes the directory cache contents to disks.
: write-dir-cl  ( -- error? )
   dir-dev @ set-device
   dir-cl @ 0>  if    \ Subdirectory cluster
      dir-cl @ 1  dir-buf  write-clusters   ( error? )
   else      \ Root directory sectors
      dir-cl @ cl>root-sectors              ( rel-sector# )
      #dir-sectors w@ over -                ( rel-sector# rem-#sectors )
      spc c@ min                            ( rel-sector# #sectors )
      swap dir-sector0 w@ + swap            ( sector# #sectors )
      dir-buf  write-sectors      ( error? )
   then
;

\ Ensures that the cluster containing the desired directory entry is in
\ memory, reading it from disk if necessary.
: set-dirent  ( offset cl dev -- error? )
   rot  dir-buf + dirent !                     ( cl dev )

   over dir-cl @ =  over dir-dev @ = and  if   ( cl dev )
      2drop  \ Directory cluster already in memory
   else                                        ( cl dev )
      \ The desired cluster is not in the cache, so we have to read it in.

      \ Invalidate the cache in case of read failure
      init-dir                                 ( cl dev )

      dup set-device                           ( cl dev )

      \ Subdirectory or root directory?

      over  0>  if                             ( cl dev )
         \ Subdirectory; read clusters from cluster space
         over 1 dir-buf read-clusters          ( cl dev error? )
      else                                     ( cl dev )
         \ Root directory; read sectors from before cluster space
         over cl>root-sectors                  ( cl dev rel-sector# )
         #dir-sectors w@ over -                ( cl dev rel-sector# rem-#sects)
         spc c@ min                            ( cl dev rel-sector# #sectors )
         swap dir-sector0 w@ + swap            ( cl dev sector# #sectors )
         dir-buf read-sectors                  ( cl dev error? )
      then                                     ( cl dev error? )

      if  "CaR ". "dir ". cr  2drop  true exit  then
      ( cl dev )
      \ The read succeeded, so we can set the directory cache tags
      dir-dev ! dup dir-cl !   ( cl )

      \ Since the directory cache is sized in clusters, not sectors,
      \ and since a cluster may be larger than the root directory,
      \ part of the directory cache may be invalid.  This can only
      \ happen for the root directory which is allocated in sectors;
      \ subdirectories are allocated in clusters.

      0<=  if          ( )
         \ This is the root directory.
         \ Is part of the directory buffer invalid?

         dir-cl @ 1- cl>root-sectors #dir-sectors w@ >  if

            \ Set the invalid portion to look like unallocated files.
            dir-cl @ 1- cl>root-sectors #dir-sectors w@ - ( #inv-sectors )
            dir-buf /cluster +  swap /sector * -  0 swap c!
         then
      then
   then
   false
;

: +dirent  ( -- end? )
   search-cl @ cl#eof =  if  true exit  then

   /dirent search-offset +!
   /cluster  ( dir-chunk-size )  search-offset @ >  if  false exit  then
   0 search-offset !

   \ Advance to the next cluster in the directory if there is one

   search-cl @
   dup 0>  if                                      ( current-cluster )
      \ It's a normal subdirectory cluster
      cluster@  dup fat-end?                       ( new-cluster# end? )
   else                                            ( current-cluster )
      \ It's the root directory so the sectors are in a fixed place
      1- dup cl>root-sectors #dir-sectors w@ >=    ( pseudo-cl# end? )
   then                                            ( new-cl# end? )

   tuck  if  drop  else  search-cl !  then         ( end? )
;

: advance-entry  ( -- 0=deleted | -1=okay | 1=soft-end  | 2=hard-end )
   +dirent  if  2 exit  then \ Go to next dirent; exit if there are no more

   \ Set the directory entry address; exit if set-dirent fails
   search-offset @ search-cl @ search-dev @ set-dirent if  2 exit  then

   de_attributes c@  h# f =  if  0 exit  then  \ ignore a VFAT long file name

   de_attributes c@  at_vollab and  if  0 exit  then  \ ignore a volume label

   de_name c@  case
      0      of     1   endof \ No more valid entries
      h# e5  of     0   endof \ Deleted file
      ( default )  -1 swap \ Valid entry
   endcase
;

: next-file  ( -- another? )
   begin  advance-entry  dup 0<=  while  0< if  true  exit  then   repeat
   drop  false
;
: find-dir  ( -- another? )
   begin
      advance-entry  dup 0<=
   while
      0<  if
         de_attributes c@ at_subdir and  if
            names-match?  if  true  exit  then
         then
      then
   repeat
   drop  false
;

: attributes-match?  ( -- flag? )
   de_attributes c@ at_archiv invert and  ( masked-attributes )
   search-attrib c@ invert and  0=
;
\ : attributes-match?  ( -- flag? )
\    de_attributes c@  at_archiv invert and  at_rdonly invert and
\    ?dup  0=  if  at_normal  then
\    search-attrib c@ and  0<>
\ ;
: reset-search  ( cl# -- )
   dup search-dir-cl ! search-cl !  /dirent negate search-offset !
;

[ifndef] /string
\ Remove n characters (if there are that many) from the string adr,len
: /string  ( adr len n -- adr' len' )  over min  tuck -  -rot + swap  ;
[then]

: set-search  ( adr len file-types -- )

   search-attrib c!

   \ Set the search drive, either from the path if it contains e.g. A: , or
   \ from the current device

   drive#  dup search-dev !  set-device    ( adr' len' )

   \ The path starts at the root directory if the first character is "\";
   \ otherwise it starts at the current directory
   dup 1 >=  if
      over c@  ascii \  =  if
         1 /string
         rdirclus l@
      else
         dv_cwd-cl l@
      then
   else
      dv_cwd-cl l@
   then                                    ( adr' len' cl# )

   reset-search                            ( adr' len' )

   \ If a search path is present, find the indicated subdirectory

   begin                                   ( adr' len' )

      \ Split the remaining string at the first backslash, if there is one
      ascii \ split-before                 ( adr' len' dir-adr dir-len )

   2 pick  while                           ( adr' len' dir-adr dir-len )
      set-filename                         ( adr' len' )
      find-dir if  file-cluster@
      else  cl#eof then                    ( adr' len' cl# )
      dup reset-search                     ( adr' len' cl# )

      \ Bail out if the requested directory wasn't found
      cl#eof =  if  2drop exit  then       ( adr' len' )
      1 /string				   ( adr' len' )  \ Remove the '\'
   repeat                                  ( adr 0 filename-adr filename-len )

   set-filename
   2drop
;

: init-search  ( adr len file-types -- )
   file-search-state search-state ! ( adr len file-types )  set-search
;

internal

: find-next  ( -- flag )
   begin  next-file  while
      attributes-match? names-match?  and  if  true exit  then
   repeat
   false
;
: find-first  ( adr len file-types -- flag )  init-search find-next  ;

private

: extend-dir  ( -- error? )
   search-cl @ 0<=  if  true exit  then
   search-cl @ allocate-cluster           ( cluster# true  |  false )
   if                                     ( cluster# )
      dup search-cl @ cluster!            ( cluster# )
      dup search-cl !  0 search-offset !  ( cluster# )
      0 swap search-dev @ set-dirent ?dup  if  exit  then
      dirent @  /cluster  0  fill    \ Clear it.
      write-dir-cl   ( error? )
   else                                 ( )
      true
   then
;

\ This is only called after "find-first" has just been executed, so the
\ directory and drive context is already set properly.
: find-free-dirent  ( -- error? )
   \ Go back to the starting cluster of the directory that was most recently
   \ searched.
   search-dir-cl @ reset-search

   ( advance-entry returns:  -1=file | 0=deleted  | 1=soft-end  | 2=hard-end )
   begin  advance-entry  dup 0 1 between 0=  while
      2 =  if  extend-dir exit  then
   repeat

   \ Found a slot for the new file
   drop  false
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
