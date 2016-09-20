\ See license at end of file
purpose: Linux ext2fs file system superblock

decimal

512     constant ublock
2       constant super-block#
1024    constant /super-block
h# ef53 constant fs-magic

0 instance value super-block
0 instance value gds

\ XXX note: if the ext2fs is always LE, simplify this code.
defer short@  ( adr -- w )  ' be-w@ to short@
defer int@    ( adr -- l )  ' be-l@ to int@
defer short!  ( w adr -- )  ' be-w! to short!
defer int!    ( l adr -- )  ' be-l! to int!

\ superblock data
: +sbl  ( index -- value )  super-block  swap la+ int@  ;
: +sbw  ( index -- value )  super-block  swap wa+ short@  ;
: datablock0    ( -- n )   5 +sbl  ;
: logbsize	( -- n )   6 +sbl 1+  ;
: bsize		( -- n )   1024  6 +sbl lshift  ;	\ 1024
: /frag		( -- n )   1024  7 +sbl lshift  ;	\ 1024
: bpg		( -- n )   8 +sbl  ;			\ h#2000 blocks_per_group
: fpg		( -- n )   9 +sbl  ;			\ h#2000 frags_per_group
: ipg		( -- n )  10 +sbl  ;			\ h#790  inodes_per_group
: magic         ( -- n )  28 +sbw  ;
: state@        ( -- n )  29 +sbw  ;    \ for fsck: 0 for dirty, 1 for clean, 2 for known errors
: state!        ( n -- )  super-block 29 wa+ short!  ;
: revlevel	( -- n )  19 +sbl  ;
: /inode        ( -- n )  revlevel 1 =  if  44 +sbw  else  h# 80  then  ;
\ : bsize	( -- n )
\    /block if   1024  6 +sbl lshift to /block  then  /block
\ ;

: ceiling   ( nom div -- n )     ;

\ : total-inodes		( -- n )   0 +sbl  ;
: d.total-blocks	( -- d )   1 +sbl  84 +sbl  ;
: d.total-free-blocks	( -- d )   3 +sbl  86 +sbl  ;
\ : total-free-inodes	( -- n )   4 +sbl  ;
\ : total-free-blocks+!	( -- n )   3 +sbl  +  super-block  3 la+ int!  ;
\ : total-free-inodes+!	( -- n )   4 +sbl  +  super-block  4 la+ int!  ;
: d.total-free-blocks!	( d -- )   super-block  tuck 86 la+ int!  3 la+ int!  ;
: total-free-inodes!	( -- n )   super-block  4 la+ int!  ;
: #groups   ( -- n )   d.total-blocks bpg um/mod swap  if  1+  then  ;

: recover?  ( -- flag )  24 +sbl 4 and 0<>  ;

: compat-flags    ( -- mask )  23 +sbl  ;
: incompat-flags  ( -- mask )  24 +sbl  ;
: ro-flags        ( -- mask )  25 +sbl  ;

: sb-filetype? ( -- flag )  incompat-flags 2 and  0<>  ;
: sb-64bit?    ( -- flag )  incompat-flags h# 80 and  0<>  ;
: sb-extents?  ( -- flag )  incompat-flags h# 40 and  0<>  ;
: sb-gd-csum?  ( -- flag )  ro-flags       h# 10 and  0<>  ;
: sb-nlink?    ( -- flag )  ro-flags       h# 20 and  0<>  ;

\ Don't write to a disk that uses extensions we don't understand
: unknown-extensions?   ( -- unsafe? )
   compat-flags   h# ffffffff invert and        \ Accept all compat extensions
   incompat-flags h# 00000002 invert and  or    \ Incompatible - accept FILETYPE, EXTENTS, FLEX_BG
   ro-flags       h# 00000073 invert and  or    \ RO - accept SPARSE_SUPER, LARGE_FILE, GDT_CSUM, DIR_NLINK, EXTRA_ISIZE
;
: 'sb-uuid  ( -- adr )  super-block h# 68 +  ;
variable le-group
: sb-desc-size  ( -- )  d# 127 +sbw  ;

: sb-gd-csum  ( 'gd -- w )  h# 1e + le-w@  ;
: sum-gd  ( group# 'gd -- sum )
   h# ffff 'sb-uuid d# 16 ($crc16)           ( group# 'gd sum )
   rot le-group le-l!  le-group /l ($crc16)  ( 'gd sum' )
   over h# 1e ($crc16)                       ( 'gd sum' )
   sb-64bit?  h# 20 sb-desc-size <  and  if  ( 'gd sum' )
      swap sb-desc-size  h# 20 /string       ( sum adr len )
      ($crc16)                               ( sum' )
   else                                      ( 'gd sum' )
      nip                                    ( sum' )
   then                                      ( sum' )
;
: gd-csum-ok?  ( group# 'gd -- ok? )
   sb-gd-csum?  if            ( group# 'gd )
      tuck sum-gd             ( 'gd sum )
      swap h# 1e + le-w@  <>  ( flag )
   else                       ( group# 'gd )
      2drop true              ( flag )
   then                       ( flag )
;
: set-gd-csum  ( group# 'gd -- )
   sb-gd-csum?  if            ( group# 'gd )
      tuck sum-gd             ( 'gd sum )
      swap h# 1e +  le-w!     ( )
   else                       ( group# 'gd )
      2drop                   ( )
   then                       ( )
;

: do-alloc  ( adr len -- )  " dma-alloc" $call-parent  ;
: do-free   ( adr len -- )  " dma-free" $call-parent  ;

: init-io  ( -- )
   \ Used to set partition-offset but now unnecessary as parent handles it
;

: d.write-ublocks  ( adr len d.dev-block# -- error? )
   ublock du* " seek" $call-parent ?dup  if  exit  then		( adr len )
   tuck " write" $call-parent <>
;
: put-super-block  ( -- error? )
   super-block /super-block super-block# u>d d.write-ublocks
;

: d.read-ublocks  ( adr len d.dev-block# -- error? )
   ublock du* " seek" $call-parent ?dup  if  exit  then		( adr len )
   tuck " read" $call-parent <>
;

: get-super-block  ( -- error? )
   super-block /super-block super-block# u>d d.read-ublocks ?dup  if  exit  then

   ['] le-l@ to int@  ['] le-w@ to short@
   ['] le-l! to int!  ['] le-w! to short!
   magic fs-magic =  if  false exit  then

   ['] be-l@ to int@  ['] be-w@ to short@
   ['] be-l! to int!  ['] be-w! to short!
   magic fs-magic <>
;

: d.gds-fs-block#  ( -- d.fs-block# )
   datablock0 1+ u>d	( d.logical-block# )
;
: d.gds-block#  ( -- d.dev-block# )
   d.gds-fs-block#  bsize ublock / du*		( dev-block# )
;
: desc64?  ( -- flag )  sb-desc-size  0<>  ;
: /gd  ( -- n )  sb-desc-size  ?dup 0=  if  h# 20  then  ;
: /gds  ( -- size )  #groups /gd *  ublock round-up  ;
: group-desc  ( group# -- adr )  /gd *  gds +  ;
: d.gpimin    ( group -- d.block# )
   group-desc  dup  2 la+ int@  ( adr block# )
   desc64?  if  swap 9 la+ int@ else  nip 0  then  ( d.block# )
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
