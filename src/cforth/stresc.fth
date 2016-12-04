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

: (next-char) ( c-addr u -- c-addr' u' char ) over c@ >r 1 /string r> ;
: (parse-hex-digit) ( char -- u )
   dup '0' '9' 1+ within if '0' - exit then
   dup 'a' 'g' within if 'a' - exit then
   dup 'A' 'G' within if 'A' - exit then
   true abort" Invalid hex digit in string after \x."
;

: (parse-\x) ( c-addr u -- c-addr' u' )
   dup 2 < abort" Premature end of string after \x."
   (next-char) (parse-hex-digit) >r
   (next-char) (parse-hex-digit) r> 4 lshift or c,
;

: (parse-\) ( c-addr u -- c-addr' u' )
   dup 0= abort" Premature end of string after \."
   (next-char) case
      'a' of #7 c, endof
      'b' of #8 c, endof
      'e' of #27 c, endof
      'f' of #12 c, endof
      'l' of #10 c, endof
      'm' of #13 c, #10 c, endof
      'n' of #10 c, endof
      'q' of #34 c, endof
      'r' of #13 c, endof
      't' of #9 c, endof
      'v' of #11 c, endof
      'z' of #0 c, endof
      '"' of #34 c, endof
      'x' of (parse-\x) endof
      '\' of #92 c, endof
      true abort" Invalid escape character."
   endcase
;

: (parse-s\"-loop) ( c-addr u -- c-addr' u' )
   begin
      dup 0= if exit then
      (next-char) case
	 '\' of (parse-\) endof
	 '"' of exit endof
	 dup c,
      endcase
   again
;

\ Parse STRING, translating \-escape characters.  Store the translated
\ string after HERE.  U is the length of the string.
: (parse-s\") ( "string" -- u )
   here                                      ( here )
   source >in @ /string (parse-s\"-loop)     ( here c-addr' u' )
   drop source drop - >in !		     ( here )
   here swap -				     ( u )
   dup negate allot
;

: s\" ( "string" -- c-addr u )
   source >in @ /string drop	( c-addr )   \ save start of parse area
   (parse-s\")			( c-addr u )
   2dup here rot rot move	( c-addr u ) \ overwrite parse area
   state @  if postpone sliteral  then
; immediate
