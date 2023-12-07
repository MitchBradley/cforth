marker -schedule-tool.f   s" cforth" ENVIRONMENT?
   [IF]   drop cr lastacf .name #19 to-column .( 05-12-2023 ) \ By J.v.d.Ven
   [THEN]

0 [if]

NOTE: The local time should be right before running a schedule.
New or changed entries are executed when they are scheduled in the future.
Under Cforth schedule-tool.f can be flased into ROM.

There are 2 tables in use.
A schedule-table is linked to an options-table.
The schedule-table uses records-pointers for sorting.
The options-table is used to execute entries of schedule and in the dropdown of a HTML menu.

The CONTENT of the field sched.option is linked to the POSITION of a option-record.
Errors will occur when option-records are changed/deleted without changing/deleting.
the linked schedule-records.

Pointers should be initialized by the application.
[then]

decimal
       0 value    &schedule-file    \ A pointer to the filename of the schedule table


0 value &schedule-table

/table init-table to &schedule-table
#2 &schedule-table >#records !      \ Just a start, can be extended by the user.
#2 cells &schedule-table >record-size ! \  Map 1 schedule record:   Time-in-HHMM  Option#

: >aptr@>schedule-record# ( which# - record# )  &schedule-table nt>aptr @ &schedule-table >record-size @ / ;



\ The 2 fields:
: >sched.time       ( &record - >sched.time )  ; immediate
: >sched.option     ( &record - &Option# )   cell+ ;

: n>sched.time@     ( n - mmhh )    &schedule-table nt>record >sched.time @ ;
: n>sched.option@   ( n - option# ) &schedule-table nt>record >sched.option @ ;



         0 value &options-table     \ The inline options-table, NOT sorted.

3 cells constant /option-record     \ Map options record:    xt-option cnt-string-option adr-string-option
         0 value #option-records    \ Fixed when the application is loaded

: >opt.record  ( record#  - &record )  /option-record * &options-table + ; \ Fixed location, no relative adresses used.

\ Usage of the fields in the options-record:
: >opt.xt    ( &record - >opt.xt )  ; immediate
: opt.menu"  ( &option-record - adr cnt ) cell+ 2@ ; \ The discription of the option in the dropdown menu



: sched.record-->opt.record ( &schedule-record - &option-record flag-in-table ) \ linking a schedule-record
   >sched.option @  dup 0 #option-records within  swap >opt.record swap ;       \ to its option-record

#538976288 constant NoTime

0 value default-option \ Option# executed when there are no entries in the schedule

variable scheduled \ Entry lately has been scheduled

    true  value StopRunSchedule?
f# 0.0e0 fvalue boot-time


: next-scheduled-time ( - mmhh ) scheduled @ 1+ n>sched.time@  ;

: /schedule-file ( - #records )
   &schedule-file count file-exist?
     if   &schedule-file count r/w open-file drop
          dup file-size drop d>s swap close-file drop
          &schedule-table >record-size @ /
     else  20 \ 20 records to start
     then ;

: load-schedule ( - )
   &schedule-table >#records @  1+ &schedule-table >record-size @ *  dup allocate drop dup  &schedule-table !
   swap 2dup 120 fill
   &schedule-file count file-exist?
        if    &schedule-file count @file drop
        else  2drop
        then
  -1 scheduled !
   &schedule-table >#records @  dup allocate-ptrs dup &schedule-table  >table-aptrs !
   &schedule-table >record-size @  rot build-ptrs ;

10 value #new-records
: extend-schedule ( - )
   &schedule-table  >table-aptrs @ &schedule-table @  \ Old record-pointers and old schedule-table
   /schedule-file #new-records + &schedule-table >#records !  load-schedule dup
      if    free drop free drop \ free the old record-pointers and old schedule-table
      else  2drop
      then ;

0 value WaitForSleeping-

defer schedule-entry  \ When repeating is needed

: reset-schedule-entry ( - )  ['] noop is schedule-entry ;
reset-schedule-entry

S" gforth" ENVIRONMENT? [IF] 2drop \ No polling under gforth

0 value TidSchedule

: wait-if-later-today ( mmhh - )
   time>mmhh 2359 <
     if  time>mmhh over <
           if   #2359 min WaitUntil
           else drop
           then
     else  drop  60000 ms -1 scheduled !
     then  ;

: schedule ( - )      \ Execute entries for today that are waiting till the right time
   next-scheduled-time time>mmhh <= \  All entries should be complete at 23:59
           if     scheduled @ 1+ &schedule-table nt>record sched.record-->opt.record \ inside tabel?
                   if    s" Schedule: " pad place
                          >opt.xt @  dup >name$ +upad upad" +log
                         execute 1 scheduled +!
                   else  drop
                   then
           else   next-scheduled-time wait-if-later-today
           then ;

: find-schedule-record ( mmhh-done - record# ) \ On a sorted schedule table
   &schedule-table >#records @  swap  2359 min  \ The found time needs to be smaller or equal than 2359
   &schedule-table >#records @  0
      do  dup i n>sched.time@  <         \ search TILL mmhh-done is
             if     drop i 1- swap leave \  bigger than the the found time
             then                        \ in the schedule-table
      loop drop ;

   s" 0 1 cells key: schedule-timer  schedule-timer  Ascending bin-sort" evaluate
s" cell 1 cells key: schedule-option schedule-option Ascending bin-sort" evaluate

: sort-schedule     ( - )
  by[ schedule-option schedule-timer ]by  &schedule-table table-sort ;

: init-schedule ( &schedule-file - )
   to &schedule-file /schedule-file &schedule-table >#records !
   load-schedule sort-schedule ;

: run-schedule-loop ( - ) begin   schedule  again ;

: sync-schedule     ( - ) sort-schedule time>mmhh find-schedule-record dup scheduled !
                          0 max n>sched.time@ Wait-if-later-today
                          run-schedule-loop ;

: kill-schedule     ( - ) TidSchedule  kill false to StopRunSchedule? ;

: restart-schedule  ( - ) StopRunSchedule?
                              if  kill-schedule
                              then
                          ['] sync-schedule  execute-task to TidSchedule
                          true to StopRunSchedule? ;

: restart-changed-schedule  ( mmhh-done - )  drop restart-schedule ;

: start-schedule    ( - )  ['] sync-schedule  execute-task to TidSchedule
                           true to StopRunSchedule? ;

[ELSE]


: schedule ( - )
    StopRunSchedule?
      if time>mmhh #2359 >=
          if    &schedule-table >#records @   scheduled !
          else  scheduled @ 1+  dup &schedule-table >#records @  <
                  if  dup n>sched.time@ time>mmhh  <=
                         if  dup scheduled ! &schedule-table nt>record  dup sched.record-->opt.record
                                if    cr ." Schedule "
                                      swap >sched.time @ .mmhh
                                      >opt.xt @ dup space >name$ type
                                      execute
                                else  drop
                                then
                         else   drop \ outside schedule
                         then
                  else   drop  \ &schedule-table >#records @  exceeded
                  then
          then
      then ;

: kill-schedule ( - ) false to StopRunSchedule? ;

: find-schedule-record ( mmhh-done - record# ) \ On a sorted schedule table
   &schedule-table >#records @  swap  2359 min  \ The found time needs to be smaller or equal than 2359
   &schedule-table >#records @  0
      do  dup i n>sched.time@  <=         \ search as long as the mmhh-done is
             if     drop i 1- swap leave \ less or equal than the the found time
             then                        \ in the schedule-table
      loop drop ;

defer sort-schedule

: init-schedule ( &schedule-file - ) \ The keys must be defined in RAM.
   to &schedule-file /table init-table to &schedule-table
   #2 &schedule-table >#records !
   #2 cells &schedule-table >record-size !
   s" 0 1 cells key: schedule-timer  schedule-timer  Ascending bin-sort" evaluate
s" cell 1 cells key: schedule-option schedule-option Ascending bin-sort" evaluate
s" : (sort-schedule) ( - ) by[ schedule-option schedule-timer ]by &schedule-table table-sort ;" evaluate
s" ' (sort-schedule) is sort-schedule" evaluate
   extend-schedule ;

: restart-schedule ( - )
   sort-schedule time>mmhh find-schedule-record scheduled ! true to StopRunSchedule?  ;

: restart-changed-schedule  ( mmhh-done - )
   sort-schedule 1+ find-schedule-record  scheduled ! true to StopRunSchedule? ;

create-timer: ttimer-WaitForsleeping
1 value Sleep-till-sunset-option              \ The id for sleep-at-boot in &options-table


: tTilEnd  ( ttimer - ) ( f: us-waittime - us )  cell+ f@ f+ usf@ f- ;

: .msgTimeout ( - )
    cr f# 30e6 ttimer-WaitForsleeping tTilEnd f# 1e-6 f* fround f>s .
   ." seconds before deep-sleep."  ;

\  ttimer-WaitForsleeping start-timer   .msgTimeout

: .time-duration ( #seconds - )
   #3600 /mod bl swap ##$ type
   #60 /mod [char] : swap ##$ type
   [char] : swap ##$ type ;

: #seconds-deep-sleeping  ( #seconds - )
   dup .time-duration
   range-Gforth-servers 2@ -ArpRange 2000 ms
   esp-wifi-stop spiffs-unmount 1 rtc-clk-cpu-freq-set 10 ms
   cr ."  SLEEPING." 3 max  deep-sleep ;

60 60 * value seconds-before-sunset

: sleep-seconds-before-sunset        ( SecondsBeforeSunset - )
    UtcSunSet  local-time-now  f- s>f f- fdup f0>
       if    cr .date .time ."  Needed sleep " f>d drop  #seconds-deep-sleeping
       else  fdrop cr .date .time ."  No sleep needed."
             false to WaitForSleeping-
       then ;

: ftime-till-next-second ( - )
   usf@ fus>fsec fround fsec>fus  [ f# 1 fsec>fus ] fliteral us-to-deadline  ;

: scheduled-wakeup ( - #seconds )
   cr  .date .time ."  sleep-schedule deep-sleep time:"
   next-scheduled-time 2359 min  UtcTill f>s
   ftime-till-next-second fus ;

: (sleeping-schedule) ( - )
    next-scheduled-time 2359 min time>mmhh >
      if WaitForSleeping- 0=
           if    true to WaitForSleeping-  ttimer-WaitForsleeping start-timer
           else  f# 30e6 ttimer-WaitForsleeping tElapsed?
                   if    scheduled-wakeup  #seconds-deep-sleeping
                   else  .msgTimeout
                   then
           then
       then ;

: schedule|sunset ( - )
   next-scheduled-time 2359 > \ No entries in schedule?
     if    seconds-before-sunset sleep-seconds-before-sunset
     else  (sleeping-schedule)              \ Follow schedule
     then ;

: (sleep-till-sunset) ( - )                   \ OR untill an upcomming entry in the schedule
   UtcSunSet f0>                              \ will the sun set?
       if  WaitForSleeping- 0=                \ Waiting / countdown not started?
              if    true to WaitForSleeping-
                    ttimer-WaitForsleeping start-timer
              else  30000 ttimer-WaitForsleeping tElapsed?
                       if  cr schedule|sunset
                       else   .msgTimeout
                       then
              then
       then ;

: (sleep-at-boot)   ( - )
   boot-time date-from-utc-time date>jjjjmmdd
   local-time-now   date-from-utc-time date>jjjjmmdd =  \ Only today
      if 0 n>sched.option@
         Sleep-till-sunset-option = \ Is sleep-at-boot the FIRST entry in the schedule?
           if  (sleep-till-sunset)
           then
       then ;


[THEN]


: (StopRunSchedule)   ( - )
     StopRunSchedule?
       if     false to WaitForsleeping- ['] noop is schedule-entry  kill-schedule
       else   scheduled @  n>sched.time@  restart-changed-schedule
       then   ;


ALSO HTML

: schedule-html-header	( -- )   s" Schedule" html-header    ;

: <ScheduleButton>   ( btntxt cnt cmd cnt - ) \ For a small CSS button
   <Btn
   +html| "  style="padding: 1px 10px;  width: 90px; font-size: 16px";  class="btn">|
   Btn> ;

: add-schedule-lines  { xt-option-list -- }
   &schedule-table >#records @  0
      do  i n>sched.option@   0 #option-records 1- between
          if  +HTML| <form action="/Scheduled=| i >aptr@>schedule-record# .html +HTML| ">|
              <tr>
                <td> +HTML| <input type="time"|
                +HTML| value=|
                [char] :  i n>sched.time@  #100 /mod [char] " swap ##$ +html   ##$ +html
                +HTML| "id="I| i (.) +html +HTML| "|
                +HTML| name="nn" aria-label="nn">|
                +HTML| <input type="hidden"| NoName>
                </td>
             <td> s" nn" 1 <SELECT i n>sched.option@   xt-option-list execute </SELECT>  </td>
             <td> s" Set entry" s" SetEntrySchedule" <CssButton> </td>
           </tr> </form>
          then
      loop ;

: html-schedule-list ( xt-option-list - )
   +HTML| <table border="0" cellpadding="0" cellspacing="12" width="400px">|
      <tr> 2 <#tdL> +HTML| Daily schedule:| </td> </tr>
      <tr>   <td>  +HTML| Start| </td> <td>  +HTML| Action| </td>
             <td>  +HTML| Confirm| </td>
      </tr>
      <tr> ( xt-option-list - ) add-schedule-lines </tr>
      <tr>  <td> +HTML| <form action="/Scheduled=nn">|
                     s" Reboot" 2dup <cssbutton>
             </form> </td>
            <td> +HTML| <form action="/Scheduled=nn">|   \ <form>
                   StopRunSchedule?
                      if    s" Runs "
                      else  s" Stopped "
                      then  s" StopRunSchedule" <cssbutton>
            </form> </td>
            <td> +HTML| <form action="/Scheduled=nn">|
                      s" Add entry" s" AddEntrySchedule" <cssbutton>
             </form> </td>
      </tr>
   </table>
   </fieldset> </td> </tr> </table>
   </center> </h4> </body> </html> ;

: start-html-page
   schedule-html-header   +HTML| <body bgcolor="#FEFFE6">|
   <center> <h4>
   +HTML| <table border="0" cellpadding="0" cellspacing="2" width="20%">|
   <tr> <tdL> <fieldset> <legend> ;

: +TimeDate/legend ( - )
   local-time-now .Html-Time-from-UtcTics .HtmlBl
   date-now rot .html +HTML| -| swap .html  +HTML| -| .html +HTML| .| </legend> ;

: .schedule-record ( &schedule-record - )
    dup sched.record-->opt.record
      if   swap  3 spaces dup >sched.option @ .
                 3 spaces >sched.time @ .mmhh
                 opt.menu"  bl emit type
      else  2drop ." Free"
      then  ;

: .schedule ( - )
    cr ." # Option# Time  Execute"
    &schedule-table >#records @  0
      do   cr i dup .  &schedule-table >table-record .schedule-record
      loop ;

: .schedule-sorted ( - )
    cr ." # Option# Time  Execute"
    &schedule-table >#records @  0
      do   cr i dup .   &schedule-table nt>record .schedule-record
      loop ;

: add-options-dropdown ( option#-activated -- )
   #option-records 0
      ?do    i  >opt.record opt.menu" i 3 pick <<option-cap>>
      loop
   s" Remove " #option-records 3 roll <<option-cap>> ;


PREVIOUS

TCP/IP DEFINITIONS

: SetEntry-schedule  ( schedule.record#  hh mm #DropDown - )
   >r swap #100 * +   swap &schedule-table >table-record >sched.time dup >r !
   2r>
   over #option-records =
       if    NoTime over ! nip NoTime swap \ Remove entry
             scheduled @  n>sched.time@
       else  time>mmhh
       then  -rot >sched.option !
   &schedule-table @  &schedule-table table-size &schedule-file count file-it

   StopRunSchedule?
       if  restart-changed-schedule
       else  drop sort-schedule
       then ;

: set-initial-sched.Option ( &record - ) >sched.Option 0 swap ! ;

: freelist-full? ( - ior )
   true &schedule-table >#records @  0
      do  i &schedule-table >table-record >sched.Option @ #option-records >=
            if  i &schedule-table >table-record  NoTime over ! set-initial-sched.Option drop false leave
            then
      loop ;

: AddEntry-schedule ( - )
   scheduled @ n>sched.time@ >r   freelist-full?
      if  extend-schedule     \ When the freelist is full
          &schedule-table >#records @  1- &schedule-table >table-record set-initial-sched.Option
      then
   r> StopRunSchedule?
      if    restart-changed-schedule
      else  drop
      then ;

: StopRunSchedule   ( - )  (StopRunSchedule)   ;


S" cforth" ENVIRONMENT? [IF] DROP
        : clr-req-buf ( -- )    req-buf /req-buf s" %3A" BlankString 2drop ;
[ELSE]  : clr-req-buf ( -- )    req-buf lcount   s" %3A" BlankString 2drop ;
[THEN]

FORTH DEFINITIONS

\ \s
