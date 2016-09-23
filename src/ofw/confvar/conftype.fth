\ See license at end of file
purpose: Configuration option data types and encoding

\ Maintenance of configuration parameters in non-volatile storage.
\ The PR*P and CHRP bindings require specific storage formats in NVRAM.

\ Configuration items are stored in the dictionary as follows:
\   	header
\   	acf  - Points to "action" data structure.  1 token
\ (apf) offset - Byte offset of data in user area.
\		High bit set indicates a "no-default"-type item
\		For integer-valued and enumerated data types, the
\		user area location contains the data.  For string and
\		byte array data types, two user area locations contain
\		the address and length of the data.
\	default - Holds default data (unless "no-default" type).  For
\		integer-valued and enumerated data types, the default
\		value is stored here as one cell.  For string and byte
\		array data types, the length is stored as a cell, followed
\		by the data bytes.

\ config object actions:	 ( value format depends on type of object )
\ 0 get  ( acf -- value )
\ 1 set  ( value acf -- )
\ 2 addr ( acf -- adr )
\ 3 decode  ( value acf -- adr len )		    value to ASCII
\ 4 encode  ( adr len acf -- true | value false )   ASCII to value
\ 5 get-default  ( acf -- value )

headerless

\ Interface to the low-level storage mechanism/format for config variables

\ Called when the config variable cache, if any, needs to be updated
defer cv-update    ( -- )               ' noop       to cv-update

defer cv-unused    ( -- #bytes )

\ Read and write primitive configuration data types
defer cv-flag@     ( apf -- flag )
defer cv-flag!     ( flag apf -- )
defer cv-int@      ( apf -- n )
defer cv-int!      ( n apf -- )
defer cv-string@   ( apf -- adr len )
defer cv-string!   ( adr len apf -- )
defer cv-bytes@    ( apf -- adr len )
defer cv-bytes!    ( adr len apf -- )
defer cv-secmode@  ( apf -- n )         ' cv-int@    to cv-secmode@
defer cv-secmode!  ( n apf -- )         ' cv-int!    to cv-secmode!
defer cv-password@ ( apf -- adr len )   ' cv-string@ to cv-password@
defer cv-password! ( adr len apf -- )   ' cv-string! to cv-password!


: nodefault  ( -- )  lastacf >body  dup  l@  h# 80000000 or  swap l!  ;
: (nodefault?)  ( apf -- flag )  l@  h# 80000000 and  0<>  ;
' (nodefault?) to nodefault?

: $default-value?  ( val$ apf -- default? )
   dup nodefault?  if  drop nip 0=   else  body> get-default  $=  then
;
: default-value?  ( n apf -- default? )
   dup nodefault?  if  2drop false  else  body> get-default  =  then
;

\ bad-number already defined in finddev.fth
\ create bad-number ," Bad number syntax"

: $>flag  ( adr len -- flag )  -null " true" $=  ;
: flag>$  ( flag -- adr len )  if  " true"(00)"  else  " false"(00)"  then  ;

: 'cv-adr  ( apf -- adr )  l@ h# c0000000 invert and up@ +  ;
: cv?  ( apf -- flag )  l@ h# 40000000 and  0<>  ;

: cv-adr  ( apf -- adr overridden? )
   dup 'cv-adr @  dup  if  nip true  else  drop la1+ false  then
;

: create-option  ( "name" -- )
   headerless? dup >r  if  headers  then
   also options definitions  create  previous definitions
   r>  if  headerless  then
;
: config-create  ( "name" -- ua-offset )
   create-option
   0  /n ualloc dup h# 4000.0000 or  l, up@ +  !
;

headers
6 actions
action: ( apf -- flag )  cv-flag@  ;
action: ( flag apf -- )  cv-flag!  ;
action: ( apf -- adr )  cv-adr drop  ;
action: ( flag apf -- adr len )  drop flag>$  ;
action: ( adr len apf -- flag )  drop $>flag  ;
action: ( apf -- flag )   la1+ @ 0<>  ;

: config-flag  ( "name" default-value -- )  config-create use-actions  ,  ;

false config-flag diag-switch?
' diag-switch? is (diagnostic-mode?)

headerless
: (.d)  ( n -- adr len )
   base @ >r  decimal  <# 0 hold u#s u#>  r> base !
;
: ?base  ( adr len -- adr' len' )
   dup 2 >  if                     ( adr len )
      over c@ ascii 0  =  if       ( adr len )
         over 1+ c@ ascii x =  if  ( adr len )
	    hex  2 /string         ( adr+2 len-2 )
	 else                      ( adr len )
            octal  1 /string       ( adr+1 len-1 )
         then                      ( adr' len' )
      then                         ( adr' len' )
   then                            ( adr' len' )
;
: $>number  ( adr len -- n )
   -null                        ( adr,len' )
   base @ >r  decimal           ( adr,len )   ( r: base )
   ?base  -trailing -leading    ( adr',len' ) ( r: base )
   $number  r> base !  if       (  )
      bad-number throw          (  )
   then                         ( n )
;

headers
: set-config-int-default  ( n xt -- )  >body na1+ unaligned-!  ;

6 actions
action: ( apf -- n )  cv-int@  ;
action: ( n apf -- )  cv-int!  ;
action: ( apf -- adr )  cv-adr drop  ;
action: ( n apf -- adr len )  drop (.d)  ;
action: ( adr len apf -- n )  drop $>number  ;
action: ( apf -- n )  na1+ @  ;

: config-int  ( "name" default-value -- )  config-create use-actions   ,  ;
: nodefault-int  ( "name" -- )  0 config-int nodefault  ;

: ,cstr  ( $ -- adr )
   here  over 1+ taligned note-string  allot  ( $ new-adr )
   place-cstr                                 ( adr )
;

: rel!  ( adr1 adr2 -- )  tuck - swap unaligned-!  ;
: rel@  ( adr2 -- adr1 )  dup unaligned-@ +  ;

6 actions
action: ( apf -- adr len )  cv-string@  ;
action: ( adr len apf -- )  cv-string!  ;
action: ( apf -- adr )  cv-adr drop ;
action: ( adr len apf -- adr len )  drop $cstr cscount 1+  ;
action: ( adr len apf -- adr len )  drop -null  ;
action: ( apf -- adr len )  la1+ rel@ cscount  ;

\ This implementation of config-string ignores maxlen, using data representations
\ that do not require specifying a maximum length.
: config-string  ( "name" default-value$ maxlen -- )
   config-create use-actions  ( default-value$ maxlen )
   drop                       ( default-value$ )
   here >r  /n allot          ( default-value$ r: where )  \ Place location of def$
   ,cstr r> rel!              ( )
;
: nodefault-string  ( "name" maxlen -- )  0 0  swap config-string nodefault  ;

: set-config-string-default  ( new-default$ xt -- )
   >body la1+ >r             ( new-default$ r: ptr-adr )
   ,cstr r> rel!             ( )
;

6 actions
action: ( apf -- adr len )  cv-bytes@  ;
action: ( adr len apf -- )  cv-bytes!  ;
action: ( apf -- adr )  cv-adr drop ;
action: ( adr len apf -- adr len )  drop  ;
action: ( adr len apf -- adr len )  drop  ;
action: ( apf -- adr len )   la1+ dup la1+ swap @  ;

\ e.g. keymap
: config-bytes  ( "name" default-value-adr len maxlen -- )
   config-create use-actions  drop             ( adr len )
   dup ,
   dup taligned  here swap note-string  allot  ( adr len here )
   swap move
;

\ e.g. oem-logo
\ : nodefault-bytes  ( "name" maxlen -- )  0 0 swap config-bytes  nodefault  ;
: nodefault-bytes  ( "name" maxlen -- )  
   0 0 rot config-bytes  
   nodefault
   cv-update
;

\ Define a configuration variable for security with the following values:
\   0  =  "none"
\   1  =  "command"
\   2  =  "full"

create invalid-value  ," Invalid value for configuration parameter"

6 actions	\ the sixth action might not be needed, due to no default
action:  ( apf -- n )  cv-secmode@  ;
action:  ( n apf -- )  cv-secmode!  ;
action:  ( apf -- adr )  ;
action:  ( n apf -- adr len )
   drop
   case
      1  of  " command"(00)"  endof
      2  of  " full"(00)"     endof
             " none"(00)"     rot
   endcase
;
action:  ( adr len apf -- n )
   drop  -null
   2dup  " full"    $=  if  2drop 2  exit    then
   2dup  " command" $=  if  2drop 1  exit    then
         " none"    $=  if  0        exit    then
   invalid-value throw
;
action:  ( apf -- n )   drop  0  ;

headers
config-create security-mode  use-actions  0 ,  nodefault

0 nodefault-int security-#badlogins


defer system$    ' null$ to system$
: encode-pw   ( password$ -- digest$ )  system$ $md5digest2  ;

6 actions
action:  ( apf -- adr len )  cv-password@  ;
action:  ( adr len apf -- )  cv-password!  ;
action:  ( apf -- adr )  ;
action:  ( adr len apf -- adr len )  3drop  0 0  ;
action:  ( adr len apf -- adr len )  drop encode-pw  ;
action:  ( apf -- adr len )  drop  0 0   ;

config-create security-password   use-actions  0 ,  nodefault

headerless

\ true if command or full security
: security-on?  ( -- flag )  security-mode 1 2 between  ;

d# 14 constant max-password
max-password buffer: pwbuf0
max-password buffer: pwbuf1

: legal-passwd-char?   ( char -- flag )  bl  h# 7e  between  ;
: get-password  ( adr -- adr len )
   0  begin                    ( adr len )
      key dup  linefeed <>  over carret <>  and
   while                       ( adr len char )
      2dup  legal-passwd-char?  swap max-password <  and  if  ( adr len char )
         >r 2dup + r> swap c!  ( adr len )
         1+                    ( adr len )
      else                     ( adr len char )
         drop beep             ( adr len )
      then                     ( adr len )
   repeat                      ( adr len char )
   drop   cr
;

: password-okay?  ( -- good-pw? )
   security-on? 0= if  true exit  then
   
   ??cr ." Firmware Password: "
   pwbuf0 get-password encode-pw			( digest$ )
   security-password compare 0=  if  true exit  then	( )
   
   ." Sorry.  Waiting 10 seconds." cr
   security-#badlogins 1+ to security-#badlogins
   lock[  d# 10.000 ms  ]unlock
   false
;

headers
: password  ( -- )
   ." New password ("  max-password .d  ." characters max) "   
   pwbuf0 get-password					( adr len )
   ." Retype new password: "    pwbuf1 get-password	( adr len adr len )

   2over $= if			  	( adr len )
      ['] security-password encode	( true | adr len false )
      if
         ." Invalid string - password unchanged" cr
      else
	 ['] security-password set	( )
      then
   else
      2drop				( )
      ." Mismatch - password unchanged" cr
   then
;

headerless
: (?permitted)  ( adr len -- adr len )
   source-id  if  exit  then	\ Apply security only to interaction
   2dup  " go"   $=  if  exit  then
   2dup  " boot" $=  if  exit  then
   password-okay? 0=  abort" "
;
: secure  ( -- )
   ['] (?permitted) is ?permitted
   [ also hidden ]  ['] security-on? is deny-history?  [ previous ]
;
: unsecure  ( -- )
   ['] noop is ?permitted
   [ also hidden ]  ['] false is deny-history?  [ previous ]
;
: init-security  ( -- )
   security-on?  if  secure  else  unsecure  then
;
headers


[ifdef] v2-compat
" /openprom" find-device
   \ Bug ID 1120271 NVRAM decode bug
   \ Indicates the presence of the fix for the
   \ 'decode' action of the NVRAM parameters
   0 0 " decode-complete" property
device-end
[then]
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
