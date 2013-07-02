: ad-convert  ( pin port -- value )
   if  h# e0060000  else  h# e0034000  then  ( pin cr-adr )
   1 rot lshift  h# 20ff00 or                ( cr-adr mask )
   2dup swap l!                              ( cr-adr mask )
   h# 01000000 or over l!                    ( cr-adr )
   4 +                                       ( dr-adr )

   0  begin  drop  dup l@  dup 0<  until     ( dr-adr value )

   nip  6 rshift  h# 3ff and                 ( value )
;
