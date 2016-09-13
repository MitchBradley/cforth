purpose: Present dropins as a filesystem
\ See license at end of file

0 0  " "  " /" begin-package
" dropin-fs" name

headerless
0 instance value base-adr
0 instance value image-size
0 value open-count
false value written?
0 instance value seek-ptr

: clip-size  ( adr len -- len' adr len' )
   seek-ptr +   image-size min  seek-ptr -     ( adr len' )
   tuck
;
: update-ptr  ( len' -- len' )  dup seek-ptr +  to seek-ptr  ;

headers
external
: seek  ( d.offset -- status )
   0<>  over image-size u>  or  if  drop true  exit  then \ Seek offset too big
   to seek-ptr
   false
;

: open  ( -- flag )
   \ This lets us open the node during compilation
   standalone?  0=  if  true exit  then

   0 to base-adr
   0 to seek-ptr                                    ( )
   my-args  dup  if                                 ( adr len )
      2dup  " \"  $=  if                            ( adr len )
         2drop true exit
      else                                          ( adr len )
         over c@  [char] \  =  if  1 /string  then  ( adr' len' )
         find-drop-in  dup  if                      ( di-adr di-len true )
            -rot  to image-size  to base-adr        ( true )
         then                                       ( flag )
         exit                                       ( flag )
      then                                          ( adr len )
   then                                             ( adr len )
   2drop                                            ( )
   false
;
: close  ( -- )
   \ This lets us open the node during compilation
   standalone?  0=  if  exit  then

   base-adr 0<>  if  base-adr image-size release-dropin  then
;
: size  ( -- d.size )  image-size u>d  ;
: read  ( adr len -- actual )
   clip-size                     ( len' adr len' )
   seek-ptr base-adr +  -rot     ( len' device-adr adr len' )
   move                          ( len' )
   update-ptr                    ( len' )
;
: load  ( adr -- len )
   base-adr swap image-size move  image-size
;
: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   ?dup 0=  if  open-drop-in  then      ( id )
   another-dropin?  if                  ( id )
      " built-time-int" $find  if       ( id s m h xt )
         execute                        ( id s m h packed-date )
         d# 100 /mod  d# 100 /mod       ( id s m h d m y )
      else                              ( id s m h adr len )
         2drop  0 0 0                   ( id s m h d m y )
      then                              ( id s m h d m y )
      " built-date-int" $find  if       ( id s m h xt )
         execute                        ( id s m h packed-date )
         d# 100 /mod  d# 100 /mod       ( id s m h d m y )
      else                              ( id s m h adr len )
         2drop  0 0 0                   ( id s m h d m y )
      then                              ( id s m h d m y )
      di-expansion be-l@                ( id s m h d m y size )
      ?dup 0=  if  di-size be-l@  then  ( id s m h d m y size )
      o# 100444                         ( id s m h d m y size attributes )
      di-name cscount                   ( id s m h d m y size attr name$ )
      true                              ( id s m h d m y size attr name$ true )
   else                                 ( )
      close-drop-in  false              ( false )
   then
;

: free-bytes  ( -- d.#bytes )
   open-drop-in  0                    ( high-water )
   0  begin  another-dropin?  while   ( high-water id )
      nip  di-size be-l@ 4 round-up   ( id size )
      over +  swap                    ( high-water' id )
   repeat                             ( high-water )
   size  rot 0  d-                    ( d.#bytes )
;

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
