\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: loadfcod.fth
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
purpose: Load file for FCode interpreter
copyright: Copyright 2006 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Load file for FCode interpreter
headers
start-module

\ fload ${BP}/forth/lib/xmath.fth		\ 64 bit * and / extensions
fload ${BP}/ofw/fcode/applcode.fth		\ Miscellaneous stuff
[ifdef] resident-packages
fload ${BP}/ofw/fcode/memtest.fth		\ Generic memory test
[else]
autoload: memtest.fth
defines: mask
defines: memory-test-suite
[then]
fload ${BP}/ofw/fcode/common.fth		\ Basic FCode parsing

alias processor-type ferror

init-tables

fload ${BP}/ofw/fcode/byteload.fth		\ The compiler loop
	\ Compiling and defining words

fload ${BP}/ofw/fcode/spectok.fth		\ Control structures

fload ${BP}/ofw/fcode/probepkg.fth		\ Probe for FCode packages

fload ${BP}/ofw/fcode/comptokt.fth
fload ${BP}/ofw/fcode/primlist.fth		\ Codes for kernel primitives
fload ${BP}/ofw/fcode/sysprims.fth		\ Codes for system primitives
fload ${BP}/ofw/fcode/extcodes.fth		\ FirmWorks-specific primitives
64\ fload ${BP}/ofw/fcode/sysprm64.fth	\ Codes for 64-bit system primitives
fload ${BP}/ofw/fcode/debugfc.fth		\ FCode source directives
fload ${BP}/ofw/fcode/loaddi.fth

end-module

headers
