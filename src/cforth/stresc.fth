\ Literal strings supporting embedded escape sequences and hex bytes

decimal
0 value $buf  0 value /$buf
: add-char  ( char -- )
   $buf /$buf + c!  1 /$buf + to /$buf
;
: $>$buf  ( adr len -- )
   tuck  $buf /$buf +  swap move   ( len )
   /$buf +  to /$buf               ( )
;
: nextchar  ( adr len -- false | adr' len' char true )
   dup  0=  if  nip exit  then   ( adr len )
   over c@ >r  swap 1+ swap 1-  r> true
;

: nexthex  ( adr len -- false | adr' len' digit true )
   begin
      nextchar  if         ( adr' len' char )
	 d# 16 digit  if   ( adr' len' digit )
	    true true      ( adr' len' digit true done )
	 else              ( adr' len' char )
	    drop false     ( adr' len' notdone )
	 then              ( adr' len' digit true done | adr' len' notdone )
      else                 (  )
	 false true        ( false done )
      then
   until
;
: get-hex-bytes  ( -- )
   [char] ) parse                   ( adr len )
\  caps @  if  2dup lower  then     ( adr len )
   begin  nexthex  while            ( adr' len' digit1 )
      >r  nexthex  0= ( ?? ) abort" Odd number of hex digits in string"
      r>                            ( adr'' len'' digit2 digit1 )
      4 << +  add-char              ( adr'' len'' )
   repeat
;
\ : get-char  ( -- char )  input-file @ fgetc  ;
: get-char  ( -- char|-1 )
   source  >in @  /string  if  c@  1 >in +!  else  drop -1  then
;
: get-escaped-string  ( -- adr len )
   'source @ >in @ +  to $buf  0 to /$buf
   begin
      [char] " parse   $>$buf
      get-char  dup bl <=  if  drop $buf /$buf exit  then  ( char )
      case
         [char] n of  control J          add-char  endof
         [char] r of  control M          add-char  endof
         [char] t of  control I          add-char  endof
         [char] f of  control L          add-char  endof
         [char] l of  control J          add-char  endof
         [char] b of  control H          add-char  endof
         [char] ! of  control G          add-char  endof
         [char] ^ of  get-char h# 1f and add-char  endof
         [char] ( of  get-hex-bytes                endof
         ( default ) dup                add-char
      endcase
   again
;
: "  \ string  ( -- adr len )
   get-escaped-string
   state @  if  postpone sliteral  then
; immediate
