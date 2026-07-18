marker -ntc_web.fth lastacf .name #20 to-column .( 19-06-2026 ) \ By J.v.d.Ven

\ ntc_web.fth to see the measured temperature from an NTC in a browser.
\ Compile this file in RAM when the ESP32 boots.

[ifndef] av-ntc cr .( av-ntc is missing. See readme.txt for installation. ) cr QUIT [THEN]

0 value sensor-web$  \ Used when the sensor-web is not active at port 8899
0 value msg-board$   \ Used when there is no message board at port 8899


s" MachineSettings.fth" file-exist?  \ For av-trim sensor-web$ and msg-board$
  [if]    fl MachineSettings.fth
  [then]


DECIMAL ALSO HTML

5 constant adc-channel

DataItem: &NtcGraph     \ Properties for the temperature line (color etc)

\ &sample-buffer-ntc  \ Pointer to the samples of the ADC. The results are passed to &CBdata
 60 to /sample-buffer-ntc  \ Max number of records for &sample-buffer-ntc
/sample-buffer-ntc to #max-samples

  0 value &CBdata  \ Pointer to a circular buffer. Map 2 floats: TimeInUTC temperature
960 value /CBdata  \ Max number of records in circular buffer for the temperature

: ntc-temp ( -- TempCelcius )  adc-channel adc-mv-av Vntc Rntc ntc-sh av-trim f+ ;

0 [if]  \ Just for testing
: +recs ( StartLevel NumberOfRecords -- ) \ add test records
   0 ?do
      dup i + s>f
      &CBdata >circular-head dup fdup f!
      #1 floats + f!
      &CBdata  incr-cbuf-count
   loop drop ;

: .datalines ( -- )         \ See the records in the circular buffer.
   &CBdata >max-records @ 0  ?do   \ Scan ALL records
      i  &CBdata >circular f@  f0<>  if
         cr i &CBdata >circular  f@ fe.
         i &CBdata >circular  #1 floats + f@ fe.
      then
   loop ;

: .circular ( -- )         \ See the records in the circular buffer.
   cr ." N   >circ-i    Tic          temp (C)"
   &CBdata circular-range  ?do \ Scan only the records in the circular-range
      cr i dup . 3 spaces
      &CBdata >circular-index dup . 5 spaces
      &CBdata >record-cbuf dup f@ f. 2 spaces
      #1 floats + f@ fe.
   loop ;
[then]

\ To send a msg over the network.

#80 allocate drop value state$
variable latest-temperature  1234 latest-temperature !
variable server-id 28 server-id ! \ id of this server

: +Fstate ( addr count -- )   state$ +lplace ;

: +StateVar      (  addrVar letter$ --)
   sp@ 1 +Fstate drop
   @ (.) state$ +lplace
   s"  " +Fstate ;

variable n/a -4141 n/a !
variable #Floor  0 #Floor  !

: Sent-state ( -- )
   sensor-web$ 0<>
   if  state$ off
       s" /Floor "                  +Fstate
       #Floor             [char] F  +StateVar
       latest-temperature [char] T  +StateVar
       n/a                [char] H  +StateVar
       n/a                [char] 1  +StateVar
       n/a                [char] 2  +StateVar
       n/a                [char] D  +StateVar
       ms@ here ! here    [char] M  +StateVar
       server-id          [char] @  +StateVar
       s"  "                        +Fstate
       state$ lcount  sensor-web$  UdpWrite
   then ;

: sent-temp-hum-to-msgboard  ( -- )
   msg-board$ 0<>  if
      decimal s" -2130706452 F0 T:" state$ lplace
      latest-temperature @  #10 /  #256 * #256 * (.)  state$ +lplace
      state$  lcount  msg-board$   UdpWrite
   then ;

0 [if] \ Some tests
2234   latest-temperature ! sent-temp-hum-to-msgboard \ = 22
1234   latest-temperature ! sent-temp-hum-to-msgboard \ = 12

943   latest-temperature ! sent-temp-hum-to-msgboard \
123   latest-temperature ! sent-temp-hum-to-msgboard \
103   latest-temperature ! sent-temp-hum-to-msgboard \


220 latest-temperature ! sent-temp-hum-to-msgboard \ = 2.2
120 latest-temperature ! sent-temp-hum-to-msgboard \ = 1.2

20   latest-temperature ! sent-temp-hum-to-msgboard \ = 0.2
10   latest-temperature ! sent-temp-hum-to-msgboard \ = 0.1

0   latest-temperature ! sent-temp-hum-to-msgboard \ = 0.0

-10   latest-temperature ! sent-temp-hum-to-msgboard \ = -0
-20   latest-temperature ! sent-temp-hum-to-msgboard \ = -2
-92   latest-temperature ! sent-temp-hum-to-msgboard \ = -9
[then]

f# 5e0 f# 60e0 f* fvalue fcycle-time \ Time between two records in &CBdata

0 value next-measurement-ntc
2 value #fields

: (local-time-now) ( F: -- tics-unchecked )   get-secs s>f localtics-from-utctics ;
: temp-sym ( -- ) &deg +HTML| C | ;

: set-next-measurement-ntc ( -- )
   (local-time-now) fdup fdup   fcycle-time f+
   fcycle-time f/ ftrunc fcycle-time f*
   fswap f- f# 3e0  f- f# 1e0 fmax
   cr ." New results after:" fdup f. ." seconds  " f+ f>s to next-measurement-ntc ;

: clear-CBdata ( &cBufParms -- )
   dup >r >&data-buffer @   r@ >max-records @ #fields floats * bounds  do
      f# 0e0 i f!    [ 1 floats ] literal
   +loop
   r> >cbuf-count off ;

: send-data ( -- )        \ *2
   av-ntc fdup
   f# 10e0 f* fround f# 10e0 f* f>s
   latest-temperature !  sent-temp-hum-to-msgboard Sent-state
   &CBdata >circular-head local-time-now dup f!
   [ 1 floats ] literal + f! &CBdata incr-cbuf-count
   1 to fmeasure-complete  ;

: take-ntc-samples ( -- )  \ *1
   GotTime? 0=  if
      time-server$  0<>  if
         check-time \ Get the time from a local network
      else
         set-time  \ Input the time by hand.
      then
   then
   ntc-temp
   &sample-buffer-ntc >circular-head f!
   &sample-buffer-ntc incr-cbuf-count
   &sample-buffer-ntc >cbuf-count @ #max-samples >=
      if   ['] send-data SetStage  then ;

: wait-for-next-sample ( -- )  \ *5
   (local-time-now) f>s next-measurement-ntc >  if  \  tTotal tElapsed?
      .tcycle   stages- if
         ." End " &CBdata >cbuf-count ?  .time cr
      then
   tTotal start-timer usf@ to tcycle
   ['] take-ntc-samples SetStage
   then ;

: handle-ntc ( -- )
   'stage  execute  fmeasure-complete 1 =  if
      0 to fmeasure-complete
      set-next-measurement-ntc
      ['] wait-for-next-sample SetStage
   then ;

: add-data-header
   <tr>
   <tdR> 3 .HtmlSpaces +html| Time| </td>
   <tdR> 2 .HtmlSpaces  +html| Temperature| </td>
   <td> +html| (| temp-sym +html| )| 
    </td>
   </tr> ;

1 floats constant TempOffset
 $C30F3D constant TempColor

: datapoint ( n>=0 -- addr )  &CBdata >circular 1 floats + ;

: lastdatapoint ( #end #start &DataLine  -- ) ( F: -- val )
   3drop  &CBdata circular-range drop 1-
   datapoint f@ ; \ realtime data can also be used.

: InitDataParms ( -- )
   f# 1e0             &NtcGraph    >Compression f!
   ['] datapoint      &NtcGraph    >CfaDataLine !
   ['] lastdatapoint  &NtcGraph    >CfaLastDataPoint ! ;

: MoveLeft_InRightMargin ( #pixels -- Y-pos ) SvgWidth swap - ;

: .html-uu:mm (  F: UtcTics -- )
   fdup f0>=  if
      bl
   else
      fabs [char] -
   then
   >r Time-from-UtcTics
   r> swap ##$ +html
   [char] : swap ##$ +html  drop ;

: add-x-label-text ( n -- )
   &CBdata >circular f@  fdup
   .html-uu:mm .HtmlBl
   Jd-from-UtcTics Date-from-jd 2drop .Html ;

: labelsBottom ( -- )
   &CBdata circular-range 2dup - s>f nip
   ['] add-x-label-text color-x-labels  Rotation-x-labels x-labels ;

: y-labels-left ( -- )
   -4 3 TempColor ['] Anchor-Justify-right  y-labels ;

: y-labels-right ( -- )
   104 MoveLeft_InRightMargin
   3   TempColor ['] Anchor-Justify-left y-labels ;

: find-interval  ( -- #end #start ) ( f -- interval )
   &CBdata circular-range  2dup - 1-  dup SetXResolution
   s>f #X_Lines xResolution * 1- 1 max s>f f/ ;

3 value DataLineWidth

: PlotDataLine  ( #end #start &DataLine  -- ) ( F: interval -- )
   >r swap 1 max swap 1+ 2dup
   r@ >CfaDataLine perform f@  r@ >FirstEntry f!
   r@ >CfaDataLine perform f@  r@ >LastEntry f!
   r@ <poly_line_sequence  DataLineWidth  r@ >Color @ poly_line>
   MinYBotExact r@ >MinStat f!  MaxYtopExact r@ >MaxStat f!
   Average r> >AverageStat f! ;

: .Legend ( color-pm -- ) 16 swap   s" &#9608; " <<FontSizeColor>> ;

: (f.3) ( F: n -- ) ( -- addr cnt )
   1000.00f f>dint <# # # # .#-> ;

: add-line-ntc ( addr -- )
   dup <tr>    <tdR> f@  .Html-Time-from-UtcTics </td>
   1 floats +  <tdR> f@  (f.3) +html </td>
   </tr>  ;

: add-datalines-ntc ( -- )
   &CBdata circular-range drop dup  #20 - 0 max  ?do
      i &CBdata >circular add-line-ntc
   loop ;

:  <NoData> ( -- )  <br>  +HTML| ------ No data yet. ------| <br> ;
 
: .latest-temp ( -- )
   +HTML|  Latest: | av-ntc fdup (f.3) +html temp-sym 
   &CBdata circular-range drop dup #12 >= if
     +HTML| . Change since last hour: | 
       #12 - 0 max &CBdata >circular 1 floats + f@ f- (f.3) +html temp-sym
   else 
      fdrop drop
   then
 ;  
 
: html-chart ( -- )
   &cbdata @  if
     57 to RightMargin  65 to BottomMargin
     InitSvgPlot
     TempColor &NtcGraph >color !
     find-interval  >r
     #X_Lines dup 1- r@ * s>f to MaxXtop #Max_Y_Lines  SetGrid
     r> &NtcGraph PlotDataLine
     y-labels-left y-labels-right labelsBottom
     </svg>
     <tr> <tdL>
     TempColor .Legend  +HTML| Temperature (| temp-sym  +HTML| ).|
     &CBdata circular-range -  dup .html   +HTML|  records.| .latest-temp  2 <  if
        +HTML|  The graph starts after 5 minutes.|
     then
     <td>
  else
     <NoData>
  then
  <tdR> .forth-driven  <td>
  </tr> ;

: start-ntc-page ( -- )
   s" Ntc " html-header  +HTML| <body bgcolor="#FEFFE6">|
   <center> <h4>
   +HTML| <table border="0" cellpadding="0" cellspacing="2" width="30%">|
   <tr> <tdL> <fieldset> +html| <legend align="left">|
      [ifdef]   SitesIndex SitesIndex
      [then] ;

: set_time_form  ( -- )
   start-ntc-page
   s" /home" s" Chart" <<TopLink>>
   <strong> +HTML| Snapshots ntc&nbsp;| </strong>  .HtmlSpace </legend>
   <br> +HTML| Set system date and time: |
   <br> <br> +HTML|  <form> <input type="datetime-local" name="sys_time_user" value="0"> |
   <br> <br> s" Set time" s" nn" <CssButton> </form>
   </tr> </fieldset>   </td> </tr> </table>
   </center>  </h4> </body> </html> ;

: home-page  ( -- )
   time-server$ GotTime? or  if
      start-ntc-page
      s" /set_time_form" s" Set time" <<TopLink>>
      s" /list" s" Snapshots" <<TopLink>>
      <strong> +HTML| Chart ntc | </strong> +TimeDate/legend
      +HTML| <table border="0" cellpadding="0" cellspacing="0"  heigth="1%" width="900px">|
      html-chart
      </table>
      </fieldset> </td> </tr> </table>
   else
      set_time_form  \ Need a local time first
   then  ;

: List-page  ( -- )    \ Builds the HTML-page starting at HtmlPage$
   start-ntc-page
   s" /home" s" Chart" <<TopLink>>
   <strong> +HTML| Snapshots ntc&nbsp;| </strong>  .HtmlSpace </legend>
   +HTML| <table border="0" cellpadding="0" cellspacing="2"  width="250px">|
              add-data-header add-datalines-ntc  </tr>
          </table> </fieldset>
  </td> </tr> </table>
  </center>
  </h4> </body> </html> ;

ALSO TCP/IP DEFINITIONS

: /set_time_form  ( -- )  ['] set_time_form set-page ;
: sys_time_user ( -- ) \ Actions after /set_time_form
  parse-word
  2dup [char] - bl replace-all-by 
  2dup [char] T bl replace-all-by 
  2dup [char] % bl replace-all-by 
  2dup [char] A bl replace-all-by 
  evaluate nip 0
  swap rot \ - Y m d H m s
  3 roll 4 roll 5 roll
  UtcTics-from-Time&Date UtcTics-from-LocalTics f>s 0 0 0 SetLocalTime
  tTotal start-timer GotTime? . usf@ to tcycle  ['] take-ntc-samples SetStage
  0 to fmeasure-complete
  cr .date .time cr
  /home ;

: /List  ( -- )    \ /List Builds the HTML-page starting at HtmlPage$
   ['] List-page set-page ;

FORTH DEFINITIONS TCP/IP

: sensor+http-responder  ( timeout -- ) \ Handles ntc + http-responder KEEP
    accept-reconnect  ms@ >r stages-
       if  dup abs .
       then
       if   handle-ntc
       else http-responder
       then
   1000 ms@ r> - 0 max - 200 max to poll-interval ;

: program-loop ( -- )
   begin
      poll-interval responder key?  if
         key escape =  if
            +a exit
         else
            begin  key?  while  key drop  repeat
         then
      then
   again ;

: initial-logon ( -- )
     wifi-connected@ 0= if
      logon wifi-connected@ 0=   if
          esp-wifi-stop  100 ms [ 30 60 * ] literal deep-sleep \ Retry after 30 minutes
      then
   then ;

: init-res (  -- )
   2 set-precision
   1 floats /sample-buffer-ntc allocate-cbuffer to &sample-buffer-ntc \ ADC
   clr-sample-buffer-ntc
   cr ntc-temp fdup f.
   f# 10e0 f* fround f# 10e0 f* f>s latest-temperature !
   logon
   init-HtmlPage 
   2 floats /CBdata allocate-cbuffer to &CBdata
   &CBdata clear-CBdata InitDataParms
   #20 to #Max_X_Lines
   listener-socket 1 < if
      bold http-listen ." /home" norm
   then
   tTotal start-timer ;

: send_ask_time ( -- )
   time-server$ 0<> if
      cr ." Ask time from: " 100 ms time-server$ count type
      ms@ >r asktime ms@ r> - dup space . ." ms "  3000 >  if
         cr ." Stream failed. Rebooting." 1500 ms
         esp-wifi-stop 200 ms 2 deep-sleep
      then
   then ;

: start-web-server  ( -- )
   cr htmlpage$ 0=  if
      ['] sensor+http-responder to responder  init-res
   else  bold ." Listening on http://" ipaddr@ .ipaddr ." /home" norm
   then
   ['] home-page is /home
   ['] take-ntc-samples SetStage
   set-next-measurement-ntc
   ALSO TCP/IP SEAL
   cr ." The first results appear after 2 minutes in the list." cr
   sent-temp-hum-to-msgboard Sent-state
   100 ms esp-clk-cpu-freq 1000000 / . ." Mhz "
   1000 to poll-interval
   cr ." Hit <escape> for Forth"  cr
   send_ask_time
   program-loop         \ Contains the loop of the server
   +a order cr quit ;

: faster ( -- )
   f# 1e0 to fcycle-time
   #1000 to next-measurement-ntc
   4 to /sample-buffer-ntc
   /sample-buffer-ntc to #max-samples ;

\ Startup:

PREVIOUS PREVIOUS

HtmlPage$ [if] HtmlPage$ free drop 0 to HtmlPage$ [then]

true to stages-
cr .free
' start-web-server is s

\ For debugging
\ ' see-request is handle-request \ To see the total received requests
\ ' see-command is handle-request \ To see the commands only of the received requests
 
start-web-server
\ \s

