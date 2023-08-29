\ Interface to MCP23017 I2C GPIO expander

$20 value mcp-i2c-slave
: select-lcd  ( 0..3 -- )  $20 + to mcp-i2c-slave  ;

4 buffer: mcp-buf
: mcp-w@  ( reg# -- w )  mcp-i2c-slave false i2c-le-w@  ;
: mcp-w!  ( w reg# -- )  mcp-i2c-slave i2c-le-w! drop  ;

: mcp-set  ( gpio# reg# -- )
   >r  1 swap lshift   r@ mcp-w@  or  r> mcp-w!
;
: mcp-clr  ( gpio# reg# -- )
   >r  1 swap lshift invert  r@ mcp-w@  and  r> mcp-w!
;
: mcp-gpio-is-output  ( gpio# -- )  0 mcp-clr  ;
: mcp-gpio-is-input  ( gpio# -- )  0 mcp-set  ;
: mcp-gpio-pullup-off  ( gpio# -- )  $0c mcp-clr  ;
: mcp-gpio-pullup-on  ( gpio# -- )  $0c mcp-set  ;
: mcp-gpio-clr  ( gpio# -- )  $12 mcp-clr  ;
: mcp-gpio-set  ( gpio# -- )  $12 mcp-set  ;
: mcp-gpio-pin@  ( gpio# -- flag )  1 swap lshift  $12 mcp-w@  and  0<>  ;

: byte-split ( n16 -- high low ) dup #8 rshift swap $FF and ;
: .mcp-pin   ( gpio# -- ) mcp-gpio-pin@ . ;
: .mcp-pins  ( -- ) #16 0  do  i cr dup . .mcp-pin  loop ;
: set-inputs-pullup   ( n -- )
   0  do  i dup mcp-gpio-is-input mcp-gpio-pullup-on  loop ;

: mcp-ints@ ( -- ints ) $10 ( INTCAPA) mcp-w@ ;

: .mcp-ints  ( -- ) \  Reads the INTCAPA register AND clears the INT pin
   $07 ( DEFVALB) mcp-w@ ." DEFVALB:" .h
   $06 ( DEFVALA) mcp-w@ ." DEFVALA:" .h
   mcp-ints@ ."   B/A:"   .h ;

: set-interrupts-on-change ( Bits_BBAA -- )
   byte-split $08 ( INTCONA) mcp-w! $09 ( INTCONB) mcp-w!  ;

: clr-mcp-ints ( -- )  \ clears the INT pin and the INTCAPA register
   $10 ( INTCAPA) mcp-w@ drop
   $FFFF set-interrupts-on-change
   0     set-interrupts-on-change
   $10 ( INTCAPA) mcp-w@ drop ;

: init-mcp-ints ( Bits_BBAA -- )
   $40 $0A ( IOCON)  mcp-w!   \ Mirror
   byte-split $04 ( GPINTENA) mcp-w! $05 ( GPINTENB) mcp-w!
   clr-mcp-ints ;
