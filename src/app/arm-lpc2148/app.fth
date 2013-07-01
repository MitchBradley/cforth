\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth


\ Replace 'quit' to make CForth auto-run some application code
\ instead of just going interactive.
: app  ." CForth" cr hex quit  ;

\ " ../objs/tester" $chdir drop

" app.dic" save
