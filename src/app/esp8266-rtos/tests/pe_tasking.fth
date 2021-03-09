s" pe_tasking_test" $find  [if]   bye  [then]  2drop  marker pe_tasking_test  \ To prevent nesting

s" sysledOn" $find nip not [if]

: sysledOn    ( -- )  0 GPIO2 gpio-pin!  ;
: sysledOff   ( -- )  1 GPIO2 gpio-pin!  ;

[then]

3 cells allocate drop value counters
counters 3 cells erase

: >counter ( n -- ) cells counters + ;
: incr_counter  ( counter - )  >counter 1 swap +! ;

    task: test-task1
    task: test-task2
    task: test-task3

: test1   ( - )
   test-task1 switch-regs
      begin 0 incr_counter 50 ms again
   end-task ;

: test2   ( - )
    test-task2 switch-regs
      begin 1 incr_counter 100 ms again
    end-task ;

: BlinkSysLed ( flag - flag' )
    if   sysledon  false
    else sysledoff true
    then ;

: test3   ( - )
    test-task3 switch-regs
    false   \ assume the sysled is off
       begin 2 incr_counter BlinkSysLed 200 ms
       again
    end-task ;

: .counters ( - )  3 0 do  i >counter @ .d loop ;

: monitor ( - )
    reset-terminal
    cr ." Enter any key to exit the monitor. "
       begin  10 3 at-xy .counters   5 vTaskDelay key? until ;

: start-tasks ( - )  \ The best way to start several tasks
   stack_size
   #256 to stack_size  \ Decreasing the stack usage for new tasks under RTOS
   ['] test1 test-task1  execute-task
   ['] test2 test-task2  execute-task
   ['] test3 test-task3  execute-task
   to stack_size        \ restore default size
;


: kill-tasks ( - )  \ The best way to start several tasks
   test-task1   kill
   test-task2   kill
   test-task3   kill sysledoff ;


start-tasks

cr .( Starting the monitor.)

monitor

0 [if]  \ Options:
   test-task1   Suspend
   test-task2   Suspend
   test-task3   Suspend

   test-task1   resume
   test-task2   resume
   test-task3   resume

   test-task1   free
   test-task2   free
   test-task3   free

   test-task1   TaskDelete
   test-task2   TaskDelete
   test-task3   TaskDelete
[then]
\ \s
