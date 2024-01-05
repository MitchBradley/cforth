\ test_time.fth 20-12-2023

DECIMAL

: code-in-minutes ( $hrs count - coded-min )   single? #60  * 16bneg + ;
: add-coded-w ( n - ) s" #" tmp$ +lplace (.) tmp$ +lplace s"  w, " tmp$ +lplace ;
: add-coded-c ( n - ) s" #" tmp$ +lplace (.) tmp$ +lplace s"  c, " tmp$ +lplace ;

: List-weekdays
       ." 0:sunday    1:monday  2:tuesday   3:wednesday"
    cr ." 4:thursday  5:fryday  6:saterday"   ;

: .last-input-tz ( - )  \ As long as tmp$ is not changes
    cr ." The new summertime would last for: " cr
    .tz-header cr
    tmp$ lcount s" create " nip /string bl NextString evaluate
    2023 .summer-time
    cr cr ." If OK then: Paste the following code into timezones.f"
    cr tmp$ lcount type cr ;

: Dst-input ( - )
    ." change at LOCAL [UUMM] : " 4  enter-input extract-time
    60 * +  16bneg + nip  add-coded-w                  \ 5) Add change time that day. In local time
    List-weekdays cr 9 to-column
    ." Day number of the involved weekday : "
        1 enter-input  single?                         \ Ask #weekday
    ." Index of the involved weekday in it's month : "
        4 enter-input single? 16bneg + add-coded-w     \ 6) Add occurence in month
        add-coded-c 35 to-column                       \ 7) Add #weekday
   ." In month : " 2  enter-input single? add-coded-c  \ 8) Add month
   ."  Number of days before the involved weekday : "
       1 enter-input  single? add-coded-c ;            \ 9) Add subtract #weekdays

: init-timezone ( - coded-minutes )
    tmp$
       if   tmp$ off
       else 255 allocate drop to tmp$
       then
    cr s" create " tmp$ lplace                                   \ 1) Add create
    cr ."  Max 34 pos for name : " 34 enter-input  tmp$ +lplace  \ 2) Add name
    s"   incr-tz " tmp$ +lplace 10 to-column   \ Increment #tz during compiing
    ." Utc offset : " 3 enter-input code-in-minutes ;

: input-tz-rule ( - )           \ Input for extra timezones that observe DST
    init-timezone  add-coded-w                           \ 3) Add Utc offset
    5 to-column ." Shift in minutes: " 3 enter-input
    single? 16bneg + add-coded-w                         \ 4) Add shift
    cr ." For Dst START, " Dst-input
    cr ." For Dst END, "   Dst-input
    tmp$ lcount evaluate         \ Test the code of the input
    -1 #tz +! .last-input-tz ;   \ Show the Forth code for timezones.f

: time-list-meeting ( sec mm hh dd mm yyyy-GMT  -- )
   cr utctics-from-time&date greenwich-mean-time
   0 lmargin ! #60 rmargin ! #13 tabstops ! ??cr
     ." Local times for the zoom meeting at:"
   fdup  .time-from-utctics
   fdup space .date-from-utctics  ."  UTC" cr
   tz-Endlist  #tz @ 0
       do    ?cr >link link@
             2dup >body fdup convert-to-tz
             fdup bold .time-from-utctics norm space
              date-from-utc-time 2drop .## space
             dup  >name$ shorten-tz-name type
       loop
    2drop fdrop cr ;

 \ Use : 0 0 13 9 12 2023 time-list-meeting


: world-clock ( - )
  0 lmargin ! #86 rmargin ! #13 tabstops ! ??cr
  greenwich-mean-time tz-Endlist
  #tz @ 0
       do       ?cr >link link@  tuck >name$ shorten-tz-name type  ." :"
                2dup swap >body @time  convert-to-tz
                fdup  .date-from-utctics
                       bold .time-from-utctics norm
                swap 30 .tab
  fdepth 0<  abort" Floating Point Stack Underflow"
       loop
   2drop  cr ;

: watch-world-clock ( - )
   hide-cursor 0 7 at-xy world-clock show-cursor ;

\ Use: cls 18 set-precision f# 1 fsec>fus ' watch-world-clock execute-until-escape

0 [if]
Notes:
 2023 .list-summer-times            \ To list all timezones in timezones.fth
 Europe/Amsterdam 2023 .summer-time \ Lists just 1

\ Conversions between time zones at the current local time:
 local-time-now europe/amsterdam america/chicago convert-to-tz .time-from-utctics
 local-time-now europe/amsterdam america/chicago convert-to-tz .Date-from-utctics

\ Conversions between time zones at a specified time:
  0  3  13 28 8 2023 utctics-from-time&date greenwich-mean-time
              europe/amsterdam convert-to-tz .time-from-utctics

2038 tests:
0 14 07 19 1 2037 UtcTics-from-Time&Date f.s fdup .Date-from-utctics .time-from-utctics
0 14 07 19 1 2038 UtcTics-from-Time&Date f.s fdup .Date-from-utctics .time-from-utctics
0 14 07 19 1 2100 UtcTics-from-Time&Date f.s fdup .Date-from-utctics .time-from-utctics

Under esp-idf v3.x.x the time of the esp32 is not handled right beyond 2038
From: https://github.com/espressif/esp-idf/issues/584
Subtract 883612800 seconds and dates and weekdays are the same again!
The 2038 problem is solved in v5

[then]

