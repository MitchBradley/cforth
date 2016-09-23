purpose: PPP MD5 Message-digest routines

\ RSA Data Security, Inc. MD5 Message-Digest Algorithm

\  To form the message digest for a message M
\    (1) Initialize using md5init
\    (2) Call md5update and M	for at least one M
\    (3) Call md5final
\  The message digest is now in md5digest[0...15]

[ifdef] notdef
This file was translated into Forth from md5.h and md5.c in the Linux
source code, which contained the following:

/*
 ***********************************************************************
 ** md5.h -- header file for implementation of MD5                    **
 ** RSA Data Security, Inc. MD5 Message-Digest Algorithm              **
 ** Created: 2/17/90 RLR                                              **
 ** Revised: 12/27/90 SRD,AJ,BSK,JT Reference C version               **
 ** Revised (for MD5): RLR 4/27/91                                    **
 **   -- G modified to have y&~z instead of y&z                       **
 **   -- FF, GG, HH modified to add in last register done             **
 **   -- Access pattern: round 2 works mod 5, round 3 works mod 3     **
 **   -- distinct additive constant for each step                     **
 **   -- round 4 added, working mod 7                                 **
 ***********************************************************************
 */

/*
 ***********************************************************************
 ** Copyright (C) 1990, RSA Data Security, Inc. All rights reserved.  **
 **                                                                   **
 ** License to copy and use this software is granted provided that    **
 ** it is identified as the "RSA Data Security, Inc. MD5 Message-     **
 ** Digest Algorithm" in all material mentioning or referencing this  **
 ** software or this function.                                        **
 **                                                                   **
 ** License is also granted to make and use derivative works          **
 ** provided that such works are identified as "derived from the RSA  **
 ** Data Security, Inc. MD5 Message-Digest Algorithm" in all          **
 ** material mentioning or referencing the derived work.              **
 **                                                                   **
 ** RSA Data Security, Inc. makes no representations concerning       **
 ** either the merchantability of this software or the suitability    **
 ** of this software for any particular purpose.  It is provided "as  **
 ** is" without express or implied warranty of any kind.              **
 **                                                                   **
 ** These notices must be retained in any copies of any part of this  **
 ** documentation and/or software.                                    **
 ***********************************************************************
 */
[then]

\ This code only works right on 32-bit systems

decimal

headers
16 constant /digest
/digest buffer: md5digest	\ contains result after MD5Final call

headerless
64     buffer: md5input		\ input buffer
16 /l* buffer: md5xin		\ transformation input buffer
04 /l* buffer: md5buf		\ scratch buffer

0 value md5count

\ MD5 primitives

\ x y and  x invert z and  or
: md5F   ( x y z -- n )   -rot over and -rot invert and or  ;

\ z x and  z invert y and  or
: md5G   ( x y z -- n )   tuck invert and -rot and or  ;

: md5H   ( x y z -- n )   xor xor  ;

\ x z invert or  y xor
: md5I   ( x y z -- n )   invert rot or xor  ;

: rotate_left   ( x n -- y )   2dup lshift -rot  32 swap - rshift or  ;

\ FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4

: md5FF   ( a b c d x s e -- )
   swap >r + >r				( a b c d )	( r: s x+e )
   rot @ dup >r rot @ rot @ md5F	( a F )		( r: s x+e b@ )
   over @ + r> swap r> +		( a b@ first )	( r: s )
   r> rotate_left + swap !
;
: GG   ( a b c d x s e  - )
   swap >r + >r				( a b c d )	( r: s x+e )
   rot @ dup >r rot @ rot @ md5G	( a F )		( r: s x+e b@ )
   over @ + r> swap r> +		( a b@ first )	( r: s )
   r> rotate_left + swap !
;
: HH   ( a b c d x s e -- )
   swap >r + >r				( a b c d )	( r: s x+e )
   rot @ dup >r rot @ rot @ md5H	( a F )		( r: s x+e b@ )
   over @ + r> swap r> +		( a b@ first )	( r: s )
   r> rotate_left + swap !
;
: II   ( a b c d x s e  - )
   swap >r + >r				( a b c d )	( r: s x+e )
   rot @ dup >r rot @ rot @ md5I	( a F )		( r: s x+e b@ )
   over @ + r> swap r> +		( a b@ first )	( r: s )
   r> rotate_left + swap !
;

: l+!   ( n a -- )   dup l@ rot + swap l!  ;

\ Basic MD5 step. Transforms md5buf based on md5input.
variable md5a
variable md5b
variable md5c
variable md5d
7	constant S11
12	constant S12
17	constant S13
22	constant S14
5	constant S21
9	constant S22
14	constant S23
20	constant S24
4	constant S31
11	constant S32
16	constant S33
23	constant S34
6	constant S41
10	constant S42
15	constant S43
21	constant S44
: Transform   ( buf in -- )
   swap >r
   r@ 0 la+ l@  md5a !
   r@ 1 la+ l@  md5b !
   r@ 2 la+ l@  md5c !
   r@ 3 la+ l@  md5d !
   
   >r
   
   \ Round 1
   md5a md5b md5c md5d r@  0 la+ l@  S11 3614090360 md5FF	\ 1
   md5d md5a md5b md5c r@  1 la+ l@  S12 3905402710 md5FF	\ 2
   md5c md5d md5a md5b r@  2 la+ l@  S13  606105819 md5FF	\ 3
   md5b md5c md5d md5a r@  3 la+ l@  S14 3250441966 md5FF	\ 4
   md5a md5b md5c md5d r@  4 la+ l@  S11 4118548399 md5FF	\ 5
   md5d md5a md5b md5c r@  5 la+ l@  S12 1200080426 md5FF	\ 6
   md5c md5d md5a md5b r@  6 la+ l@  S13 2821735955 md5FF	\ 7
   md5b md5c md5d md5a r@  7 la+ l@  S14 4249261313 md5FF	\ 8
   md5a md5b md5c md5d r@  8 la+ l@  S11 1770035416 md5FF	\ 9
   md5d md5a md5b md5c r@  9 la+ l@  S12 2336552879 md5FF	\ 10
   md5c md5d md5a md5b r@ 10 la+ l@  S13 4294925233 md5FF	\ 11
   md5b md5c md5d md5a r@ 11 la+ l@  S14 2304563134 md5FF	\ 12
   md5a md5b md5c md5d r@ 12 la+ l@  S11 1804603682 md5FF	\ 13
   md5d md5a md5b md5c r@ 13 la+ l@  S12 4254626195 md5FF	\ 14
   md5c md5d md5a md5b r@ 14 la+ l@  S13 2792965006 md5FF	\ 15
   md5b md5c md5d md5a r@ 15 la+ l@  S14 1236535329 md5FF	\ 16
		     
  \ Round 2	     
   md5a md5b md5c md5d r@  1 la+ l@  S21 4129170786 GG	\ 17
   md5d md5a md5b md5c r@  6 la+ l@  S22 3225465664 GG	\ 18
   md5c md5d md5a md5b r@ 11 la+ l@  S23  643717713 GG	\ 19
   md5b md5c md5d md5a r@  0 la+ l@  S24 3921069994 GG	\ 20
   md5a md5b md5c md5d r@  5 la+ l@  S21 3593408605 GG	\ 21
   md5d md5a md5b md5c r@ 10 la+ l@  S22   38016083 GG	\ 22
   md5c md5d md5a md5b r@ 15 la+ l@  S23 3634488961 GG	\ 23
   md5b md5c md5d md5a r@  4 la+ l@  S24 3889429448 GG	\ 24
   md5a md5b md5c md5d r@  9 la+ l@  S21  568446438 GG	\ 25
   md5d md5a md5b md5c r@ 14 la+ l@  S22 3275163606 GG	\ 26
   md5c md5d md5a md5b r@  3 la+ l@  S23 4107603335 GG	\ 27
   md5b md5c md5d md5a r@  8 la+ l@  S24 1163531501 GG	\ 28
   md5a md5b md5c md5d r@ 13 la+ l@  S21 2850285829 GG	\ 29
   md5d md5a md5b md5c r@  2 la+ l@  S22 4243563512 GG	\ 30
   md5c md5d md5a md5b r@  7 la+ l@  S23 1735328473 GG	\ 31
   md5b md5c md5d md5a r@ 12 la+ l@  S24 2368359562 GG	\ 32
		     
  \ Round 3	     
   md5a md5b md5c md5d r@  5 la+ l@  S31 4294588738 HH	\ 33
   md5d md5a md5b md5c r@  8 la+ l@  S32 2272392833 HH	\ 34
   md5c md5d md5a md5b r@ 11 la+ l@  S33 1839030562 HH	\ 35
   md5b md5c md5d md5a r@ 14 la+ l@  S34 4259657740 HH	\ 36
   md5a md5b md5c md5d r@  1 la+ l@  S31 2763975236 HH	\ 37
   md5d md5a md5b md5c r@  4 la+ l@  S32 1272893353 HH	\ 38
   md5c md5d md5a md5b r@  7 la+ l@  S33 4139469664 HH	\ 39
   md5b md5c md5d md5a r@ 10 la+ l@  S34 3200236656 HH	\ 40
   md5a md5b md5c md5d r@ 13 la+ l@  S31  681279174 HH	\ 41
   md5d md5a md5b md5c r@  0 la+ l@  S32 3936430074 HH	\ 42
   md5c md5d md5a md5b r@  3 la+ l@  S33 3572445317 HH	\ 43
   md5b md5c md5d md5a r@  6 la+ l@  S34   76029189 HH	\ 44
   md5a md5b md5c md5d r@  9 la+ l@  S31 3654602809 HH	\ 45
   md5d md5a md5b md5c r@ 12 la+ l@  S32 3873151461 HH	\ 46
   md5c md5d md5a md5b r@ 15 la+ l@  S33  530742520 HH	\ 47
   md5b md5c md5d md5a r@  2 la+ l@  S34 3299628645 HH	\ 48
		     
  \ Round 4	     
   md5a md5b md5c md5d r@  0 la+ l@  S41 4096336452 II	\ 49
   md5d md5a md5b md5c r@  7 la+ l@  S42 1126891415 II	\ 50
   md5c md5d md5a md5b r@ 14 la+ l@  S43 2878612391 II	\ 51
   md5b md5c md5d md5a r@  5 la+ l@  S44 4237533241 II	\ 52
   md5a md5b md5c md5d r@ 12 la+ l@  S41 1700485571 II	\ 53
   md5d md5a md5b md5c r@  3 la+ l@  S42 2399980690 II	\ 54
   md5c md5d md5a md5b r@ 10 la+ l@  S43 4293915773 II	\ 55
   md5b md5c md5d md5a r@  1 la+ l@  S44 2240044497 II	\ 56
   md5a md5b md5c md5d r@  8 la+ l@  S41 1873313359 II	\ 57
   md5d md5a md5b md5c r@ 15 la+ l@  S42 4264355552 II	\ 58
   md5c md5d md5a md5b r@  6 la+ l@  S43 2734768916 II	\ 59
   md5b md5c md5d md5a r@ 13 la+ l@  S44 1309151649 II	\ 60
   md5a md5b md5c md5d r@  4 la+ l@  S41 4149444226 II	\ 61
   md5d md5a md5b md5c r@ 11 la+ l@  S42 3174756917 II	\ 62
   md5c md5d md5a md5b r@  2 la+ l@  S43  718787259 II	\ 63
   md5b md5c md5d md5a r@  9 la+ l@  S44 3951481745 II	\ 64
   
   r> drop
   
   md5a @  r@ 0 la+ l+!
   md5b @  r@ 1 la+ l+!
   md5c @  r@ 2 la+ l+!
   md5d @  r> 3 la+ l+!
;

headers
\ The routine md5init initializes the message-digest context
: md5init   ( -- )
   0 to md5count
   
   \ Load magic initialization constants.
   md5buf
   h# 67452301 over l!  la1+
   h# efcdab89 over l!  la1+
   h# 98badcfe over l!  la1+
   h# 10325476 swap l!					( )
;

headerless
: md5-addchar   ( mdi char -- mdi' )
   \ add new character to buffer, increment mdi
   over md5input + c!  1+				( mdi )

   \ transform if necessary
   dup h# 40 = if
      drop						( )
      16 0 do
	 md5input i la+ le-l@  md5xin i la+ l!
      loop						  
      md5buf  md5xin  Transform
      0							( mdi )
   then
;

headers
\ The routine md5update updates the message-digest context to
\  account for the presence of each of the characters inBuf[0..inLen-1]
\  in the message whose digest is being computed.
: md5update   ( inBuf inLen -- )
   \ compute number of bytes mod 64
   md5count h# 3f and				( inBuf inLen mdi )

   \ update number of bytes
   over  md5count + to md5count			( inBuf inLen mdi )
   
   -rot						( mdi inBuf inLen )
   bounds ?do  i c@ md5-addchar  loop		( mdi )
   drop
;

\ The routine md5final terminates the message-digest computation and
\   ends with the desired message digest in md5digest[0...15].
: md5final   ( -- )
   \ pad out length to 56 mod 64
   md5count h# 3f and					( mdi )
   dup 56 < if  56  else  120  then  over -		( mdi padlen )
   dup if
      swap h# 80 md5-addchar				( padlen mdi )
      swap 1- 0 ?do   0 md5-addchar   loop  drop
   else
      2drop
   then
   
   \ transfer 56 bytes to transformation input buffer
   14 0 do
      md5input i la+ le-l@  md5xin i la+ l!
   loop
   
   \ append original length in bits
   md5count 3 lshift  md5xin 14 la+ l!			( bytes )
   0  md5xin 15 la+ l!					( )
   
   \ and transform
   md5buf  md5xin  Transform

   \ copy buffer to digest
   4 0 do						( )
      md5buf i la+ l@  md5digest i la+ le-l!
   loop
;
: md5end  ( -- digest$ )  MD5Final md5digest /digest  ;

: $md5digest1  ( $1 -- digest$ )
   MD5Init	( a n )
   MD5Update	( )
   md5end       ( digest$ )
;
: $md5digest2  ( $1 $2 -- digest$ )
   MD5Init			( $1 $2 )
   2swap MD5Update  MD5Update	( )
   md5end                       ( digest$ )
;
