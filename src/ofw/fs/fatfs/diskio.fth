\ See license at end of file
\ Implementation of the device driver interface used by the DOS file
\ system code.  This file knows some details of both the underlying
\ device level and the DOS file level above.  It is responsible for
\ translating between those levels; for instance, it translates DOS
\ device numbers to the corresponding SCSI logical unit numbers.
\
\ Exports:
\
\   read-sectors   (S sector# #sectors addr -- error? )   Reads sectors
\   write-sectors  (S sector# #sectors addr -- error? )   Writes sectors
\   r/w-sectors  (S sector# #sectors addr lun read? -- error? )
\
\ Imports:
\   current-device

private

: init-sector-size  ( -- )  " block-size" $call-parent  bps w!  ;
: translate-params  (S sector# #sectors addr -- addr #bytes )
   rot bps w@ um*  " seek"  $call-parent  ( #sectors addr err? )
   abort" seek failed in translate-params" 
   swap bps w@ *
;

: read-sectors   (S sector# #sectors addr -- error? )
   translate-params  dup >r  " read"  $call-parent  r> <>
;
: write-sectors  (S sector# #sectors addr -- error? )
   translate-params  dup >r  " write"  $call-parent  r> <>
;

[ifdef] mount-drive
4 constant #devices

string-array device-names
  ," /floppy"
  ," /floppy"
  ," disk0"
  ," disk1"
end-string-array

: ?drive#  ( drive# -- drive# )
   dup 0 #devices  within  ( drive-number okay? )
   0=  abort" Maximum drive number is 3 (D:)"
;
: (unmount)  ( drive# -- )
   ?drive#
   driver @  dup  if  ( ihandle )
      close-dev  0 driver !
   else
      2drop
   then
;
: get-drive#  \ drive-letter  ( -- true | drive# false )
   optional-arg$  dup  if
      drop c@  upc  ascii A -  false
   else
      2drop true
   then
;
: unmount  \ drive-letter  ( -- )
   get-drive#  abort" Usage: unmount drive-letter"
   (unmount)
;
: $mount  ( path$ drive# -- )
   dup (unmount)   >r   ( path$ )
   open-dev  dup  0= abort" Can't open disk device for mounting"  ( ihandle )
   r> driver !
;   
: mount  \ pathname drive-letter  ( -- )
   safe-parse-word  dup  if  ( path$ )
      get-drive#            ( path$ [ drive# ] flag )
   else
      true
   then                     ( path$ [ drive# ] flag )
   abort" Usage: mount pathname drive-letter"
   $mount
;
: ?init-device  ( -- )
   driver @ 0=  if
      current-device @  device-names  count  current-device @  $mount
   then
;
[else]
alias ?init-device noop  ( -- )
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
