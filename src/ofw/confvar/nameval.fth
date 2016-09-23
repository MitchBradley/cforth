\ See license at end of file
purpose: "name=value" configuration variable encoding

\ Configuration variables are stored in the configuration area in
\ name=value\0 form.  Variables that are at their default values
\ are not stored, conserving NVRAM space (the default value is
\ stored in the dictionary entry).

headerless

\ This will be set later if the configuration variable area can be extended
defer cv-area       ( -- adr len )

\ Generic version that uses all of available NVRAM
: (cv-area)  ( -- adr len )  config-mem config-size  ;
' (cv-area) to cv-area

defer grow-cv-area  ( needed -- )      ' drop to grow-cv-area

\ Generic version that just looks for an obviously broken initial name
: (config-checksum?)  ( -- flag )
   cv-area drop  d# 32  bounds  ?do    ( )
      \ Good if we encounter '=' or \0 or ff before an unprintable character
      i c@  dup 0=  over [char] = =  or  swap h# ff = or  if  unloop  true exit  then
      \ Bad if we encounter an unprintable character before the first = or \0 or ff
      i c@  bl 1+  h# 7f within  0=  if  unloop false exit  then
   loop
   \ Bad if the first name is too long
   false
;
' (config-checksum?) to config-checksum?


: update-modified-adr  ( adr -- )  config-mem - update-modified-range  drop  ;

: another-ge-var?  ( adr len -- false | adr' len' value$ name$ true )
   dup 0=  if  2drop false exit  then         ( adr len )
   over c@ h# ff =  if  2drop false exit  then ( adr len )
   0  left-parse-string                       ( adr' len' var$ )
   dup 0=  if  4drop false  exit  then        ( adr' len' var$ )
   [char] = left-parse-string                 ( adr' len' value$ name$ )
   true
;
: find-ge-var  ( name$ -- true | rem$ value$ buf-name$ false )
   2>r
   cv-area
   begin  another-ge-var?  while                    ( rem$ value$ name$ )
      2dup 2r@ $=  if  2r> 2drop  false exit  then  ( rem$ value$ name$ )
      4drop                                         ( rem$ )
   repeat                                           ( rem$ )
   2r> 2drop true
;

: env-end  ( -- adr )  cv-area +  ;
: env-cleared  ( -- adr )
   cv-area dup 0=  if  + exit  then  ( adr len )

   0  -rot bounds 1+  swap  do     ( top-adr )
     drop i                        ( top-adr' )
     i 1- c@  if  leave  then      ( top-adr' )
   -1 +loop                        ( top-adr' )
;
: delete-ge-var  ( rem$ value$ buf-name$ -- )
   drop nip nip nip                 ( rem-adr name-adr )

   \ Set the low-water-mark
   dup update-modified-adr          ( rem-adr name-adr )

   \ Find the top of the active NVRAM area
   over  env-cleared umax           ( rem-adr name-adr top-adr )
   \ Set the high-water-mark
   dup update-modified-adr          ( rem-adr name-adr top-adr )

   \ Copy the high portion down (from rem to name size [top-rem]
   3dup   2 pick -  move            ( rem-adr name-adr top-adr )

   \ Clear the new piece at the top (from name+(top-rem) to top) 
   2 pick - over +                  ( rem-adr name-adr name+top-rem )
   -rot -                           ( name+top-rem rem-name )
   h# ff fill
;
: ?delete-ge-var  ( $name -- )
   find-ge-var  0=  if  delete-ge-var  then
;
: find-available  ( -- adr len )
   cv-area  begin              ( rem$ )
      dup  if                  ( rem$ )
         over c@ h# ff =  if   ( rem$ )
            exit
         then                  ( rem$ )
      then                     ( rem$ )
      0 left-parse-string      ( rem$ env$ )
   while  drop  repeat         ( rem$ adr )
   -rot  + over -                                   ( adr len )
;
: (cv-unused)  ( -- len )  find-available nip  ;
' (cv-unused) to cv-unused

: get-available  ( size -- adr fail? )
   >r  find-available r@ -  dup 0< if		( adr -need )
      nip negate grow-cv-area			( )
      find-available r@ u<			( adr fail? )
   else						( adr -need )
      drop false
   then
   r> drop
;
: add-ge-var  ( $value $name -- value-len | -1 )
   2 pick  over + 2+		  ( $value $name #bytes-needed )
   get-available  if		  ( $value $name nv-name-adr )
      5drop -1			  ( -1 )
   else		                  ( $value $name nv-name-adr )
      dup update-modified-adr	  ( $value $name nv-name-adr )
      >r			  ( $value $name )
      tuck r@ swap move		  ( $value name-len )
      r> +  [char] = over c!  1+  ( $value nv-value-adr )
      2dup 2>r  swap move  2r>	  ( value-len nv-value-adr )
      over +  0 over c!		  ( value-len terminator-adr )
      update-modified-adr	  ( value-len )
   then				  ( value-len | -1 )
;
: show-ge-area  ( -- )
   cv-area                                      ( rem$ )
   begin  another-ge-var?  while                ( rem$ value$ name$ )
      exit?  if  4drop 2drop exit  then         ( rem$ value$ name$ )
      2dup  $find-option  if                    ( rem$ value$ name$ xt )
         5drop                                  ( rem$ )
      else                                      ( rem$ value$ name$ )
         type value-column (type-entry) cr      ( rem$ )
      then                                      ( rem$ )
   repeat                                       ( )
;
' show-ge-area to show-extra-env-vars	\ Install in user interface

: show-ge-var  ( $name -- )
   2dup find-ge-var  if    ( $name )
   else                    ( name$ rem$ value$ buf-name$ )
      type value-column (type-entry) cr  4drop
   then
;
' show-ge-var to show-extra-env-var	\ Install in user interface

: clear-ge-vars  ( -- )
   cv-area h# ff fill
   \ The 1- is necessary because update-modified-adr refers to
   \ a byte that is touched, not the one just after it.
   cv-area bounds  update-modified-adr  1- update-modified-adr 
;
' clear-ge-vars  to erase-user-env-vars

: (put-ge-var)  ( value$ name$ -- len )
   config-rw 2dup ?delete-ge-var  add-ge-var  config-ro
   cv-update
;
' (put-ge-var) to put-env-var		\ Install in client interface

: put-ge-var  ( value$ name$ -- )
   (put-ge-var) -1 =  if  ." Out of NVRAM environment space" cr  then
;
' put-ge-var  to put-extra-env-var	\ Install in user interface

: ($unsetenv)  ( name$ -- )
   config-rw ?delete-ge-var config-ro  cv-update
;
' ($unsetenv) to $unsetenv

: next-ge-var  ( name$ -- name$' )
   dup  if                          ( name$ )            
      find-ge-var  if               ( )
         \ name$ does not refer to an extant user environment variable
         null$  exit
      else                          ( rem$ value$ name$ )
         \ name$ refers to an extant user environment variable; begin
         \ the search after it
         4drop                      ( rem$ )
      then                          ( rem$ )
   else                             ( name$ )
      \ name$ is null; start searching at the beginning of the GE area
      2drop  cv-area                ( rem$ )
   then                             ( rem$ )
 
   \ In the remainder of the GE area, search for a environment variable
   \ that is not one of the firmware-defined ones.

   begin  another-ge-var?  while    ( rem$ value$ name$ )
      2dup  $find-option  if        ( rem$ value$ name$ xt )
         5drop                      ( rem$ )
      else                          ( rem$ value$ name$ )
         2swap 2drop  2swap 2drop   ( name$ )
         exit
      then                          ( rem$ )
   repeat                           ( )
   null$
;
' next-ge-var to next-env-var		\ Install in client interface

: get-ge-var  ( $name -- true | value$ false )
   find-ge-var  if  true  exit  then   ( rem$ value$ name$ )
   2drop 2swap 2drop false
;
' get-ge-var to get-env-var		\ Install in client interface

headers
: clear-nvram  ( -- )
   config-rw
   0 update-modified-range drop  config-size update-modified-range drop
   config-mem config-size  h# ff fill
   set-mfg-defaults
   config-ro
   init-modified-range
   cv-update
;
' clear-nvram is reset-config

headerless
: read-ge-area  ( -- )
   cv-area                         ( rem$ )
   begin  another-ge-var?  while   ( rem$ value$ name$ )
      $find-option  if             ( rem$ value$ xt )
         nip >body 'cv-adr !       ( rem$ )
      else                         ( rem$ value$ )
         2drop                     ( rem$ )
      then                         ( rem$ )
   repeat                          ( )
;
stand-init: 
   ['] read-ge-area to cv-update
;

: put-env$  ( val$ apf default-value? -- )
   config-rw

   \ Invalidate the old value pointer.  It might seem that this should
   \ be done inside the "default-value" branch of the test below, but
   \ that would not work in the case where the attempt to add the new
   \ value failed due to lack of space.
   over 0 swap 'cv-adr !            ( val$ apf )

   over body> >name name>string  2>r ( val$ apf default? )  ( r: name$ )

   if                                ( val$ apf )  ( r: name$ )
      \ If the value to set is the same as the default value,
      \ we just delete the old value if there is one.
      3drop  2r> $unsetenv           ( )
   else                              ( val$ apf )  ( r: name$ )
      \ Otherwise we delete the old value if there is one,
      \ and add the new value.
      drop  2r> put-ge-var           ( )
   then                              ( )

   config-ro
;

: init-options  ( -- )
   ['] options  follow
   begin  another?  while
      name> >body  dup cv?  if  0 swap 'cv-adr !  else  drop  then
   repeat
   read-ge-area
;

: >cv$  ( cv-adr -- cv-adr cv-len )
   dup  begin                              ( cv-adr adr )
      dup c@  dup 0<>  swap h# ff <> and   ( cv-adr adr more? )
   while                                   ( cv-adr adr )
      1+                                   ( cv-adr adr' )
   repeat                                  ( cv-adr adr )
   over -    ( cv-adr cv-len )
;

: (cv-flag@)  ( apf -- flag )  cv-adr  if  >cv$ $>flag  else  @ 0<>  then  ;
: (cv-flag!)  ( flag apf -- )  2dup default-value? 2>r flag>$ 2r> put-env$  ;

: (cv-int@)  ( apf -- n )  cv-adr  if  >cv$ $>number  else  @  then  ;
: (cv-int!)  ( n apf -- )  2dup default-value? 2>r (.d)   2r> put-env$  ;

\ It uses three forms for the data: values in binary, strings in ASCII, 
\ and a packed binary form in NVRAM. The packed form eliminates nulls and
\ FFs in the array by using FE as an escape: the next character represents
\ 1..3F nulls (if msbs are 00) or FEs (if msbs are 01) or FF (if msbs are 10).

h# ffe constant /pack-buf
/pack-buf 2+ buffer: pack-buf
0 value pntr
: #consecutive  ( lastadr adr b -- n )
   -rot                            ( b lastadr adr )
   tuck -  h# 3f min               ( b adr maxn )
   -rot  2 pick  0  do	           ( maxn b adr )
      2dup i ca+ c@ <> if	   ( maxn b adr )
	 3drop i unloop exit       ( n )
      then                         ( maxn b adr )
   loop                            ( maxn b adr )
   2drop                           ( maxn )
;
: pack-byte  ( b -- full? )
   pack-buf pntr ca+ c!
   pntr 1+ to pntr
   /pack-buf pntr u<=
;
: pack-env   ( adr len -- adr' len' )	\ Binary to packed
   0 to pntr   bounds ?do		( )
      i c@  case                        ( c: char )
         0 of    			( )
            h# fe pack-byte ?leave     	( )
	    ilimit i 0 #consecutive    	( step )
            dup                         ( step code )
         endof				( step code )
         h# fe  of 			( )
            h# fe pack-byte ?leave	( )
	    ilimit i h# fe #consecutive ( step )
            dup h# 40 or                ( step code )
         endof				( step code )
	 h# ff  of			( )
            h# fe pack-byte ?leave	( )
	    ilimit i h# ff #consecutive ( step )
            dup h# 80 or		( step code )
	 endof				( step code )
         ( default )  1 swap dup        ( step char char )
      endcase				( step code|char )
      pack-byte ?leave   		( step )
   +loop                                ( )
   pack-buf pntr                        ( adr len )
;
0 value unpack-buf
0 value /unpack-buf
: not-packed?  ( adr len -- flag )
   dup false                                   ( adr len  len packed? )
   2swap  bounds  ?do                          ( ulen packed? )
      i c@  h# fe =  if                        ( ulen packed? )
         drop  2-               \ fe and next  ( ulen' )
         i 1+ c@ h# 3f and  +   \ #inserted    ( ulen' )
         true 2                                ( ulen packed? advance )
      else                                     ( ulen packed? )
         1                                     ( ulen packed? advance )
      then                                     ( ulen advance )
   +loop                                       ( ulen packed? )
   if                                          ( ulen )
      dup to /unpack-buf                       ( ulen )
      alloc-mem to unpack-buf                  ( )
      false                                    ( false )
   else                                        ( ulen )
      drop true                                ( true )
   then                                        ( flag )
;

: unpack-env   ( adr len -- adr' len' )	\ Packed to binary
   2dup not-packed?  if  exit  then     ( adr len )
   0 to pntr   bounds ?do	        ( )
      /unpack-buf pntr u<= ?leave
      1  i c@ dup h# fe =  if		( 1 c )
	 2drop  2  i 1+ c@		( 2 n' )
	 dup h# 3f and >r		( 2 n' )

         6 rshift			( 2 index )
         " "(00 fe ff ff)" drop + c@	( 2 c' )

	 unpack-buf pntr ca+		( 2 c' a )
	 r@ /unpack-buf pntr - min	( 2 c' a len )
	 rot fill			( 2 )
	 r> pntr + to pntr		( 2 )
      else				( 1 c )
	 unpack-buf pntr ca+ c!		( 1 )
	 pntr 1+ to pntr		( 1 )
      then				( step )
   +loop                                ( )
   unpack-buf  pntr                     ( adr len )
;

: (cv-bytes@)  ( apf -- adr len )
   cv-adr  if				( nvram-adr )
      >cv$ unpack-env                   ( adr len )
   else					( dictionary-adr )
      dup @ swap la1+ taligned swap	( adr len )
   then
;
: (cv-bytes!)  ( adr len apf -- )
   3dup $default-value?  if		( adr len )
      true put-env$                     ( )
   else                                 ( adr len apf )
      >r                                ( adr len )
      pack-env                          ( adr' len' )
      r> false put-env$                 ( )
   then                                 ( )
;

: (cv-string@)  ( apf -- adr len )  cv-adr  if  >cv$ unpack-env  else  rel@ cscount  then  ;
: (cv-string!)  ( adr len apf -- )  (cv-bytes!)  ;

' (cv-flag@)   to cv-flag@
' (cv-flag!)   to cv-flag!
' (cv-int@)    to cv-int@
' (cv-int!)    to cv-int!
' (cv-string@) to cv-string@
' (cv-string!) to cv-string!
' (cv-bytes@)  to cv-bytes@
' (cv-bytes!)  to cv-bytes!

headers
: init-config-vars  ( -- )
   init-nvram-buffer  init-options  init-security
;
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
