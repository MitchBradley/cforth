\ Configuration "smart-comments".  Define the name for your machine,
\ and comment out the names of the other machines.  Then you can use
\ \? to include or exclude system-dependent lines of code.  For instance,
\ if  vax is defined and sun2.0 is not defined, then
\    \? vax     .( I am a Vax) cr
\    \? sun2.0  .( I am a Sun) cr
\ will print "I am a Vax"

\ : vax ;
\ : sun2.0  ;
\ : sun3.0  ;

\ Comments-out the rest of the line if flag is false.
: ?\  ( flag -- )   0=  if  [compile] \  then  ;  immediate

: \?  \ name  ( -- )
   parse-word $find  dup  if  nip  else  nip nip  then [compile] ?\
; immediate
