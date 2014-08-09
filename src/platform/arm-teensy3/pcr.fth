\ ports, each with 32 pins
h# 0 constant port-a#
h# 1 constant port-b#
h# 2 constant port-c#
h# 3 constant port-d#
h# 4 constant port-e#

\ pin control registers
h# 4004.9000 constant pcr-base

\ size of a port's pin control registers
h# 1000 constant /pcr-port

\ pin control register (per port and pin)
: port.pin>pcr  ( port# pin# -- pcr )  4 *  swap  /pcr-port *  pcr-base +  +  ;

\ global pin control register (per port)
: port>gpcr  ( port# -- gpcr.d' )  /pcr-port *  pcr-base +  h# 80  +  ;

\ pin control register bits
: +af1  h# 0000.0100 or  ;  \ mux, pin mux control, alternative 1
: +af2  h# 0000.0200 or  ;  \ mux, pin mux control, alternative 2
: +dse  h# 0000.0040 or  ;  \ dse, drive strength enable, high
: +ode  h# 0000.0020 or  ;  \ ode, open drain enable, enabled

\ pin control register access
: pcr!  ( mask port# pin# -- )  port.pin>pcr  !  ;
: pcr@  ( port# pin# -- mask )  port.pin>pcr  @  ;
