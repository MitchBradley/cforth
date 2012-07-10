: .commit  ( -- )
   'version cscount 
   dup d# 8 >  if
      drop 8 type  ." ..."
   else 
      type
   then
;
: .built  ( -- )  
;
: banner  ( -- )
   cr ." CForth built " 'build-date cscount type
   ."  from commit " .commit
   cr
;
