fl ../../cforth/printf.fth

\ Since this build includes and relies on floating point,
\ we set the initial number base to decimal so floating
\ point constants do the right thing.
decimal

" app.dic" save
