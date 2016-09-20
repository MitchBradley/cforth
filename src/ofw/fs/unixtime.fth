\ See license at end of file
purpose: Convert Unix seconds to time and date

decimal
\ February is given 29 days so the loop in >d/m will exit at the "unloop".
\ The array begins at March so that the leap day falls at the end.
create days/month
\ Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov   Dec   Jan   Feb
  31 c, 30 c, 31 c, 30 c, 31 c, 31 c, 30 c, 31 c, 30 c, 31 c, 31 c, 29 c,

\ In >d/m and d/m>, the yearly period starts on March 1. day-in-year is
\ relative to March 1, and month-index 0 is March, 9 is December, 10 is January,
\ 11 is February.  This representation simplifies the calculations by 
\ putting the optional leap day at the end, i.e. day-of-year=365.

\ Convert day-in-year to day-of-month and month-index.

: >d/m  ( day-in-year0..365 -- day1..31 month-index0..11 )
   d# 12 0  do                           ( days-left )
      days/month i ca+ c@  2dup <  if    ( days-left )
         drop 1+  i  unloop exit         ( -- day1..31 month-index0..11 )
      then                               ( days-left )
      -                                  ( days-left' )
   loop                                  ( days-left )
   \ This is reached only if the argument is >365
   1+  d# 12                             ( day1..31 month-index0..11 )
;

\ Convert day-of-month and month-index to day-in-year.

: d/m>  ( day1..31 month-index0..11 -- day-in-year0..365 )
   swap 1-  swap 0  ?do  i days/month + c@ +  loop	( day-in-year )   
;

d# 365 constant d/y
d/y d# 2 *  \ Days in the 2 years from 1970 to 1972
d# 31 +     \ Days in January 1972
d# 29 +     \ Days in February 1972 (a leap year)
constant days-to-break

: unix-seconds>   ( seconds -- s m h d m y )
   \ Changing the 3 /mod's below to u/mod's would "fix" the year 2038 problem
   \ at the expense of breaking dates before 1970.
   d# 60 /mod  d# 60 /mod  d# 24 /mod	( s m h days )

   \ Rotate the number space so that day 0 is March 1, 1972,
   \ the beginning of a 4 year + 1 day leap cycle
   days-to-break -

   \ Reduce modulo the number of days in a 4-year leap cycle
   \ This depends on floored division
   [ d/y 4 * 1+ ] literal /mod >r	( s m h day-in-cycle r: cycles )

   \ Reduce by the number of days in a normal year
   d/y /mod				( s m h day-in-year year-in-cycle r: cycles )

   \ If year-in-cycle is 4, it's Feb 29
   dup 4 =  if				( s m h day-in-year year-in-cycle r: cycles )
      \ Leap day Feb 29 at end of cycle
      swap d/y +  swap 1-		( s m h day-in-year' year-in-cycle' r: cycles )
   then					( s m h day-in-year year-in-cycle r: cycles )
   r> 4 * + >r				( s m h day-in-year r: year )

   >d/m			      		( s m h day-in-month month-index r: year )

   \ Adjust the month number - at this point March is 0 and we want it to be 3
   3 +			      		( s m h d month' r: year )

   \ Months 13 and 14 are January and February of the following year
   dup d# 13 >=  if			( s m h d month r: year )
      d# 12 -  r> 1+ >r	      		( s m h d month' r: year' )
   then			      		( s m h d month r: year )

   r> d# 1972 +				( s m h d m y )
;

: >unix-seconds  ( s m h d m y -- seconds )	\ since 1970
   d# 1972 - >r						( s m h d m  r: y' )

   \ Move January and February to the end so the leap day is day number 365
   dup 3 <  if						( s m h d month' r: y )
      d# 12 +  r> 1- >r					( s m h d month' r: y' )
   then							( s m h d month  r: y )

   \ Convert month numbers 3..14 to 0..11
   3 -							( s m h d month-index  r: y )

   \ Convert day and month to day in year
   d/m>							( s m h day-in-year  r: y )

   r@ 4 /						( s m h day-in-year leap-years  r: y )
   r> d/y * +						( s m h day-in-year year-days )
   +							( s m h days )

   \ Adjust to 1970
   days-to-break +					( s m h days' )

   \ Changing the 3 *'s below to u*'s would "fix" the year 2038 problem
   \ at the expense of breaking dates before 1970.
   d# 24 * +   d# 60 * +   d# 60 * +			( seconds )
;

\ e.g.  time&date >unix-seconds 
\ >unix-seconds unix-seconds>	should have no net effect

hex

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
