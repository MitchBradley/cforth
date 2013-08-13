\ Temporary hex, and temporary decimal.  "h#" interprets the next word
\ as though the base were hex, regardless of what the base happens to be.
\ "d#" interprets the next word as though the base were decimal.
\ "o#" interprets the next word as though the base were octal.
\ "b#" interprets the next word as though the base were binary.

decimal
: #:  \ name  ( base -- )  \ Define a temporary-numeric-mode word
   create , immediate
   does>  base @ >r  @ base !  parse-word compile-word  r> base !
;

16 #: h#	\ Hex number
10 #: d#	\ Decimal number
 8 #: o#	\ Octal number
 2 #: b#	\ Binary number

\ The old names; use h# and d# instead
16 #: th
10 #: td
