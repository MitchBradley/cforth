\ Interface to MCP23017 I2C GPIO expander

\needs read-i2c  fload i2c.fth

$20 value mcp-i2c-slave
: select-lcd  ( 0..3 -- )  $20 + to mcp-i2c-slave  ;

4 buffer: mcp-buf
: mcp-reg-setup  ( reg# -- )  mcp-i2c-slave set-i2c-slave  mcp-buf c!  ;
: mcp-w@  ( reg# -- w )
   mcp-reg-setup
   mcp-buf 1 write-i2c
   mcp-buf 2 read-i2c  mcp-buf le-w@
;
: mcp-w!  ( w reg# -- )
   mcp-reg-setup       ( w )
   mcp-buf 1+ le-w!    ( )
   mcp-buf 3 write-i2c
;

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
