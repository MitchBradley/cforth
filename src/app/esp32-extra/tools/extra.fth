marker -extra.fth  cr lastacf .name #19 to-column .( 23-10-2024 ) \ By J.v.d.Ven

\ Additional words I often use.

alias b   bye
alias cls reset-terminal
alias h.  .h
alias word-join  wljoin
alias word-split lwsplit

: lower-char ( C -- c )
   dup [char] A [char] Z between
     if   $20 or
     then  ;

: si ( <word> - )
   safe-parse-word 2dup bounds
         do  i c@ lower-char i c!
         loop
   $sift ;

: s>f         ( n -- ) ( f: - n )  s>d d>f ;
: f>s         ( -- n ) ( f: n - )  f>d d>s ;

[ifdef]  spi_master_write64  true  [else]  false  [then]  constant esp8266?

esp8266? [if]

2 constant sysled
alias init-sysled noop
: sysledOn    ( -- )  0 sysled gpio-pin!  ;
: sysledOff   ( -- )  1 sysled gpio-pin!  ;
: init-adc    ( -- )  8 0 adc-init abort" ADC init failed" ; \ in TOUT mode
: cpu_freq!   ( 1=80Mhz|2=160Mhz -- )  0 2 max swap esp_set_cpu_freq ;

alias cpu_freq@ esp_clk_cpu_freq

[else]  \ esp32

: cpu_freq!        ( 1=80Mhz|2=160Mhz|3=240Mhz -- ) 10 ms  rtc-clk-cpu-freq-set ;
alias cpu_freq@   esp-clk-cpu-freq


[ifdef] rtc-fast  \ For esp-idf-v3.3.6 and better

#3584 constant /fast_mem \ The maximum size of RTC-fast memory defined in interface.c
variable >top_fast_mem   >top_fast_mem off \ -/- 34 bytes used by the os

: allocate-fast-mem ( n - addr ior )
   aligned >top_fast_mem @ 2dup + /fast_mem >
     if    2drop 0 true
     else  + dup >top_fast_mem ! rtc-fast false
     then ;

[then]

#32 value sysled
: init-sysled       ( -- )  sysled gpio-is-output ;
: sysledOn          ( -- )  1 sysled gpio-pin!    ;
: sysledOff         ( -- )  0 sysled gpio-pin!    ;

#60000 to wifi-timeout
: wifi-open-station ( retr wifi-timeout wifi-storage &ss sscnt  &pw pwcnt - flag )
\    0 " wifi" log-level!
    5 roll 10 ms wifi-open nip nip ;

\ For an extra uart
0    value uart_num
#130 value /RxBuf
0    value &RxBuf

: send-tx ( adr cnt -  )
   tuck swap uart_num uart-write-bytes <> abort" uart-write-bytes failed" ;

: read-rx ( - #read )  0 /RxBuf &RxBuf uart_num  uart-read-bytes ;

: create-timer: ( <name> - ) 3 cells  buffer: ;  \ Map: cell-flag float-UsTimeStart
: start-timer   ( timer - )  true over ! cell+ usf@ f! ;
: .tElapsed     ( timer - )  dup usf@  cell+ f@  f- f# 0.001 f* f. ." ms" ;

: tElapsed? ( f: us-elapsed - ) ( timer - flag )
   dup @
      if    cell+ f@  f+ usf@ f< \ Time elapsed?
      else  2drop false          \ The timer is off
      then ;

0 [if] \ Usage:

create-timer: ttimer

: test-1second ( - )
    ttimer start-timer   begin   f# 1e6 ttimer tElapsed?  until ;

test-1second

[then]

: min>fus  ( minutes - ) ( F: - us ) s>f f# 60e6  f* ;
: hrs>fus  ( hours - ) ( F: - us )   #60 * min>fus ;
: fus>fsec ( F: us - sec ) f# 1e-6 f* ;
: fus>fms  ( F: us - ms )  f# 1e-3 f* ;
: fsec>fus ( F: sec - us ) f# 1e6 f* ;

2variable (time-start)    f# 0 fvalue trim-time

: set-trim-time ( - )
    1 ms (time-start) get-system-time!
    usf@ (time-start) 2@ system-time>f f- to trim-time ;

: time-reset ( - )
    trim-time f0=
       if  set-trim-time
       then
    (time-start) get-system-time! ;

: us-elapsed ( us-start seconds-start - ) ( f: usf@ - us-elapsed )
     system-time>f f- trim-time f- ;

: .elapsed ( - )
   usf@  (time-start) 2@ us-elapsed fus>fsec fe. ." sec." ;

create-timer: tTotal
0      value stages-
f# 0  fvalue tcycle
' noop value 'stage
0 value fmeasure-complete

variable #samples
#25      value #max-samples
\ In us:
f# 1e6   fvalue time-1-sample
f# 180e3 fvalue cycle-time
f# 180e3 fvalue next-measurement

: .tcycle ( - )
    stages-
        if  cr space usf@ tcycle f- f# 0.000001 f* f>d drop .
        then  ;

: SetStage ( cfa - )
  stages-
     if    .tcycle dup .name
     then to 'stage ;

[then]

: bold        ( -- ) .esc[ '1' (emit  'm' (emit ; \ VT100
: norm        ( -- ) .esc[ '0' (emit  'm' (emit ;
: hide-cursor ( -- ) #out @ .esc[ s" ?25l" type #out ! ;
: show-cursor ( -- ) #out @ .esc[ s" ?25h" type #out ! ;

: lcount      ( addr -- addr' count ) dup cell + swap @ ;
: +lplace     ( addr len dest -- )    2dup  >r >r  lcount + swap  cmove r> r> +! ;
: lplace      ( addr len dest -- )    0 over ! +lplace ;
: es          ( ?? -- ) ( f: ?? -- )  clear fclear ; \ empty stacks
: 16bit>32bit ( signed16bits - signed32bits )  dup $7FFF >  if  $FFFF0000 or  then ;
: 4drop       ( n4 n3 n2 n1 -- )   2drop 2drop ;
: (number?)   ( addr len -- d1 f1 )  $number?  if   true   else 0. false  then ;
: -ftrunc     ( f: n - -ftrunc )   fdup ftrunc f-  ;
: f2drop      ( fs: r1 r2 -- )     fdrop fdrop ;
: dup>r       ( n1 -- n1 ) ( R: -- n1 ) s" dup >r"  evaluate ; immediate

: parse-single ( <number$> - n flag )  \ parse-single
   parse-word dup 0=
      if    ." No number found" nip dup
      else  2dup (number?)
                if    d>s -rot 2drop true
                else  2drop cr type ."  <--- Bad number" false dup
                then
      then ;

0 value seed
: init-seed       ( - )      random ms@ + to seed ;

: Rnd        ( -- rnd )
    seed dup 0= or   dup 13 lshift xor   dup 17 rshift xor
    dup 5 lshift xor dup to seed  ;

: RandomLim  ( limit - random )   rnd swap /mod drop ;

: cells+ ( a1 n1 -- a1+n1*cell ) \ multiply n1 by the cell size and add
          cells + ;              \ the result to address a1

: +cells ( n1 a1 -- n1*cell+a1 ) \ multiply n1 by the cell size and add
          swap cells+ ;          \ the result to address a1


: check-conditional   ( mark - mark here )
    depth 0> true ?pairs    dup lastacf here cell+ within true ?pairs here ;

patch check-conditional here >resolve
patch check-conditional here <resolve


: begin-structure     ( <name> -- addr 0 )
             create here 0 0 ,
             does> ( -- size ) @ ;

: end-structure       ( addr n -- )
             swap ! ;                \ set size

: +field  ( offset size -- offset' )
   create  over ,  +  ( offset' )
   does>  ( adr -- adr' )  @ + ;

: field:     ( n1 <"name"> -- n2 ) ( addr -- 'addr )  aligned cell +field ;
: bfield:    ( n1 <"name"> -- n2 ) ( addr -- 'addr )  1 +field ;
: wfield:    ( n1 <"name"> -- n2 ) ( addr -- 'addr )  2 +field ;
: lfield:    ( n1 <"name"> -- n2 ) ( addr -- 'addr )  4 +field ;
: xfield:    ( n1 <"name"> -- n2 ) ( addr -- 'addr )  8 +field ;

: f2dup   ( fs: r1 r2 -- r1 r2 r1 r2 )  fover fover ;
: perform ( adr - )  s" @ execute " evaluate ; immediate

#27 constant escape
: escape? ( - flag )
    key?
     if  key escape =
          if    true
          else
                begin  key?
                while  key drop
                repeat
              false
          then
     else 0
     then ;

: us-to-deadline ( f: us-base us-incr - us-wait )
   f+ usf@ f- f# 0 fmax ;  \ us-base + us-incr should be > then usf@

: find-deadline ( addr-fus-base addr-fus-timeout - ) ( f: - us-to-deadline )
   over f@  f@ f2dup f+ f! us-to-deadline ;

: execute-until-escape  ( xt -- )  ( f: #ms-timeout - )
    0 0   { xt &#ms-timeout &usstrt -- }
    /f allocate drop dup to &#ms-timeout f!
    /f allocate drop dup usf@ fus>fsec fround fsec>fus to &usstrt f!
       begin  xt execute
              &usstrt &#ms-timeout find-deadline
              fus                \ No drift in the software
\             fdrop 1000 ms      \ Replace the previous line with this line and it drifts
\             usf@ &usstrt f@ f- fe.  ." us deviation.  "   \ Show the drift
              escape?
       until
     &#ms-timeout free drop &usstrt free drop ;

begin-structure /circular
   field: >(cbuf-count)
   field: >max-records
   field: >record-size
   field: >&data-buffer
end-structure

: >cbuf-count ( - ) ;  immediate

: incr-cbuf-count ( &CBuffer - ) 1 swap >cbuf-count +!  ;


: >record-cbuf ( i-Cbuffer &CBuffer - adr ) \ i= index that must point INTO the circular buffer
    tuck >&data-buffer @ rot >record-size @ rot * + ;

HIDDEN DEFINITIONS

: >circular-index-abs ( i &CBuffer - i-Cbuffer )
    dup >cbuf-count @ swap >max-records @ 2dup >
       if    >r + r>  /mod drop
       else  2drop
       then ;

FORTH DEFINITIONS ALSO HIDDEN

: >circular-index ( i &CBuffer - i-Cbuffer )
    over 0>=
      if    >circular-index-abs
      else  dup >r >max-records @ negate over >=
             if    drop 0
             else  r@ >cbuf-count @ + 0 max
             then  r> >circular-index-abs
      then ;

: circular-range ( &CBuffer - i-end i-start )
   dup >cbuf-count @  over >max-records @ >
       if    >max-records
       else  >cbuf-count
       then
   @ 0 ;

: >circular      ( i &CBuffer - addr )
    tuck >circular-index swap >record-cbuf ;

: >circular-head ( &CBuffer - adr ) \ Next to be used
    dup >cbuf-count @
    over >max-records @ /mod drop
    swap >record-cbuf ;

: allocate-cbuffer ( rec-size #records - &CBufParms )
    /circular allocate drop >r
    dup  r@ >max-records !
    over r@ >record-size !
    * allocate abort" Allocate-cbuffer failed "
    r@ >&data-buffer ! \ Pointer to the data
    0 r@ >cbuf-count !
    r> ;

PREVIOUS

: b.     ( n -  )  base @ 2 base ! swap . base ! ;
: start-length ( bStart bEnd  - bStart length )  over - 1+  ;

: #mask (  bstart length -- n2 )  \ Create a mask at bstart
   >r -1 r@ rshift  r> lshift invert
   swap lshift ;

: #bits@ ( n1 bstart #bits - n ) \ Fetch a number of bits from n1 at bstart
   >r    rshift
   -1 r> lshift
   invert and ;

: bits@  ( n1 bstart bend  - n ) \ Fetch the bits from bstart
   start-length  #bits@  ;       \ to and including bend

: #bits!   { n1 n2 bstart length -- n2 } \ Store n1 in n2 at bstart
   bstart length #mask \ Create a mask at bstart
   n1 bStart lshift    \ Shift n1 to position
   over and            \ Remove excessive bits from n1
   n2 rot invert and   \ Clear bits in n2
   or ;                \ Store n1 in n2

: bits!  ( n1 n2 bstart bend -- n1 ) \ Store n1 in n2 starting at bstart
   start-length  #bits!  ;           \ to and also using bend.


: scan  ( addr len c -- addr2 len2 )
    >r rp@ 1 search r> drop 0=
      if   + 0
      then  ;

: BlankString  ( adrs cnts adr cnt - adrEnd cntEnd|0 )
  dup >r search
    if    swap  dup r> bl fill swap
    else  r> 2drop 0
    then ;


: BlankStrings ( adrs cnts adr cnt -- )
     begin  2over 2over BlankString dup
     while  2rot 2drop 2swap
     repeat
   4drop 2drop  ;

: NextString ( a n delimiter -- a1 n1 )
    >r  2dup r> scan nip - ;

: SkipDots ( str$ count #dots - remains$ count )
   0  do [char] . scan dup 0=
            if    leave
            then
         1 /string
      loop ;

: my-host-id" ( - adr cnt ) ipaddr@ ipaddr$ 3 SkipDots ; \ IP4

: GetValue ( adrOf-Number+limiter length limiter - n flag )
    NextString over c@ [char] - = dup >r
         if    1 /string
         then
    0 0 2swap  >number nip 0=
         if   d>s r>
                  if    negate
                  then  true
         else  r> drop 2drop 0 0
         then ;

: DeepSleep ( sec - )
   [ifdef] esp-wifi-stop  esp-wifi-stop  spiffs-unmount 3 rtc-clk-cpu-freq-set
   [else]  wifi-off
   [then]
   1 max deep-sleep ;

: Reboot ( - )  ." Rebooting..." 1 DeepSleep ;

: ##$        ( seperator n -- adr cnt ) s>d <# # #  2 pick hold  #> rot 0= abs /string ;
: f>dint ( f: n magn - ) ( d: - n )  f* fround f>d tuck dabs ;
: .#-> [char] . hold  #s rot sign #>  ;
: (f.2) ( f -- ) ( -- c-addr u )  f# 100e0  f>dint <# # # .#-> ;
: (f.1) ( f -- ) ( -- c-addr u )  f# 10e0   f>dint <# # .#-> ;
: ip4Host ( adr cnt - ) ipaddr@ ipaddr$ #10 /string ;

0     value lsock
0     value HtmlPage$  \ To collect html for streaming.
#6000 value /HtmlPage

: SendHtmlPage ( - )
   HtmlPage$ lcount dup 0>
     if    lsock lwip-write drop
     else  2drop
     then ;

: stream-html  ( - )  SendHtmlPage htmlpage$ off ;

\ NOTE for a ESP8266:
\ if lwip-read returns may return -1 then a sock is used and must also be closed !
\ Otherwise LWIP_SELECT will return 0 since the sock is not closed

: +html   ( adr cnt -- )
    htmlpage$ lcount nip over + /HtmlPage >
       if  stream-html
       then
    htmlpage$ +lplace ;

0 value tmp$

: init-HtmlPage ( - )
    /HtmlPage cell+ allocate
    abort" Allocating HtmlPage failed " dup to HtmlPage$ off
    255 allocate   abort" Allocating tmp$ failed "  to tmp$ ;

: rjust ( a u width char -- a2 u2 )
   >r over - 0 max dup tmp$ !
   tmp$ cell+ swap r> fill
   tmp$ +lplace
   tmp$ lcount ;

: file-exist?         ( filename cnt -- true-if-file-exist )
    r/o open-file   if   drop false   else    close-file drop  true   then ;

: +file ( filename cnt buffer lcnt - )   \ Adding a file to a lcounted buffer
    >r >r r/o open-file
       if    2r> 3drop
       else  r@ @ r@ + cell+
             2r> >r 2 pick read-file drop
             swap close-file drop r> +!
       then ;

: @file ( buffer cnt filename cnt - #read ) \ Place a file in a buffer
    r/o open-file throw  dup>r
    read-file throw
    r> close-file drop  ;

: hold"       ( - ) [CHAR] " hold ;
: hold"bl     ( - ) bl hold hold" ;

: .free     ( - )
    base @ decimal ."  Free, "  ." ram:" unused 0 u,.r
    ."  heap:" esp_get_free_heap_size 0 u,.r base ! bl emit ;

: file-it  ( buffer cnt filename cnt - ) \ Write a buffer to a file
    r/w create-file throw >r
    r@  write-file throw
    r@  flush-file drop 25 ms
    r>  close-file drop ;

: open-file-append  ( filename cnt - hndl ) \ Points to the last postion in a file
    2dup r/w open-file
      if    drop r/w create-file throw      \ Create the file when it does not exist
      else  >r 2drop
            r@ file-size throw
            r@ reposition-file throw r>
      then ;

: WriteFile ( txt cnt hndl - )  write-file throw ;

: writeHTML  ( filename cnt - )          \ Write HtmlPage$ to file
    HtmlPage$ lcount 2swap file-it ;

\ Files to load options if they exist.
: set-app ( filename cnt - ) s" _appname.txt" file-it ; \ For start
: -app	( - )                 s" _appname.txt" delete-file ;
: -html ( - )                s" _KeepHtmlFiles.txt" delete-file ;

0 value adr-compile-file
: compile-file  ( - )  \ Compile the file named in _appname.txt"
    #50 allocate drop to adr-compile-file adr-compile-file off
    s" _appname.txt" adr-compile-file #40 +file
    adr-compile-file lcount
    2dup file-exist? 0=
      if    2drop
      else  2dup cr bold type norm space included
      then
   adr-compile-file free drop
   quit ;

: seal   ( -- )
   context token@     context #vocs /n * erase
   dup   context #vocs 1- ta+  token!   execute  ;

: enter-wifi-settings ( passwordBuf ssidBuf - )
    2>r
    cr ." Setting up a WiFi connection. The SSID and password will"
    cr ." be saved in plain text in wifi_connect.fth on the MCU."
    cr ." Enter SSID:"     pad dup 50 accept r> place
       ." Enter Password:" pad dup 50 accept r> place ;

\ Retries: -1 for unlimited, 0 for none, otherwise that many
2 value wifi-#retries
0 value wifi-storage
-2 value wifi-logon-state   \ -2 not tried   -1 logon failed    0 Logon OK

: wifi-station-on  { &ss sscnt &pw pwcnt -- }
    wifi-mode@ case
      1 of ipaddr@ @ 0=
                if  ." >>> Try a reboot and SET-SSID if needed." cr
                then           endof
      2 of  ." WiFi is already on in AP mode; type wifi-off to stop it"     cr endof
      3 of  ." WiFi is already on in Sta+AP mode; type wifi-off to stop it" cr endof
            cr ." Connecting to wifi: " &ss sscnt type cr
            wifi-#retries wifi-timeout wifi-storage
            &ss sscnt  &pw pwcnt wifi-open-station
                if   -1 to wifi-logon-state
                      cr ." >>> WiFi station connection failed. Try SET-SSID" cr
                else  0 to wifi-logon-state
                then
    endcase ;

create TcpPort$ ," 8080"     create UdpPort$ ," 8899"

: UdpWrite ( send$ cnt ip-server$ - )
   count UdpPort$ count 2swap udp-connect
   >r   r@ lwip-write  50 ms  r> lwip-close drop ;

: TcpWrite ( bufer cnt ip-server$ - )
   >r #1000 TcpPort$ count r> count stream-connect >r
   r@ lwip-write drop 50 ms
   r> lwip-close ;

\ After "WiFi station connection failed":
\ Reboot and remove wifi_connect.fth then enter logon

: SleepIfNotConnected ( #sec-deep-sleep - )
    ipaddr@ @ 0=
      if    100 ms cr  ." No connection. Entering sleep mode..."  DeepSleep
      else  drop
      then ;

: crlf$		( -- adr n )    " "r"n" ;
: +html_line	( adr n -- )    +html crlf$ +html ;
: html|		( -<string|>- ) [char] | parse postpone sliteral ; immediate
: +html|	( -<string|>- ) postpone html| postpone +html ; immediate

: set-ssid ( - )                \ Creates wifi_connect.fth on the MCU
    init-HtmlPage HtmlPage$ off \ A reboot is needed when the entered parameters were wrong
    50 allocate drop 50 allocate drop   2dup 2dup   enter-wifi-settings
    +html| s" | count +html +html| " |
    +html| s" | count +html  html| " wifi-station-on | +html_line
    free drop  free drop
    s" wifi_connect.fth" writeHTML   HtmlPage$ free drop 0 to HtmlPage$
    s" wifi_connect.fth" included #35 ms ;

: logon ( -- )
      s" wifi_connect.fth" file-exist?
        if   s" wifi_connect.fth" included #35 ms
             9 0  do  ipaddr@ @ 0<>   if   leave   then  i . #2000 ms
                  loop
        else set-ssid
        then  ;

\ For setvbuf
0 constant _IOFBF \ set fully buffered
1 constant _IOLBF \ set line buffered
2 constant _IONBF \ set unbuffered

\ \s
