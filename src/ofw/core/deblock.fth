\needs umin  : umin  ( u1 u3 -- u3 )  2dup u<  if  drop  else  nip  then  ;

\ Block-to-byte conversion support package.
\ This permits efficient I/O of arbitrary-sized transfers to an
\ underlying device with a fixed block size.
\ This is instantiated as a support package from within another "parent"
\ driver that implements the following methods:
\
\ Mandatory parent methods:
\
\   write-blocks  ( adr block# #blocks -- #blocks-written )
\       Write to underlying device
\   read-blocks   ( adr block# #blocks -- #blocks-read )
\       Read from underlying device
\
\ Optional parent methods.  A default behavior or value is used if the method is not present.
\
\   dma-alloc     ( #bytes -- adr )
\       Allocate space for a buffer.  Defaults to use the general-purpose
\       system memory allocator.  The method should be implemented
\       if read-blocks and/or write-blocks require memory from a special pool
\       in order to work correctly or efficiently.
\   dma-free      ( adr #bytes -- )
\       Free allocated buffer.  Defaults to use the general-purpose system
\       memory allocator.
\   block-size    ( -- #bytes )
\       Size of blocks to be written to device.  Defaults to 512 bytes.
\   max-transfer     ( -- #bytes )
\       The largest transfer (a multiple of blocksize) that is possible.
\       Defaults to 64K bytes.
\   #blocks          ( -- #blocks )
\       The maximum number of blocks that the device can accept.  The deblocker will
\       not attempt to write blocks past this limit.  Defaults to unlimited.
\   current-#blocks  ( -- #blocks )
\       The current number of blocks that the device has, used for the deblocker's
\       size method.  Defaults to the value from #blocks.  #blocks and current-#blocks
\       might be different for dynamically-sized devices.

decimal

" /packages" find-device
new-device

headerless
0 instance value btop     \ number of valid characters in the buffer
0 instance value bend     \ limiting position for putting bytes in the buffer
0 instance value bcurrent \ current position in buffer
false instance value dirty?   \ true if the buffer has been modified
0 0 instance 2value dstart  \ Position in backing device of the first byte in buffer
false instance value write-clipped?   \ true if too few blocks were written

0 instance value block#         \ block offset from last seek
0 instance value buffer         \ The buffer
0 instance value bufsize 	\ Size of buffer
0 instance value blocksize	\ Sector size of underlying device
0 instance value #blocks	\ The maximum number of blocks on the device

0 instance value end-block#
0 instance value write-shortfall

\ These are the words that a program uses to read and write to/from a file.

\ An implementation factor which
\ ensures that btop is >= bcurrent.  bcurrent
\ can temporarily advance beyond btop while a file is being extended.

: sync  ( -- )  \ if current > top, move up top
   btop bcurrent u<  if  bcurrent to btop  then
;

\ Don't try to transfer past the end of the device.

: clipped-#blocks  ( #bytes -- block# #blocks )
   blocksize /                   ( #blocks )
   dstart  blocksize um/mod nip  ( #blocks block# )
   2dup + to end-block#          ( #blocks block# )

   tuck +                        ( block# end-block# )
   #blocks  if                   ( block# end-block# )
      swap block# umin           ( end-block# block#' )
      swap block# umin           ( block#' end-block#' )
   then                          ( block# end-block# )
   over -                        ( block# #blocks )
;

\ If the current file's buffer is modified, write it out
: ?flushbuf  ( -- )
   dirty?  if
      sync
      btop clipped-#blocks          ( block# #blocks )
      over swap                     ( block#  block# #blocks  )
      buffer -rot                   ( block#  adr block# #blocks )
      " write-blocks" $call-parent  ( block# actual-#blocks )
      +  end-block# swap - blocksize *  to write-shortfall   ( )

      false to dirty?
      0 to btop  0 to bcurrent
   then
;

\ Aligns a number to a buffer boundary.
: align-byte#  ( d.byte# -- d.aln-byte# )  bufsize um/mod nip  bufsize um*  ;
: byte#-aligned?  ( d.byte# -- flag )  2dup align-byte#  d=  ;


\ An implementation factor which
\ fills the buffer with a block from the current file.  The block will
\ be chosen so that the file address "d.byte#" is somewhere within that
\ block.

: fillbuf  ( d.byte# -- )
   align-byte# to dstart         ( )  \ Aligns position to a buffer boundary
   buffer                        ( adr )
   bufsize clipped-#blocks       ( adr block# #blocks' )
   " read-blocks" $call-parent   ( actual-#blocks )
   blocksize *  to btop          ( #bytes-read )
   bufsize to bend
;

\ An implementation factor which
\ returns the address within the buffer corresponding to the
\ selected position "d.byte#" within the current file.

: bufpos>  ( bufpos -- d.byte# )  s>d  dstart d+  ;
: >bufpos  ( d.byte# -- bufpos )  dstart d- drop  ;

\ This is called from put to open up space in the buffer for block-sized
\ chunks, avoiding prefills that would be completely overwritten.
: prefill?  ( len -- flag )

   \ If the current buffer pointer is not block-aligned, must prefill
   bcurrent bufpos>  byte#-aligned?  0=  if  drop true  exit  then  ( len )

   u>d align-byte# drop                 ( aln-len )

   \ If the incoming data won't fill a block, must prefill
   ?dup  0=  if  true exit  then        ( aln-size )

   \ If there is still space in the buffer, just open it up for copyin
   bufsize bend -  ?dup  if             ( aln-len buffer-avail )
      min  bend + to bend  false exit   ( -- false )
   then                                 ( aln-len )

   \ Save current on stack because ?flushbuf clears it
   bcurrent                             ( aln-len current )

   \ The buffer is full; clear out its old contents
   ?flushbuf                            ( aln-len current )

   \ Advance the file pointer to the new buffer starting position
   bufpos> to dstart                    ( aln-len )

   bufsize min  to bend                 ( )  \ Room for new bytes
   0 to btop  0 to bcurrent             ( )  \ No valid bytes yet
   false                                ( false )
;

\ An implementation factor which
\ advances to the next block in the file.  This is used when accesses
\ to the file are sequential (the most common case).

\ Assumes the byte is not already in the buffer!
: shortseek  ( bufpos -- )
   ?flushbuf                          ( bufpos )
   bufpos>                            ( d.byte# )
   2dup fillbuf                       ( d.byte# )
   >bufpos  btop umin  to bcurrent    ( )
;

0 invert 1 >> constant maxint	\ Assumes 2's complement

\ Copyin copies bytes starting at adr into the buffer at
\ bcurrent.  The number of bytes copied is either all the bytes from
\ current to end, if the buffer has enough room, or all the bytes the
\ buffer will hold, if not.
\ The not-copied remainder string is returned.
: copyin  ( adr len -- adr' len' )
   dup  bend bcurrent -  min       ( adr len #copy )
   dup if  true to dirty?  then    ( adr len #copy )
   2 pick over                     ( adr len #copy  adr #copy )
   bcurrent buffer +  swap move    ( adr len #copy  )
   dup bcurrent + to bcurrent      ( adr len #copy )
   /string                         ( adr' len' )
;

\ Copyout copies bytes from the buffer into memory starting at current.
\ The number of bytes copied is either enough to fill memory up to end,
\ if the buffer has enough characters, or all the bytes the
\ buffer has left, if not.
\ The not-copied remainder string is returned.
: copyout  ( adr len -- adr' len' )
   dup  btop bcurrent -  min     ( adr len  #copy )
   2 pick over                   ( adr len  #copy  adr #copy )
   bcurrent buffer +  -rot move  ( adr len  #copy )
   dup bcurrent + to bcurrent    ( adr len  #copy )
   /string                       ( adr' len' )
;
headers

" deblocker" device-name

\ This property indicates that bug 1074409 has been fixed.
\ If this property is not present, client programs must install a patch.
0 0 " disk-write-fix" property

: open  ( -- okay? )
   0 to block#                           ( )

   " block-size"  ['] $call-parent catch  if  2drop d# 512  then
   to blocksize                          ( )

   " max-transfer"  ['] $call-parent catch  if  2drop  h# 1.0000  then  ( max )

   \ For fixed-length devices, block-size is greater than 1.  In that
   \ case, we use a buffer that is at least the size of a block, and
   \ preferably somewhat larger, to avoid blowing disk revs.  We don't
   \ want it to be too large though, or we will lose performance when
   \ accessing files, which may require accessing relatively-small index
   \ or directory blocks.
   \ For variable-length devices, block-size is 1.  In that case, we
   \ use a buffer the size of max-transfer.  If we use a smaller one,
   \ the device may try to map too much space.
   blocksize 1 >  if  h# 4000 min  blocksize max  then
   to bufsize                           ( )

   bufsize  " dma-alloc" ['] $call-parent  catch  if  ( x y z )
      3drop  bufsize  allocate  if  ( x-adr )
         drop  false exit           ( -- false )
      then                          ( adr )
   then                             ( adr )
   to buffer                        ( )

   " #blocks" ['] $call-parent  catch  if  ( x x )
      2drop  0                             ( 0 )
   then                                    ( #blocks )
   to #blocks                              ( )

   true                                    ( true )
;

: size  ( -- size.low size.high )
   sync
   btop bufpos>                                     ( d.buffered )
   " current-#blocks" ['] $call-parent catch  if    ( d.buffered x x )
      2drop                                         ( d.buffered )
      #blocks  if  #blocks blocksize um*  else  -1 maxint  then  ( d.buffered d.stored )
   else                                             ( d.buffered #blocks-stored )
      blocksize um*                                 ( d.buffered d.stored )
   then                                             ( d.buffered d.stored )
   dmax                                             ( d.size )
;

: position  ( -- d.offset )  bcurrent bufpos>  ;

: seek   ( d.offset -- error? )
   sync

   \ See if the desired byte is in the buffer
   \ The byte is in the buffer iff offset.high is 0 and offset.low
   \ is less than the number of bytes in the buffer
   2dup dstart d-           ( d.byte# offset.low offset.high )
   over bend  u>=  or  if   ( d.byte# bufpos )
      \ Not in buffer
      \ Flush the buffer and get the one containing the desired byte.
      drop ?flushbuf                         ( d.byte# )
      2dup byte#-aligned?  if                ( d.byte# )
         \ If the new offset is on a block boundary, don't read yet,
         \ because the next op could be a large write that fills the buffer.
         to dstart                           ( )
         0 to btop  0 to bend  0             ( bufpos )
      else
         2dup fillbuf                        ( d.byte# )
         >bufpos                             ( bufpos )
      then                                   ( bufpos )
   else                                      ( d.byte# bufpos )
      \ The desired byte is already in the buffer.
      nip nip                                ( bufpos )
   then

   \ Seeking past end of file actually goes to the end of the file
   btop umin   to bcurrent
   false
;

: read  ( adr len -- #read )
   sync                        ( adr len )
   tuck                        ( len  adr len )
   begin  copyout dup  while   ( len  adr' remlen )
      bcurrent shortseek       ( len  adr remlen )
      \ If, after the seek, the buffer is empty, no more bytes can be read
      bcurrent btop u>=  if  nip -  exit  then
   repeat                      ( len  adr remlen )
   nip -                       ( #read )
;
: write  ( adr len -- #written )
   tuck                           ( len  adr remlen )
   begin  copyin dup  while       ( len  adr remlen' )
      sync                        ( len  adr remlen )
      \ Prefill? tries to avoid unnecessary reads by opening up space
      \ in the buffer for chunks that will completely fill a block.
      dup prefill?  if            ( len  adr remlen )
         bcurrent shortseek       ( len  adr remlen )
      then                        ( len  adr remlen )
      write-shortfall  ?dup  if   ( len  adr remlen shortfall )
         +  nip swap -  exit      ( -- #written )
      then                        ( len  adr remlen )
   repeat                         ( len  adr remlen )
   nip -                          ( #written )
;
: close  ( -- )
   buffer  if                     ( )
      ?flushbuf                   ( )
      buffer  bufsize " dma-free" ['] $call-parent catch  if  ( x x x x )
         4drop  buffer free drop  ( )
      then                        ( )
   then                           ( )
;

finish-device
device-end
