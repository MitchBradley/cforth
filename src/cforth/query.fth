\ Obsolescent word QUERY

: query  ( -- )
   0 set-input
   tib /tib  accept  dup #tib !  tib swap set-source  0 >in !
;
