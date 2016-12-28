: ms  ( ms -- )
   get-msecs +
   begin
      dup get-msecs - 0<
   until
   drop
;

: us  ( us -- )
   get-usecs +
   begin
      dup get-usecs - 0<
   until
   drop
;

0 value timestamp
: t(  get-msecs to timestamp  ;
: )t  get-msecs timestamp - .d ." ms"  ;

: u(  get-usecs to timestamp  ;
: )u  get-usecs timestamp - .d ." us"  ;
