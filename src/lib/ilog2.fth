\ purpose: Base-2 logarithm with fractional result
\ copyright: Copyright 1999 FirmWorks  All Rights Reserved

: ilog2  ( i -- log.fraction log.integer )
   dup log2 >r                ( i r: log.int )

   \ Having determined the integer portion of the result,
   \ we shift the number left so the MSB is one.  This is equivalent
   \ to dividing the number by 2**int, with an implied scale factor
   \ of 2**(BitsPerCell-1).  The result represents a number in the
   \ range [1..2)   Assuming 32-bit arithmetic, h#8000.0000 represents 1
   \ and h#ffff.ffff represents 2-epsilon.

   bits/cell r@ - 1- lshift   ( i' r: log.int )

   \ Compute the bits of the fractional result
   0  swap  bits/cell 0  do   ( log i' r: log.int )

      \ Square the working number, representing the result as a double
      \ number.  The implied scale factor is now 2**(2*BitsPerCell-2)
      \ and the represented number is in the range [1..4).
      dup um*                 ( log d.i' )

      \ If the high bit of the the double number is set, the squared
      \ value is >= 2.
      dup 0<  if              ( d.i' log' )

         \ The square is >=2, so record a 1 bit in the logarithm value.
         rot 2* 1+ -rot       ( log' d.i )

         \ Scale the working number back to a single number; we are
         \ effectively dividing it by two to get it back in the range
         \ [1..2), but because of the way we are representing things,
         \ it just happens to be in the right place already.
         nip                  ( log' i' )
      else                    ( d.i' log' )
         \ The square is <2, so record a 0 bit in the logarithm value.
         rot 2* -rot          ( log' d.i' )

         \ Scale the working number back to a single number and shift
         \ it left one bit to put it back in the range [1..2).
         \ I know this is confusing; you will just have to trust me
         \ that it works.
         1 lshift  swap 0<  if  1+  then   ( log i' )
      then                    ( log i )
   loop                       ( log i )
   drop r>                    ( log.fraction log.int )
;
