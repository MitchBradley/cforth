\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

fl ../../cforth/printf.fth

: .commit  ( -- )  'version cscount type  ;

: .built  ( -- )  'build-date cscount type  ;

: banner  ( -- )
   cr ." CForth built " .built
   ."  from " .commit
   cr
;

\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  banner  hex  quit  ;

alias id: \

\ Open Firmware stuff; omit if you don't need it
fl ${CBP}/ofw/loadofw.fth      \ Mostly platform-independent
fl ofw-rootnode.fth \ ESP8266-specific

" app.dic" save
