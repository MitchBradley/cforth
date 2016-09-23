\ See license at end of file
purpose: Write-through RAM cache for firmware NVRAM area

\ A write-through copy of NVRAM is maintained in RAM. Only modified 
\ areas are rewritten. Actual access is handled by the /nvram node.

0 value nvram-node  ' nvram-node  " nvram"  chosen-value

headerless

\ These can be set later to system-specific values
false value config-valid?
defer layout-config     ' noop to layout-config
defer reset-config      ' noop to reset-config
defer config-checksum?  ' noop to config-checksum?


0 value config-size
0 value config-mem

0 value min-modified
0 value max-modified

: init-modified-range  ( -- )
   0 to max-modified  config-size to min-modified
;
: modified-range  ( -- min len )  min-modified max-modified 1+ over -  0 max  ;

: update-modified-range  ( offset -- offset )
   dup min-modified min  to min-modified
   dup max-modified max  to max-modified
;

\ note: words are stored big-endian.
: nvram-c@  ( offset -- c )  config-mem +  c@  ;
: nvram-w@  ( offset -- w )  dup ca1+ nvram-c@  swap nvram-c@  bwjoin  ;
: nvram-l@  ( offset -- l )  dup wa1+ nvram-w@  swap nvram-w@  wljoin  ;

: nvram-c!  ( c offset -- )  update-modified-range  config-mem +  c!  ;
: nvram-w!  ( w offset -- )  >r wbsplit r@ nvram-c!  r> ca1+ nvram-c!  ;
: nvram-l!  ( l offset -- )  >r lwsplit r@ nvram-w!  r> wa1+ nvram-w!  ;

: write-range  ( min len -- )
   dup  if   ( min len )
      over 0  " seek" nvram-node $call-method drop  ( min len )
      swap config-mem +  swap  " write" nvram-node $call-method drop
   else
      2drop
   then
;
: write-modified  ( -- )
   modified-range  write-range
;

defer set-env-checksum  ' noop to set-env-checksum
variable config-level  
: (config-rw)  ( -- )  1 config-level +!  ;
' (config-rw) to config-rw
: (config-ro)  ( -- )
   -1 config-level +!
   config-level @ 0=  if
      write-modified
      set-env-checksum
      init-modified-range
   then
;
' (config-ro) to config-ro

: read-nvram  ( -- error? )
   init-modified-range
   0 0  " seek" nvram-node $call-method drop
   config-mem config-size  " read" nvram-node $call-method
   config-size <>
;

\ Call init-env-vars after opening the nvram node 
: init-nvram-buffer  ( -- )
   0 config-level !

   \ The "size" method returns a double number
   " size" nvram-node $call-method drop to config-size

   config-size alloc-mem to config-mem

   read-nvram  if
      ." Can't read the configuration memory" cr
      false
   else
      config-checksum?  if
         true
      else
         reset-config
         read-nvram drop
         config-checksum?  if
            true
         else
            ." Failed to set configuration memory to its default values" cr
            false
         then
      then
   then
   to config-valid?
   config-valid?  0=  if
      ." The configuration memory is invalid.  Using default values." cr
   then
;
headers
: set-mfg-defaults  ( -- )
   config-rw

   layout-config

   set-defaults

   config-ro
   config-checksum? to config-valid?
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
