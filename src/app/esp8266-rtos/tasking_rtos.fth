0 [if]   tasking_rtos.fth for cforth,
Based on tasking.fth written by Mitch Bradley.
Modified by J.v.d.Ven  March 9th, 2021 for an experimental pre-emptive multitasking system under RTOS


Issues:
1) Use MS only after all tasks are running  OR  use it before the first time of execute-task
   Please check that the tick interrupt is actually running. ( vTaskDelay )
   You can do this by placing a break point in the tick interrupt handler, defined within port.c.

2) switch-regs at the start of each task and
   end-task at the end of each task are needed to avoid an exception.

3) Can't use quit in a task.

4) Can't always put a whole server into a task

5) For exceptions like: mStack canary watchpoint triggered (NAME)
   Increase the stack in extend.c from 2048 to 4096 in xTaskCreate

6) key? in a task will hang the task.

7) When global or task: are used they must be placed in RAM. This file may in ROM.

8) The floating point stack is NOT changed when a new task is activated.
   Use floating point operations only in the main task.

[then]

nuser task-handle

\ Access to
: >task ( 'uservar 'task -- 'uservar-in-task )  + up@ -  ;

\ Access local variables in a task from another task
: task@  ( 'uservar 'task -- n )  >task @  ;
: task!  ( n 'uservar 'task -- )  >task !  ;

\ Layout of private storage for a new task:
\ Space             Size
\ -----             ----
\ User Area         user-size
\ Parameter Stack   /task-stack
\ Tib               /tib
\ Return Stack      /task-rs
\ .
\ The dictionary and the Parameter Stack share an area equal
\ to the task storage area size minus user-size minus task-rs-size
\
\ The terminal input buffer and the Return Stack share an area of
\ size task-rs-size.  Tib grows up, Return Stack grows down.

\ Increase this to give the task a larger return stack
#20 cells value /task-rs

\ Increase this to give the task a larger data stack
#20 cells value /task-stack

\ Increase this to give the task a larger stack size for RTOS
#2048 value stack_size

\ Before the new task has been forked, invoking the task name will
\ return the address of its body.  After forking, it will return the
\ address of its user area
\ The task's body contains the address and size

\ Allocate and initialize the user area for the new task, schedule it
\ Internal implementation factor

: allocate-task  ( 'task -- task-up )
   \ Allocate run-time space
   dup na1+ @        ( task-body /task )
   dup alloc-mem     ( task-body /task task-up)

   \ Initialize the user area with a copy of the current task's user area
   up@  over  #user @  cmove     ( task-body  /task  task-up)

   \ Since we copied the user area, his link already points to my successor.
   \ Now make him my new successor in the task queue.

 \  dup link !                    ( task-body  /task  task-up)

   >r                            ( task-body  /task  r: task-up )

   \ Set the body of the task word to point to the new user area
   r@ rot !                      ( /task  r: task-up )

   \ Get the top address of the task data area
   r@ +                          ( 'task-end  r: task-up )

   \ Task return stack
   dup  rp0 r@ task!             ( 'task-end  r: task-up )

   /task-rs - /tib -  dup 'tib r@ task!  ( 'task-sp  r: task-up )
   sp0 r@ task!                          ( r: task-up )

   r@  up0 r@ task!             ( r: task-up )
   r@  user-size +  dp r@ task! ( r: task-up )
\   r@ sleep
   r>                           ( task-up )
;


: $task: ( size name$ -- ) \ name and allocate a new task
   $create      ( size )
   0 , ,
   does>          ( task-pfa -- task-up )
   dup @          ( pfa task-up )
   dup  if        ( pfa task-up )
      nip         ( up )
   else           ( pfa 0 )
      drop allocate-task  ( up )
   then           ( task-up )
;

: /task  ( -- size )  user-size /task-rs + /tib + /task-stack +  ;
: task:  \ name  ( -- name ) \ name and allocate a new task using default size
   /task parse-word  $task:
;

up@ constant main-task

\ Give the task a word to execute and add it to the round-robin list
\ The xt must be a colon definition
: fork  ( task-action-xt task-up -- )
   >r  >body                   ( ip r: task )
   sp0 r@ task@  'sp r@ task!  ( ip r: task )
   rp0 r@ task@  'rp r@ task!  ( ip r: task )

   \ Push IP on task return stack
   'rp r@ task@  -1 na+        ( ip task-rp  r: task )
   tuck !                      ( task-rp  r: task ) \ Stores body of task-action-xt
   'rp r> task!
;

\ In CForth, the default behavior of VARIABLE is to
\ put the data in the user area, where it is task-specific.
\ GLOBAL creates a variable that is shared between all tasks.
: global  create 0 ,  ;

: resume     ( task - ) task-handle swap task@ vTaskResume  ;
: suspend    ( task - ) task-handle swap task@ vTaskSuspend ;
: kill       ( task - ) dup free drop task-handle swap task@ vTaskDelete ;
: end-task   ( - )      task-handle @ vTaskDelete ;

: switch-regs ( task -- )
   >r up0 r@ task@ up! \  task ptr
      rp0 r> task@ cell - rp!
      sp0 @ sp!
      xTaskGetCurrentTaskHandle task-handle ! ;

: execute-task ( xt task -- )
   tuck fork 'rp swap task@ @ body> stack_size task ;


\ \s
