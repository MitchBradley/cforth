\ See license at end of file
purpose: EXT4 extent handling

d# 12 constant /extent-record

struct
   /w field >eh_magic
   /w field >eh_entries
   /w field >eh_max
   /w field >eh_depth
   /l field >eh_generation
constant /extent-header

: ext-magic?  ( 'eh -- flag )  >eh_magic short@ h# f30a =  ;
: extent?  ( -- flag )  direct0 ext-magic?  ;

struct
   /l field >ee_block
   /w field >ee_len
   /w field >ee_start_hi
   /l field >ee_start_lo
constant /extent

struct
   /l field >ei_block   \ Same offset and size as >ee_block
   /l field >ei_leaf_lo
   /w field >ei_leaf_hi
   /w +  ( >ei_unused )
constant /extent-index  \ Same length as /extent

: index-block@  ( 'extent-index -- d.block# )
   dup >ei_leaf_lo int@  swap >ei_leaf_hi short@
;
: extent-block@  ( 'extent -- d.block# )
   dup >ee_start_lo int@  swap >ee_start_hi short@
;

: >extent  ( index 'eh -- 'extent )
   /extent-header +  swap /extent *  +
;

\ Works for both extents and extent-index's because they are the
\ same length and their block fields are in the same place.
: ext-binsearch  ( block# 'eh -- block# 'extent )
   >r                       ( block# r: 'eh )
   1                        ( block# left r: 'eh )
   r@ >eh_entries short@ 1- ( block# left right r: 'eh )
   begin  2dup <=  while    ( block# left right r: 'eh )
      2dup + 2/             ( block# left right middle r: 'eh )
      dup r@ >extent        ( block# left right middle 'extent r: 'eh )
      >ei_block int@        ( block# left right middle extent-block r: 'eh )
      4 pick >  if          ( block# left right middle r: 'eh )
         nip 1-             ( block# left right' r: 'eh )
      else                  ( block# left right middle r: 'eh )
         rot drop           ( block# right middle r: 'eh )
         1+ swap            ( block# left' right r: 'eh )
      then                  ( block# left right r: 'eh )
   repeat                   ( block# left right r: 'eh )
   drop  1-                 ( block# left r: 'eh)
   r> >extent               ( block# 'extent )
;

: get-extent-block  ( 'extent-index -- 'eh )
   d.block                   ( 'eh )

   \ Error check
   dup ext-magic? 0=  if     ( 'eh )
      ." EXT4 bad index block" cr
      debug-me
   then                      ( 'eh )
;

: extent->pblk#  ( logical-block# -- d.physical-block# )
   direct0                      ( logical-block# 'eh )
   dup >eh_depth short@ 0  ?do  ( logical-block# 'eh )
      ext-binsearch             ( logical-block# 'extent-index )
      index-block@              ( logical-block# d.block# )
      get-extent-block          ( logical-block# 'eh' )
   loop                         ( logical-block# 'eh )

   ext-binsearch  >r            ( logical-block# r: 'extent )
   \ At this point the extent should contain the logical block
   r@ >ee_block int@ -          ( block-offset  r: 'extent )
   
   \ Error check
   dup  r@ >ee_len short@  >=  if  ( block-offset  r: 'extent )
      ." EXT4 block not in extent" cr
      debug-me
   then                            ( block-offset  r: 'extent )
   u>d  r> extent-block@  d+       ( d.block# )
;

: free-extent-blocks  ( 'extent -- )
   dup extent-block@             ( 'extent d.block# )
   rot >ee_len short@  0  ?do    ( d.block# )
      2dup d.free-block          ( d.block# )
      1. d+                      ( d.block#' )
   loop                          ( d.block#' )
   2drop                         ( )
;

: (delete-extents)  ( 'eh level -- )  recursive
   ?dup  if                      ( 'eh level )
      \ Level nonzero means 'eh is an index, so recursively free its blocks.
      1-                         ( 'eh level' )
      over >eh_entries short@    ( 'eh level #entries )
      0  ?do                     ( 'eh level )
         i third >extent         ( 'eh level 'extent-index )
         index-block@ 2>r        ( 'eh level r: d.block# )
         2r@ get-extent-block    ( 'eh level 'subordinate-eh  r: d.block# )
         over (delete-extents)   ( 'eh level  r: d.block# )
         2r> d.free-block        ( 'eh level )
      loop                       ( 'eh level )
      2drop                      ( )
   else                                       ( 'eh )
      \ Level 0 means 'eh is an extent list
      \ For each extent in the list ...
      dup >eh_entries short@  0  ?do          ( 'eh )
         \ Free all the blocks in that extent
         i over >extent free-extent-blocks    ( 'eh )
      loop                                    ( 'eh )
      drop                                    ( )
   then                          ( )
;

\ Delete blocks listed in the current set of extents
: delete-extents  ( -- )
   direct0                      ( 'eh )
   dup >eh_depth short@         ( 'eh depth )
   (delete-extents)             ( )
;

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
