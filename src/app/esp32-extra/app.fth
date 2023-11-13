\ Load file for application-specific Forth extensions

fl ../../lib/misc.fth
fl ../../lib/dl.fth
fl ../../lib/random.fth
fl ../../lib/ilog2.fth
fl ../../lib/tek.fth

warning @ warning off
: bye standalone?  if  restart  then  bye  ;
warning !

: .commit  ( -- )  'version cscount type  ;

: .built  ( -- )  'build-date cscount type  ;

: banner  ( -- )
   cr ." CForth built " .built
   ."  from " .commit
   cr
;

\ m-emit is defined in textend.c
alias m-key  key
alias m-init noop

: m-avail?  ( -- false | char true )
   key?  if  key true exit  then
   false
;

: ms>ticks  ( ms -- ticks )
   esp-clk-cpu-freq #80000000 over =
     if    drop
     else  #240000000 =
             if   exit
             else #1 lshift
             then
     then  #3 /
;

 f# 0 fvalue us-start   \ Must be updated after set-system-time

: system-time>f ( us seconds -- ) ( f: -- us )
   s" s>d d>f f# 1000000 f*  s>d d>f  f+ "  evaluate ; immediate

: usf@         ( f: -- us )
   s" dup dup sp@ get-system-time! system-time>f" evaluate ; immediate

: ms@         ( -- ms )
   f# .001 usf@ us-start f- f* f>d drop ;

alias get-msecs ms@

: ms ( ms -- )
   s>d d>f f# 1000 f* usf@  f+
     begin   fdup  usf@  f- f# 100000000 f>
     while   #100000000 us
     repeat
   usf@  f- f>d drop abs us
;

fl wifi.fth

fl ../esp8266/xmifce.fth
fl ../../lib/crc16.fth
fl ../../lib/xmodem.fth
also modem
: rx  ( -- )  pad  unused pad here - -  (receive)  #100 ms  ;
previous

fl files.fth
fl server.fth
fl tasking_rtos.fth        \ Preemptive multitasking
fl tools/extra.fth

: interrupt?  ( -- flag )
   ." Type a key within 2 seconds to interact" cr
   #20 0  do  #100 ms  key?  if  key drop  true unloop exit  then   loop
   false
;

: load-startup-file  ( -- ior )   " start" ['] included catch   ;

: app ( - ) \ Sometimes SPIFFS or a wifi connection causes an error. A reboot solves that.
   usf@ to us-start
   banner  hex  interrupt? 0=
      if     s" start" file-exist?
           if   load-startup-file
                if   ." Reading SPIFFS. " cr interrupt? 0=
                    if    reboot
                    then
                then
           then
      then
   quit
;

alias id: \

" app.dic" save
