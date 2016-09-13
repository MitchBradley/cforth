\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: availpm.fth
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
purpose: "available" property for memory node
copyright: Copyright 1990-1994 Sun Microsystems, Inc.  All Rights Reserved

headers

" /memory" find-device

headerless

: make-phys-memlist  ( adr len node-adr -- adr len' false )
   node-range                    ( adr len  base size )
[ '#adr-cells @ 2 = ] [if]
   \   node-range pages>phys-adr,len encode-reg encode+ false
\   pages>phys-adr,len  nip       ( adr len base size )
   pages>phys-adr,len			( adr len base.lo base.hi size )
   2>r   encode-int encode+   2r>	( adr len base.hi size )
[then]
   >r  encode-int encode+
   r>  encode-int encode+
   false
;

headers

5 actions
action:  drop  
   0 0 encode-bytes                              ( adr 0 )
   physavail  ['] make-phys-memlist  find-node   ( adr len  prev 0 )
   2drop  over here - allot                      ( adr len )
;
action:  drop 2drop  ;
action:  ;
action:  drop  ;
action:  drop  ;

" available" make-property-name  use-actions

: size  ( -- d.#bytes )
   current-device >r
   my-voc push-device
   0 0  2>r                       (  )              ( r: d.size )
   get-unit  0=  if               ( adr len )       ( r: d.size )
      begin  dup  while           ( adr len )       ( r: d.size )
[ '#adr-cells @ 2 = ] [if]
	 decode-int drop          ( adr' len' )     ( r: d.size )
[then]
	 decode-int drop          ( adr' len' )     ( r: d.size )
	 decode-int  u>d          ( adr' len' ud )  ( r: d.size )
	 2r> d+ 2>r               ( adr' len' )     ( r: d.size' )
      repeat                      ( adr 0 )         ( r: d.size' )
      2drop                       (  )              ( r: d.size' )
   then  2r>                      ( d.#bytes )
   r> push-device
;

device-end
