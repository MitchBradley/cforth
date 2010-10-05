\ Forth interfaces to C extension routines

decimal

also ccalls
  0 ccall: pc@      { i.port -- i.byte }
  1 ccall: pc!      { i.byte i.port -- }
  2 ccall: pw@      { i.port -- i.word }
  3 ccall: pw!      { i.word i.port -- }
  4 ccall: pl@      { i.port -- i.long }
  5 ccall: pl!      { i.long i.port -- }

  6 ccall: config-b@   { i.cfgadr -- i.byte }
  7 ccall: config-b!   { i.byte i.cfgadr -- }
  8 ccall: config-w@   { i.cfgadr -- i.word }
  9 ccall: config-w!   { i.word i.cfgadr -- }
 10 ccall: config-l@   { i.cfgadr -- i.word }
 11 ccall: config-l!   { i.long i.cfgadr -- }
previous
