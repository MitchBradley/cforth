h# d value eol

warning @ warning off
\ This lets us handle files with CR-LF line ends
: \  eol parse 2drop ; immediate
warning !

: load-base  here 5000 +  ;
: dx  ( -- adr len )
   load-base
   begin  key dup control d  <>  while  over c!  1+  repeat  ( adr 4 )
   drop load-base tuck -
;
: dl  dx evaluate ;
