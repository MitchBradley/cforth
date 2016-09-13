\ See license at end of file
\ DOS directory entry structure

hex

private

variable dirent

: efield \ name ( dirent-offset size -- dirent-offset')
   create over , + does> @ dirent @ +
;

struct \ dirent
 8 efield de_name          \  0  base name
 3 efield de_extension	   \  8  ext (first byte: 0 - empty; e5 - deleted)
 1 efield de_attributes	   \  b  attributes

\ Bits in attributes byte

01 constant at_rdonly	   \ Read only
02 constant at_hidden	   \ Invisible in directory search
04 constant at_system	   \ System file
08 constant at_vollab	   \ Volume label
10 constant at_subdir	   \ Subdirectory
20 constant at_archiv	   \ Needs archiving (changed since last backup)

 1 efield de_reserved	   \  c  reserved
 1 efield de_csec	   \  d  # of 10 msec intervals in 2 secs (Win95)
 2 efield de_ctime	   \  e  creation time (Win95)
 2 efield de_cdate	   \ 10  creation date (Win95)
 2 efield de_adate	   \ 12  last access date (Win95)
 2 efield de_firsthi	   \ 14  upper 12 bits of beginning cluster# (Win95)
 2 efield de_time	   \ 16  modification time
 2 efield de_date	   \ 18  modification date
 2 efield de_first	   \ 1a  beginning cluster#
 4 efield de_length	   \ 1c  #bytes in file

constant /dirent

13 buffer: file-name-buf

: "$append  ( pstr adr len -- pstr )
   dup >r   2 pick count +  swap cmove  ( pstr )
   dup c@ r> + over c!
;

: file-name  ( -- adr len )
   de_name 8 -trailing  file-name-buf pack  ( pstr )
   de_extension 3 -trailing nip  if
       " ."  "$append  de_extension 3 -trailing "$append  ( pstr )
   then
   count
;

: file-size  ( -- #bytes )  de_length lel@ ;
: file-date  ( -- day month year )  de_date lew@ >dmy  ;
: file-time  ( -- sec min hour )  de_time lew@ >hms  ;
: file-attributes  ( -- bitmask )  de_attributes c@ ;

: file-cluster!  ( cluster# -- )
   lwsplit de_firsthi lew!  de_first lew!
;

: file-cluster@  ( -- cluster# )
   de_first lew@
   fat-type c@  fat32 =  if  de_firsthi lew@  wljoin  then
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
