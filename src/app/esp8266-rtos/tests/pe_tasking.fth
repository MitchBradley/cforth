[ifdef]  pe_tasking  bye  [then]  marker pe_tasking  \ To prevent nesting

[ifdef]  spi_master_write64  true  [else]  false  [then]  constant esp8266?

esp8266? [if]

2 constant sysled
alias init-sysled noop
: sysledOn    ( -- )  0 sysled gpio-pin!  ;
: sysledOff   ( -- )  1 sysled gpio-pin!  ;

[else]  \ esp32

5 set-priority      \ Is needed on a esp32 !
#32 value sysled
: init-sysled       ( -- )  sysled gpio-is-output ;
: sysledOn          ( -- )  1 sysled gpio-pin!    ;
: sysledOff         ( -- )  0 sysled gpio-pin!    ;

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
   init-sysled stack_size
\   #2048 to stack_size  \ Decreasing the stack usage for new tasks under RTOS
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
   test-task1  suspend-task
   test-task2  suspend-task
   test-task3  suspend-task

   test-task1   resume-task
   test-task2   resume-task
   test-task3   resume-task

   test-task1   free
   test-task2   free
   test-task3   free

   test-task1   TaskDelete
   test-task2   TaskDelete
   test-task3   TaskDelete
[then]
\ \s
