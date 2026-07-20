\ timers.fth interactive test.
\ Timer callback must not overlap itself.
\ Keep interval longer than callback execution time.

decimal  
create test1 cell allot #1000 test1 !
create test2 cell allot  0 test2 !

: timed ( -- ) 
   #10 0 do 
      cr 1 test1 +! #100 ms test1 ?  
   loop 
   ." timed done! " 
;
: main
   cr ." Main started" #20 0 
      do cr 1 test2 +! #100 ms test2 ?  
   loop ." Main ready! " 
;

' timed #1000 set-alarm \ Timer timed runs once in interrupt context.
main \ Main is interrupted by timed until timed is complete.
.s


#1000 test1 !   0 test2 !

: main-loop ( - ) 
   #5 0 do 
      cr 1 test1 +! #100 ms test1 ? test2 ? 
   loop 
   ." main-loop ready! " 
;  

: repeating ( - ) 1 test2 +! ;
' repeating #10 repeat-alarm 
main-loop

cr 500 ms .( The repeat-alarm still runs: ) #500 ms  test1 ? test2 ? 
.s

\ To stop: 0 0 repeat-alarm
