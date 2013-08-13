\ Comments that span mulitiple lines

\ Turn this variable on to make long comments apply to the keyboard too.
\ This is useful for cutting and pasting bits of code into a Forth
\ system.
variable long-comments  long-comments off
warning @  warning off
: (  \ "comments)"  ( -- )
   begin
      >in @  [char] ) parse       ( >in adr len )
      nip +  >in @  =             ( delimiter-not-found? )
      long-comments @  source-id  -1 0 between  0=  or  and  ( more? )
   while                          ( )
      refill  0=  if  exit  then  ( )
   repeat
; immediate
warning !
