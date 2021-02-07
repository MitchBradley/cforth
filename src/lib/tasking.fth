\ Multitasking

\ Access to
: >task ( 'uservar 'task -- 'uservar-in-task )  + up@ -  ;

\ Access local variables in a task from another task
: task@  ( 'uservar 'task -- n )  >task @  ;
: task!  ( n 'uservar 'task -- )  >task !  ;

\ When a task is asleep, the round-robin loop will skip it.

\ put the task at task-addr to sleep (make it inactive)
: sleep ( task-addr -- )  true asleep rot task!  ;

\ awaken the task at task-addr (make it active)
: wake  ( task-addr -- )  false asleep rot task!  ;

\ put current task to sleep
: stop  ( -- )  up@ sleep (pause  ;

\ disable pausing - the current task gains exclusive control
: single ( -- )
   ['] noop to pause
;
: multi ( -- )  \ initialize multitasking
   ['] pause behavior  ['] (pause <>  if
      up@ link !     \ point the current task to itself
      up@ wake       \ Make sure the main task is awake
      ['] (pause to pause
   then
;

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
   dup link !                    ( task-body  /task  task-up)

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
   r@ sleep
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

\ Give the task a word to execute and add it to the round-robin list
\ The xt must be a colon definition
: fork  ( task-action-xt task-up -- )
   multi  \ Ensure that multitaking is enabled
   >r >body                           ( ip r: task )

   sp0 r@ task@  'sp r@ task!  ( ip r: task )
   rp0 r@ task@  'rp r@ task!  ( ip r: task )

   \ Push IP on task return stack
   'rp r@ task@  -1 na+        ( ip task-rp  r: task )
   tuck !                      ( task-rp  r: task )
   'rp r@ task!                ( r: task )

   r> drop
;

\ In CForth, the default behavior of VARIABLE is to
\ put the data in the user area, where it is task-specific.
\ GLOBAL creates a variable that is shared between all tasks.
: global  create 0 ,  ;

\ BACKGROUND is a defining word for a task and its action.  Example:
\  global counts
\  background counter   begin pause 1 counts +! again  ;

: background ( "name" -- )
   task:
   lastacf execute  ( task-up )
   :noname  over fork  ( task-up )
   wake
;
