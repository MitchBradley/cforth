\ Bit-banding maps a complete word of memory onto a single bit in the bit-band
\ region. For example, writing to one of the alias words sets or clears the
\ corresponding bit in the bit-band region. This enables every individual bit in
\ the bit-banding region to be directly accessible from a word-aligned address
\ using a single LDR instruction. It also enables individual bits to be toggled
\ without performing a read-modify-write sequence of instructions.

1 #28 shift 1- constant BITBAND.BASEMASK_               \ covers the offset
BITBAND.BASEMASK_ invert constant BITBAND.BASEMASK      \ covers only the page
\ bit_word_offset is the position of the target bit in the bit-band memory region.
$2000000 constant BITBAND.OFFSET

: BITBAND ( addr bit -- aliasaddress ) 
    $4 * \ offest caused by the bit
    swap
    dup  \ we need to split the addr is two parts
	\ get the bit_band_base - the starting address of the alias region. 
    BITBAND.BASEMASK and
    swap
	\ get the byte_offset - the number of the byte in the bit-band region that
	\ contains the targeted bit.
    BITBAND.BASEMASK_
    and $20 *
    + +
	\ add the bit_word_offset - the position of the target bit in the bit-band
	\ memory region.
    BITBAND.OFFSET +
;

." Test for SFR " $4001140C 5 BITBAND $42228194 = if ." Passed" else ." Failed" then CR
." Test for RAM " $200FFFFC #24 BITBAND $23ffffe0 = if ." Passed" else ." Failed" then CR
