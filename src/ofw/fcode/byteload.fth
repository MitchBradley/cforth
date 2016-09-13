\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: byteload.fth
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
purpose: Implements byte-load interface to FCode interpreter
copyright: Copyright 1990-2001 Sun Microsystems, Inc.  All Rights Reserved

headerless
: compile-byte  ( adr immediate? -- )
   state @ 0=  or  if  execute  else  compile,  then
;

\ Interpret FCode beginning at "adr", with successive FCode bytes
\ separated by "stride" address units.  "stride" is usually 1,
\ but may be otherwise; for example, if "stride" is 4, then the
\ FCode interpreter will fetch every fourth byte (e.g. a byte-wide
\ FCode PROM on a 32-bit justified bus).

: (byte-load)  ( adr stride -- )

   ['] compile-byte is do-byte-compile

   depth 2-  >r		\ Save stack depth

   \ Interpret byte sequence
   ['] byte-interpret catch ?dup  if  throw  then

   depth  r> - 	?dup  if
      ??cr ." Warning: Fcode sequence resulted in "
      ." a net stack depth change of "  .d  cr
      nullstring throw
   then
;

headers
: byte-load ( adr stride -- )
   new-token-tables >r
   ['] (byte-load)  catch  ?dup  if    ( adr stride err# )
      .error                           ( adr stride )
      2drop
   then
   r> old-token-tables
;
\ Support for FCode-encoded dropin drivers

: execute-buffer  ( adr len -- )
   over c@  dup  h# f0 h# f3 between  swap h# fd =  or  if
      drop  1 byte-load  exit
   then

   execute-buffer
;

