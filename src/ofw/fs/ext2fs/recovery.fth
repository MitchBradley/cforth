h# c03b3998 constant jbd_magic

struct
   /l field >h_magic
   /l field >h_blocktype
   /l field >h_sequence
constant /journal-header
   
\ Superblock - blocktype 3 (version 1) or 4 (version 2)
/journal-header
   /l field >s_blocksize
   /l field >s_maxlen
   /l field >s_first
   /l field >s_sequence
   /l field >s_start
   /l field >s_errno
   /l field >s_feature_compat
   /l field >s_feature_incompat
   /l field >s_feature_ro_compat
   \ We don't need the rest
drop

\ Commit header - blocktype 2
/journal-header
     /c  field >h_chksum_type
     /c  field >h_chksum_size
   2 /c*       \ Padding
   4 /l* field >h_chksum
   2 /l* field >h_commit_sec
     /l  field >h_commit_nsec
constant /commit-header

\ Revoke header - blocktype 5
/journal-header
   /l field >r_count
constant /revoke-header

\ Descriptor block - blocktype 1 - journal header followed by an array of tags
\ Tag - 32-bit and 64-bit forms
struct
   /l field >t_blocknr
   /l field >t_flags
dup constant /tag32
   /l field >t_blocknr_high
constant /tag64

0 value j-buf
0 value j-compat
0 value j-incompat
0 value j-blocksize
0 value j-first
0 value j-last
0 value j-start
0 value j-sequence
0 value tag-bytes

0 value jsb
0 value bh
0 value obh
: free-journal  ( -- )
   jsb  if  jsb  bsize       free-mem  0 to jsb  then
   bh   if   bh  j-blocksize free-mem  0 to  bh  then
   obh  if  obh  j-blocksize free-mem  0 to obh  then
;
: read-journal  ( -- skip? )
   bsize alloc-mem to jsb
   8 set-inode                                  \ 8 is the well-known inode# for the journal
   jsb 0 read-file-block                     ( )

   jsb >h_magic be-l@ jbd_magic <>  if
      free-journal  true exit                ( -- skip? )
   then

   jsb >h_blocktype be-l@ 3 4 between 0=  if
      \ Not superblock
      free-journal  true exit                ( -- skip? )
   then

   jsb >s_start be-l@  to j-start
   j-start 0=  if
      free-journal  true exit                ( -- skip? )
   then
   
   jsb >s_blocksize be-l@  to j-blocksize            ( )

   j-blocksize bsize <>  if
      ." Journal block size != filesystem block size" cr
      free-journal  true exit               ( -- skip? )
   then

   j-blocksize alloc-mem to bh                       ( )
   j-blocksize alloc-mem to obh                      ( )

   jsb >s_sequence be-l@  to j-sequence              ( )
   jsb >s_first be-l@ to j-first                     ( )
   jsb >s_maxlen be-l@ to j-last                     ( )

   jsb >s_feature_compat be-l@ to j-compat           ( )
   jsb >s_feature_incompat be-l@ to j-incompat       ( )

   j-incompat 2 and  if  /tag64  else  /tag32  then  to tag-bytes    \ 2:FEATURE_INCOMPAT_64BIT

   false                                               ( skip? )
;

: +wrap  ( n increment -- n' )
   +  dup j-last >=  if
      j-last -  j-first +
   then
;

0 value tagend
0 value tagp
: first-tag  ( -- )
   bh  j-blocksize +  to tagend   ( )
   bh  /journal-header +  to tagp ( )
;
: +tagp  ( -- end? )
   tagp >t_flags be-l@            ( flags )
   tagp tag-bytes +               ( flags tagp )
   over 2 and  0=  if  d# 16 +  then  ( flags tagp ) \ 2:FLAG_SAME_UUID
   to tagp                        ( flags )
   8 and  if                      ( )          \ 8:FLAG_LAST_TAG
      true                        ( end? )           
   else                           ( )
      tagp tagend >=              ( end? )
   then                           ( end? )
;
: count-tags  ( -- count )
   0                                  ( count )
   first-tag  begin  1+  +tagp until  ( count end? )
;

: write-jblock  ( d.block# adr -- )
   -rot d.write-fs-block     ( error? )
   if  ." Journal recovery write error" cr  abort  then
;

0 value next-log-block
: log-block++  ( -- block# )
   next-log-block dup 1 +wrap to next-log-block  ( block# )
;
: next-jblock  ( buf -- )
   log-block++ read-file-block            ( )
;

0 value crc32-sum
: crc32-block  ( buf -- )
   crc32-sum crctab  rot  j-blocksize  ($crc)  to crc32-sum
;
: calc-chksums  ( -- )
   bh crc32-block
   count-tags  0  ?do
      obh next-jblock  obh crc32-block
   loop
;

listnode
   /n 2* field >r_block#
   /n    field >r_sequence
nodetype: revoke-node

instance variable revoke-list
revoke-list off

: free-revoke-list  ( -- )
   begin  revoke-list >next-node  while  ( )
      revoke-list delete-after           ( node )
      revoke-node free-node              ( )
   repeat                                ( )
; 

\ Worker function for find-node?
: block#=  ( d.block# 'node -- d.block# flag )
   >r_block# 2@  2over d=
;

\ node is either the found one or the insertion point
: find-revoked?  ( d.block# -- d.block# false | d.block# node found? )
   revoke-list ['] block#= find-node?
;

0 value next-commit-id

: revoked?  ( d.block# -- revoked? )
   find-revoked?  if       ( d.block# node )
      nip nip              ( node )
      >r_sequence @        ( sequence# )
      next-commit-id =     ( revoked? )
   else                    ( d.block# )
      2drop  false         ( revoked? )
   then                    ( revoked? )
;

: set-revoke  ( d.block# -- )
   find-revoked?  if                                 ( d.block# node )
      nip nip                                        ( node )
      next-commit-id  over >r_sequence @  - 0>=  if  ( node )
	 next-commit-id  over >r_sequence !          ( node )
      then                                           ( node )
      drop                                           ( )
   else                                              ( d.block# )
      revoke-node allocate-node >r                   ( d.block# r: newnode )
      r@ >r_block# 2!                                ( r: newnode )
      next-commit-id  r@ >r_sequence  !              ( r: newnode )
      r> revoke-list insert-after                    ( )
   then                                              ( )
;

listnode
   /n 2* field >o_block#
   /n 2* field >o_pblock#
   /n    field >o_escaped?
nodetype: overlay-node

instance variable overlay-list
overlay-list off

: free-overlay-list  ( -- )
   begin  overlay-list >next-node  while  ( )
      overlay-list delete-after           ( node )
      overlay-node free-node              ( )
   repeat                                 ( )
; 

: find-overlay?  ( d.block# -- d.block# false | d.block# node true )
   overlay-list ['] block#= find-node?
;

: j-read-file-block  ( adr lblk# -- )
   >d.pblk#  if                   ( adr d.pblk# )
      find-overlay?  if           ( adr d.pblk# node )
         nip nip                  ( adr node )
         tuck >o_pblock# 2@       ( node adr d.pblk# )
         d.block over bsize move  ( node adr )
         swap >o_escaped? l@  if  ( adr )
            jbd_magic swap be-l!  ( )
         else                     ( adr )
	    drop                  ( )
	 then                     ( )
      else                        ( adr d.pblk# )
         d.block swap bsize move  ( )
      then                        ( )
   else                           ( adr )
      bsize erase                 ( )
   then                           ( )
;

0 value j-read-only?
: set-overlay-node  ( escaped? log-blk# d.block# node -- )
   >r                               ( escaped? log-blk# d.block# r: node )
   r@ >o_block# 2!                  ( escaped? log-blk# r: node )
   >d.pblk#  0= abort" EXT3/4 bad block number in journal"
                                    ( escaped? d.pblk# r: node )
   r@ >o_pblock# 2!                 ( escaped? r: node )
   r> >o_escaped? l!                ( )
;
: note-jblock  ( d.block# escaped? log-blk# -- )
   2swap find-overlay?  if          ( escaped? log-blk# d.block# node )
      set-overlay-node              ( )
   else                             ( escaped? log-blk# d.block# )
      overlay-node allocate-node >r ( d.block# escaped? log-blk# r: newnode )
      r@ set-overlay-node           ( r: newnode )
      r> overlay-list insert-after  ( )
   then
;

: replay-tag  ( -- )
   tagp >t_blocknr be-l@               ( block# )
   j-incompat 2 and  if                ( block# )     \ 2:FEATURE_INCOMPAT_64BIT
      tagp >t_blocknr_high be-l@       ( d.block# )
   else                                ( block# )
      u>d                              ( d.block# )
   then                                ( d.block# )
   2dup revoked?  if                   ( d.block# )
      2drop                            ( )
      log-block++ drop                 ( )
   else                                ( d.block# )
      tagp >t_flags be-l@ 1 and        ( d.block# escaped? )
      j-read-only?  if                 ( d.block# escaped? )
         log-block++ note-jblock       ( )
      else                             ( d.block# escaped? )
         obh next-jblock               ( d.block# escaped? )
         if                            ( d.block# )  \ 1:FLAG_ESCAPE
            jbd_magic obh >data be-l!  ( d.block# )
         then                          ( d.block# )
         obh write-jblock              ( )
      then                             ( )
   then                                ( )
;

: replay-descriptor-block  ( -- )
   first-tag  begin  replay-tag  +tagp until  ( )
;

0 value pass
: scanning?   ( -- flag )  pass 0=  ;
: revoking?   ( -- flag )  pass 1 =  ;
: replaying?  ( -- flag )  pass 2 =  ;

0 value end-transaction

: do-descriptor-block  ( -- )
   replaying?  if
      replay-descriptor-block
   else
      scanning?  if
	 j-compat 1 and  if  \ FEATURE_COMPAT_CHECKSUM
	    end-transaction 0=  if
	       calc-chksums  \ Can abort
               exit          \ Continues loop in pass-loop
	    then
	 then
      then
      next-log-block  count-tags  +wrap  to next-log-block
   then
;

0 value j-failed-commit
: do-commit-chksum  ( -- )
   bh >h_chksum be-l@                                 ( sum )
   end-transaction  if                                ( sum )
      true to j-failed-commit                         ( sum )
      drop exit                                       ( -- )
   then                                               ( sum )

   dup crc32-sum =                                    ( sum flag )
   bh >h_chksum_type c@ 1 = and \ 1:CRC32_CHKSUM      ( sum flag' )
   bh >h_chksum_size c@ 4 = and \ 4:CRC32_CHKSUM_SIZE ( sum flag' )
   if                                                 ( sum )
      drop                                            ( )
   else                                               ( sum )
      0=                                              ( flag )
      bh >h_chksum_type c@ 0=                         ( flag' )
      bh >h_chksum_size c@ 0= and  0=  if             ( flag' )
         next-commit-id to end-transaction            ( )
         j-incompat 4 and  if                         ( )  \ 4:FEATURE_INCOMPAT_ASYNC_COMMIT 
            next-commit-id to j-failed-commit         ( )
            abort
         then                                         ( )
      then                                            ( )
   then                                               ( )
   -1 to crc32-sum                                    ( )
;
: do-commit-block  ( -- )
   scanning?  if
      j-compat 1 and  if   \ FEATURE_COMPAT_CHECKSUM
         do-commit-chksum
      then
   then
   next-commit-id 1+ to next-commit-id
;

: do-revoke-block  ( -- )
   revoking?  0=  if  exit  then

   bh /revoke-header +                      ( adr )
   bh >r_count be-l@   bounds               ( endadr adr )

   j-incompat 2 and  if                     ( endadr adr )     \ 2:FEATURE_INCOMPAT_64BIT
      ?do  i be-x@     set-revoke  8 +loop  ( )
   else
      ?do  i be-l@ u>d set-revoke  4 +loop  ( )
   then
;

: pass-loop  ( -- )
   begin
      scanning?  0=  if
         next-commit-id end-transaction - 0>=  if  exit  then
      then
      bh next-jblock                               ( )
      bh >h_magic be-l@ jbd_magic <>  if           ( )
	 exit                                      ( -- )
      then                                         ( )
      bh >h_sequence be-l@ next-commit-id <>  if   ( adr )
	 exit                                      ( -- )
      then                                         ( )
      bh >h_blocktype be-l@  case                  ( )
	 1  of  do-descriptor-block  endof         ( )
         2  of  do-commit-block      endof         ( )
         5  of  do-revoke-block      endof         ( )
         ( default )  drop exit                    ( )
      endcase                                      ( )
   again
;
: one-pass  ( pass -- )
   to pass
   -1 to crc32-sum
   j-sequence to next-commit-id
   j-start    to next-log-block
   pass-loop
   scanning?  if
      end-transaction 0=  if
         next-commit-id to end-transaction
      then
   else
      end-transaction next-commit-id <> abort" Recover end-transaction mismatch"
   then
;
: commit-journal  ( -- )
   j-read-only?  if  exit  then
   jsb >s_sequence dup be-l@ 1+ swap be-l!
   0 jsb >s_start be-l!
   jsb 0 write-file-block
   flush
;
: process-journal  ( -- )
   read-journal  if  exit  then

   ." Recovering from journal "
   j-read-only?  if  ." (read-only)"  then
   ." ... "

   0 to end-transaction

   0 ['] one-pass catch  ?dup  if
      .error
      ." Journal scan failed" cr
      free-journal exit
   then

   1 ['] one-pass catch  ?dup  if
      .error
      ." Journal revoke failed" cr
      free-revoke-list  free-journal  exit
   then

   2 ['] one-pass catch  ?dup  if
      .error
      ." Journal replay failed" cr
      free-overlay-list free-revoke-list  free-journal  exit
   then

   free-revoke-list

   commit-journal
   free-journal
cr
;
