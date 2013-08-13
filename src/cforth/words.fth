\ Display the WORDS in the Context Vocabulary
only forth also definitions
: words   (s -- )
   0 lmargin !  td 64 rmargin !  td 14 tabstops !
   ??cr
   context token@ follow
   begin   another?  while   ( acf )
     >name$                  ( adr len )
     dup h# 1f and  .tab     ( adr len )
     type space
     exit? if  exit  then
   repeat
;

only definitions forth also
: words    words ;
only forth also definitions
