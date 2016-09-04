\ "Frame buffer" driver with a factoring similar to OFW's "termemu" package

0 value column#
0 value line#
0 value #columns
0 value #lines
1 value #scroll-lines

defer draw-character  ( char -- )
defer delete-characters  ( #chars -- )
defer delete-lines  ( #lines -- )

: kill-1line  ( -- )  #columns column# -  delete-characters  ;
: set-line  ( line# -- )  0 max  #lines 1- min  to line#  ;
: set-column  ( -- column# -- )  0 max  #columns  1- min  to column#  ;
: +column  ( delta-columns -- )  column# +   set-column  ;
: +line  ( delta-lines -- )  line# +  set-line  ;

: do-newline  ( adr len -- adr len )
   relax      ( adr len )  \ Give the system a chance to run on every newline
   line#  #lines 1-  <  if
      \ We're not at the bottom of the screen, so we don't need to scroll
      line# 1+ set-line  ( adr len )

      \ Clear next line if we're in wrap mode
      #scroll-lines 0=  if   kill-1line   then
   else  \ We're at the bottom of the screen, so we have to scroll

      \ In wrap mode, we just go to the top of the screen
      #scroll-lines 0=  if  0 set-line  kill-1line  exit  then

      #scroll-lines                        ( adr len #scroll-lines )

      #lines min                           ( adr len #lines-to-scroll )
      line#                                ( adr len #lines line# )
      0 set-line   swap dup delete-lines   ( adr len line# #lines-to-scroll )
      - 1+  set-line                       ( adr len )
   then
;

: fb-emit  ( c -- )
   dup carret =    if  drop  0 to column#  exit  then
   dup linefeed =  if  drop  do-newline  exit  then
   draw-character
   column# #columns 1- u<  if  1 +column  else  0 set-column   do-newline then
;
: fb-type  ( adr len -- )  bounds  ?do  i c@ fb-emit  loop  ;
: fb-cr  ( -- )  " "r"n" fb-type  ;

: fb-at-xy  ( column# line# -- )  set-line  set-column  ;
