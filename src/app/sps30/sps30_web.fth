s" MachineSettings.fth" file-exist? [if] fl MachineSettings.fth [then]
marker -sps30_web.fth  cr lastacf .name #19 to-column .( 04-05-2023 ) \ By J.v.d.Ven

\ To see the air quality in a web browser.
\ The SPS30 should be connected to an extra UART on the ESP32. See sps30.fth

\ Needed in ROM:
needs /circular      ../esp/extra.fth
needs AskTime        ../esp/timediff.fth
needs Html	     ../esp/webcontrols.fth
needs svg_plotter.f  ../esp/svg_plotter.f

ALSO HTML ALSO SPS30 DEFINITIONS
needs handle-sps30   ../sps30/sps30.fth  \ Needs to be compiled in ROM

esp8266? [IF] cr .( Needs an extended version of Cforth on an ESP32! )
cr .( See https://github.com/Jos-Ven/cforth/tree/WIP  ) QUIT [THEN]

cr cr .(  WAIT for the webserver! ) cr

DECIMAL

: add-line-sps30 ( adr - )
   dup <tr> <tdR> f@  .Html-Time-from-UtcTics </td>
   1 floats +  #fields 1 - floats   bounds
       do    <tdR> i f@ (f.2) +html </td>
            [ 1 floats ] literal
       +loop  </tr>  ;

: add-datalines-sps30 ( - )
   &CBdata-sps30 circular-range drop dup  #20 - 0 max
       ?do   i &CBdata-sps30 >circular add-line-sps30
       loop ;

: add-sps30-header
   <tr>
       <td>  .HtmlBl </td>
     4 <#tdC> s" /home"    s" ug/m3" <<TopLink>> </td>
     5 <#tdC> s" /NumConc" s" #/cm3" <<TopLink>> </td>
       <tdR> s" /Tps"     s" um"    <<TopLink>> </td>
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

DataItem: &Sps30Graph \ Proporties for the temperature line (color etc)

: .html-uu:mm (  f: UtcTics - )
   fdup f0>=
      if   bl
      else fabs [char] -
      then
   >r Time-from-UtcTics
   r> swap ##$ +html
   [char] : swap ##$ +html  drop ;

: x-label-text-CBdata ( n - )
   &CBdata-sps30 >circular f@  fdup
   .html-uu:mm .HtmlBl
   Jd-from-UtcTics Date-from-jd
   2drop .Html ;

0 value i#end
0 value i#start
f# 0e0 fvalue f-interval
0 value OffsetField

: set-interval ( #end #start - ) ( f interval -  )
   to i#start to i#end to f-interval
   pm10-Offset to OffsetField ;

0 [if] \ Just for testing
: +recs ( start n - ) \ add test records
   0
       ?do   dup i + s>f
             dup i +  &CBdata-sps30 >circular-head tuck !
             dup fdup f!
             dup fdup #4 floats + f!
             #10 floats +  f!
             &CBdata-sps30 incr-cbuf-count
       loop drop ;

: .datalines ( - )                 \ See the records in the CBdata.
   &CBdata-sps30 >max-records @ 0  \ Scan ALL records
       ?do  i  &CBdata-sps30 >circular #10 floats +  f@  f0>
                if  cr  i &CBdata-sps30  >circular pm1.0-Offset + f@ fe.
                    i &CBdata-sps30 >circular  pm10-Offset + f@ fe.
                then
       loop ;

: .circular ( - )                   \ See the records in the CBdata.
   cr ." N  >circ-i  pm1.0 pm10"
   &CBdata-sps30 circular-range \ Scan only the records in the circular-range
       ?do   cr i dup . 3 spaces &CBdata-sps30 >circular-index dup . 5 spaces
             &CBdata-sps30 >record-cbuf dup
              f@ fe. 2 spaces
             pm10-Offset + f@ fe.
       loop ;

[then]

: find-interval  (  - #end #start ) ( f - interval )
   &CBdata-sps30 circular-range  2dup -  1-   \ corrects # vert lines
   dup  SetXResolution  \ Scale line length to the number of gaps
   s>f #X_Lines   xResolution *  1- s>f f/ ;

: datapoint ( n>=0 - adr )
   &CBdata-sps30 >circular OffsetField + ;

: lastdatapoint ( #end #start &DataLine  - ) ( f: - val )
   3drop  &CBdata-sps30 circular-range drop 1-
   datapoint f@ ; \ Can be overwritten by realtime data

3 value DataLineWidth

: <poly_line_sequence_summed-up ( #end #start &dataline -- ) ( f: interval - )
   <polyline_points  Maximized-fpoly-points>  ;

: PlotDataLine ( color offset -- )
   to OffsetField &Sps30Graph >r  r@ >color !
   i#end i#start  r@ >CfaDataLine perform f@  r@ >FirstEntry f!
   r@ >CfaDataLine perform f@  r@ >LastEntry f!
   i#end 1 max \ longer data line # xlabels
   i#start 1+ \  To get the first coordinates of the dataline
   r@ f-interval <poly_line_sequence_summed-up  DataLineWidth  r@ >Color @ poly_line>
   stream-html
   MinYBotExact r@ >MinStat f!  MaxYtopExact r@ >MaxStat f!
   Average r> >AverageStat f! ;

: .Legend ( color-pm - ) 16 swap   s" &#9608; " <<FontSizeColor>> ;

0 value Compression-
: InitDataParms ( - )
   Compression- \ drop 0
      if  f# 1.08e0
      else f# 1e0
      then
   &Sps30Graph        >Compression f!
   ['] datapoint      &Sps30Graph    >CfaDataLine !
   ['] lastdatapoint  &Sps30Graph    >CfaLastDataPoint ! ;

: set-min-max  ( offset -- ) ( - )
   to offsetfield  &sps30graph SetMinMaxY ;

: set-min-max-chart  ( HighOffset LowOffset-- )
   >r     set-min-max
   MaxYtop
   i#end 1 max  dup s>f to MaxXtop  i#start 1+  r> set-min-max
   to MaxYtop
 \  <xb> <yb>  <xt> <yt>   F:<xb>   <yb>     <xt>      <yt>
   Hw.MinMax               MinXBot MinYBot   MaxXtop  MaxYtop set-gwindow  ;

: init-chart ( - )
   ['] noop set-page
   +HTML| <table border="0" cellpadding="0" cellspacing="2" width="100%">|
   65 to BottomMargin   57 to RightMargin  65 to BottomMargin
   pm10-Offset to OffsetField
   find-interval set-interval
   InitSvgPlot
   #X_Lines dup 1-  i#end   i#start - *
   s>f to MaxXtop #Max_Y_Lines SetGrid
   i#end 1 max  dup s>f to MaxXtop  i#start 1+ dup s>f to MinXBot ;

: end-html-page-graph ( - )
   4 .HtmlSpaces
   &CBdata-sps30 circular-range -  dup .html   +HTML|  records. |  2 <
      if  <br> +HTML|  The graph starts after 3 minutes.|
      then
   </td>
   <tdr> .forth-driven </td>
   </tr> </table> </fieldset>
   </td> </tr> </table> </body> </html> ;

: labelsBottom ( - )
   &CBdata-sps30 circular-range 2dup - s>f nip
   ['] x-label-text-CBdata color-x-labels  Rotation-x-labels x-labels ;

: PlaceLabels ( - )
   -4 3             color-y-labels-right ['] Anchor-Justify-right y-labels \ In left margin
   SvgWidth 104 - 3 color-y-labels-right ['] Anchor-Justify-left  y-labels \ In right margin
   labelsBottom </svg> ;

: nc-chart ( - )
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

: pm-chart ( - )
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

: tps-chart ( - )
   init-chart tps-Offset set-min-max
 \ <xb> <yb>  <xt> <yt>   F:<xb>   <yb>     <xt>      <yt>
   Hw.MinMax               MinXBot MinYBot   MaxXtop  MaxYtop set-gwindow
   color-tps  tps-Offset PlotDataLine
   PlaceLabels
   <tr> <tdL>  color-tps .Legend
   +HTML| Typical particle size (um).|
   end-html-page-graph ;


\ ----------- schedule ---

here dup to &options-table
\               Map: xt     cnt adr-string
' take-samples-  dup , >name$ , ,
' start-sleep    dup , >name$ , ,
' start-cleaning dup , >name$ , ,


\ ' initial-sleep  dup , >name$ , ,

here swap - /option-record  / to #option-records
create file-schedule-sps30 ," schedule-sps30.dat"

0 [if]
: SchedOptions-sps30 ( n -- )
   #option-records 0
      do    &options-schedule i  >Option-schedule Option-schedule"   i   3 pick <<option-cap>>
      loop
  s" Remove " #option-records 3 roll <<option-cap>> ;
[then]


\ ------------

: .pause-msg ( - ) cr  ." [<Esc>,Pause,Resume,View,Html]" ;

: sensor+http-responder   ( timeout -- )
   timed-accept us@ >r stages-
       if  dup abs .
       then
       if   handle-sps30 \  runs measurements and the schedule of the sps30
       else http-responder
       then
   1000 us@ r> - 1000 / - 200 max ms>ticks to poll-interval ;

: poll-pause-sps30 ( timeout -- )
   1000 ms>ticks to poll-interval
   timed-accept 0=
     if  http-responder
     then
   StopRunSchedule?
     if  schedule schedule-entry
     then
;

: SitesIndex  ( - )
   +HTML|  <a href="http://192.168.0.201:8080/SitesIndex" target="_top">Index</a> | ;

: Schedule-page  ( - )
   start-html-page
   [ifdef]  SitesIndex  SitesIndex [then]
   s" /list"    s" List"      <<TopLink>>
   s" /home"    s" Mass"      <<TopLink>>
   s" /NumConc" s" Number"    <<TopLink>>
   s" /Tps"     s" Tps"       <<TopLink>>
   +TimeDate/legend
   ['] add-options-dropdown  html-schedule-list ;


: start-Sps30-page
   s" Sps30 " html-header
  +HTML| <body bgcolor="#FEFFE6">|
   <center> <h4>
   +HTML| <table border="0" cellpadding="0" cellspacing="2" width="20%">|
   <tr> <tdL> <fieldset> <legend> ;

2 constant minutes-wakup-ahead

: sleep-needed? ( - flag )
    scheduled @ 1+ n>sched.time@  time>mmhh - minutes-wakup-ahead < \ A new entry in sight ?
       if false exit                               \ No sleep needed
       then
    0 n>sched.option@  Sleep-till-sunset-option =  \ Sleep option active? Then sleep until the next item!
    scheduled @ 1+ n>sched.time@  2359 < and  ;    \ Current entry inside schedule?


ALSO TCP/IP DEFINITIONS

: TcpTime ( UtcTics UtcOffset sunrise  sunset - ) \ Response to GetTcpTime see timediff.fth
   SetLocalTime
   ms@ to start-tic
   boot-time f0=
     if   @time to boot-time
     then
   set-next-measurement-sps30
   cr .date .time bl emit tTotal start-timer restart-schedule
   sleep-needed?     \ if true sleep until the next item in the schedule
      if  .pause-msg ."   Starting the sleeping-schedule" cr
          ['] poll-pause-sps30      to responder
          ['] (sleeping-schedule) is schedule-entry
      then ;

: /set_time_form  ( - )
   start-Sps30-page
   s" /home" s" Chart" <<TopLink>>
   <strong> +HTML| Sps30 | </strong>  .HtmlSpace </legend>
   <br> +HTML| Set system date and time: |
   <br> <br> +HTML|  <form> <input type="datetime-local" name="sys_time_user" value="0"> |
   <br> <br> s" Set time" s" nn" <CssButton> </form>
  </tr> </fieldset>   </td> </tr> </table>
  </center>  </h4> </body> </html> ;

: /home ( - )
   time-server$ GotTime? @ or
      if    start-Sps30-page
            [ifdef]  SitesIndex  SitesIndex [then]
            s" /set_time_form" s" Set time" <<TopLink>>
            s" /Schedule" s" Schedule" <<TopLink>>
            s" /list"     s" List"     <<TopLink>>
            s" /NumConc"  s" Number"   <<TopLink>>
            s" /Tps"      s" Tps"      <<TopLink>>
            +TimeDate/legend
            pm-chart
      else  /set_time_form  \ Need a local time first
      then  ;


: sys_time_user ( - ) \ Actions after /set_time_form
  parse-word
  2dup [char] - remove_seperator
  2dup [char] T remove_seperator
  2dup [char] % remove_seperator
  2dup [char] A remove_seperator
  evaluate nip 0
  swap rot \ - Y m d H m s
  3 roll 4 roll 5 roll
  UtcTics-from-Time&Date f>s 0 0 0 SetLocalTime
  ms@ to start-tic tTotal start-timer restart-schedule
  cr .date .time cr
  ['] /home set-page ;

: /NumConc ( - )
   start-Sps30-page
   [ifdef]  SitesIndex  SitesIndex [then]
   s" /Schedule" s" Schedule" <<TopLink>>
   s" /list" s" List"         <<TopLink>>
   s" /home" s" Mass"         <<TopLink>>
   s" /Tps"  s" Tps"          <<TopLink>>
   +TimeDate/legend
   nc-chart ;

: /Tps ( - )
   start-Sps30-page
   [ifdef]  SitesIndex  SitesIndex [then]
   s" /Schedule" s" Schedule" <<TopLink>>
   s" /list"    s" List"      <<TopLink>>
   s" /home"    s" Mass"      <<TopLink>>
   s" /NumConc" s" Number"    <<TopLink>>
   +TimeDate/legend
   tps-chart ;

: /list ( -- )    \ Builds the HTML-page starting at HtmlPage$
   ['] noop set-page  start-Sps30-page
   [ifdef]  SitesIndex  SitesIndex [then]
   s" /Schedule" s" Schedule" <<TopLink>>
   +HTML| List last 20 records  |  +TimeDate/legend
   +HTML| <table border="0" cellpadding="0" cellspacing="2" width="50%">|
   add-sps30-header
   add-datalines-sps30
   </table> </fieldset> </td> </tr> </table>
   </center> </h4> </body> </html> ;

\  ---- Schedule page ----

: /Schedule  ( - ) ['] Schedule-page set-page ;

: SetEntrySchedule \ ( id hh mm #DropDown - ) | ( id  #DropDown - )
   SetEntry-schedule  /Schedule ;

: AddEntrySchedule  ( - ) addentry-schedule /Schedule ;


\  ---- End schedule ----

alias /NewPage  noop
alias / /home

\ --------------


PREVIOUS SPS30 DEFINITIONS


: init-res ( - )
   ['] sensor+http-responder to responder
   wifi-logon-state  -2 =
     if  #500000 us logon
     then
   1800 SleepIfNotConnected
   s" 192.168.0.212" dup 1+ allocate drop dup to msg-board$ place
   s" 192.168.0.201" dup 1+ allocate drop dup to sensor-web$  place

\   s" -" tmp$ lplace ipaddr@ ipaddr$ 10 /string tmp$ +lplace
\   s" - Sps30 sensor." tmp$ +lplace
\   tmp$ lcount dup 1+ allocate drop dup to pagetitle$ place

   file-schedule-sps30 init-schedule
   init-HtmlPage

   InitDataParms
   #20 to #Max_X_Lines
   http-listen ;

: .inverted ( n - not-n )  not dup  if  ."  Yes." else ."  No." then ;

0 value See_HTML

: set-responder ( key - )
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

: program-loop ( - )
   begin key?
           if  key dup #27 =
               if   drop
                    2 ms 3 rtc-clk-cpu-freq-set
                    cr esp-clk-cpu-freq 1000000 / . ." Mhz "
                    +f ONLY FORTH ALSO SPS30  order cr quit
               else  set-responder
               then
           begin  key?  while key  drop
           repeat
           then
         1800 SleepIfNotConnected    \ Sleep for 30 minutes if there is no wifi connection
         poll-interval responder
        \  1 to fmeasure-complete es \ To test the schedule without a sps30
   again ;

: faster ( - )
   1 to cycle-time
   1 to #max-samples
   #1000 to time-1-sample
   #1000 to warm-up-time ;


1 value sps30?

: send_ask_time ( - )
   time-server$ 0<>
     if     cr ." Ask time from: " 100 ms time-server$ count type
            ms@ >r asktime ms@ r> - dup space . ." ms "  1000 >
                 if   cr ." Stream failed. Rebooting." 1500 ms 3 DeepSleep
                 then
     then ;

: start-web-server  ( -- )
   cr htmlpage$ 0=
       if      init-res
       else    restart-schedule
               ." Listening again."
       then
   TCP/IP SEAL
   sps30?
      if  init-sps30 .device-information
              3 startMeasurement wait-status-reg
              init-fmeasure
      else  &RxBuf 0=
               if  init-res-sps30
               then
      then
   cr ." Cycle time: "   cycle-time 60000 / . ." minutes."
   cr ." Max log time: " /CBdata-sps30 cycle-time *
         3600000 / 24 /mod . ." days and " . ." hours." cr
   ['] 1st-measurement SetStage
   10 ms 1 rtc-clk-cpu-freq-set
   cr esp-clk-cpu-freq 1000000 / . ." Mhz "
   cr ." Alarm-limit: " alarm-limit f.
   0  to WaitForSleeping-
   send_ask_time \ check-time
   500 ms>ticks to poll-interval
   cr ." The first results appear after 30 seconds in the list." cr
   cr cr ." Now, the webserver is active!  "
   time-server$ 0=
     if   cr ." Enter the date and time in the webserver." cr
     then
   program-loop   \ Contains the loop of the server
 ;

f# 3.0e0 to alarm-limit



cr .free cr  ORDER cr

\ ' see-request is handle-request
: s start-web-server ;

true to stages-

start-web-server
\  \s
