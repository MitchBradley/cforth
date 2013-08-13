\ Loads the file if the filename is not defined in the dictionary
: requires  \ filename  ( -- )
   $defined  if  drop  else  included  then
;
\ Loads the file if wordname is not already defined
: needs  \ wordname filename  ( -- )
   $defined  if                   ( xt )
      drop parse-word 2drop
   else                           ( adr len )
      2drop parse-word included
   then
; immediate
\ Interprets the line if wordname in not already defined
: \needs  \ wordname rest-of-line  ( -- )
   $defined   if  drop [compile] \   else  2drop  then
; immediate
