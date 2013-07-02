\ See license at end of file
purpose: Numeric display of startup progress

\ Display 2-digit hex or decimal numbers using a simple 3x5 font
\ in a small framebuffer.  The framebuffer is assumed to be 4 bits/pixel,
\ 12 pixels per line, with a pitch of 6 bytes.  The 3x5 font is
\ equivalent to a 7-segment display.

\ There are only 4 distinct row values in a 7-segment display -
\ horizontal bar , left vertical bar, right vertical bar, and
\ left+right vertical bars.  The patterns below encode those
\ cases as pixel values.
\ The frame buffer is assumed to be little-endian, i.e. the
\ least-significant nibble of a shortword displays in the
\ leftmost pixel of the group.
\ 0 is black (foreground), while f is white (background)
\ The 3x5 font is displayed in a 4-wide cell, so each row
\ has a white (f, background) leftmost pixel.

create patterns
h# ff0f w, \ 0  - dot on the right
h# 0fff w, \ 1  - dot on the left
h# 0f0f w, \ 2  - dots on left and right
h# 000f w, \ 3  - dots all the way across

\ Each digit in the base-4 numerals below indexes one of the four patterns.
\ The rightmost (least significant) digit is the topmost line of the 5-high
\ glyph.

create numerals
4 base !
32223 w, \ 0
11111 w, \ 1
30313 w, \ 2
31313 w, \ 3
11322 w, \ 4
31303 w, \ 5
32303 w, \ 6
11113 w, \ 7
32323 w, \ 8
31323 w, \ 9
22323 w, \ a
32300 w, \ b
30003 w, \ c
32311 w, \ d
30303 w, \ e
00303 w, \ f
hex

6 constant fb-pitch
: putdig  ( n pos -- )
   numerals rot wa+ w@                ( pos glyph )
   \ Vertical offset by 2 lines (fb-pitch 2*), horizontal by pos character cells
   diagfb-pa fb-pitch 2* +  rot wa+   ( glyph fb-adr )
   5 0  do                            ( glyph fb-adr )
      over 3 and                      ( glyph fb-adr pattern# )
      patterns swap wa+ w@            ( glyph fb-adr pattern )
      over w!                         ( glyph fb-adr )
      swap 2/ 2/  swap fb-pitch +     ( glyph' fb-adr' )
   loop                               ( glyph fb-adr )
   2drop                              ( )
;
: putdec  ( n -- )  d# 10 /mod  0 putdig  1 putdig  ;
: puthex  ( n -- )  d# 16 /mod  0 putdig  1 putdig  ;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
