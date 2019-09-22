\ This program converts font data from the format used by
\ Raster Font Editor v0.15 to the unusual bit layout
\ used by the SSD 1306 display chip.  In that chip, each
\ byte represents 8 bits of a vertical display column, with
\ bit 0 being the topmost bit.
\ So the bytes are:
\ Byte 0 bit 0: column 0 row0 (top) .. byte 0 bit 7: column 0 row7 (bottom)
\ Byte 1 bit 0: column 1 row0 (top) .. byte 0 bit 7: column 1 row7 (bottom)
\ This can be described as vertical by byte, increment by column
\ When you get to the character width, then you have to increment
\ the row number by 8.

\ The data in allnums.fnt is orthogonal to that:
\ First byte is row 0 columns 7..0 (big endian)
\ Second byte is row 1 columns 7..0
\ ...
\ i.e horizontal by byte, increment by row
\ When you get to the height, increment the column number by 8

\ So basically it has to be flipped every which way and
\ also endian-converted.  Ouch.

\ The font is a bit numeric font with digits from 0 to 9
\ plus blank.  The size is 21 wide by 32 high, giving the
\ largest possible 3-digit numbers on a 64x48 OLED display,
\ with a little room at the bottom for status messages using
\ a small 5x7 alphanumeric font.

\ I create the numeric font with Raster Font Editor v0.14.
\ and saved it as allnums.fnt (a binary format).  This program
\ reads allnums.fnt and outputs text to stdout, which can be
\ copied/pasted or redirected into numfont-bits.fth .

\ Each row is a vertical stripe of 8 bits
\ The second row is offset by 

\needs le-w@ fl ../../lib/misc.fth

0 value glyph-buf

0 value width
0 value width-bytes
0 value height
0 value height-bytes
0 value height-rounded
0 value #chars
0 value offset
0 value /glyph

: bits>bytes  ( bits -- bytes )  7 + 8 /  ;

0 value fid
$74 constant /header
/header buffer: fnt-header
: +header  ( offset -- adr )  fnt-header +  ;
: fnt-setup  ( filename$ -- )
   r/o open-file abort" Can't open file"  to fid
   fnt-header /header fid read-file abort" Failed to read header"  drop
   $56 +header le-w@ to width
   $58 +header le-w@ to height
   $60 +header c@   $5f +header c@ - 1+ to #chars
   $71 +header le-w@ to offset
   height bits>bytes to height-bytes
   width bits>bytes to width-bytes
   height-bytes 8 * to height-rounded
   width-bytes height-rounded * to /glyph
   /glyph alloc-mem to glyph-buf
   offset u>d fid reposition-file abort" Can't seek to glyph bits"
;

: glyph-in  ( -- )
   width-bytes 0  do
      height-rounded 0  do
         i width-bytes *  j + glyph-buf +  1  ( adr len )
         fid read-file abort" Glyph read failed" drop
      loop
   loop
;
0 value mask
: >offset  ( col# -- offset )
   8 /mod  ( bit# adr )
   $80 rot rshift  to mask  ( adr )
;

: get-vertical-byte  ( row column -- byte )
   >offset  swap width-bytes * 8 * +  glyph-buf +  ( adr )
   \ We go vertically in the frame buffer collecting
   \ one bit from each row, merging them into the
   \ output byte, little-endian.  i.e. the bit in
   \ the topmost (first) row is bit 0 of the output
   0 swap  8 width-bytes * bounds ?do  ( byte )
      2/  i c@ mask and  if  $80 or  then
   width-bytes +loop
;
: glyph-out  ( -- )
   height-bytes  0  do
      width  0  do
         j i get-vertical-byte  ( byte )
         <# u# u# u#> type  ."  "
      loop
      cr
   loop
   cr
;
: convert-glyphs  ( -- )
   ." \ This file was auto-generated from allnums.fnt by convertfnt.fth" cr cr
   ." #" width .d ." #" height .d ." #" #chars .d  ." ssd-font: numfont" cr cr
   #chars 0  do
      i .d ." glyph" cr
      glyph-in
      glyph-out
   loop
   ." ( blank )  #10 glyph" cr
   glyph-in
   glyph-out

   fid close-file drop
;
" allnums.fnt" fnt-setup  convert-glyphs
