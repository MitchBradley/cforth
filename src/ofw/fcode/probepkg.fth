\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: probepkg.fth
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
purpose: Package creation and probing tools
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Package probing.

h# 10000 constant /fcode-prom

: probe-virtual  ( arg-str reg-str fcode-vadr -- )
   dup c@  dup  h# f0 h# f3 between  swap h# fd =  or  0=  if
      ." Invalid FCode start byte at " .h cr
      2drop 2drop
      exit
   then
   new-device        ( arg-str reg-str fcode-vadr )
   >r  set-args      ( )  ( r: fcode-vadr )
   r> 1 byte-load
   finish-device
;
: probe  ( arg-str reg-str fcode-str -- )
   diagnostic-mode?  if
      ." Probing " (.parents) ."  at "  2dup type  space space
   then

   ( arg-str reg-str fcode-str )

   " decode-unit"  ['] $call-self  catch  if  ( arg-str reg-str x x x x )
      2drop 2drop 2drop 2drop
      diagnostic-mode?  if  ." Invalid FCode address." cr  then
      exit
   then                                ( arg-str reg-str fcode-offs,space )
   \ XXX the mapping size ought to be a function of the byte stride.
   \ However, we don't know the byte stride until we start to compile
   \ One solution is to map more than we will ever need.

   /fcode-prom  " map-in" $call-self   ( arg-str reg-str fcode-vadr )

   dup cpeek  if                       ( arg-str reg-str fcode-vadr value )
      drop                             ( arg-str reg-str fcode-vadr )
      dup >r  probe-virtual  r>        ( fcode-vadr )
      diag-cr
   else                                ( arg-str reg-str fcode-vadr )
      " Nothing there" diag-type-cr
      nip nip nip nip                  ( fcode-vadr )
   then                                ( fcode-vadr )

   /fcode-prom " map-out" $call-self   ( )
;
