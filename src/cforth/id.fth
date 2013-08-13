\ For SCCS id's.  Use:
\ id filename.f 1.1 88/01/07
\
\ Then   filename.f ".   will give you the id info.

forth definitions
: id  \ rest of line  ( -- string )
   create
   delimiter @ newline =  if   0 ,  else  0 parse ",  then
;
