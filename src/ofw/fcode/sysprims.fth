\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: sysprims.fth
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
purpose: FCode token number definitions for system (2-byte) FCodes
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

hex
\ --- Memory allocation and mapping --------------------------------------
\ v1 v2  000 1  (reserved - because alocated by single byte fcodes)
v1 v2  001 1 byte-code: obsolete-fcode	\ Was dma-alloc  ( #bytes -- virtual )
v1 v2  002 1 byte-code: my-address            ( -- physical )
v1 v2  003 1 byte-code: my-space              ( -- space )
v1 v2  004 1 byte-code: obsolete-fcode	\ Was memmap   ( physical space size -- virtual )
v1 v2  005 1 byte-code: free-virtual          ( virtual len -- )
v1 v2  006 1 byte-code: obsolete-fcode	\ Was >physical ( virtual -- physical space )

\      007 1
\      008 1
\      009 1
\      00a 1
\      00b 1
\      00c 1
\      00d 1
\      00e 1

v1 v2  00f 1 byte-code: obsolete-fcode	\  Was my-params ( -- addr len )
v1 v2  010 1 byte-code: property         ( val-adr val-len name-adr name-len -- )
			\ Was attribute
v1 v2  011 1 byte-code: encode-int       ( n1 -- adr len )
			\ Was xdrint
v1 v2  012 1 byte-code: encode+          ( adr len1 adr len2-- adr len1+2 )
			\ Was xdr+
v1 v2  013 1 byte-code: encode-phys      ( paddr space -- adr len )
			\ Was xdrphys
v1 v2  014 1 byte-code: encode-string    ( adr len -- adr' len+1 )
			\ Was xdrstring
v2.1   015 1 byte-code: encode-bytes     ( adr len -- adr' len+1 )
			\ Was xdrbytes

\ --- Shorthand Property Creation --------------------------------------
v1 v2  016 1 byte-code: reg                   ( physical space size -- )
v1 v2  017 1 byte-code: obsolete-fcode	\ Was intr         ( int-level vector -- )
v1     018 1 byte-code: obsolete-fcode	\ driver           ( adr len -- )
v1 v2  019 1 byte-code: model                 ( adr len -- )
v1 v2  01a 1 byte-code: device-type           ( adr len -- )
   v2  01b 1 byte-code: parse-2int            ( adr len -- address space )
			\ Was decode-2int

\ --- Driver Installation ------------------------------------------------
v1 v2  01c 1 byte-code: is-install            ( acf -- )
v1 v2  01d 1 byte-code: is-remove             ( acf -- )
v1 v2  01e 1 byte-code: is-selftest           ( acf -- )
v1 v2  01f 1 byte-code: new-device            ( -- )

\ --- Selftest -----------------------------------------------------------
v1 v2  020 1 byte-code: diagnostic-mode?      ( -- flag )

v1 v2  021 1 byte-code: obsolete-fcode	\ Was display-status        ( n -- )
v1 v2  022 1 byte-code: memory-test-suite     ( adr len -- status)
v1 v2  023 1 byte-code: obsolete-fcode	\ Was group-code            ( -- adr )
v1 v2  024 1 byte-code: mask                  ( -- adr )

v1 v2  025 1 byte-code: get-msecs             ( -- ms )
v1 v2  026 1 byte-code: ms                    ( n -- )
v1 v2  027 1 byte-code: finish-device         ( -- )

v3     028 1 byte-code: decode-phys     ( adr1 len2 -- adr2 len2 phys.lo..hi )
v3     029 1 byte-code: push-package	( phandle -- )
v3     02a 1 byte-code: pop-package	( -- )
v3     02b 1 byte-code: interpose	( adr len phandle -- )
\      02c
\      02d
\      02e
\      02f

  v1 v2  030 1 byte-code: map-low        ( phys size -- virt ) \ Was map-sbus

\ --- Sbus Support - now obsolescent
  v1 v2  031 1 byte-code: sbus-intr>cpu  ( sbus-intr# -- cpu-intr# )
\ v1 v2  037 1 -- [S-Bus support]

\ --- P4 Bus address spaces - (these moved to /dev/p4bus/fcodeprims.fth) -
\ v1     038 1  -- [P4 Bus support] obsolete
\ v1     ...    -- [P4 Bus support] obsolete
\ v1     03f 1  -- [P4 Bus support] obsolete

\ --- Interrupts (Think about this!) -------------------------------------
\        040 1 byte-code: catch-interrupt       ( level vector -- )
\        041 1 byte-code: restore-interrupt     ( level -- )
\        042 1 byte-code: interrupt-occurred?   ( -- flag )
\        043 1 byte-code: enable-interrupt      ( level -- )
\        044 1 byte-code: disable-interrupt     ( level -- )
\        045 1
\        046 1
\        047 1
\        048 1
\        049 1
\        04a 1
\        04b 1
\        04c 1
\        04d 1
\        04e 1
\        04f 1

\ TERMINAL/FRAMEBUFFER OPERATIONS (DISPLAY DEVICE FCODES)
\ --- Terminal emulator values -------------------------------------------
v1 v2  050 1 byte-code: #lines                ( -- n )
v1 v2  051 1 byte-code: #columns              ( -- n )
v1 v2  052 1 byte-code: line#                 ( -- n )
v1 v2  053 1 byte-code: column#               ( -- n )

0 [if]
v1 v2  054 1 byte-code: inverse?              ( -- flag )
v1 v2  055 1 byte-code: inverse-screen?       ( -- flag )
\ v1     056 1 byte-code: frame-buffer-busy?    ( -- flag ) \ Obsolete

\ --- Terminal emulation low-level operations ----------------------------
v1 v2  057 1 byte-code: draw-character        ( char -- )
v1 v2  058 1 byte-code: reset-screen          ( -- )
v1 v2  059 1 byte-code: toggle-cursor         ( -- )
v1 v2  05a 1 byte-code: erase-screen          ( -- )
v1 v2  05b 1 byte-code: blink-screen          ( -- )
v1 v2  05c 1 byte-code: invert-screen         ( -- )
v1 v2  05d 1 byte-code: insert-characters     ( n -- )
v1 v2  05e 1 byte-code: delete-characters     ( n -- )
v1 v2  05f 1 byte-code: insert-lines          ( n -- )
v1 v2  060 1 byte-code: delete-lines          ( n -- )
v1 v2  061 1 byte-code: draw-logo             ( line# laddr lwidth lheight -- )

\ --- Frame Buffer Text routines -----------------------------------------
v1 v2  062 1 byte-code: frame-buffer-adr      ( -- addr )
v1 v2  063 1 byte-code: screen-height         ( -- n )
v1 v2  064 1 byte-code: screen-width          ( -- n )
v1 v2  065 1 byte-code: window-top            ( -- n )
v1 v2  066 1 byte-code: window-left           ( -- n )

\      067 1
v3     068 1 byte-code: foreground-color      ( -- index )
v3     069 1 byte-code: background-color      ( -- index )

\ --- Font ---------------------------------------------------------------
v1 v2  06a 1 byte-code: default-font          ( -- fntbase chrwidth chrheight fntbytes #1stchr #chrs    )
v1 v2  06b 1 byte-code: set-font              (    fntbase chrwidth chrheight fntbytes #1stchr #chrs -- )
v1 v2  06c 1 byte-code: char-height           ( -- n )
v1 v2  06d 1 byte-code: char-width            ( -- n )
v1 v2  06e 1 byte-code: >font                 ( char -- adr )
v1 v2  06f 1 byte-code: fontbytes             ( -- n )  \ Bytes/scan line, usu. 2

\ --- 1-bit frame buffer routines ----------------------------------------
\ The FB1 support package is obsolete in IEEE 1275
[ifdef] include-fb1
v1 v2  070 1 byte-code: fb1-draw-character    ( char -- )
v1 v2  071 1 byte-code: fb1-reset-screen      ( -- )
v1 v2  072 1 byte-code: fb1-toggle-cursor     ( -- )
v1 v2  073 1 byte-code: fb1-erase-screen      ( -- )
v1 v2  074 1 byte-code: fb1-blink-screen      ( -- )
v1 v2  075 1 byte-code: fb1-invert-screen     ( -- )
v1 v2  076 1 byte-code: fb1-insert-characters ( #chars -- )
v1 v2  077 1 byte-code: fb1-delete-characters ( #chars -- )
v1 v2  078 1 byte-code: fb1-insert-lines      ( #lines -- )
v1 v2  079 1 byte-code: fb1-delete-lines      ( #lines -- )
v1 v2  07a 1 byte-code: fb1-draw-logo         ( line# logoadr lwidth lheight -- )
v1 v2  07b 1 byte-code: fb1-install           ( width height #cols #lines -- )
v1 v2  07c 1 byte-code: fb1-slide-up          ( #lines -- )
[else]
v1 v2  070 1 byte-code: obsolete-fcode	\ Was fb1-draw-character    ( char -- )
v1 v2  071 1 byte-code: obsolete-fcode	\ Was fb1-reset-screen      ( -- )
v1 v2  072 1 byte-code: obsolete-fcode	\ Was fb1-toggle-cursor     ( -- )
v1 v2  073 1 byte-code: obsolete-fcode	\ Was fb1-erase-screen      ( -- )
v1 v2  074 1 byte-code: obsolete-fcode	\ Was fb1-blink-screen      ( -- )
v1 v2  075 1 byte-code: obsolete-fcode	\ Was fb1-invert-screen     ( -- )
v1 v2  076 1 byte-code: obsolete-fcode	\ Was fb1-insert-characters ( #chars -- )
v1 v2  077 1 byte-code: obsolete-fcode	\ Was fb1-delete-characters ( #chars -- )
v1 v2  078 1 byte-code: obsolete-fcode	\ Was fb1-insert-lines      ( #lines -- )
v1 v2  079 1 byte-code: obsolete-fcode	\ Was fb1-delete-lines      ( #lines -- )
v1 v2  07a 1 byte-code: obsolete-fcode	\ Was fb1-draw-logo         ( line# logoadr lwidth lheight -- )
v1 v2  07b 1 byte-code: obsolete-fcode	\ Was fb1-install           ( width height #cols #lines -- )
v1 v2  07c 1 byte-code: obsolete-fcode	\ Was fb1-slide-up          ( #lines -- )
[then]

\        07d 1
\        07e 1
\        07f 1

\ --- 8-bit frame buffer routines ----------------------------------------
v1 v2  080 1 byte-code: fb8-draw-character    ( char -- )
v1 v2  081 1 byte-code: fb8-reset-screen      ( -- )
v1 v2  082 1 byte-code: fb8-toggle-cursor     ( -- )
v1 v2  083 1 byte-code: fb8-erase-screen      ( -- )
v1 v2  084 1 byte-code: fb8-blink-screen      ( -- )
v1 v2  085 1 byte-code: fb8-invert-screen     ( -- )
v1 v2  086 1 byte-code: fb8-insert-characters ( #chars -- )
v1 v2  087 1 byte-code: fb8-delete-characters ( #chars -- )
v1 v2  088 1 byte-code: fb8-insert-lines      ( #lines -- )
v1 v2  089 1 byte-code: fb8-delete-lines      ( #lines -- )
v1 v2  08a 1 byte-code: fb8-draw-logo         ( line# ladr lwidth lheight -- )
v1 v2  08b 1 byte-code: fb8-install           ( width height #cols #lines -- )
[then]

\        08c 1
\        08d 1
\        08e 1
\        08f 1

\ --- VME Bus address spaces - (these moved to /dev/vmebus/fcodeprims.fth)
\ v1 v2  090 1  -- [VME Bus support]
\ v1 v2  ...    -- [VME Bus support]
\ v1 v2  096 1  -- [VME Bus support]

\ --- NET OPERATIONS -----------------------------------------------------
\ v1     0a0 1 byte-code: return-buffer
\ v1 obs 0a1 1 byte-code: xmit-packet           ( bufadr #bytes -- #sent     )
\ v1 obs 0a2 1 byte-code: poll-packet           ( bufadr #bytes -- #received )
\ v1     0a3 1 byte-code: local-mac-address     (    adr len -- ) \ Driver sets this
v1 v2  0a4 1 byte-code: mac-address           ( -- adr len )    \ System sets this

\      0a5 1
\      0a6 1
\      0a7 1
\      0a8 1
\      0a9 1
\      0aa 1
\      0ab 1
\      0ac 1
\      0ad 1
\      0ae 1
\      0af 1

\      0b0 1
\      ...
\      0ff 1

\ --- Package and device handling ----------------------------------------
\      000 2  (reserved - because alocated by single byte fcodes)
v2    001 2 byte-code: device-name           ( addr len -- )
v2    002 2 byte-code: my-args               ( -- addr len )
v2    003 2 byte-code: my-self               ( -- ihandle )
v2    004 2 byte-code: find-package          ( adr len -- [phandle] ok? )
v2    005 2 byte-code: open-package          ( adr len phandle -- ihandle | 0 )
v2    006 2 byte-code: close-package         ( ihandle -- )
v2    007 2 byte-code: find-method           ( adr len phandle -- [acf] ok? )
v2    008 2 byte-code: call-package          ( acf ihandle -- )
v2    009 2 byte-code: $call-parent          ( adr len -- )
v2    00a 2 byte-code: my-parent             ( -- ihandle )
v2    00b 2 byte-code: ihandle>phandle       ( ihandle -- phandle )

\     00c 2

v2    00d 2 byte-code: my-unit               ( -- offset space )
v2    00e 2 byte-code: $call-method          ( adr len ihandle -- )
v2    00f 2 byte-code: $open-package         ( arg-adr,len name-adr,len -- ihandle | 0 )

\ --- CPU information ----------------------------------------------------
v2    010 2 byte-code: processor-type        ( -- processor-type )
v2    011 2 byte-code: obsolete-fcode	\ Was firmware-version      ( -- n )
v2    012 2 byte-code: obsolete-fcode	\ Was fcode-version         ( -- n )

\ --- Asyncronous support ------------------------------------------------
v2    013 2 byte-code: alarm                 ( acf n -- )

\ --- User interface -----------------------------------------------------
v2    014 2 byte-code: (is-user-word)        ( adr len acf -- )

\ --- Interpretation -----------------------------------------------------
v2    015 2 byte-code: suspend-fcode         ( -- )

\ --- Error handling -----------------------------------------------------
v2    016 2 byte-code: abort                 ( -- )
v2    017 2 byte-code: catch                 ( acf -- error-code )
v2    018 2 byte-code: throw                 ( error-code -- )
v2.1  019 2 byte-code: user-abort            ( -- )

\ --- Package attributes -------------------------------------------------
v2    01a 2 byte-code: get-my-property         ( nam-adr nam-len -- [val-adr val-len] failed? )
			\ Was get-my-attribute
v2    01b 2 byte-code: decode-int              ( val-adr val-len -- n )
			\ Was xdrtoint
v2    01c 2 byte-code: decode-string           ( val-adr val-len -- adr len )
			\ Was xdrtostring
v2    01d 2 byte-code: get-inherited-property  ( nam-adr nam-len -- [val-adr val-len] failed? )
			\ Was get-inherited-attribute
v2    01e 2 byte-code: delete-property         ( nam-adr nam-len -- )
			\ Was delete-attribute
v2    01f 2 byte-code: get-package-property    ( adr len phandle -- [val-adr val-len] failed? )
			\ Was get-package-attribute

\ --- aligned, atomic access ---------------------------------------------
v2    020 2 byte-code: cpeek                 ( adr -- { byte true } | false )
v2    021 2 byte-code: wpeek                 ( adr -- { word true } | false )
v2    022 2 byte-code: lpeek                 ( adr -- { long true } | false )

v2    023 2 byte-code: cpoke                 ( byte adr -- ok? )
v2    024 2 byte-code: wpoke                 ( word adr -- ok? )
v2    025 2 byte-code: lpoke                 ( long adr -- ok? )

v3    026 2 byte-code: lwflip                ( l1 -- l2 )
v3    027 2 byte-code: lbflip                ( l1 -- l2 )
v3    028 2 byte-code: lbflips               ( adr len -- )

\  v2 029 2 byte-code: adr-mask              ( n -- )
\     02a 2
\     02b 2
\     02c 2
\     02d 2

64\ v3     02e 2 byte-code: rx@	   ( xaddr -- o )
64\ v3     02f 2 byte-code: rx!        ( o xaddr -- )

[ifdef] notdef
\ These FCode Functions are installed in the token tables later, after their
\ system-dependent implementations are defined.  See ./regcodes.fth
v2    030 2 byte-code: rb@                   (      adr -- byte )
v2    031 2 byte-code: rb!                   ( byte adr --      )
v2    032 2 byte-code: rw@                   (      adr -- word )
v2    033 2 byte-code: rw!                   ( word adr --      )
v2    034 2 byte-code: rl@                   (      adr -- long )
v2    035 2 byte-code: rl!                   ( long adr --      )
[then]

v2    036 2 byte-code: wbflips               ( adr len -- )  \ Was wflips
v2    037 2 byte-code: lwflips               ( adr len -- )  \ Was lflips

\ --- probing of subordinate devices
v2.2  038 2 byte-code: obsolete-fcode	\ Was probe  ( arg-str reg-str fcode-str -- )
v2.2  039 2 byte-code: obsolete-fcode	\ Was probe-virtual ( arg-str reg-str fcode-adr -- )

\     03a 2
v2.3  03b 2 byte-code: child                 ( phandle -- phandle' )
v2.3  03c 2 byte-code: peer                  ( phandle -- phandle' )
v3    03d 2 byte-code: next-property
			     \  ( adr1 len1 phandle -- false | adr2 len2 true )
v3    03e 2 byte-code: byte-load	     ( adr xt -- )
v3    03f 2 byte-code: set-args            ( arg-str unit-str -- )

\ --- parsing argument strings
v2    040 2 byte-code: left-parse-string ( adr len char -- adrR lenR adrL lenL )
