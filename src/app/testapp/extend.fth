\ Forth interfaces to C extension routines

decimal

also ccalls
 0 ccall: cindex@      { -- i.byte }
 1 ccall: cindex!      { i.byte -- }
 2 ccall: cdata@       { -- i.byte }
 3 ccall: cdata!       { i.byte -- }

 4 ccall: serial-flash { a.flash-adr -- i.length }
 5 ccall: erase-flash  { a.flash-adr i.len -- i.length }
 6 ccall: write-flash  { a.buf a.flash-adr i.len -- i.length }

 7 ccall: rem-mayget   { a.buf -- i.gotone? }
 8 ccall: rem-key      { -- i.char }
 9 ccall: rem-emit     { i.char -- }
10 ccall: rem-init     { -- }

11 ccall: rcv-key?     { -- i.numavail }
12 ccall: rcv-key      { -- i.char }
13 ccall: rcv-emit     { i.char -- }
14 ccall: rcv-init     { -- }

15 ccall: dbgu-mayget  { a.buf -- i.gotone? }
16 ccall: dbgu-key     { -- i.char }
17 ccall: dbgu-emit    { i.char -- }

18 ccall: xtoa         { i.digits i.num -- a.cstr }

19 ccall: setup-tones  { a.bins a.nbins -- }
20 ccall: tones-next   { -- i.sample }


21 ccall: shift-lsbs   { i.bits i.nbits i.last i.first -- i.bits }
22 ccall: shift-33msbs { i.bits i.first -- i.bits }
23 ccall: spi-byte     { i.write -- i.read }
24 ccall: psoc-poll    { -- }
25 ccall: capture      { i.delay i.match i.mask i.len a.adr -- }
26 ccall: vectors      { i.num a.adr -- }

previous
