: ascii  \ name  ( -- char )
   state @  if  postpone [char]  else  char  then
; immediate

256 buffer: "temp

create nullstring 0 ,

: c"  \ string"  ( -- pstr )
   state @  if
      postpone ("s)  ,"
   else
      [char] " parse  "temp pack
   then
; immediate

: ""  \ name  ( -- pstr )
   state @  if
      postpone ("s)  parse-word  ",
   else
      parse-word  "temp pack
   then
; immediate
: ["]  \ name  ( -- pstr )  \ For backwards compatibility; obsolete (use p" )
   postpone ("s)    ,"
;   immediate
: [""]  \ name  ( -- pstr ) \ For backwards compatibility; obsolete (use "" )
   postpone ("s)  parse-word ",
; immediate
alias p" c"

: ?enough  ( n -- )  depth >=  abort" Not enough Parameters"  ;
