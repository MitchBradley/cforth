\ Bit-banding maps a complete word of memory onto a single bit in the bit-band
\ region. For example, writing to one of the alias words sets or clears the
\ corresponding bit in the bit-band region. This enables every individual bit in
\ the bit-banding region to be directly accessible from a word-aligned address
\ using a single LDR instruction. It also enables individual bits to be toggled
\ without performing a read-modify-write sequence of instructions.

\ Usage:
\   variable x
\   0 x !
\   x 0 BITBAND 1 swap c! x @ .

: bitband  ( bit adr -- aliasadr )
   dup 5 lshift            ( bit adr byte-offset )  \ Spread low part of address; high bits will be shifted out
   swap $f000.0000 and or  ( bit adr' )             \ Keep high nibble of address
   $0200.0000 or           ( bit adr' )             \ Offset to bitband alias space
   swap la+                ( aliasadr )             \ Merge bit number as 32-bit word offset
;

." Test for SFR "   5 $4001140C BITBAND $42228194 = if ." Passed" else ." Failed" then CR
." Test for RAM " #24 $200FFFFC BITBAND $23ffffe0 = if ." Passed" else ." Failed" then CR
