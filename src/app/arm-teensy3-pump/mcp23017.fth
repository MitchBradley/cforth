\ Interface to MCP23017 I2C GPIO expander

$20 value mcp-i2c-slave
: select-lcd  ( 0..3 -- )  $20 + to mcp-i2c-slave  ;

: mcp-w@  ( reg# -- w )  mcp-i2c-slave false i2c-le-w@  ;
: mcp-w!  ( w reg# -- )  mcp-i2c-slave i2c-le-w!  ;

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
