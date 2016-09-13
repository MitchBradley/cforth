32\ : le-x@  ( adr -- x )  dup le-l@  swap la1+ le-l@  ;
0 value #gpt-partitions
0 value /gpt-entry
32\ 0. 2value partition-lba0
32\ alias x>u drop
32\ alias u>x u>d
32\ alias x+ d+
32\ alias x- d-
32\ alias xswap 2swap
32\ : onex 1. ;
32\ : xu*d  ( x u -- d )  du*  ;
64\ alias xu*d um*

: gpt-magic  ( -- adr len )  " EFI PART"  ;
: gpt-blk0   ( adr -- d.blk0 )  d# 32 + le-x@  ;
: gpt-#blks  ( adr -- d.blks )  dup d# 40 + le-x@  rot gpt-blk0 x-  onex d+  ;
