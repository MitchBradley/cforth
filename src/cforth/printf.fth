purpose: printf and sprintf
\ See license at end of file

: push-octal  ( -- )  r>  base @ >r >r  octal  ;

\needs lex fl ../lib/lex.fth

d# 1024 buffer: spbuf
0 value splen
: +spbuf  ( adr len -- )
   dup splen + d# 1024 >  abort" sprintf buffer overflow"
   tuck  spbuf splen +  swap  move   ( len )
   splen + is splen
;
: +spchar  ( char -- )
   splen d# 1023 >  abort" sprintf buffer overflow"
   spbuf splen +  c!
   splen 1+ is splen
;

: 1/string  ( adr len -- adr' len' char )
   dup  if                      ( adr len )
      over c@ >r  1 /string  r>  ( adr' len' char )
   else                          ( adr len )
      -1                         ( adr len -1 )
   then
;

: replace%  ( ... tail$ -- ... tail$' )  \ Handle % escapes
   1/string              ( ... tail$ char )
   case
      [char] u  of   push-decimal rot (u.) +spbuf  pop-base  endof
      [char] d  of   push-decimal rot (.)  +spbuf  pop-base  endof
      [char] x  of   push-hex     rot (u.) +spbuf  pop-base  endof
      [char] s  of   2swap +spbuf  endof
      [char] o  of   push-octal   rot (u.) +spbuf  pop-base  endof
      -1        of   endof
      ( default )  dup +spchar
   endcase
;

: replace\  ( ... tail$ -- ... tail$' )   \ Handle backslash escapes
   1/string              ( ... tail$ char )
   case
      [char] n  of  #10 +spchar  endof
      [char] r  of  #13 +spchar  endof
      [char] t  of  #09 +spchar  endof
      [char] f  of  #12 +spchar  endof
      [char] l  of  #10 +spchar  endof
      [char] b  of  #08 +spchar  endof
      [char] !  of  #07 +spchar  endof
      ( default ) dup +spchar
   endcase
;

: sprintf  ( ... adr len -- adr' len' )
   0 is splen

   begin  dup  while              ( ... adr len )
      " %\" lex  if               ( ... tail$ head$ delim )
         -rot +spbuf              ( ... tail$ delim )
         [char] %  =  if  replace%  else  replace\  then  ( ... tail$ )
      else                        ( ... tail$ )
         +spbuf 0 0               ( ... 0 0 )
      then                        ( ... tail$ )
   repeat                         ( tail$ )
   2drop   spbuf splen
;
: printf  ( ... adr len -- )  sprintf type  ;

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
