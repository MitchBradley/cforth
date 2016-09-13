\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: primlist.fth
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
purpose: FCode token number definitions for primitive (1-byte) FCodes
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

\ === Bootprom tokens (see also sysprims.fth) ============================
\
\ Notes: 1)  This table is in numerical order.
\
\        2)  Syntax for FCode definitions:
\                 ______________________________________
\            a)  |  v1 v2  nnn n  byte-code: <name> ...
\                   * Version 1 FCodes carried forward into version 2.
\                 ______________________________________
\            b)  |  v1     nnn n  byte-code: <name> ...
\                   * Obsoleted version 1 fcodes (generate a warning
\                     message when found by the version 2 tokenizer).
\                 ______________________________________
\            c)  |     v2  nnn n  byte-code: <name> ...
\                   * FCodes new to version 2 (didn't exist in version 1).
\                 ______________________________________
\            d)  |\        nnn n
\                   * FCodes never allocated.
\                 ______________________________________
\            e)  |\ v1     nnn n  byte-code: <name> ...
\                   * FCodes intended for version 1 but never released
\                     with version 1 (commented out of version 1 source).
\                 ______________________________________
\            f)  |\ v1 v2  nnn n  byte-code: <name> ...
\                   * Reserved FCodes.
\
\
\        3)  The above syntax allows us to keep obsoleted words, but at
\            the same time to alert s-bus developer as to their obsolence.
\
\        4)  While compling the boot prom "v1" and "v2" are defined as
\            noops so backward compatiblity can be achieved with either
\            a or b above.
\
\
\ ========================================================================



\ === basic FCodes =======================================================

hex
v1 v2  000 0 byte-code: end0       ( -- )

\ v1 v2  001 0 byte-code: table1
\ v1 v2  002 0 byte-code: table2
\ v1 v2  003 0 byte-code: table3
\ v1 v2  004 0 byte-code: table4
\ v1 v2  005 0 byte-code: table5
\ v1 v2  006 0 byte-code: table6
\ v1 v2  007 0 byte-code: table7
\ v1 v2  008 0 byte-code: table8
\ v1 v2  009 0 byte-code: table9
\ v1 v2  00a 0 byte-code: table10
\ v1 v2  00b 0 byte-code: table11
\ v1 v2  00c 0 byte-code: table12
\ v1 v2  00d 0 byte-code: table13
\ v1 v2  00e 0 byte-code: table14
\ v1 v2  00f 0 byte-code: table15

v1 v2  010 0 byte-code: b(lit)     ( -- n )
v1 v2  011 0 byte-code: b(')       ( -- acf )
v1 v2  012 0 byte-code: b(")       ( -- adr len )
v1 v2  013 0 byte-code: bbranch    ( -- )
v1 v2  014 0 byte-code: b?branch   ( -- )
v1 v2  015 0 byte-code: b(loop)    ( -- )
v1 v2  016 0 byte-code: b(+loop)   ( n -- )
v1 v2  017 0 byte-code: b(do)      ( end start -- )
v1 v2  018 0 byte-code: b(?do)     ( end start -- )
v1 v2  019 0 byte-code: i          ( -- index )
v1 v2  01a 0 byte-code: j          ( -- outerindex )
v1 v2  01b 0 byte-code: b(leave)   ( -- )
v1 v2  01c 0 byte-code: b(of)      ( sel tstval - sel|none ) \ then offset.

v1 v2  01d 0 byte-code: execute    ( acf -- )

v1 v2  01e 0 byte-code: +          ( n1 n2 -- n3 )
v1 v2  01f 0 byte-code: -          ( n1 n2 -- n3)
v1 v2  020 0 byte-code: *          ( n1 n2 -- n3)
v1 v2  021 0 byte-code: /          ( n1 n2 -- n3)
v1 v2  022 0 byte-code: mod        ( n1 n2 -- n3)
v1 v2  023 0 byte-code: and        ( n1 n2 -- n3)
v1 v2  024 0 byte-code: or         ( n1 n2 -- n3)
v1 v2  025 0 byte-code: xor        ( n1 n2 -- n3)
v1 v2  026 0 byte-code: invert     ( n1 -- n2 )		\ Was not
v1 v2  027 0 byte-code: lshift     ( n1 cnt -- n2 )	\ Was <<
v1 v2  028 0 byte-code: rshift     ( n1 cnt -- n2 )	\ Was >>
v1 v2  029 0 byte-code: >>a        ( n1 cnt -- n2 )
v1 v2  02a 0 byte-code: /mod       ( n1 n2 -- rem quot )
v1 v2  02b 0 byte-code: u/mod      ( n1 n2 -- rem quot )
v1 v2  02c 0 byte-code: negate     ( n1 -- n2 )

v1 v2  02d 0 byte-code: abs        ( n1 -- n2 )
v1 v2  02e 0 byte-code: min        ( n1 n2 -- n3 )
v1 v2  02f 0 byte-code: max        ( n1 n2 -- n3 )

v1 v2  030 0 byte-code: >r         ( n -- )  ( rs: -- n )
v1 v2  031 0 byte-code: r>         ( -- n )  ( rs: n -- )
v1 v2  032 0 byte-code: r@         ( -- n )  ( rs: -- )
v1 v2  033 0 byte-code: exit       ( -- )

v1 v2  034 0 byte-code: 0=         ( n -- flag )
v1 v2  035 0 byte-code: 0<>        ( n -- flag )
v1 v2  036 0 byte-code: 0<         ( n -- flag )
v1 v2  037 0 byte-code: 0<=        ( n -- flag )
v1 v2  038 0 byte-code: 0>         ( n -- flag )
v1 v2  039 0 byte-code: 0>=        ( n -- flag )
v1 v2  03a 0 byte-code: <          ( n1 n2 -- flag )
v1 v2  03b 0 byte-code: >          ( n1 n2 -- flag )
v1 v2  03c 0 byte-code: =          ( n1 n2 -- flag )
v1 v2  03d 0 byte-code: <>         ( n1 n2 -- flag )
v1 v2  03e 0 byte-code: u>         ( n1 n2 -- flag )
v1 v2  03f 0 byte-code: u<=        ( n1 n2 -- flag )
v1 v2  040 0 byte-code: u<         ( n1 n2 -- flag )
v1 v2  041 0 byte-code: u>=        ( n1 n2 -- flag )
v1 v2  042 0 byte-code: >=         ( n1 n2 -- flag )
v1 v2  043 0 byte-code: <=         ( n1 n2 -- flag )
v1 v2  044 0 byte-code: between    ( n min max -- flag )
v1 v2  045 0 byte-code: within     ( n min max -- flag )

v1 v2  046 0 byte-code: drop       ( n -- )
v1 v2  047 0 byte-code: dup        ( n -- n n )
v1 v2  048 0 byte-code: over       ( n1 n2 -- n1 n2 n1 )
v1 v2  049 0 byte-code: swap       ( n1 n2 -- n2 n1 )
v1 v2  04a 0 byte-code: rot        ( n1 n2 n3 -- n2 n3 n1 )
v1 v2  04b 0 byte-code: -rot       ( n1 n2 n3 -- n3 n1 n2 )
v1 v2  04c 0 byte-code: tuck       ( n1 n2 -- n2 n1 n2 )
v1 v2  04d 0 byte-code: nip        ( n1 n2 -- n2 )
v1 v2  04e 0 byte-code: pick       ( +n -- n2 )
v1 v2  04f 0 byte-code: roll       ( +n -- )
v1 v2  050 0 byte-code: ?dup       ( n -- n | n n )
v1 v2  051 0 byte-code: depth      ( -- +n )

v1 v2  052 0 byte-code: 2drop      ( n1 n2 -- )
v1 v2  053 0 byte-code: 2dup       ( n1 n2 -- n1 n2 n1 n2 )
v1 v2  054 0 byte-code: 2over      ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 )
v1 v2  055 0 byte-code: 2swap      ( n1 n2 n3 n4 -- n3 n4 n1 n2 )
v1 v2  056 0 byte-code: 2rot       ( n1 n2 n3 n4 n5 n6 -- n3 n4 n5 n6 n1 n2 )

v1 v2  057 0 byte-code: 2/         ( n1 -- n2 )
v1 v2  058 0 byte-code: u2/        ( n1 -- n2 )
v1 v2  059 0 byte-code: 2*         ( n1 -- n2 )

v1 v2  05a 0 byte-code: /c         ( -- n )
v1 v2  05b 0 byte-code: /w         ( -- n )
v1 v2  05c 0 byte-code: /l         ( -- n )
v1 v2  05d 0 byte-code: /n         ( -- n )
v1 v2  05e 0 byte-code: ca+        ( n1 index -- n2 )
v1 v2  05f 0 byte-code: wa+        ( n1 index -- n2 )
v1 v2  060 0 byte-code: la+        ( n1 index -- n2 )
v1 v2  061 0 byte-code: na+        ( n1 index -- n2 )
v1 v2  062 0 byte-code: char+      ( n1 -- n2 )		\ Was ca1+
v1 v2  063 0 byte-code: wa1+       ( n1 -- n2 )
v1 v2  064 0 byte-code: la1+       ( n1 -- n2 )
v1 v2  065 0 byte-code: cell+      ( n1 -- n2 )		\ Was na1+
v1 v2  066 0 byte-code: chars      ( n1 -- n2 )		\ Was /c*
v1 v2  067 0 byte-code: /w*        ( n1 -- n2 )
v1 v2  068 0 byte-code: /l*        ( n1 -- n2 )
v1 v2  069 0 byte-code: cells      ( n1 -- n2 )		\ Was /n*

v1 v2  06a 0 byte-code: on         ( adr -- )
v1 v2  06b 0 byte-code: off        ( adr -- )
v1 v2  06c 0 byte-code: +!         ( n adr -- )
v1 v2  06d 0 byte-code: @          ( adr -- n )
v1 v2  06e 0 byte-code: l@         ( adr -- L )
v1 v2  06f 0 byte-code: w@         ( adr -- w )
v1 v2  070 0 byte-code: <w@        ( adr -- w )
v1 v2  071 0 byte-code: c@         ( adr -- b )
v1 v2  072 0 byte-code: !          ( n adr -- )
v1 v2  073 0 byte-code: l!         ( n adr -- )
v1 v2  074 0 byte-code: w!         ( n adr -- )
v1 v2  075 0 byte-code: c!         ( n adr -- )
v1 v2  076 0 byte-code: 2@         ( adr -- n1 n2 )
v1 v2  077 0 byte-code: 2!         ( n1 n2 adr -- )

v1 v2  078 0 byte-code: move       ( adr1 adr2 cnt -- )
v1 v2  079 0 byte-code: fill       ( adr cnt byte -- )
v1 v2  07a 0 byte-code: comp       ( adr1 adr2 cnt -- n )
v1 v2  07b 0 byte-code: noop       ( -- )

v1 v2  07c 0 byte-code: lwsplit    ( L -- w.lo w.hi )
v1 v2  07d 0 byte-code: wljoin     ( w.lo w.hi -- L )
v1 v2  07e 0 byte-code: lbsplit    ( L -- b.lo b b b.hi )
v1 v2  07f 0 byte-code: bljoin     ( b.lo b b b.hi -- L )
v1 v2  080 0 byte-code: wbflip     ( w1 -- w2 )		\ Was flip

v1 v2  081 0 byte-code: upc        ( char -- upper-case-char )
v1 v2  082 0 byte-code: lcc        ( char -- lower-case-char )
v1 v2  083 0 byte-code: pack       ( adr len pstr -- pstr )
v1 v2  084 0 byte-code: count      ( pstr -- adr len )

v1 v2  085 0 byte-code: body>      ( apf -- acf )
v1 v2  086 0 byte-code: >body      ( acf -- apf )

v1 v2  087 0 byte-code: fcode-revision  ( -- n )  \ Was version

v1 v2  088 0 byte-code: span       ( -- adr )

v3     089 0 byte-code: unloop     ( -- )

v1 v2  08a 0 byte-code: expect     ( adr +n -- )

v1 v2  08b 0 byte-code: alloc-mem  ( cnt -- adr )
v1 v2  08c 0 byte-code: free-mem   ( adr cnt -- )

v1 v2  08d 0 byte-code: key?       ( -- flag )
v1 v2  08e 0 byte-code: key        ( -- char )
v1 v2  08f 0 byte-code: emit       ( char -- )
v1 v2  090 0 byte-code: type       ( adr +n -- )

v1 v2  091 0 byte-code: (cr        ( -- )
v1 v2  092 0 byte-code: cr         ( -- )
v1 v2  093 0 byte-code: #out       ( -- adr )
v1 v2  094 0 byte-code: #line      ( -- adr )

v1 v2  095 0 byte-code: hold       ( char -- )
v1 v2  096 0 byte-code: <#         ( -- )
v1 v2  097 0 byte-code: u#>        ( L -- adr +n )	\ Was #>
v1 v2  098 0 byte-code: sign       ( n -- )
v1 v2  099 0 byte-code: u#         ( +L1 -- +L2 )	\ Was #
v1 v2  09a 0 byte-code: u#s        ( +L -- 0 )		\ Was #s
v1 v2  09b 0 byte-code: u.         ( u -- )
v1 v2  09c 0 byte-code: u.r        ( u cnt -- )
v1 v2  09d 0 byte-code: .          ( n -- )
v1 v2  09e 0 byte-code: .r         ( n cnt -- )
v1 v2  09f 0 byte-code: .s         ( -- )
v1 v2  0a0 0 byte-code: base       ( -- adr )

\ v1     0a1 0 byte-code: convert       \ -- removed for brevity

   v2  0a2 0 byte-code: $number    ( adr len -- n false | true )

v1 v2  0a3 0 byte-code: digit      ( char base -- digit true | char false )

v1 v2  0a4 0 byte-code: -1         ( -- -1 )
v1 v2  0a5 0 byte-code: 0          ( -- 0 )
v1 v2  0a6 0 byte-code: 1          ( -- 1 )
v1 v2  0a7 0 byte-code: 2          ( -- 2 )
v1 v2  0a8 0 byte-code: 3          ( -- 3 )
v1 v2  0a9 0 byte-code: bl         ( -- n )
v1 v2  0aa 0 byte-code: bs         ( -- n )
v1 v2  0ab 0 byte-code: bell       ( -- n )

v1 v2  0ac 0 byte-code: bounds     ( n cnt -- n+cnt n )
v1 v2  0ad 0 byte-code: here       ( -- adr )
v1 v2  0ae 0 byte-code: aligned    ( adr1 -- adr2 )

v1 v2  0af 0 byte-code: wbsplit    ( w -- b.lo b.hi )
v1 v2  0b0 0 byte-code: bwjoin     ( b.lo b.hi -- w )

v1 v2  0b1 0 byte-code: b(<mark)
v1 v2  0b2 0 byte-code: b(>resolve)

\ v1     0b3 0 byte-code: set-token  ( offset token#   table# -- )
\ v1     0b4 0 byte-code: set-table  ( offset #entries table# -- )

v1 v2  0b5 0 byte-code: new-token     \ then table#, code#, token-type
v1 v2  0b6 0 byte-code: named-token   \ then string, table#, code#, token-type

v1 v2  0b7 0 byte-code: b(:)       ( -- )
v1 v2  0b8 0 byte-code: b(value)   ( -- )
v1 v2  0b9 0 byte-code: b(variable) ( -- )
v1 v2  0ba 0 byte-code: b(constant) ( -- )
v1 v2  0bb 0 byte-code: b(create)  ( -- )
v1 v2  0bc 0 byte-code: b(defer)   ( -- )
v1 v2  0bd 0 byte-code: b(buffer:) ( -- )
v1 v2  0be 0 byte-code: b(field)   ( -- )
\   v2  0bf 0 byte-code: b(code)    ( -- )                   \ version 2 token

v2.1   0c0 0 byte-code: instance   ( -- )     \ 2.1

\   0c1 0

v1 v2  0c2 0 byte-code: b(;)       ( -- )

v1 v2  0c3 0 byte-code: b(to)      ( acf -- )	\ Was b(is)
v1 v2  0c4 0 byte-code: b(case)    ( selector -- selector )
v1 v2  0c5 0 byte-code: b(endcase) ( selector -- )
v1 v2  0c6 0 byte-code: b(endof)   ( -- )

v3     0c7 0 byte-code: #	   ( ud1 -- ud2 )
v3     0c8 0 byte-code: #s         ( ud1 -- 0 0 )
v3     0c9 0 byte-code: #>	   ( ud -- adr len )

   v2  0ca 0 byte-code: external-token        ( -- )

v1 v2  0cb 0 byte-code: $find      ( adr len -- adr len false  |  acf +-1 )
v1 v2  0cc 0 byte-code: offset16   \ Sets the offset length to 16 bits

   v2  0cd 0 byte-code: evaluate   ( adr len -- )	\ Was eval

\      0ce 0
\      0cf 0

v1 v2  0d0 0 byte-code: c,         ( n -- )
v1 v2  0d1 0 byte-code: w,         ( n -- )
v1 v2  0d2 0 byte-code: l,         ( n -- )
v1 v2  0d3 0 byte-code:  ,         ( n -- )

   v2  0d4 0 byte-code: um*        ( u1 u2 -- ud ) \ Was u*x
   v2  0d5 0 byte-code: um/mod     ( ud1 u2 -- u.rem u.quot )	\ Was xu/mod
\      0d6 0
\      0d7 0

   v2  0d8 0 byte-code: d+         ( d1 d2 -- d3 )  \ Was x+
   v2  0d9 0 byte-code: d-         ( d1 d2 -- d3 )  \ Was x-

v3     0da 0 byte-code: get-token  ( fcode# -- xt immediate? )
v3     0db 0 byte-code: set-token  ( xt immediate? fcode# -- )
v3     0dc 0 byte-code: state      ( -- adr )
v3     0dd 0 byte-code: compile,   ( xt -- )
v3     0de 0 byte-code: behavior   ( xt1 -- xt2 )
\      0df 0

   v2  0f0 0 byte-code: start0     ( -- )                   \ version 2 token
   v2  0f1 0 byte-code: start1     ( -- )                   \ version 2 token
   v2  0f2 0 byte-code: start2     ( -- )                   \ version 2 token
   v2  0f3 0 byte-code: start4     ( -- )                   \ version 2 token

\      0f4 0
\      0f5 0
\      0f6 0
\      0f7 0
\      0f8 0
\      0f9 0
\      0fa 0
\      0fb 0
v2.3   0fc 0 byte-code: ferror

v1 v2  0fd 0 byte-code: version1   \ then 0byte,chksum(2bytes),length(4bytes)
\ v1     0fe 0 byte-code: 4-byte-id  \ then 3 more bytes

v1 v2  0ff 0 byte-code: end1
