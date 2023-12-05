marker -timediff.fth cr lastacf .name #19 to-column .( 05-12-2023 ) \ By J.v.d.Ven

f# -1 fvalue UtcSunRise
f# -1 fvalue UtcSunSet

f# 86400. fconstant #SecondsOneDay
   #3600   constant #SecondsOneHour

: jd                ( dd mm yyyy -- julian-day )
    >r                            ( dd mm)( r: yyyy)
        #3 -  dup 0< if  #12 +  r> 1- >r  then
        #306 *  #5 +  #10 /  +       ( day)
        r@  #1461 #4 */  +  #1721116 +
           dup #2299169 > if
               #3 +  r@ #100 / -  r@ #400 / +
           then
    r> drop ;

: /_mod           ( dividend divisor -- remainder quotient )
    >r s>d r> fm/mod ;

: /_    ( dividend divisor -- quotient )  /_mod nip ;

: _mod  ( dividend divisor -- remainder )  /_mod drop ;

: gregorian-year-from-fixed  ( fixed-date -- gregorian-year )
    1 -                      ( d0) \ 1 - for gregorian-epoch
    #146097 /_mod            ( d1 n400)
        #400 * swap          ( year d1)
    #36524  /_mod            ( year d2 n100)
        dup >r               ( year d2 n100)( r: n100)
        #100 *  rot + swap   ( year d2)
    #1461   /_mod            ( year d3 n4)
        #4 * rot + swap      ( year d3)
    #365    /_               ( year n1)
        dup >r               ( year n1)( r: n100 n1)
        +                    ( year)
    r> #4 = r> #4 = or not if 1+ then ;

: gregorian-leap-year?  ( gregorian-year -- flag )
    dup    #4 _mod 0=         ( gregorian-year flag)
    over #100 _mod 0= not and
    swap #400 _mod 0= or      ( flag)
    ;

: day-number             ( month day year -- day-of-year )
    >r  swap                        ( day month)( r: year)
        dup >r                            ( r: year month)
            #367 *  #362 -  #12 / +         ( day-of-year)
        r> 2 > if  \  adjust for mar..dec.      ( r: year)
            r@ gregorian-leap-year? if  1-  else  2 - then
        then
    r> drop ;

: fixed-from-gregorian    ( month day year -- fixed-date )
    dup 1- >r                          ( r: previous-year)
    day-number                              ( day-of-year)
    r@   4 /_  +
    r@ #100 /_  -
    r@ #400 /_  +
    r> #365 * + ;

: gregorian-from-fixed      ( fixed-date -- day month year )
    dup gregorian-year-from-fixed >r              ( r: year)
    dup  1 ( jan ) 1 r@ fixed-from-gregorian -   ( date prior-days)
    over 3 ( mar ) 1 r@ fixed-from-gregorian < not if
        r@ gregorian-leap-year? if  1+  else 2 +  then
    then
    #12 *  #373 +  #367 / >r            ( date)( r: year month)
    2r@ 1 rot fixed-from-gregorian - 1+               ( day)
    r>  r> ( day month  year) ;

: Jd-from-UtcTics        ( f: UtcTics - fjd )  #SecondsOneDay f/ f# 2440588 f+  ;

: 0UtcTics-from-Jd&Time  ( ss mm uu JD -  ) ( f: - UtcTics )
   #2440588 - s>f #SecondsOneDay f* #SecondsOneHour * swap #60 * + + s>f f+ ;

: UtcTics-from-Jd&Time  ( ss mm uu JD -  ) ( f: - UtcTics )
   #2440588 - s>f #SecondsOneDay f* #SecondsOneHour * swap #60 * + + s>f f+ ;

: UtcTics-from-Time&Date      ( ss mm uu dd mm year - ) ( f: - UtcTics )
   jd UtcTics-from-Jd&Time  ;

: Time-from-UtcTics      ( f: UtcTics - ) ( - ss mm uu )
   Jd-from-UtcTics -ftrunc #SecondsOneDay f* fround f>s
   #SecondsOneHour /mod swap #60 /mod #60 /mod drop rot ;

: Moment-from-JD          ( F: julian-day-number -- moment )
    f# -1721424.5E0  f+ ;  \ -1721424.5E0 = JD-Start

: Date-from-jd          ( f: fjd - ) ( - dd mm year )
    ftrunc Moment-from-JD f>s  Gregorian-from-Fixed ;

: Date-from-UtcTics      ( f: UtcTics - ) ( - dd mm year )
    Jd-from-UtcTics Date-from-jd ;

: week-day ( Julian-day - day )  ftrunc f>s 1+ 7 mod ; \ 0=Sunday

: Day-of-Week-from-Fixed     ( fixed-date -- day-of-week )
    7 _mod ;

: Weekday-on-or-Before     ( date k -- date' )
    over swap - day-of-week-from-fixed - ;

: Weekday-After     ( date k -- date' )
    swap 7 + swap weekday-on-or-before ;

: Weekday-Before     ( date k -- date' )
    swap 1- swap weekday-on-or-before ;

: 'th-Weekday  ( n k month day year -- date )
    Fixed-from-Gregorian       ( n k date)
    swap rot >r                ( date k)( R: n)
    r@ 0< if  Weekday-After  else  Weekday-Before  then ( date)
    r> 7 * + ;

: last-day-month ( month year - day )
    over #12 =
      if    #31 -rot
      else  swap 1+ swap  2>r
            0 0 0 1 2r>  UtcTics-from-Time&Date #SecondsOneDay f-
            Date-from-UtcTics
      then
    2drop ;

: 'th-Weekday-in-month   ( THi|LAST-i #weekday month year  -- fixed-date )
    >r  2 pick 0<
       if    dup r@ last-day-month
       else  1
       then
    r> 'th-Weekday ;

: utc-from-fixed ( fixed - utctics-at-00:00 )
   >r  0 0 0 r> gregorian-from-fixed UtcTics-from-Time&Date ;

: unsigned>f ( unsigned - ) ( f: - n )
    dup 0<
       if    s>d drop 1
       else  s>d
       then
    d>f ;

: .##      ( - n )        s>d <# # # #> type  ;
: .-       ( n - )        .##  ." -"   ;
: get-secs ( - UtcTics )  dup dup sp@ get-system-time! nip ; \ 05-12-2023 In UTC!
: @time    ( - f: #secs ) get-secs unsigned>f ;     \
: .(date)  ( d m y - )    base @ >r decimal >r swap .-  .-  r> (.) type r> base ! ;
: .Date-from-utctics ( f: UtcTics - )   Date-from-UtcTics .(date) ;

begin-structure /tz \ Only 18
wfield: >tz-utc
wfield: >tz-Shift

wfield: >tz-time-start
wfield: >tz-weekday-date-start
bfield: >tz-index-weekday-start
bfield: >tz-month-start
bfield: >tz-weekdays-subtract-start

wfield: >tz-time-end
wfield: >tz-weekday-date-end
bfield: >tz-index-weekday-end
bfield: >tz-month-end
bfield: >tz-weekdays-subtract-end
end-structure

: utc-only? ( coded-minutes - flag )  $7000 <  ; \ Below $7000 ?

: ms-from-w-minutes ( tz-minutes - ms )
   dup utc-only?
     if   $5fff
     else 16bneg
     then
   -  #60 * ;

: @dst-start ( tz-list-item -  utc-offset )
    dup >tz-Shift w@ ms-from-w-minutes swap
        >tz-utc   w@ ms-from-w-minutes + ; \ utc-offset januari

: current-year ( &tz-list-item  - year )
   @time  @dst-start  s>f f+ Date-from-UtcTics nip nip ;

: @dst-date ( &weekday-date year - fixed-date )
   >r dup>r w@ 16bneg - r@ 2 + c@ r@ 4 + c@ - r> 3 + c@
   r> 'th-Weekday-in-month ;

: utc-offset-from-tzdata ( &weekday-date year - ) ( f: - utc00:00 )
    @dst-date utc-from-fixed ;

: @utc_offset ( &tz - utc-offset  ) >tz-utc w@ ms-from-w-minutes ;

: Dst-start ( &tz - shift+utc-offset ) ( f: utc00:00 - utc00:00+utc_time )
    dup>r >tz-time-start w@ ms-from-w-minutes s>f f+
    r@ >tz-Shift w@ ms-from-w-minutes
    r> @utc_offset + ;

: Dst-end ( &tz - shift+utc-offset )  ( f: utc00:00 - utc00:00+utc_time )
    dup>r >tz-time-start w@ ms-from-w-minutes s>f f+  r> @utc_offset ;

: find-utc-offset-in-year (  tz-list-item year - utc-offset )
   swap >r
   r@ >tz-weekday-date-start  over utc-offset-from-tzdata
   r@ Dst-start f> \ beyond start?
   r@ >tz-weekday-date-end 3 roll utc-offset-from-tzdata
   r> Dst-end f<   \ before end?
       rot and
         if    drop
         else  nip
         then ;

: current-year-from-utc-tics ( &tz-list-item  - year )  ( f: utc-tics - )
   @dst-start  s>f f+ Jd-from-UtcTics Date-from-jd nip nip ;

: find-utc-offset-at-utc ( tz-list-item - )  ( f: utc-tics - utc-offset )
   dup w@ utc-only?
      if    fdrop w@ ms-from-w-minutes
      else  fdup  dup fdup current-year-from-utc-tics \  current-year *** offset adr year
            find-utc-offset-in-year
      then
   s>f ; \ f# 10000 europe/amsterdam debug find-utc-offset-at-utc find-utc-offset-at-utc

: find-utc-offset ( tz-list-item - )  ( f: - utc-offset )
   dup w@ utc-only?
      if    fdrop w@ ms-from-w-minutes
      else  @time fdup  r@ current-year
            find-utc-offset-in-year
      then
    s>f ;

: convert-to-tz ( tz-source tz-destination -  ) ( f: utc-local-time-source  - utc-destination )
   swap fdup find-utc-offset-at-utc  f- \ gmt
   fdup  find-utc-offset-at-utc   f+ ;


: LocalTics-from-UtcTics ( f: UtcTics - LocalTics ) tz-local find-utc-offset f+ ;
: UtcTics-from-LocalTics ( f: UtcTics - LocalTics ) tz-local find-utc-offset f- ;

: date-from-utc-time     ( F: UtcTics - ) ( - dd mm yearLocal )
    LocalTics-from-UtcTics Date-from-UtcTics ;

: date-now               ( - dd mm yearLocal )    @time date-from-utc-time ;

: .mmhh        ( mmhh - ) s>d <# # # [char] : hold  # # #> type ;

: .signed ( n - )
   dup 0=
     if    space
     else  dup 0>
             if [char] + emit
             then
     then
   . ;

: .tz-header   ( - )
    ." Time zone" #25 spaces
    ." UTC Shift #wkd - Starts     Time #wkd - Ends       Time" ;

: .time-date-dst  ( &tz-weekday-date year - )
    over swap
    @dst-date gregorian-from-fixed .(date)  space
    2 -  w@ 16bneg - #100 * #60 / .mmhh ;

: .summer-time ( tz-list-item  year - )
    >r dup body> >name$ type #34 to-column
    dup >tz-utc  w@ dup ms-from-w-minutes #3600 / dup abs #10 <
         if    space
         then
   .signed #39 to-column
    utc-only?
        if    r> 2drop
        else  dup >tz-Shift  w@ 16bneg - .signed #44 to-column 2 spaces
              dup >tz-index-weekday-start c@ .  space
              dup >tz-weekdays-subtract-start c@ .
              dup >tz-weekday-date-start r@  .time-date-dst 2 spaces
              dup >tz-index-weekday-end c@ . space
              dup >tz-weekdays-subtract-end c@ .
                  >tz-weekday-date-end   r>  .time-date-dst
    then ;

: .list-summer-times { year -- }
    cr year .   cr .tz-header
     tz-Endlist  #tz @ 0
       do    cr >link link@ dup >body year .summer-time
       loop
    drop cr ;

: shorten-tz-name ( addr-tz/city cnt - short-tz-name cnt )
   2dup [char] / scan dup
    if   1 /string 2swap  3 min pad lplace
         s" /" pad +lplace pad +lplace
    else 2drop pad lplace
    then s"            " pad +lplace pad lcount #14 min ;

: date>jjjjmmdd    ( d m j - jjjjmmdd )   #10000 * swap #100 * + + ;
: GotTime?         ( - flag ) date-now nip nip #2022 > ;
: local-time-now   ( - f: #secs-local )   @time LocalTics-from-UtcTics  ;

: UtcTics-from-Time-today ( ss mm uu - f: UtcTics  )
    date-now UtcTics-from-Time&Date ;

f# 1e9     fconstant Nanoseconds
f# 86400e0 fconstant #SecondsToDay

: UtcTics-from-hm ( hhmmTodayUTC - ) ( f: - UtcTics )
   #100 /mod 0 -rot date-now  UtcTics-from-Time&Date ;

: UtcTill  ( hhmmTargetLocal -- ) ( F: -- UtcTics )
   UtcTics-from-hm  UtcTics-from-LocalTics @time f2dup f<
       if   fswap #SecondsToDay f+ fswap \ Next day when the time has past today
       then
    f- ;

: time>mmhh ( - mmhh )  local-time-now time-from-utctics #100 * + nip ;

: .Html-Time-from-UtcTics ( f: UtcTics - )
    base @ decimal
    Time-from-UtcTics
    bl swap ##$ +html
    2 0 do  [char] : swap ##$ +html  loop
    base ! ;

: .Time-from-UtcTics ( f: UtcTics - )
    base @ decimal
    Time-from-UtcTics
    bl swap ##$ type
    2 0 do  [char] : swap ##$ type  loop
    base ! ;

: .time   ( - )        local-time-now .Time-from-UtcTics ;
: .date   ( - )        date-now  .(date) ;

: Time&Date-from-UtcTics      ( f: UtcTics -  ss mm uu dd mm yearUtc )
   fdup Time-from-UtcTics Date-from-UtcTics ;

: Time&DateLocal-from-UtcTics ( f: UtcTics -  ss mm uu dd mm yearLocal )
   LocalTics-from-UtcTics Time&Date-from-UtcTics ;

: Time&Date ( -  ss mm uu dd mm yearLocal )
   local-time-now Time&Date-from-UtcTics ;

0 value time-server$ \ Pointer to the ip address that responds to GetTcpTime

: GetTcpTime ( - ) \ Sends: my-net-id" Ask_time
   HtmlPage$ off
   my-host-id" HtmlPage$ lplace
   s"  Ask_time" HtmlPage$ +lplace
   HtmlPage$ lcount time-server$ TcpWrite  ;

: SetLocalTime (  LocalTics UtcOffset sunrise sunset - )
   s>f to UtcSunSet   s>f  to UtcSunRise  drop
   s>f UtcTics-from-LocalTics f>s set-system-time  ; \ 05-12-2023 In UTC!

: AskTime ( - )                            \ Adapt if needed!
   time-server$ 0<>
     if     gettcptime                     \ To get the UTC-time from an RPI
     then ;

\ When gettcptime is used the time server should respond with a tcp packet like:
\ GET 1671279235 3600 1671259560 1671287340  TcpTime HTTP/1.1
\ That packet is handled by the word TcpTime.
\ See the webserver in sps30_web.fth for an example.
\ To define a time server use:
\ s" 192.168.0.201" dup 1+ allocate drop dup to time-server$ place

: check-time ( - )
   GotTime? 0=
     if    AskTime
     then   ;

\ Manual input:

: single? ( n$ cnt -- n ) (number?) 0= if ." Bad number" quit then d>s  ;

: extract-time ( hhmm[ss]$ cnt - seconds minutes hours )
   dup 6 = -rot 2>r
     if    2r@ 4 /string drop 2 single?
     else  0
     then
   2r@ 2 /string drop 2 single?
   2r> drop 2 single?
    ;

: extract-date ( ddmmyyyy$ cnt - day mnont year )
   2dup 2>r drop 2 single?
   2r@ 2 /string drop 2 single?
   2r> 4 /string drop 4 single? ;

: enter-input  ( length -- string cnt )  pad dup rot accept ;

: enter-timezone/UTC-time-offset ( - UTC-offset)
   3 enter-input  (number?)
     if    d>s #3600 *
     else  2drop tz-local dup find-utc-offset
           body> >name$  ." tz-local is deferred to: "  type f>s
     then ;


\ defer tz-local to the right timezone in your app.

: enter-date-time ( -- ss mm uu dd mm yearLocal utc-offset flag )
   cr ."   Date ddmmyyyy: " #8 dup >r enter-input
   dup r> <>  dup 0= s>f
        if   cr ." Date needs 8 positions. Like 21092023. "
        then
   extract-date dup #1970 <
       if   fdrop false s>f cr ." Year must bigger than 1969. "
       then
   >r 2>r   ."   Time hhmm[ss]: " 6 enter-input
   dup #4 < dup 0= s>f
       if cr ." Time needs at least 4 positions. Like 1245. "
       then
   extract-time  2r> r> f>s f>s and
   ."   Enter 't' for time zone or the UTC time offset: "
    enter-timezone/UTC-time-offset
   swap ;

: set-time     ( - )              \ Manual input for time
   base @ decimal
   enter-date-time                \ Got the time in LOCAL time
     if    >r UtcTics-from-Time&Date  f>s
           r> 0 0 SetLocalTime    \ sunrise and sunset are ignored here.
           space .date .time
     else  3drop 3drop drop cr ." Bad Time/date."
     then  space base ! ;

: SetLocalTime-from-network ( UtcTics UtcOffset sunrise  sunset - ) \ For TcpTime
   2swap tuck + swap 2swap SetLocalTime ;
\ \s
