\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: applcode.fth
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
purpose: Miscellaneous FCode functions
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headerless
: 4-byte-id  ( -- )  ;         \ version 1 token

headers
\ FCode version
h# 3.0000 constant fcode-revision  ( -- n )
alias fcode-version fcode-revision   ( -- n )
alias version fcode-revision       ( -- n )

: firmware-version  ( -- n )  major-release d# 16 <<  minor-release +  ;

\ 5 constant processor-type

alias v1 noop          \ Include version 1 FCode support
alias v2 noop          \ Include version 2.0 FCode support
alias v2.1 noop        \ Include version 2.1 FCode support
alias v2.2 noop        \ Include version 2.2 FCode support
alias v2.3 noop        \ Include version 2.3 FCode support
alias v3 noop	       \ Include version 3 FCode support
alias vfw  noop

: (is-user-word)  ( adr len acf -- )
   also forth definitions
   -rot $create -1 setalias
   previous definitions
;

-1 constant -1

: suspend-fcode  ( -- )  ;

: map-low  ( offset size -- virtual )  my-space swap " map-in" $call-parent  ;

: encode-intr  ( int-level vector -- )
   >r sbus-intr>cpu encode-int  r> encode-int  encode+
;

also magic-properties definitions
: intr  ( value-str name-str  -- value-str name-str )
   \ Create an "interrupts" property unless one already exists
   " interrupts" get-my-property  if             ( value$ name$ )
      2over 0 0 encode-bytes 2swap  bounds  ?do  ( value$ name$ prop$ )
	 i /l get-encoded-int encode-int encode+ ( value$ name$ prop$' )
      2 /l*  +loop  " interrupts" property
   else                                   ( value$ name$ prop-adr,len )
      2drop                               ( value$ name$ )
   then                                   ( value$ name$ )
;
previous definitions

alias name device-name
: model  ( adr len -- )  " model"  string-property  ;
: reg    ( adr space size -- )  encode-reg  " reg"   property  ;
: intr   ( int-level vector -- )  encode-intr " intr"  property  ;

[ifndef] wbflips
: wbflip  ( n1 -- n2 )  wbsplit swap bwjoin  ;
: wbflips  ( adr len -- )
   bounds  ?do
      i unaligned-w@  wbflip  i unaligned-w!
   /w +loop
;

: lwflip  ( n1 -- n2 )  lwsplit swap wljoin  ;
: lwflips  ( adr len -- )
   bounds  ?do
      i unaligned-l@  lwflip  i unaligned-l!
   /l +loop
;

: lbflip  ( n1 -- n2 )  lbsplit swap 2swap swap bljoin  ;
: lbflips  ( adr len -- )
   bounds  ?do
      i unaligned-l@  lbflip  i unaligned-l!
   /l +loop
;

64\ : xbflip  ( x -- x' )  xlsplit lbflip swap lbflip lxjoin  ;
64\ : xlflip  ( x -- x' )  xlsplit swap lxjoin  ;
64\ : xwflip  ( x -- x' )  xlsplit lwflip swap lwflip lxjoin  ;

64\ : xbflips ( adr,len -- )
64\    bounds  ?do
64\      i unaligned-@ xbflip i unaligned-!
64\   /x +loop
64\ ;
64\  : xlflips ( adr,len -- )
64\     bounds  ?do
64\        i unaligned-@ xlflip i unaligned-!
64\     /x +loop
64\  ;
64\  : xwflips ( adr,len -- )
64\     bounds  ?do
64\        i unaligned-@ xwflip i unaligned-!
64\     /x +loop
64\  ;

[then]
\ alias wflips wbflips
\ alias lflips lwflips

defer $instructions  ( name$ -- )  ' 2drop to $instructions
defer instructions-done  ( -- )    ' noop to instructions-done
defer instructions-idle  ( -- )    ' noop to instructions-idle
