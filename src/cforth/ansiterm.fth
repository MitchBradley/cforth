purpose: Terminal control for ANSI terminals

headerless
: .esc[        ( -- )     control [ (emit  [char] [ (emit  ;
: .esc[x       ( c -- )   .esc[ (emit  ;
: put-n        ( n -- )   push-decimal  (.) (type  pop-base  ;
: .esc[nx      ( n c -- n )  .esc[ over put-n (emit  ;
headers

: reset-terminal  ( -- )     control [ (emit  [char] c (emit  ;
alias rt reset-terminal

: left         ( -- )     [char] D .esc[x  -1 #out  +!  ;
: right        ( -- )     [char] C .esc[x   1 #out  +!  ;
: up           ( -- )     [char] A .esc[x  -1 #line +!  ;
: down         ( -- )     [char] B .esc[x   1 #line +!  ;
: insert-char  ( c -- )   [char] @ .esc[x  (emit ;
: delete-char  ( -- )     [char] P .esc[x  ;
: kill-line    ( -- )     [char] K .esc[x  ;
: kill-screen  ( -- )     [char] J .esc[x  ;
: insert-line  ( -- )     [char] L .esc[x  ;
: delete-line  ( -- )     [char] M .esc[x  ;
: inverse-video ( -- )    [char] 7 .esc[x  [char] m (emit  ;

: lefts        ( n -- )   [char] D .esc[nx  negate #out  +!  ;
: rights       ( n -- )   [char] C .esc[nx         #out  +!  ;
: ups          ( n -- )   [char] A .esc[nx  negate #line +!  ;
: downs        ( n -- )   [char] B .esc[nx         #line +!  ;

\ Cancel all character attributes - boldness, underline, reverse video, etc.
: cancel       ( -- )     [char] m .esc[x  ;

\ Cancel inverse video.  This sequence is not universally supported.
: not-dark     ( -- )     [char] 2 .esc[x  [char] 7 (emit  [char] m (emit  ;

defer light  ' cancel is light
defer dark   ' inverse-video is dark

: at-xy  ( col row -- )
    2dup #line !  #out !
    .esc[   1+ put-n  [char] ; (emit  1+ put-n  [char] H (emit
;
: page         ( -- )  0 0 at-xy  kill-screen  ;

true value ansi-colors?

headerless
: color:  ( adr len "name" -- )
   create ",
   does> ansi-colors? if  .esc[  count (type  [char] m (emit  else  drop  then
;
headers
" 0"    color: default-colors
" 1"    color: bright
" 2"    color: dim
" 4"	color: underline
" 30"   color: black-letters
" 31"   color: red-letters
" 32"   color: green-letters
" 33"   color: yellow-letters
" 34"   color: blue-letters
" 35"   color: magenta-letters
" 36"   color: cyan-letters
" 37"   color: white-letters
" 40"   color: black-screen
" 41"   color: red-screen
" 42"   color: green-screen
" 43"   color: yellow-screen
" 44"   color: blue-screen
" 45"   color: magenta-screen
" 46"   color: cyan-screen
" 47"   color: white-screen
