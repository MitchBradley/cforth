\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: detokeni.fth
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
purpose: Decompiles FCode binary code into FCode source text
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

only forth definitions
vocabulary detokenizer
only forth also detokenizer also definitions

warning @  warning off
: headers ; : headerless ;

needs init-tables ${BP}/ofw/fcode/common.fth
\ fload ${BP}/ofw/fcode/common.fth
32 buffer: name-buf
\ : $create  ( adr len -- )  name-buf pack count $create  ;
: /string  ( adr len cnt -- adr+cnt len-cnt )  tuck 2swap +  -rot -  ;

0 value paginate?
: cr  ( -- )  cr  paginate?  if  exit?  if  bye  then  then  ;
also forth definitions
: paginate  ( -- )  true to paginate?  ;
previous definitions

variable #indent

: ?indent  ( -- )  #indent @  #out @  -  0 max  spaces  ;
: ?indent+  ( -- )  #out @  #indent @  >  if  ."  "  else  ?indent  then  ;
: icr ( -- )  cr #indent @ spaces  ;
: ?icr ( -- )  #out @  #indent @ >  if  cr  then  ?indent  ;
: +indent ( -- )  3 #indent +!  ;
: -indent ( -- ) -3 #indent +!  ;

: show-byte  ( adr immediate? -- )
   if  execute  else  ?indent  .name  then  ?cr
;

variable external?

: byte-load  ( adr stride -- )
   external? off
   d# 64 rmargin !
   ['] show-byte is do-byte-compile
   byte-interpret	\ Interpret byte sequence
   cr ." end0 " cr
;

: byte-code:  \ name  ( code# table# -- )
   >token-table   ( code# tableaddr )
   parse-word  $find  ?dup  if                ( code# tableaddr acf immed? )
      0> if                                   ( code# tableaddr acf )
	 2 pick 2 pick  swap ta+              ( code# tableaddr acf addr )
  	 dup token@ ['] ferror <>  if         ( code# tableaddr acf addr )
  	    ??cr ." ****** DUPLICATE TOKEN " over .name cr  ( code# tableaddr acf addr )
  	 then  token!                         ( code# tableaddr )
	 set-immed  exit
      then                                    ( code# tableaddr acf )
   else                                       ( code# tableaddr adr len )
      $create lastacf                         ( code# tableaddr acf )
   then                                       ( code# tableaddr acf )
   -rot swap ta+                              ( acf addr )
   dup token@ ['] ferror <>  if               ( acf addr )
      ??cr ." ****** DUPLICATE TOKEN " over .name cr ( acf addr )
   then  token!                               (  )
;

: .def  ( adr len -- )
   external? @  if  ." external "  external? off  then
   type space lastacf .name
;

variable tok-state tok-state off
: b(:)   ??cr  " :"  .def   3 #indent !   cr tok-state on ; immediate

: b(field)           " field"    .def cr     ; immediate
: b(create)    ??cr  " create"   .def space  ; immediate
: b(constant)        " constant" .def cr     ; immediate
: b(variable)  ??cr  " variable" .def space  ; immediate
: b(value)           " value"    .def cr     ; immediate
: b(defer)     ??cr  " defer"    .def cr     ; immediate
: b(buffer:)         " buffer:"  .def cr     ; immediate

: b(;)  0 #indent !  ?icr  ." ;" cr cr tok-state off ; immediate

: b(lit)  ?indent get-long ." h# " .x  ?cr  ; immediate

: b(') ( -- )
   tok-state @  if  ." ['] "  else  ." ' "  then next-token drop .name  ?cr
; immediate

: b(")
   ?indent  ascii " emit space get-string type ascii " emit space  ?cr
; immediate

: b(to)  ?indent ." to "  ; immediate

: .offset  ( adr len -- )  type  ." (" get-offset  (.) type ." ) "  ?cr  ;

: bbranch
   get-offset  0<  if
      -indent  ?icr  ." again "
   else
      -indent ?icr ." else "  +indent   cr
      next-token 2drop  \ eat the b(>resolve)
   then
; immediate

\ : b?branch   " ?branch"  .offset  ; immediate
: b?branch
   get-offset  dup 0<  if
      drop
      -indent  ?icr  ." until" cr
   else  ( offset )
      interpreter-pointer @ +
      offset16? @  if  6  else  4  then -   ( adr )
      \ bbranch followed by a negative offset
      dup dup c@ h# 13 =   swap 1+ c@ h# 80 and 0<>  and  if ( addr )
	 -indent  ?icr  ." while"
	    h# b3 swap c!	\ Store the fake FCode for b(repeat)
      else                     ( addr )
	 drop ?indent+ ." if"
      then   +indent cr
   then
; immediate

: drop-offset  ( -- )  get-offset drop  ;

: b(<mark)     ?indent+ ." begin"  +indent cr  ; immediate
: b(>resolve)  -indent  ?icr ." then"  cr  ; immediate

: b(case)    ?indent+ ." case"  +indent cr  ; immediate
: b(of)      ?indent+ ." of  "       drop-offset  ; immediate
: b(endof)   ?indent+ ." endof" cr   drop-offset  ; immediate
: b(endcase) -indent  ?icr  ." endcase" cr  ; immediate

: b(repeat)
   -indent  ?icr ." repeat  " drop-offset next-token 2drop  cr
; immediate

: b(loop)    -indent ?icr  ." loop"   drop-offset  cr  ; immediate
: b(+loop)   -indent ?icr  ." +loop"  drop-offset  cr  ; immediate
: b(do)      ?indent+ ." do"     drop-offset  +indent cr  ; immediate
: b(?do)     ?indent+ ." ?do"    drop-offset  +indent cr  ; immediate

: b(leave)   ?indent+ ." leave "  ; immediate

\ Needed here because >r and r> are immediate in the kernel
: r>  ?indent ." r> "  ; immediate
: >r  ?indent ." >r "  ; immediate

: fake-name  ( code# table# -- )
   swap <# ascii ) hold  u#s drop  ascii , hold  u#s  ascii ( hold u#>
;

: show-def  next-token  drop execute  ;

: set-entry  ( acf code# table# -- )  >token-table swap ta+  token!  ;

: new-token     \ then table#, code#, token-type
   get-byte get-byte swap             ( code# table# )
   2dup fake-name $create  lastacf    ( code# table# acf )
   -rot set-entry
   show-def
; immediate

: named-token   \ then string, table#, code#, token-type
   get-string $create  lastacf    ( acf )
   get-byte get-byte swap         ( acf code# table# )
   2dup fake-name type space   ( acf code# table# )
   set-entry
   show-def
; immediate

: external-token   external? on  [compile] named-token  ; immediate

: .header  ( adr len -- )
   space  icr
   get-word drop  \ Skip the Checksum field
   ." \  " get-long ." Image Size     h# " .x ."  bytes." icr
;
: version1   \ then 0byte,chksum(2bytes),length(4bytes)
   ." FCode-version1"  .header
   get-byte drop  \ Skip the Rev# field
; immediate

: .start  ( -- )
   offset16  ." FCode-version"
   get-byte  8 >=  if  ." 3"  else  ." 2"  then   \ Rev# field
   ."  ( start"
;

: start0  ( -- )  .start ." 0 )" .header  ; immediate
: start1  ( -- )  .start ." 1 )" .header  ; immediate
: start2  ( -- )  .start ." 2 )" .header  ; immediate
: start4  ( -- )  .start ." 4 )" .header  ; immediate

: offset16   offset16  ." offset16" icr  ; immediate

: 4-byte-id  \ then 3 more bytes
   ." 4-byte-id " get-byte .x  get-byte .x  get-byte .x  icr
; immediate

: property  ." property" icr  ; immediate

alias v1   noop
alias v2   noop
alias v2.1 noop
alias v2.2 noop
alias v2.3 noop
alias v3   noop
alias obs  noop
alias vfw  noop

init-tables

fload ${BP}/ofw/fcode/primlist.fth	\ basic words - escape-code=0
fload ${BP}/ofw/fcode/sysprims.fth	\ gen purpose plug in routines
fload ${BP}/ofw/fcode/regcodes.fth	\ Register access words

h# 0b3 0 byte-code: b(repeat)  \ Used to be byte-code for V1 set-token

h# 10020 buffer: fcode-buf

: load-fcode  ( -- )
   fcode-buf h# 10020  ifd @ fgets  drop
   ifd @ fclose
;
only forth also detokenizer also forth definitions

: detokenize  \ name  ( -- )
   reading  load-fcode
   offset16? off  #indent off  lmargin off
   fcode-buf  dup @  h# 01030107 =  if  h# 20 +  then   ( adr )
   1 byte-load
   cr
;

warning !
