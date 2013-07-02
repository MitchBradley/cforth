\ Simple print routine, useful for loading early in the sequence before
\ the rest of the stuff needed for the <# # #> version has been loaded.
hex
create digits
   char 0 c,  char 1 c,  char 2 c,  char 3 c,  
   char 4 c,  char 5 c,  char 6 c,  char 7 c,  
   char 8 c,  char 9 c,  char a c,  char b c,  
   char c c,  char d c,  char e c,  char f c,  

: space  bl emit  ;
: spaces  0  ?do  space  loop  ;
: u.r   ( n #digits -- )
   0 >r
   swap
   begin  ( #digits rem )
      swap 1 - swap
      0 base @ um/mod  ( #digits rem quot )
      swap  digits + c@ >r
   ?dup 0= until
   ( #digits )
   0 max spaces
   begin  r> ?dup  while  emit  repeat
;
: . 0 u.r  space ;
: bounds  ( start len -- end start )  over + swap  ;
: ldump  ( adr len -- )
   bounds  ?do
      i 6 u.r
      8 cells  i over bounds ?do  i @ 9 u.r  cell +loop  cr
   +loop
;
: <=  2dup < -rot  =  or  ;
: >=  2dup > -rot  =  or  ;
: between  ( n low high -- flag )  rot tuck >=  -rot <=  and  ;
: printable?  ( n -- flag )  bl 7e between  ;
: dump  ( adr len -- )
   bounds  ?do
      i 6 u.r
      4 spaces
      10  i over bounds
      2dup  ?do  i @ 9 u.r  cell +loop
      6 spaces
      ?do
         i c@  dup printable?  0= if  drop [char] .  then emit
      loop
      cr
   +loop
;
: -dump  ( endadr len -- )  tuck - swap dump ;
