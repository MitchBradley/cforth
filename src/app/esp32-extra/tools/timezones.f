marker -timezones.fth cr cr lastacf .name #19 to-column .( 05-12-2023 )

0 [if]
Ref: https://en.wikipedia.org/wiki/Daylight_saving_time_by_country
     https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#Time_Zone_abbreviations
     https://www.worldtimebuddy.com/

Setting the right timezone with minimal memory usage:

1) For timezones in this file, change the tz-local vector like:

' Europe/Amsterdam is tz-local

2) For a country that uses a time zone that is present here with another name:
   A) Copy the data ( 2 lines when DST is observed) in your source
   B) Remove or disable incr-tz
   C) Change the tz-local vector.
   EG: Bermuda uses the same time zone as New_York:

create Bermuda \ incr-tz
 #32467 w, #32827 w, #32887 w, #32769 w, #0 c, #3 c, #0 c, #32887 w, #32768 w, #0 c, #11 c, #0 c,
' Bermuda is tz-local

3) For a new country the does not observe DST.
   A) Use create and utc-only, to add the timezone in your source
   B) Change the tz-local vector
   EG: Dhaka (UTC+06:00)

create Dhaka 6 utc-only,
' Dhaka is tz-local


When you would like to add time zones / countries here:
See input-tz-rule in tests/test_time.fth
The UTC field is filled with the difference in minutes from GMT
Add countries / time zones in reversed alphabetical order.

Notes: 1) Utc-offset Shift and Change are stored in minutes with an offset
       2) The name length is max 34 positions for America/Argentina/ComodRivadavia

[then]

$7fff constant 16bneg     variable #tz   0 #tz !
: incr-tz   ( - ) 1 #tz +! ;
: utc-only, ( Utc+ - ) #60 * $5fff + w, ; \ To store the Utc field when NO timesaving are used.

create South-Africa   incr-tz   2 utc-only,

create Paraguay incr-tz
 #32587 w, #32827 w, #32767 w, #32766 w, #0 c, #10 c, #0 c, #32767 w, #32766 w, #0 c, #3 c, #0 c,

create palestine incr-tz
 #32887 w, #32827 w, #32887 w, #32766 w, #6 c, #4 c, #0 c, #32887 w, #32766 w, #0 c, #10 c, #1 c,

create New_Zealand incr-tz
 #33547 w, #32827 w, #32887 w, #32766 w, #0 c, #9 c, #0 c, #32887 w, #32768 w, #0 c, #4 c, #0 c,

create moldova incr-tz
 #32887 w, #32827 w, #32887 w, #32766 w, #0 c, #3 c, #0 c, #32947 w, #32766 w, #0 c, #10 c, #0 c,

create Lebanon incr-tz
 #32887 w, #32827 w, #32767 w, #32766 w, #4 c, #3 c, #0 c, #32767 w, #32766 w, #0 c, #10 c, #0 c,

create Japan incr-tz 9 utc-only,

create Israel incr-tz
 #32887 w, #32827 w, #32887 w, #32766 w, #0 c, #3 c, #2 c, #32887 w, #32766 w, #0 c, #10 c, #0 c,

create Greenwich-Mean-Time incr-tz  0 utc-only,

create Europe/Moscow 3 utc-only,

create Europe/London  incr-tz
 #32767 w, #32827 w, #32827 w, #32766 w, #0 c, #3 c, #0 c, #32887 w, #32766 w, #0 c, #10 c, #0 c,

create Europe/Amsterdam incr-tz
 #32827 w, #32827 w, #32887 w, #32766 w, #0 c, #3 c, #0 c, #32947 w, #32766 w, #0 c, #10 c, #0 c,

create Egypt incr-tz
 #32887 w, #32827 w, #32767 w, #32766 w, #5 c, #3 c, #0 c, #34207 w, #32766 w, #4 c, #10 c, #0 c,

create cuba incr-tz
 #32467 w, #32827 w, #32767 w, #32769 w, #0 c, #3 c, #0 c, #32827 w, #32768 w, #0 c, #11 c, #0 c,

create China incr-tz 8 utc-only,

create Chile incr-tz
 #32587 w, #32827 w, #34207 w, #32768 w, #6 c, #9 c, #0 c, #34207 w, #32768 w, #6 c, #4 c, #0 c,

create Australia/Melbourne incr-tz
 #33427 w, #32827 w, #32887 w, #32768 w, #0 c, #10 c, #0 c, #32947 w, #32768 w, #0 c, #4 c, #0 c,

create Australia/Lord-Howe-Island incr-tz
 #33427 w, #32797 w, #32887 w, #32768 w, #0 c, #10 c, #0 c, #32887 w, #32768 w, #0 c, #4 c, #0 c,

create America/Sao_Paulo incr-tz  -3 utc-only,

create America/New_York incr-tz
 #32467 w, #32827 w, #32887 w, #32769 w, #0 c, #3 c, #0 c, #32887 w, #32768 w, #0 c, #11 c, #0 c,

create America/Arizona incr-tz -7 utc-only,

create America/Chicago  (  -  ) \ Input by hand:
    incr-tz                     \ Increase #tz for a list in .list-summer-times
       #-6 #60  * 16bneg + w,   \ Utc-offset for utc+N in minutes with an extra offset
       #1  #60  * 16bneg + w,   \ Shift dst start
       #2  #60  * 16bneg + w,   \ Starts at: 02:00 UTC
       #2 16bneg + w,   #0  c,    #3  c, \ Date dst starts: Second sunday in march
       0 c,                              \ Subtract #weekdays
       #2  #60  * 16bneg + w,            \ Ends at: 02:00 UTC
       #1 16bneg + w,   #0  c,    #11 c, \ Date dst ends: First sunday in november
       0 c,                              \ Subtract #weekdays

\ Add new time zones BEFORE this line in reversed alphabetical order.

marker (tz-Endlist)
: tz-Endlist  ( -  tz-Endlist ) ['] (tz-Endlist)  ;

\ tz-Endlist >link link@ >name$ type  \ Types the last added time zone.
defer tz-local  ' Europe/Amsterdam is tz-local \ Change it in your app.
\ 2023 .list-summer-times \ lists them
\ \s
