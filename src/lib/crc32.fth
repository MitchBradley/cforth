\ See license at end of file
purpose: ZIP CRC calculation

\ The ZIP CRC uses the polynomial:
\ x^32+x^26+x^23+x^22+x^16+x^12+x^11+x^10+x^8+x^7+x^5+x^4+x^2+x+1.
\ For more information, see the source code for the "zip" utility.

\ Table of CRC-32's of all single byte values

hex
create crctab
  00000000 l, 77073096 l, ee0e612c l, 990951ba l, 076dc419 l,
  706af48f l, e963a535 l, 9e6495a3 l, 0edb8832 l, 79dcb8a4 l,
  e0d5e91e l, 97d2d988 l, 09b64c2b l, 7eb17cbd l, e7b82d07 l,
  90bf1d91 l, 1db71064 l, 6ab020f2 l, f3b97148 l, 84be41de l,
  1adad47d l, 6ddde4eb l, f4d4b551 l, 83d385c7 l, 136c9856 l,
  646ba8c0 l, fd62f97a l, 8a65c9ec l, 14015c4f l, 63066cd9 l,
  fa0f3d63 l, 8d080df5 l, 3b6e20c8 l, 4c69105e l, d56041e4 l,
  a2677172 l, 3c03e4d1 l, 4b04d447 l, d20d85fd l, a50ab56b l,
  35b5a8fa l, 42b2986c l, dbbbc9d6 l, acbcf940 l, 32d86ce3 l,
  45df5c75 l, dcd60dcf l, abd13d59 l, 26d930ac l, 51de003a l,
  c8d75180 l, bfd06116 l, 21b4f4b5 l, 56b3c423 l, cfba9599 l,
  b8bda50f l, 2802b89e l, 5f058808 l, c60cd9b2 l, b10be924 l,
  2f6f7c87 l, 58684c11 l, c1611dab l, b6662d3d l, 76dc4190 l,
  01db7106 l, 98d220bc l, efd5102a l, 71b18589 l, 06b6b51f l,
  9fbfe4a5 l, e8b8d433 l, 7807c9a2 l, 0f00f934 l, 9609a88e l,
  e10e9818 l, 7f6a0dbb l, 086d3d2d l, 91646c97 l, e6635c01 l,
  6b6b51f4 l, 1c6c6162 l, 856530d8 l, f262004e l, 6c0695ed l,
  1b01a57b l, 8208f4c1 l, f50fc457 l, 65b0d9c6 l, 12b7e950 l,
  8bbeb8ea l, fcb9887c l, 62dd1ddf l, 15da2d49 l, 8cd37cf3 l,
  fbd44c65 l, 4db26158 l, 3ab551ce l, a3bc0074 l, d4bb30e2 l,
  4adfa541 l, 3dd895d7 l, a4d1c46d l, d3d6f4fb l, 4369e96a l,
  346ed9fc l, ad678846 l, da60b8d0 l, 44042d73 l, 33031de5 l,
  aa0a4c5f l, dd0d7cc9 l, 5005713c l, 270241aa l, be0b1010 l,
  c90c2086 l, 5768b525 l, 206f85b3 l, b966d409 l, ce61e49f l,
  5edef90e l, 29d9c998 l, b0d09822 l, c7d7a8b4 l, 59b33d17 l,
  2eb40d81 l, b7bd5c3b l, c0ba6cad l, edb88320 l, 9abfb3b6 l,
  03b6e20c l, 74b1d29a l, ead54739 l, 9dd277af l, 04db2615 l,
  73dc1683 l, e3630b12 l, 94643b84 l, 0d6d6a3e l, 7a6a5aa8 l,
  e40ecf0b l, 9309ff9d l, 0a00ae27 l, 7d079eb1 l, f00f9344 l,
  8708a3d2 l, 1e01f268 l, 6906c2fe l, f762575d l, 806567cb l,
  196c3671 l, 6e6b06e7 l, fed41b76 l, 89d32be0 l, 10da7a5a l,
  67dd4acc l, f9b9df6f l, 8ebeeff9 l, 17b7be43 l, 60b08ed5 l,
  d6d6a3e8 l, a1d1937e l, 38d8c2c4 l, 4fdff252 l, d1bb67f1 l,
  a6bc5767 l, 3fb506dd l, 48b2364b l, d80d2bda l, af0a1b4c l,
  36034af6 l, 41047a60 l, df60efc3 l, a867df55 l, 316e8eef l,
  4669be79 l, cb61b38c l, bc66831a l, 256fd2a0 l, 5268e236 l,
  cc0c7795 l, bb0b4703 l, 220216b9 l, 5505262f l, c5ba3bbe l,
  b2bd0b28 l, 2bb45a92 l, 5cb36a04 l, c2d7ffa7 l, b5d0cf31 l,
  2cd99e8b l, 5bdeae1d l, 9b64c2b0 l, ec63f226 l, 756aa39c l,
  026d930a l, 9c0906a9 l, eb0e363f l, 72076785 l, 05005713 l,
  95bf4a82 l, e2b87a14 l, 7bb12bae l, 0cb61b38 l, 92d28e9b l,
  e5d5be0d l, 7cdcefb7 l, 0bdbdf21 l, 86d3d2d4 l, f1d4e242 l,
  68ddb3f8 l, 1fda836e l, 81be16cd l, f6b9265b l, 6fb077e1 l,
  18b74777 l, 88085ae6 l, ff0f6a70 l, 66063bca l, 11010b5c l,
  8f659eff l, f862ae69 l, 616bffd3 l, 166ccf45 l, a00ae278 l,
  d70dd2ee l, 4e048354 l, 3903b3c2 l, a7672661 l, d06016f7 l,
  4969474d l, 3e6e77db l, aed16a4a l, d9d65adc l, 40df0b66 l,
  37d83bf0 l, a9bcae53 l, debb9ec5 l, 47b2cf7f l, 30b5ffe9 l,
  bdbdf21c l, cabac28a l, 53b39330 l, 24b4a3a6 l, bad03605 l,
  cdd70693 l, 54de5729 l, 23d967bf l, b3667a2e l, c4614ab8 l,
  5d681b02 l, 2a6f2b94 l, b40bbe37 l, c30c8ea1 l, 5a05df1b l,
  2d02ef8d l,

[ifndef] ($crc)
[ifdef] notdef
: crcstep  ( crc b -- crc' )
   over xor h# ff and  crctab swap la+ l@  swap 8 rshift xor
;
[then]

: ($crc)  ( crc table adr len -- crc' )
   2swap  swap  2swap              ( table crc  adr len )
   bounds ?do                      ( table crc )
      2dup                         ( table crc table crc )
      i c@  xor  h# ff and         ( table crc table index )
      la+ l@                       ( table crc l )
      swap 8 rshift  xor           ( table crc' )
   loop                            ( table crc )
   nip                             ( crc' )
;
[then]

: $crc  ( adr len -- crc )  h# ffffffff crctab  2swap  ($crc)  invert n->l  ;
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
