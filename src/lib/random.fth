\ Pseudo-random number generator using linear congruence

variable rn            \ Random number

: random  ( -- n )
   rn @  d# 1103515245 *  d# 12345 +   h# 7fffffff and  dup rn !
;
