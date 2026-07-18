marker -sps30_web.fth lastacf .name #19 to-column .( 01-07-2026 ) \ By J.v.d.Ven

0 [if]

To see the air quality in a web browser.
The SPS30 should be connected to an extra UART on the ESP32. See sps30.fth

The time zone can be changed with: tz-local ' America/New_York is tz-local
List possible time zones with:       2025 .list-summer-times
Write the change in MachineSettings.fth
See also timezones.f

[then]

[ifndef] SPS30 cr .( See readme.txt for installation. ) cr QUIT [THEN]
s" MachineSettings.fth" file-exist? [if] fl MachineSettings.fth [then]

ALSO HTML ALSO SPS30 DEFINITIONS DECIMAL

: add-line-sps30 ( addr -- )
   dup <tr> <tdR> f@  .Html-Time-from-UtcTics </td>
   1 floats +  #fields 1 - floats   bounds
       do    <tdR> i f@ fdup f# 3000e0 f> 
                 if  fdrop f# 0e0 
                 then 
             (f.2) +html </td>
             [ 1 floats ] literal
       +loop  </tr>  ;

: add-datalines-sps30 ( -- )
   &CBdata-sps30 circular-range drop dup  #20 - 0 max  ?do
      i &CBdata-sps30 >circular add-line-sps30
   loop ;

: add-sps30-header
   <tr>
       <td>  .HtmlBl </td>
     4 <#tdC> s" /home"    s" ug/m3" <<TopLink>> </td>
     5 <#tdC> s" /NumConc" s" #/cm3" <<TopLink>> </td>
       <tdR>  s" /Tps"     s" um"    <<TopLink>> </td>
   </tr>
   <tr>
   <tdR> 2 .HtmlSpaces +html| Time|  </td>
   <tdR> 2 .HtmlSpaces +html| pm1.0| </td>
   <tdR> 2 .HtmlSpaces +html| pm2.5| </td>
   <tdR> 2 .HtmlSpaces +html| pm4.0| </td>
   <tdR> 3 .HtmlSpaces +html| pm10|  </td>
   <tdR> 3 .HtmlSpaces +html| nc0.5| </td>
   <tdR> 3 .HtmlSpaces +html| nc1.0| </td>
   <tdR> 3 .HtmlSpaces +html| nc2.5| </td>
   <tdR> 3 .HtmlSpaces +html| nc4.0| </td>
   <tdR> 4 .HtmlSpaces +html| nc10|  </td>
   <tdR> 6 .HtmlSpaces +html| tps|   </td>
   </tr> ;

$E0F03D constant color-nc0.5
$00DFDF constant color-pm1.0
$06C40D constant color-pm2.5
$C30F3D constant color-pm4.0
$E3003D constant color-tps
0       constant color-pm10

DataItem: &Sps30Graph \ Properties for the temperature line (color etc)

: .html-uu:mm ( F: UtcTics -- )
   fdup f0>=
      if    bl  else  fabs [char] -  then
   >r Time-from-UtcTics
   r> swap ##$ +html
   [char] : swap ##$ +html  drop ;

: x-label-text-CBdata ( n -- )
   &CBdata-sps30 >circular f@ fdup
   .html-uu:mm .HtmlBl
   Jd-from-UtcTics Date-from-jd
   2drop .Html ;

0 value i#end
0 value i#start
f# 0e0 fvalue f-interval
0 value OffsetField

: set-interval ( #end #start -- ) ( f interval -- )
   to i#start to i#end to f-interval
   pm10-Offset to OffsetField ;

0 [if] \ Just for testing
: +recs ( start n -- ) \ add test records
   0  ?do
      dup i + s>f
      dup i +  &CBdata-sps30 >circular-head tuck !
      dup fdup f!
      dup fdup #4 floats + f!
      #10 floats +  f!
      &CBdata-sps30 incr-cbuf-count
   loop  drop ;

: .datalines ( -- )                      \ See the records in the CBdata.
   &CBdata-sps30 >max-records @ 0  ?do  \ Scan ALL records
      i &CBdata-sps30 >circular #10 floats +  f@  f0>  if
         cr  i &CBdata-sps30  >circular pm1.0-Offset + f@ fe.
         i &CBdata-sps30 >circular  pm10-Offset + f@ fe.
      then
   loop ;

: .circular ( -- )                     \ See the records in the CBdata.
   cr ." N  >circ-i  pm1.0 pm10"
   &CBdata-sps30 circular-range  ?do  \ Scan only the records in the circular-range
      cr i dup . 3 spaces &CBdata-sps30 >circular-index dup . 5 spaces
      &CBdata-sps30 >record-cbuf dup
      f@ fe. 2 spaces
      pm10-Offset + f@ fe.
   loop ;

[then]

: find-interval  ( -- #end #start ) ( f -- interval )
   &CBdata-sps30 circular-range  2dup -  1-   \ corrects # vert lines
   dup  SetXResolution  \ Scale line length to the number of gaps
   s>f #X_Lines   xResolution *  1- s>f f/ ;

: datapoint ( n>=0 -- addr )
   &CBdata-sps30 >circular OffsetField + ;

: lastdatapoint ( #end #start &DataLine -- ) ( F: -- val )
   3drop  &CBdata-sps30 circular-range drop 1-
   datapoint f@ ; \ Can be overwritten by realtime data

3 value DataLineWidth

: <poly_line_sequence_summed-up ( #end #start &dataline -- ) ( F: interval -- )
   <polyline_points  Maximized-fpoly-points>  ;

: PlotDataLine ( color offset -- )
   to OffsetField &Sps30Graph >r  r@ >color !
   i#end i#start  r@ >CfaDataLine perform f@  r@ >FirstEntry f!
   r@ >CfaDataLine perform f@  r@ >LastEntry f!
   i#end 1 max \ longer data line # xlabels
   i#start 1+ \  To get the first coordinates of the dataline
   r@ f-interval <poly_line_sequence_summed-up  DataLineWidth  r@ >Color @ poly_line>
   SendHtmlPage
   MinYBotExact r@ >MinStat f!  MaxYtopExact r@ >MaxStat f!
   Average r> >AverageStat f! ;

: .Legend ( color-pm -- ) 16 swap   s" &#9608; " <<FontSizeColor>> ;

0 value Compression-
: InitDataParms ( -- )
   Compression- \ drop 0
      if  f# 1.08e0  else  f# 1e0  then
   &Sps30Graph        >Compression f!
   ['] datapoint      &Sps30Graph    >CfaDataLine !
   ['] lastdatapoint  &Sps30Graph    >CfaLastDataPoint ! ;

: set-min-max  ( offset -- )
   to offsetfield  &sps30graph SetMinMaxY ;

: set-min-max-chart  ( HighOffset LowOffset-- )
   >r set-min-max
   MaxYtop
   i#end 1 max  dup s>f to MaxXtop  i#start 1+  r> set-min-max
   to MaxYtop
 \  <xb> <yb>  <xt> <yt>   F:<xb>   <yb>     <xt>      <yt>
   Hw.MinMax               MinXBot MinYBot   MaxXtop  MaxYtop set-gwindow  ;

: init-chart ( -- )
   ['] noop set-page
   +HTML| <table border="0" cellpadding="0" cellspacing="2" width="100%">|
   65 to BottomMargin   57 to RightMargin  65 to BottomMargin
   pm10-Offset to OffsetField
   find-interval set-interval
   InitSvgPlot
   #X_Lines dup 1-  i#end   i#start - *
   s>f to MaxXtop #Max_Y_Lines SetGrid
   i#end 1 max  dup s>f to MaxXtop  i#start 1+ dup s>f to MinXBot ;

: end-html-page-graph ( -- )
   4 .HtmlSpaces
   &CBdata-sps30 circular-range -  dup .html   +HTML|  records. |  2 <  if
      <br> +HTML|  The graph starts after 3 minutes.|
   then
   </td>
   <tdr> .forth-driven </td>
   </tr> </table> </fieldset>
   </td> </tr> </table> </body> </html> ;

: labelsBottom ( -- )
   &CBdata-sps30 circular-range 2dup - s>f nip
   ['] x-label-text-CBdata color-x-labels  Rotation-x-labels x-labels ;

: PlaceLabels ( -- )
   -4 3             color-y-labels-right ['] Anchor-Justify-right y-labels \ In left margin
   SvgWidth 104 - 3 color-y-labels-right ['] Anchor-Justify-left  y-labels \ In right margin
   labelsBottom </svg> ;

: nc-chart ( -- )
   init-chart nc10-Offset nc0.5-Offset set-min-max-chart
   color-nc0.5  nc0.5-Offset PlotDataLine
   color-pm1.0  nc1.0-Offset PlotDataLine
   color-pm2.5  nc2.5-Offset PlotDataLine  \ nc2.5 and nc4.0 are almost the same in the graph
   color-pm4.0  nc4.0-Offset PlotDataLine
   color-pm10   nc10-Offset  PlotDataLine
   PlaceLabels
   <tr> <tdL> .HtmlSpace +HTML| Number concentrations (#/cm3): |
   color-nc0.5 .Legend +HTML| nc0.5 |
   color-pm1.0 .Legend +HTML| nc1.0 |
   color-pm2.5 .Legend +HTML| nc2.5 |
   color-pm4.0 .Legend +HTML| nc4.0 |
   color-pm10  .Legend +HTML| nc10. | end-html-page-graph ;

: pm-chart ( -- )
   init-chart pm10-Offset pm1.0-Offset set-min-max-chart
   color-pm1.0  pm1.0-Offset PlotDataLine
   color-pm2.5  pm2.5-Offset PlotDataLine
   color-pm4.0  pm4.0-Offset PlotDataLine
   color-pm10   pm10-Offset  PlotDataLine
   PlaceLabels
   <tr> <tdL> .HtmlSpace +HTML| Mass concentrations (ug/m3) |
   color-pm1.0 .Legend  +HTML| pm1.0 |
   color-pm2.5 .Legend  +HTML| pm2.5 |
   color-pm4.0 .Legend  +HTML| pm4.0 |
   color-pm10  .Legend  +HTML| pm10. |
   end-html-page-graph ;

: tps-chart ( -- )
   init-chart tps-Offset set-min-max
 \ <xb> <yb>  <xt> <yt>   F:<xb>   <yb>     <xt>      <yt>
   Hw.MinMax               MinXBot MinYBot   MaxXtop  MaxYtop set-gwindow
   color-tps  tps-Offset PlotDataLine
   PlaceLabels
   <tr> <tdL>  color-tps .Legend
   +HTML| Typical particle size (um).|
   end-html-page-graph ;


\ ---- Options in schedule ----

: take-samples- ( -- )
   wakeUp reset-sps30 init-fmeasure
   3 startMeasurement ['] 1st-measurement SetStage ;

here dup to &options-table
\               Map: xt     cnt adr-string
' take-samples-  dup , >name$ , ,
' start-sleep    dup , >name$ , ,
' start-cleaning dup , >name$ , ,

here swap - /option-record  / to #option-records
create file-schedule-sps30 ," schedule-sps30.dat"

0 [if]
: SchedOptions-sps30 ( n -- )
   #option-records 0  do
      &options-schedule i  >Option-schedule Option-schedule"   i   3 pick <<option-cap>>
   loop
   s" Remove " #option-records 3 roll <<option-cap>> ;
[then]

\ ------------

: .pause-msg ( -- ) cr  ." [<Esc>,Pause,Resume,View,Html]" ;

: ms-next-second ( us-start -- #ms )
   f# 1e6 us-to-deadline fus>fms fround f>d drop  ;

: sensor+http-responder   ( timeout -- )
    accept-reconnect stages-  if
      dup abs .
   then  if
       handle-sps30 \  runs measurements and the schedule of the sps30
   else  http-responder
   then
   usf@ ms-next-second #20 max to poll-interval ;

: poll-pause-sps30 ( timeout -- )
   usf@ ms-next-second to poll-interval
    accept-reconnect 0=
     if   http-responder
     then
   WaitForsleeping-
     if   wakeUp-sps30 ['] sensor+http-responder to responder
     then  ;

: SitesIndex  ( -- )
   +HTML|  <a href="http://192.168.0.201:8080/SitesIndex" target="_top">Index</a> | ;

: Schedule-page  ( -- )
   start-html-page
   <strong> 
   [ifdef]  SitesIndex  SitesIndex [then]
   s" /system"   s" System"   <<TopLink>>
   s" /home" s" Home" <<TopLink>>  
   +HTML| Schedule| </strong>  .HtmlSpace 
   +TimeDate/legend
   ['] add-options-dropdown  html-schedule-list ;


: start-Sps30-page
   s" Sps30 " html-header
   +HTML| <body bgcolor="#FEFFE6">|
   <center> <h4>
   +HTML| <table border="0" cellpadding="0" cellspacing="2" width="20%">|
   <tr> <tdL> <fieldset> <legend> ;

f# 2e0 f# 60e0 f* fconstant seconds-around-wakup

: sleep-needed? ( -- flag )                       \ To handle timedrift after a long sleep. time-server$ depended.
   scheduled @ 1+ n>sched.time@
   hhmmUntil  seconds-around-wakup fabs  f<  if \ A new entry ?
      false  exit                                \ No sleep needed
   then
   0 n>sched.option@  Sleep-till-sunset-option =  \ Sleep option active? Then sleep until the next item!
   scheduled @ 1+ n>sched.time@  2359 < or  ;    \ Current entry inside schedule?


: check-sleep-schedule
   sleep-needed? if
      .pause-msg ."   Starting the sleeping-schedule" cr
      ['] poll-pause-sps30      to responder
      ['] (sleeping-schedule) is schedule-entry 
   then ;


:  <NoData> ( -- )
   <br>  +HTML| ------ No data yet. ------| <br>
   23 #900 #1 <hrWH> ;

ALSO TCP/IP DEFINITIONS

: TcpTime ( UtcTics UtcOffset sunrise  sunset -- ) \ Response to GetTcpTime see timediff.fth
   SetLocalTime
   usf@ fdup to start-tic  to tcycle
   tSps30 start-timer  tTotal start-timer
   boot-time f0=
     if   @time to boot-time
     then
   set-next-measurement-sps30
   cr .date .time bl emit tTotal start-timer restart-schedule
   check-sleep-schedule ;

: /set_time_form  ( -- )
   start-Sps30-page
   <strong> 
   [ifdef]  SitesIndex  SitesIndex [then]
   s" /system"   s" System"   <<TopLink>>
   s" /home" s" Home" <<TopLink>> 
   +HTML| Sps30 | </strong>  .HtmlSpace </legend>
   <br> +HTML| Set system date and time: |
   <br> <br> +HTML|  <form> <input type="datetime-local" name="sys_time_user" value="0"> |
   <br> <br> s" Set time" s" nn" <CssButton> </form>
   </tr> </fieldset>   </td> </tr> </table>
   </center>  </h4> </body> </html> ;


: /system  ( -- )
   start-Sps30-page
   <strong> [ifdef]  SitesIndex  SitesIndex [then]
   s" /home" s" Home" <<TopLink>> 
   +HTML| Sps30 | </strong>  .HtmlSpace </legend>
   <br> s" /Schedule" s" Schedule" <<TopLink>>  <br>
   <br> s" /set_time_form" s" Set time" <<TopLink>> <br> 
   <br> s" /transfer.html" s" Up/Download" <<TopLink>>  
   </form> </tr> </fieldset>   </td> </tr> </table>
   </center>  </h4> </body> </html> ;

: home-page ( -- )
   time-server$ GotTime? or if
      start-Sps30-page
         [ifdef]  SitesIndex  SitesIndex [then]
      s" /system"   s" System"   <<TopLink>>
      s" /list"     s" List"     <<TopLink>>
      s" /NumConc"  s" Number"   <<TopLink>>
      s" /Tps"      s" Tps"      <<TopLink>>
      +TimeDate/legend
      &cbdata-sps30 @  if
         pm-chart
      else
         <NoData>  then
   else  /set_time_form    \ Need a local time first
   then  ;

: sys_time_user ( -- ) \ Actions after /set_time_form
   parse-word
   2dup [char] - bl replace-all-by 
   2dup [char] T bl replace-all-by
   2dup [char] % bl replace-all-by
   2dup [char] A bl replace-all-by
   evaluate depth  if
      nip 0  swap rot  \ - Y m d H m s            \ Expects local time
      3 roll 4 roll 5 roll
      UtcTics-from-Time&Date utctics-from-localtics \ The clock runs in UTC
      f>s  0 0 0 SetLocalTime
      usf@ to tcycle
      tSps30 start-timer  tTotal start-timer
      usf@ to start-tic tTotal start-timer restart-schedule
      check-sleep-schedule
   then
   cr .date .time cr
   ['] /home set-page ;

: /NumConc ( -- )
   start-Sps30-page
     [ifdef]  SitesIndex  SitesIndex [then]
   s" /system"   s" System"   <<TopLink>>
   s" /list" s" List"         <<TopLink>>
   s" /home" s" Mass"         <<TopLink>>
   s" /Tps"  s" Tps"          <<TopLink>>
   +TimeDate/legend
   &cbdata-sps30 @  if  nc-chart  else  <NoData>  then ;

: /Tps ( -- )
   start-Sps30-page
     [ifdef]  SitesIndex  SitesIndex [then]
   s" /system"   s" System"   <<TopLink>>
   s" /list"    s" List"      <<TopLink>>
   s" /home"    s" Mass"      <<TopLink>>
   s" /NumConc" s" Number"    <<TopLink>>
   +TimeDate/legend
   &cbdata-sps30 @  if  tps-chart  else  <NoData>  then ;

: /list ( -- )    \ Builds the HTML-page starting at HtmlPage$
   ['] noop set-page  start-Sps30-page
     [ifdef]  SitesIndex  SitesIndex [then]
   s" /system"   s" System"   <<TopLink>>
   +HTML| List last 20 records  |  +TimeDate/legend
   +HTML| <table border="0" cellpadding="0" cellspacing="2" width="50%">|
   add-sps30-header
   add-datalines-sps30
   </table> </fieldset> </td> </tr> </table>
   </center> </h4> </body> </html> ;

\  ---- Schedule page ----

: /Schedule  ( -- ) ['] Schedule-page set-page ;
: /Scheduled ( -- ) clr-req-buf ['] Schedule-page set-page ;

: SetEntrySchedule \ ( id hh mm #DropDown -- ) | ( id  #DropDown -- )
   SetEntry-schedule  /Schedule ;

: AddEntrySchedule  ( -- ) addentry-schedule /Schedule ;


\  ---- End schedule ----

alias /NewPage  noop
' home-page is /home 
alias / /home

\ --------------


SPS30 DEFINITIONS


: init-res ( -- )
    wifi-connected@ 0=
     if  logon
     then
   1800 SleepIfNotConnected
   file-schedule-sps30 init-schedule
   init-HtmlPage
   InitDataParms
   #20 to #Max_X_Lines
   listener-socket -1 = if
      bold http-listen ." /home" norm
   then ;

PREVIOUS

: .inverted ( n -- not-n )  not dup  if  ."  Yes." else ."  No." then ;

0 value See_HTML

: set-responder ( key -- )
   case
        [char] p of cr ." Pause "  ['] poll-pause-sps30      to responder endof
        [char] r of cr ." Resume " ['] sensor+http-responder to responder endof
        [char] v of cr ." View stages:" stages- .inverted    to stages-   endof
        [char] h of cr See_HTML not dup
                       if    ." See HTML:"    ['] see-request
                       else  ." Silent HTML:" ['] (handle-request)
                       then                is handle-request to See_HTML  endof
          .pause-msg
   endcase ;

: empty-keybuf  ( -- )
   begin  key?
   while  key drop 50 ms
   repeat ;

: stop-sleep-sensor ( -- ) tTotal off stop-sleep-sps30 startSleep ;
' stop-sleep-sensor is action-before-deep-sleep


: Sleep30MinIfNotConnected
   ipaddr@ @ 0=
     if   stop-sleep-sensor 
          cr ." No connection. Entering sleep mode..."
          1800 deepsleep
     then ;

: program-loop ( -- )
   begin key?  
           if  key dup #27 =
               if   drop 
                    ONLY FORTH ALSO FORTH ALSO SPS30  order cr exit 
               else  set-responder
               then
           empty-keybuf
           then
         Sleep30MinIfNotConnected
         StopRunSchedule?
           if  schedule schedule-entry
           then
          usf@ ms-next-second responder
        \ 1 to fmeasure-complete es \ To test the schedule without an sps30
   again ;

: faster ( -- )
   1 to cycle-time
   1 to #max-samples
   f# 1e3 to time-1-sample
   f# 1e3 to warm-up-time ;


1 value sps30?

: send_ask_time ( -- )
   time-server$ 0<>
     if   cr ." Ask time from: " time-server$ count type
                ms@ >r asktime ms@ r> - dup space . ." ms " #1000 >
          if   cr ." Stream failed. Rebooting..." stop-sleep-sensor 1500 ms 3 DeepSleep
          then
     then ;

: set-timings ( -- )
   cr ." Cycle time: "   cycle-time f# 60000000 f/ f>s . ." minutes."
   cr ." Max log time: " /CBdata-sps30 s>f cycle-time f*
         f# 3600000000 f/ f>s 24 /mod . ." days and " . ." hours." cr
   ['] 1st-measurement SetStage
   cr ." Alarm-limit: " alarm-limit f.
   0  to WaitForSleeping-
   empty-keybuf
   cr ." The first results appear after 30 seconds in the list." cr
   time-server$ 0=
     if   space GotTime? 0=
               if  cr ." Enter the date and time in the webserver."
               then
     else  send_ask_time \ check-time
     then
   cr ;

: start-web-server  ( -- )
   cr .date .time
   cr htmlpage$ 0=
      if    init-res
      else  bold ." Listening on http://" ipaddr@ .ipaddr ." /home" norm
      then
   ['] sensor+http-responder to responder
   1000 to poll-interval restart-schedule
   cr ." Cpu at: " cpu_freq@ #1000000 / 0 ud,. ."  Mhz."
   TCP/IP SEAL sps30?
      if    init-sps30  wakeUp-sps30 #500 ms
            .device-information
            3 startMeasurement wait-status-reg #500 vtaskdelay
            init-fmeasure
      else  &RxBuf 0=
               if  init-res-sps30 wakeUp-sps30
               then
      then
   set-timings
   program-loop ;  \ Contains the loop of the server

f# 3.0e0 to alarm-limit


cr .free cr  ORDER cr

\ For debugging
\ ' see-request is handle-request \ To see the total received requests
\ ' see-command is handle-request \ To see the commands only of the received requests
 
' start-web-server is s

true to stages-

start-web-server
\  \s
