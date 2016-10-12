\ See license at end of file
purpose: lexical analysis primitive

: cindex  ( adr len char -- [ index true ]  | false )
   false swap 2swap  bounds  ?do  ( false char )
      dup  i c@  =  if  nip i true rot  leave  then
   loop                           ( false char  |  index true char )
   drop
;

\ text$ means ( text-adr text-len )
0 value delim

\ lex scans text$ for each character in delim$
\ when one is found, lex splits text$ at that delimiter and leaves
: lex   ( text$ delim$ -- rem$ head$ delim true | text$ false )
   0 is delim
   2over bounds ?do				( text$ delim$ )
      2dup i c@ cindex if			( text$ delim$ [ index ] )
	 nip nip c@  dup is delim		( text$ delim )
	 left-parse-string  leave		( rem$ head$ )
      then					( text$ delim$ | rem$ head$ )
   loop						( text$ delim$ | rem$ head$ )
   delim if
      delim true
   else
      2drop false
   then
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
