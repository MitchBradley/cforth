\ See license at end of file

\ Command completion package a la TENEX.

headerless

decimal
only forth also definitions
vocabulary command-completion
only forth also hidden also command-completion definitions

\ Interfaces to the line editing routines
defer find-end ( -- )        \ Move the cursor to the end of the word
defer cinsert  ( char -- )   \ Insert a character into the line
defer cerase   ( -- )        \ Delete the character before the cursor

\ Some variables are hijacked from the line editing code and used here:
\ line-start-adr #before

\ Index of char at the beginning of the latest word in the input buffer
variable start-of-word

20 constant #candidates-max
variable #candidates   0 #candidates !
#candidates-max /n*  buffer: candidates
variable overflow

: word-to-string  ( -- str )
   line-start-adr  start-of-word @  +  ( addr of start of word )
   #before         start-of-word @  -  ( start-addr len )
   'word  place
   'word
;

: collect-string  ( -- str )
   \ Finds start of this word and the current length of the word and
   \ leaves the address of a packed string which contains that word
   find-end
   #before    start-of-word !
   #before  if
       line-start-adr  #before  1-  bounds  ( bufend bufstart )
       swap  ( bufstart bufend )  do    \ Loop runs backwards over buffer
          i c@  bl =  if  leave  then
          -1 start-of-word +!
       -1 +loop
   then
   word-to-string  ( str )
;

: substring?  ( pstr anf -- f )

   name>string  rot count 2swap  ( pstr-adr,len name-adr,len )

   \ It's not a substring if the string is longer than the name
   2 pick  <  if  2drop drop false exit  then  ( pstr-adr pstr-len name-adr )

   true swap 2swap   ( true name-adr pstr-adr pstr-len )
   bounds  ?do       ( flag name-adr )
      dup c@  i c@ <>  if  swap 0= swap  leave   then  ( flag name-adr )
      1+             ( flag name-adr' )
   loop              ( flag name-adr'' )
   drop
;

: new-candidate  ( anf -- )
   #candidates @  #candidates-max >=  if  drop overflow on  exit  then
   candidates #candidates @ na+   !   (  )
   1 #candidates +!
;

: find-candidates-in-voc  ( str voc -- str )
   follow
   begin  another?  while
      2dup substring?  if  new-candidate  else  drop  then
   repeat
   ( str )
;

: find-candidates  ( str -- )
   #candidates off  overflow off
   prior off        ( str )
   dup c@ 0=  if  drop  exit  then     \ Don't bother with null search strings
   \ Maybe it would be better to search all the vocabularies in the system?
   context  #vocs /link *  bounds  do
      i another-link?  if                ( str voc )
         dup prior @ over prior !  = if  ( str voc )
            drop                         ( str )
         else
	    find-candidates-in-voc       ( str )
         then
      then                               ( str )
   /link +loop
   drop
;
\ True if "char" is different from the "char#"-th character in name
: cclash?  ( char# char anf -- char# char flag )
   name>string        ( char# char str-adr count )
   3 pick <=  if      ( char# char str-adr )
      drop true       \ str too short is a clash
   else               ( char# char str-adr )
      2 pick +  c@ over <>
   then
;

\ If all the candidate words have the same character in the "char#"-th
\ position, leave that character and true, otherwise just leave false.
: candidates-agree?  ( char# -- char true | false )

\ if the test string is the same length as the first candidate,
\ then the first candidate has no char at position char#, so there
\ can be no agreement.  Since the test string is a substring of all
\ candidates, the > condition should not happen

   candidates @  name>string               ( char# name-adr name-len )
   2 pick =  if  2drop false  exit  then   ( char# name-adr )
   over + c@                               ( char# char )

   \ now test all other candidates to see if their "char#"-th character
   \ is the same as that of the first candidate

   true -rot                               ( true char# char )

   candidates na1+  #candidates @  1-  /n*  bounds  ?do   ( flag char# char )
       i @ cclash?  if                                    ( flag char# char )
          rot drop  false -rot  leave
       then
   /n +loop                                               ( flag char# char )
   rot if   nip true   else   2drop false   then
;
: expand-initial-substring  ( -- )
   #before  start-of-word @  -
   begin                         ( current-length )
         dup candidates-agree?   ( current-len [ char true ] | false )
   while
         cinsert  1+             ( current-length )
   repeat
   drop
;

h# 34 buffer: candidate

\ True if there is only one candidate or if all the names are the same.
: one-candidate?  ( -- flag )

   \ We can't just compare the pointers, because we are checking for
   \ different words with the same name.

   candidates @ name>string  candidate place
   true
   candidates  #candidates @ /n*  bounds  ?do  ( flag )
      i @  name>string  candidate count        ( flag )
      $=  0=  if  0= leave  then               ( flag )
   /n +loop                                    ( flag )
;

0 [if]
: do-erase  ( -- ) \ Side effect: span and bufcursor may be reduced
   begin
      word-to-string   ( addr )
      dup c@ 0=  if  drop exit  then	\ Stop if the entire word is gone
      find-candidates
      #candidates @ 0=
   while
      cerase
   repeat
;
[then]

: do-expand  ( -- )
   expand-initial-substring

   \ Beep if the expansion does not result in a unique choice
   one-candidate?  if  bl cinsert  else beep  then
;

: expand-word  ( -- )
   collect-string find-candidates  ( )
   #candidates @  if   do-expand   else
[ifdef] do-erase  do-erase  [else]  beep  [then]
   then
;

: show-candidates  ( -- )
   td 64 rmargin !
   candidates #candidates  @  /n* bounds  ?do  ?cr  i @ .id  /n +loop
   overflow @  if  ." ..."  then
;

: do-show  ( -- )
   cr
   collect-string  dup c@  if       ( str )
      find-candidates show-candidates
   else
      drop ." Any word at all is a candidate." cr
           ." Use words to see the entire dictionary"
   then
   retype-line
;
headers

only forth also definitions
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
