\ See license at end of file
headers

\ Splits a string into two halves before the first occurrence of
\ a delimiter character.
\ adra,lena is the string including and after the delimiter
\ adrb,lenb is the string before the delimiter
\ lena = 0 if there was no delimiter

: split-before  ( adr len delim -- adra lena  adrb lenb )
   split-string 2swap
;
alias $split left-parse-string

: cindex  ( adr len char -- [ index true ]  | false )
   false swap 2swap  bounds  ?do  ( false char )
      dup  i c@  =  if  nip i true rot  leave  then
   loop                           ( false char  |  index true char )
   drop
;

\ Splits a string into two halves after the last occurrence of
\ a delimiter character.
\ adra,lena is the string after the delimiter
\ adrb,lenb is the string before and including the delimiter
\ lenb = 0 if there was no delimiter

: right-split-string  ( $1 char -- tail$ head$|null$ )
   >r  2dup + 0           ( $1 null$ )
   begin  2 pick  while                   ( head$ tail$ )
      2over + 1- c@  r@  <>
   while                                  ( head$ tail$ )
      2swap 1-  2swap swap 1- swap 1+  
   repeat  then
   r> drop                                ( head$|null$ tail$ )
   2swap                                  ( tail$ head$|null$ )
;
alias split-after right-split-string
headers
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
