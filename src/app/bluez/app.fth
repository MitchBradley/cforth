fl ../../cforth/printf.fth

#100 buffer: abort-msg
: sprintf-abort  ( ? pattern$ -- )
   sprintf abort-msg pack  'abort$ !
   -2 throw
;
[ifndef] cscount
: cscount  ( adr -- adr len )
   dup                               ( adr cur-adr )
   begin  dup c@  while  1+  repeat  ( adr end-adr )
   over -                            ( adr len )
;
[then]
: ?posix-err  ( n -- )
   0<  if
      \ EALREADY is not really a problem
      errno  dup #114 =  if  drop exit  then
      dup >r strerror cscount r>
      " Syscall error %d: %s" sprintf-abort
   then
;

/l wa1+ wa1+ buffer: poll-fd  \ n.fid w.events w.revents
: do-poll  ( ms fid mask -- nfds )
   swap poll-fd !          ( ms mask )
   poll-fd la1+ w!         ( ms )
   0 poll-fd la1+ wa1+ w!  ( ms )   \ returned events
   1 poll-fd poll          ( nfds ) \ 1 is nfds
;
: do-poll-in  ( ms fid -- nfds )  1 do-poll  ;
: do-poll-out  ( ms fid -- nfds )  4 do-poll  ;

: timed-read  ( adr len fid ms -- actual | -1 )
   over do-poll-in 1 =  if  ( adr len fid )
      h-read-file           ( actual )
   else                     ( adr len fid )
      3drop -1              ( -1 )
   then                     ( actual | -1 )
;

0 value pkt
0 value pkt2
#100 buffer: packet
: pkt{  ( -- )  packet to pkt  ;
: }pkt  ( -- adr len )  packet  pkt over -  ;
: pkt2{  ( -- )  pkt to pkt2  ;
: }pkt2  ( -- adr len )  pkt2  pkt over -  ;
: +pkt  ( n -- adr )  pkt  tuck + to pkt  ;
: pkt-b,  ( b -- )  1 +pkt c!  ;
: pkt-w,  ( w -- )  /w +pkt w!  ;
: pkt-l,  ( l -- )  /l +pkt l!  ;
: pkt-$,  ( adr len -- )  dup +pkt swap move  ;

fl bluetooth.fth
fl nod.fth
fl farfetch.fth
fl ncontrol-tags.fth

" app.dic" save
