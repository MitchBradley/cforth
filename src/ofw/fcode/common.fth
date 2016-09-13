\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: common.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
purpose: The basic FCode byte code interpreter loop
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ "Generic" byte code interpreter.  These words are used to interpret
\ byte code streams.  The action to be performed for each byte code
\ in the stream is defined externally, so the interpreter code in this
\ file may be used by several programs, such as the byte code recompiler
\ in the CPU boot PROM and the byte code display program.


headers

nuser interpreter-pointer	\ Points to next byte code in stream
nuser fcode-verbose?		\ Print out fcodes as they are encountered

headerless

nuser more-bytes?		\ True when stream is not exhausted
\ nuser table#			\ Remembers table # of last code encountered
\ nuser code#			\ Remembers code # of last code encountered
nuser stride			\ The distance between successive bytes in
				\ the code stream.  If the bytes are stored
				\ in an 8-bit PROM connected to one of the
				\ byte lanes of a 32-bit bus, stride is 4.
nuser offset16?			\ Are offsets 16 bits long?

\ Get the next byte code from the byte code stream
: get-byte  ( -- byte-code )
   interpreter-pointer @ c@  stride @ interpreter-pointer +!  ( byte-code )
;

\ Each token-tables array consists of an array of pointers to individual
\ tables, followed by an array of bytes indicating whether or not an
\ individual table has been copied for the purpose of modifying an entry.
\ The pointers are stored in Forth "token" format.
\
\ "token-tables" points to the current array of pointers, and "tables-new"
\ points to the following array of bytes.
\
\     table-ptr table-ptr table-ptr ...  copied-byte copied-byte ...
\     ^                                  ^
\     |                                  |
\  token-tables                    new-tables <== ??? Should this be "tables-new" MWI
\
\ The byte array is used to implement "copy-on-write" semantics for the
\ individual token tables.  When byte-load is executed, a new token-tables
\ array is allocated.  The current pointers to the global token tables (table
\ numbers 0..7) are copied into the new array, and the entries for local
\ token tables (table numbers 8..15) are set to null.  The first time that
\ the FCode program defines a new FCode token in a local table, the table is
\ allocated, and the corresponding entry in the byte array is set.
\
\ The first time (if at all) that the FCode program uses set-token to modify
\ a token in a global table, a copy of that table is made, the corresponding
\ pointer in the tables array is set to point to the new table, and the
\ corresponding entry in the byte array is set.  (Global tables are rarely
\ modified, so this strategy avoids unnecessary copying.)
\
\ When byte-load finishes, the entries in the byte array that are set
\ indicate token tables that are private to that invocation of byte-load;
\ those tables are freed, along with the token-tables array itself, and
\ "token-tables" is set back to the previous token-tables arrays.

d# 16 constant #token-tables		\ Maximum number of token tables
#token-tables /token 1+ * constant /token-tables

h# 100 constant tokens/table
tokens/table  /token *  constant /token-area
\tagvoc     tokens/table  8 /       constant /immed-area   \ 1 bit for each token
\nottagvoc  0 constant /immed-area

/token-area /immed-area +  constant /token-table

\ 0 value token-table0
\ /token-tables  buffer: token-table0

\ /stringbuf buffer: string-buf	\ buffer for collecting strings
d# 258 buffer: string-buf	\ buffer for collecting strings

variable token-tables-ptr	\ Token ptr to array of pointers to token tables
: token-tables  ( -- tables-pointer )  token-tables-ptr token@  ;
: tables-new  ( -- adr )  token-tables  #token-tables ta+  ;

d#  8 constant local-table#	\ First table # for local codes


\ Terminate interpretation of the byte code stream.  This is invoked
\ by byte codes 0 and ff, so that the byte code interpreter will exit
\ when an unprogrammed section of the PROM is encountered.
headers
: end0  ( -- )  more-bytes? off  ;  immediate   \ For end value 0
: end1  ( -- )  [compile] end0   ;  immediate   \ For end value ff
: ferror  ( -- )
   ." Unimplemented FCode token before address " interpreter-pointer @ .h cr
   [compile] end0
;
: obsolete-fcode  ( -- )  ferror  ;

headerless

: ttbl-align  ( -- )	\ like acf-align without 'lastacf side-effect
   #acf-align (align)
;


: set-tables  ( adr -- )  token-tables-ptr token!  ;

\ Clear the individual table pointers in the table array
: erase-tables  ( -- )
   #token-tables  0  do
      token-tables i ta+ !null-token
      0  tables-new i +  c!
   loop
;

\ Create the master copy of the token table array
: init-tables  ( -- )
   ttbl-align  here  /token-tables allot  set-tables   erase-tables
   tables-new #token-tables note-string 2drop
;

\ Allocate a new token table array, priming with copies of the old set of
\ global tables.

: new-token-tables  ( -- old-tables )
   token-tables                            ( old-tables )
   /token-tables alloc-mem  set-tables     ( old-tables )
   erase-tables                            ( old-tables )

   \ Initially, we just point to the existing global tables.
   \ Later, if a table entry needs to be modified, we will
   \ allocate a private copy of that table (copy-on-write).

   8 0  ?do                                ( old-tables )
      dup i ta+ token@ non-null?  if       ( old-tables old-table )
         token-tables i ta+  token!        ( old-tables )
      then                                 ( old-tables )
   loop                                    ( old-tables )
;

\ Restore the old token table array, free the memory used by the current
\ token table array and any new token tables to which it refers.

: old-token-tables  ( old-tables -- )
   \ Free any new token tables (local tables and modified global tables)
   #token-tables  0  do                    ( old-tables )
      tables-new i + c@  if                ( old-tables )
         token-tables i ta+ token@	   ( old-tables adr )
         /token-table free-mem             ( old-tables )
      then                                 ( old-tables )
   loop                                    ( old-tables )

   token-tables  /token-tables  free-mem   ( old-tables )
   token-tables-ptr token!                 ( )
;

\ Allocate space for a new token table and install it in the current
\ token tables array.
: new-table  ( table# -- adr )
   >r
   token-tables in-dictionary?  if                      ( )
      ttbl-align  here  /token-table allot              ( adr )
      dup /token-area +  /immed-area note-string erase  ( adr )      
   else                                                 ( )
      /token-table alloc-mem                            ( adr )
      dup /token-area +  /immed-area erase              ( adr )      
   then                                                 ( adr )
   dup  token-tables r@ ta+ token!                      ( adr )
   1 tables-new r> + c!                                 ( adr )
;

\ Create a private copy of the indicated token table, unless the existing
\ table is already private.
: ?copy-table  ( table# -- )
   tables-new over + c@  0=  if     ( table# )
      token-tables over ta+ token@  ( table# old-table )
      over new-table                ( table# old-table new-table )
      /token-table move             ( table# )
   then                             ( table# )
   drop                             ( )
;

\ Return the address of the numbered token table.  If space for that
\ table hasn't yet been allocated, allocate it.
: >token-table  ( table# -- table-adr )
   token-tables  over ta+ get-token?  if      ( table# table-adr )
      nip                                     ( table-adr )
   else                                       ( table# )
      new-table                               ( table-adr )
      tokens/table 0  do                      ( table-adr )
         dup i ta+  ['] ferror  swap token!   ( table-adr )
      loop                                    ( table-adr )
   then                                       ( table-adr )
;

\tagvoc \ Immediate bits for each token are at the end of the table.
\tagvoc \ The bit for token#0 is bit 0 of the byte at (table-addr + /token-area)
\tagvoc : >offset  ( code# table-addr -- bitoffset byteaddr )
\tagvoc    /token-area + >r  ( code# )  ( rs: imm-table-addr )
\tagvoc    8 /mod  ( bitoffset #bytes )  r> +
\tagvoc ;
: set-immed  ( code# table-addr -- )
\tagvoc     >offset  ( bitoffset0-7 byteaddr )
\tagvoc     1 rot <<   ( byteaddr bit-in-place )
\tagvoc     over c@  or  swap c!
\nottagvoc  swap ta+  ( adr )  dup token@ 1+ swap token!
;
\tagvoc : immed?  ( code# table-addr -- flag )
\tagvoc    >offset  ( bitoffset0-7 byteaddr )  c@   swap >>  1 and
\tagvoc ;

\ Gets a signed offset from the byte code stream.
: get-offset  ( -- n )
   fcode-verbose? @  if  interpreter-pointer @  then	( [? iptr ?] )
   get-byte
   offset16? @  if
      8 <<  get-byte +   d# 16
   else
      d# 24
   then 			( [? iptr ?] raw-offset shift-amount )
   tuck <<  l->n  swap >>a	( [? iptr ?] offset )

   fcode-verbose? @  if 		( iptr offset )
      dup .h				( iptr offset )  \  Print:  offset
      tuck stride @ * + 		( offset dest )
      ." ("  push-hex (u.) type pop-base ." ) "  ( offset ) \  Print:  dest
   then
;

\ Gets a 16-bit word from the byte code stream.
: get-word  ( -- 16bit ) get-byte 8 <<  get-byte +  ;

\ Gets a longword from the byte code stream.
: get-long  ( -- long )  get-word  d# 16 <<  get-word +
   fcode-verbose? @  if dup .h then
;
\ Gets a string from the byte code stream.
: get-string  ( -- adr len )
   get-byte  ( len )  dup string-buf  c!  ( len )
   string-buf 1+  swap  bounds  ?do  get-byte i c!  loop
   string-buf  count
   fcode-verbose? @  if  ??cr 8 to-column 2dup type cr then
;
: token\immed  ( code# table-addr -- xt immediate? )
\nottagvoc  swap ta+  token@                  ( table-entry )
\nottagvoc  dup 1 and  if  1- true  else  false  then       ( xt immediate? )
\tagvoc     2dup immed?  >r                                 ( code# table-addr )
\tagvoc     swap ta+  token@   r>
;
headers
\ Don't change fcode-find to return -1|0|1 like find, because
\ some people use it to "rehead" definitions.  If we need a function
\ that returns -1|0|1, give it a different name.
: fcode-find  ( code# table# -- xt immediate? )
   >token-table                                    ( code# table-addr )
   token\immed                                     ( xt immediate? )
;
headerless
\ Gets the address of a Forth word from the byte code stream.
\ The byte code stream contains a byte code.  The address of the
\ Forth word corresponding to that byte code is found and returned.

defer get-token-hook ' noop is get-token-hook

: sense-local-tokens  ( code# table# -- code# table# )
   state @  if  exit  then              ( code# table# )
   dup  8 >=  if                        ( code# table# )
      2dup fcode-find drop              ( code# table# xt )
      ['] (debug catch  if  drop  then  ( code# token# x )
   then                                 ( code# table# )
;

\ Invoke an FCode debugging mode in which the Forth source debugger
\ is invoked whenever byte-load interprets a colon definition that
\ was defined by the current FCode program.  This is quite useful for
\ debugging the probe-time behavior of FCode drivers.

headers
: debug-local-tokens  ( -- )  ['] sense-local-tokens to get-token-hook  ;

headerless
: next-token  ( -- xt immediate? )
   fcode-verbose? @  if
      ??cr  interpreter-pointer @  u. ." :   "
   then
   get-byte
   dup  #token-tables >=  over 0= or   ( byte table0? )
   if  0  else  get-byte swap  then    ( code# table# )
\    2dup table# !  code# !
   fcode-verbose? @  if
      push-hex  2dup [ also hidden ] .2  .2 [ previous ]  pop-base
   then
   get-token-hook
   fcode-find                          ( xt immediate? )
   fcode-verbose? @  if
      over .name  dup if ['] immediate .name then
   then
;

headers
: get-token  ( fcode# -- xt immediate? )  wbsplit fcode-find  ;

: set-token  ( xt immediate? fcode# -- )
   wbsplit  dup >token-table         ( xt immediate? code# table# table-addr )
   swap ?copy-table                  ( xt immediate? code# table-addr )
   rot  if  2dup set-immed  then     ( xt code# table-addr )
   swap ta+ token!
;

headerless
\ The action performed for each token in the byte code stream.  Before
\ executing byte-interpret, an action routine must be installed in
\ do-byte-compile.
defer do-byte-compile  ( xt immediate? -- )
: verify-fcode-prom-checksum ( -- )
   get-byte h# 3  <  if                          (  )
      get-word drop   \ Checksum                 (  )
      get-long drop   \ Length                   (  )
   else                                          (  )
      get-word                                   ( cksum )
      0  get-long                                ( cksum 0 length )
      interpreter-pointer @ >r                   ( cksum 0 length ) ( r: ip )
      8 - 0 ?do  get-byte + loop                 ( cksum cksum' )   ( r: ip )
      r> interpreter-pointer !                   ( cksum cksum' )
      lwsplit + lwsplit +  h# 0ffff and  <>  if  (  )
	 ." Incorrect FCode PROM checksum "      (  )
      then                                       (  )
   then                                          (  )
;
headers
variable fcode-checksum?  fcode-checksum?  off
: version1  ( -- )
   offset16? off
   fcode-checksum? @  if
      verify-fcode-prom-checksum
   else
      get-byte drop    \ Pad byte
      get-word drop    \ Checksum,
      get-long drop    \ Length
   then
;
: offset16  ( -- )  offset16? on  ;
headerless
: (version2)  ( stride -- )
   stride @ negate  interpreter-pointer +!      \ Undo previous increment
   stride !
   stride @         interpreter-pointer +!      \ Do new increment
   offset16
   fcode-checksum? @  stride @  and  if
      verify-fcode-prom-checksum
   else
      get-byte drop   \ Pad byte
      get-word drop   \ Checksum,
      get-long drop   \ Length
   then
;
headers
: start0  ( -- )  0 (version2)  ;
: start1  ( -- )  1 (version2)  ;
: start2  ( -- )  2 (version2)  ;
: start4  ( -- )  4 (version2)  ;
headerless
\ The byte code interpreter loop.  adr is the starting address of
\ the byte code stream, and stride is the distance between successive
\ bytes in the stream.
: byte-interpret  ( adr stride -- )
   warning @ >r  warning off
   stride @ >r  interpreter-pointer @ >r  more-bytes? @ >r  offset16? @ >r

   stride !   interpreter-pointer !   more-bytes? on

   begin
      more-bytes? @
   while
      next-token do-byte-compile
   repeat

   r> offset16? !  r> more-bytes? !  r> interpreter-pointer !  r> stride !
   r> warning !
;
headers
