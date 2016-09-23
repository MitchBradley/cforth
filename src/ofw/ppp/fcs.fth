\ See license at end of file
purpose: PPP Frame Check Sequence (FCS)

hex

\ 256 entry FCS lookup table
create fcstab
   0000 w, 1189 w, 2312 w, 329b w, 4624 w, 57ad w, 6536 w, 74bf w,
   8c48 w, 9dc1 w, af5a w, bed3 w, ca6c w, dbe5 w, e97e w, f8f7 w,
   1081 w, 0108 w, 3393 w, 221a w, 56a5 w, 472c w, 75b7 w, 643e w,
   9cc9 w, 8d40 w, bfdb w, ae52 w, daed w, cb64 w, f9ff w, e876 w,
   2102 w, 308b w, 0210 w, 1399 w, 6726 w, 76af w, 4434 w, 55bd w,
   ad4a w, bcc3 w, 8e58 w, 9fd1 w, eb6e w, fae7 w, c87c w, d9f5 w,
   3183 w, 200a w, 1291 w, 0318 w, 77a7 w, 662e w, 54b5 w, 453c w,
   bdcb w, ac42 w, 9ed9 w, 8f50 w, fbef w, ea66 w, d8fd w, c974 w,
   4204 w, 538d w, 6116 w, 709f w, 0420 w, 15a9 w, 2732 w, 36bb w,
   ce4c w, dfc5 w, ed5e w, fcd7 w, 8868 w, 99e1 w, ab7a w, baf3 w,
   5285 w, 430c w, 7197 w, 601e w, 14a1 w, 0528 w, 37b3 w, 263a w,
   decd w, cf44 w, fddf w, ec56 w, 98e9 w, 8960 w, bbfb w, aa72 w,
   6306 w, 728f w, 4014 w, 519d w, 2522 w, 34ab w, 0630 w, 17b9 w,
   ef4e w, fec7 w, cc5c w, ddd5 w, a96a w, b8e3 w, 8a78 w, 9bf1 w,
   7387 w, 620e w, 5095 w, 411c w, 35a3 w, 242a w, 16b1 w, 0738 w,
   ffcf w, ee46 w, dcdd w, cd54 w, b9eb w, a862 w, 9af9 w, 8b70 w,
   8408 w, 9581 w, a71a w, b693 w, c22c w, d3a5 w, e13e w, f0b7 w,
   0840 w, 19c9 w, 2b52 w, 3adb w, 4e64 w, 5fed w, 6d76 w, 7cff w,
   9489 w, 8500 w, b79b w, a612 w, d2ad w, c324 w, f1bf w, e036 w,
   18c1 w, 0948 w, 3bd3 w, 2a5a w, 5ee5 w, 4f6c w, 7df7 w, 6c7e w,
   a50a w, b483 w, 8618 w, 9791 w, e32e w, f2a7 w, c03c w, d1b5 w,
   2942 w, 38cb w, 0a50 w, 1bd9 w, 6f66 w, 7eef w, 4c74 w, 5dfd w,
   b58b w, a402 w, 9699 w, 8710 w, f3af w, e226 w, d0bd w, c134 w,
   39c3 w, 284a w, 1ad1 w, 0b58 w, 7fe7 w, 6e6e w, 5cf5 w, 4d7c w,
   c60c w, d785 w, e51e w, f497 w, 8028 w, 91a1 w, a33a w, b2b3 w,
   4a44 w, 5bcd w, 6956 w, 78df w, 0c60 w, 1de9 w, 2f72 w, 3efb w,
   d68d w, c704 w, f59f w, e416 w, 90a9 w, 8120 w, b3bb w, a232 w,
   5ac5 w, 4b4c w, 79d7 w, 685e w, 1ce1 w, 0d68 w, 3ff3 w, 2e7a w,
   e70e w, f687 w, c41c w, d595 w, a12a w, b0a3 w, 8238 w, 93b1 w,
   6b46 w, 7acf w, 4854 w, 59dd w, 2d62 w, 3ceb w, 0e70 w, 1ff9 w,
   f78f w, e606 w, d49d w, c514 w, b1ab w, a022 w, 92b9 w, 8330 w,
   7bc7 w, 6a4e w, 58d5 w, 495c w, 3de3 w, 2c6a w, 1ef1 w, 0f78 w,

\ fcs = (fcs >> 8) ^ fcstab[(fcs ^ *cp++) & ff];
: update-fcs  ( byte fcs -- fcs' )
   wbsplit                 ( byte low high )
   swap rot xor            ( high low^byte )
   fcstab swap wa+ w@ xor  ( fcs' )
;
: fcs   ( a n -- fcs )
   ffff -rot   bounds ?do  i c@ swap update-fcs  loop
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
