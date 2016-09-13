\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: spectok.fth
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
purpose: FCode compiling words, control structures, defining words
copyright: Copyright 1991-2001 Sun Microsystems, Inc.  All Rights Reserved

\ Byte-code recompiler; Compiling words and defining words

false config-flag fcode-debug?

headerless
: b(lit)  ( -- n ) 
   get-long l->n state @  if  [compile] literal  then
; immediate

: b(')  ( -- acf )
   next-token  drop  state @  if  compile (')  token,  then
; immediate

: b(")  ( -- adr len )
   get-string
   state @  if  compile (") ",  else  switch-string  "temp pack count  then
; immediate

: b(to)  ( -- )  next-token drop  do-is  ; immediate

: drop-offset  ( -- )  get-offset drop  ;

: b(do)     ( -- )  drop-offset  [compile]  do    ; immediate
: b(?do)    ( -- )  drop-offset  [compile] ?do    ; immediate
: b(loop)   ( -- )  drop-offset  [compile]  loop  ; immediate
: b(+loop)  ( -- )  drop-offset  [compile] +loop  ; immediate

alias b(leave)     leave
alias b(<mark)     begin
: b(>resolve)  ( [ >mark ] -- )  state @  if  [compile] then  then  ; immediate

: get-backward-mark  ( marks -- marks' backward-mark )
   0 >r		\ Put a sentinel value on the return stack

   \ A forward  mark is an address that points to a "0"
   \ A backward mark is an address that points to something else

   \ Move forward mark addresses to return stack

   begin  dup branch@  0=  while  >r  repeat  ( <adr )  ( r: 0 >adr0 .. >adrn )

   \ Restore forward marks to data stack,
   \ always floating the backward address to the top of the stack

   begin  r> ?dup  while  swap  repeat   ( >markn .. >mark0 <mark )
;

: skip-bytes  ( -- )
   get-offset  offset16?  if  2  else  1  then  -   ( #bytes-to-skip )
   0 ?do  get-byte drop  loop
;
: bbranch  ( [ <mark ] -- [ >mark ] )

   \ New feature
   state @ 0=  if  skip-bytes  exit  then

   get-offset 0<  if

      \ The tokenizer compiles "while" as "if"  (i.e. "b?branch(+)"),
      \ and "repeat" as "again then" (i.e. "bbranch(-) b(>resolve)").
      \ The control flow factoring of "while .. repeat" is "if but again then"
      \ It's impractical to make a smart "b?branch(+)" to automatically
      \ execute the "but" in the "while" case, because there is nothing
      \ on the stack before a real "if" to distinguish it from a "while".
      \ Therefore, we must make "bbranch(-)" smart, automatically
      \ distinguishing "again" from "repeat".
      \ Unfortunately, this is an insufficient basis for ANS Forth
      \ control flow with multiple "while"s.  We need either "but" or
      \ "b(while)".  However, we can fake it out by making "again" smart
      \ enough to search for a backward mark underneath a bunch of
      \ forward marks.  This is a cheat, but I think that it is ANS Forth
      \ compliant so long as CS-PICK and CS-ROLL are not available.

      get-backward-mark

      [compile] again
   else
      \ The tokenizer compiles "else" as "bbranch(+) then".
      \ The control flow factoring of "else" is "ahead but then".
      [compile] ahead  [compile] but
   then
; immediate

: b?branch  ( [ <mark ] -- [ >mark ] )

   \ New feature of IEEE 1275
   state @ 0=  if  ( flag )
      if  get-offset drop  else  skip-bytes  then
      exit
   then

   get-offset 0<  if  ( )
      \ The get-backward-mark is needed in case of the following valid
      \ ANS Forth construct:    BEGIN  .. WHILE .. UNTIL .. THEN
      get-backward-mark  [compile] until
   else
      [compile] if
   then
; immediate

\ Eaker's case statement
alias b(case)    case
: b(of)       ( marks -- marks )   drop-offset  [compile] of       ; immediate
: b(endof)    ( marks -- marks+ )  drop-offset  [compile] endof    ; immediate
alias b(endcase) endcase

\ I don't think we should support  [ ... ] inside colon definitions,
\ because they result in stuff in the code stream that must be skipped
\ if we are directly interpreting the PROM code.  Also, the result of
\ interpreting the ... stuff would have to be stuck into the code
\ stream, and that's not possible with PROM code.  Since we don't
\ support vocabularies, the common usage   [ also <vocabulary> ]   is not
\ necessary.

: b]  ( -- )  state on   ;
: b[  ( -- )  state off  ;  immediate

: get-code-adr   ( -- table-entry-adr )
   get-byte  get-byte  ( table# byte-code )
   swap >token-table  ( code# table-adr )
   swap ta+
;
: set-acf  ( table-entry-adr -- )  acf-align  lastacf swap token!  ;

: new-token  ( -- )  \ Code stream: table# byte-code#
   get-code-adr  ( table-entry-adr )  set-acf
; immediate

: named-token  ( -- )  \ Code stream:  namestring, table#, code#
   \ get-code-adr must be executed before $header in order
   \ to avoid splitting the dictionary if get-code-adr has to
   \ allocate a token table in the dictionary.
   get-string  get-code-adr  -rot  ( table-entry-adr adr len )
   fcode-debug?  if  $header  else  2drop  then
   set-acf
; immediate

: external-token  ( -- )  \ Code stream:  namestring, table#, code#
   \ get-code-adr must be executed before "header in order
   \ to avoid splitting the dictionary if get-code-adr has to
   \ allocate a token table in the dictionary.
   get-string  get-code-adr  -rot ( table-entry-adr adr len )
   $header
   set-acf
; immediate

: b(:)  ( -- )  colon-cf  b]  ;  immediate

: b(;)  ( -- )  compile unnest  [compile] b[  ;  immediate

: b(value)     ( n -- )     (value)     ;  immediate
: b(variable)  ( -- )       (variable)  ;  immediate
: b(defer)     ( -- )       (defer)     ;  immediate
: b(buffer:)   ( size -- )  (buffer:)   ;  immediate

: b(constant)  ( n -- )  constant-cf  ,  ;  immediate
: b(create)    ( -- )    create-cf       ;  immediate
: b(field)  ( offset size -- offset' )  create-cf over , +  does> @ +  ;


\ The following will not work:
\     create jump-table  ]  here pad up@  [
\ Here's how to do that:
\     create jump-table  ' here token,  ' pad token,  ' up@ token,

headers
