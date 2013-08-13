\ Simple data structures

: struct  ( -- initial-offset )  0  ;

: field  \ name  ( offset size -- offset' )
   create  over ,  +   ( offset' )
   does>  @ +
;
