\ gpio registers
h# 400f.f000 constant gpio-base

\ convert port and pin to mask and gpio register
: port.pin>mask.gpio  ( port# pin# -- mask gpio )
   1 swap shift         ( port# mask )
   swap                 ( mask port# )
   h# 40 * gpio-base +  ( mask gpio )
;

\ gpio access
: gpio-set  ( port# pin# -- )  port.pin>mask.gpio  h# 04 +  !  ;
: gpio-clr  ( port# pin# -- )  port.pin>mask.gpio  h# 08 +  !  ;
: gpio-toggle  ( port# pin# -- )  port.pin>mask.gpio  h# 0c +  !  ;
: gpio-pin@  ( port# pin# -- flag  )
   port.pin>mask.gpio   ( mask gpio )
   h# 10 + @ and 0<>    ( flag )
;
: gpio-dir-out  ( port# pin# -- )
   port.pin>mask.gpio   ( mask-to-set gpio )
   dup >r               ( mask-to-set gpio      r: gpio )
   @                    ( mask-to-set mask-now  r: gpio )
   or                   ( mask-new              r: gpio )
   r> h# 14 + !         ( )
;
: gpio-dir-in  ( port# pin# -- )  \ fixme
   port.pin>mask.gpio   ( mask-to-clr gpio )
   dup >r               ( mask-to-clr gpio      r: gpio )
   @                    ( mask-to-clr mask-now  r: gpio )
   swap invert and      ( mask-new              r: gpio )
   r> h# 14 + !         ( )
;
: gpio-out?  ( port# pin# -- out? )
   port.pin>mask.gpio   ( mask gpio )
   h# 14 + @ and 0<>    ( flag )
;
