\ Null application load file
\ Copy this to your application directory and amend it

\ Fload some source files
fl ../../lib/dl.fth

\ " ../../objs/tester" $chdir drop

: .commit  ( -- )  'version cscount type  ;

: .built  ( -- )  'build-date cscount type  ;

: banner  ( -- )
   ." CForth built " .built
   ."  from " .commit
   cr
;

: app  ( -- )
   banner  hex
   quit
;

" app.dic" save
