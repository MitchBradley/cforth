\ Debugger.  Thanks, Mike Perry, Henry Laxen, Mark Smeder.
\
\ The debugger lets you single step the execution of a high level
\ definition.  To invoke the debugger, type debug xxx where xxx is
\ the name of the word you wish to trace.  When xxx executes, you will
\ get a single step trace showing you the word within xxx that
\ is about to execute, and the contents of the parameter stack.
\ Debugging makes everything run slightly slower, even outside
\ the word being debugged.  see debug-off
\
\ debug name	Mark that word for debugging
\ stepping	Debug in single step mode
\ tracing	Debug in trace mode
\ debug-off	Turn off the debugger (makes the system run fast again)
\ resume	Exit from a pushed interpreter (see the f keystroke)
\
\ Keystroke commands while you're single-stepping:
\   d		go down a level
\   u		go up a level
\   c		continue; trace without single stepping
\   g		go; turn off stepping and continue execution
\   f		push a Forth interpreter;  execute "resume" to get back
\   q		abort back to the top level

only forth also definitions

false value scrolling-debug?

hex

only forth hidden also forth also definitions
hidden also definitions
variable step? step? on
variable res

-1 value displayed-xt
: force-redisplay  ( -- )  -1 to displayed-xt  ;

: (debug)       (s low-adr hi-adr -- )
   unbug   1 cnt !   ip> !   <ip !
   step? on
   force-redisplay
;

: 'unnest   (s pfa -- pfa' )
   scan-pf pf-end
\   begin   dup ta1+  swap  token@ ['] unnest =  until
;
: set-<ip  (s pfa -- )
   <ip !  <ip @  ip> @  u>=  if  <ip @  'unnest  ip> !  then
;

\ Enter and leave the debugger
forth definitions
: defer?  ( acf -- flag )  word-type  ['] key word-type =  ;

defer resolve-defers
: (resolve-defers)  ( xt -- xt' )
   begin  dup defer?  while  behavior  repeat
;
' (resolve-defers)  to resolve-defers

: (debug  ( acf -- )
   resolve-defers

   dup definer ['] :  <> abort" Not a colon definition"
   >body dup 'unnest  (debug)
;
\ Debug the caller
: debug-me  (s -- )  ip@ find-cfa (debug  ;
: debug(  (s -- )  ip@ dup 'unnest (debug)  ;
: )debug  (s -- )  ip@ ip> !  ;
: debug-off (s -- )  unbug  ;
hidden definitions
\ Go up the return stack until we find an interesting caller
: up1  ( rp -- )
   begin  na1+  dup rp0 @ <>  while             ( rs-adr )
      dup @                                     ( rs-adr ip )
      dup in-dictionary?  if                    ( rs-adr ip )
	 dup loop-end?  if                      ( rs-adr ip )
	    drop                                ( rs-adr )
         else                                   ( rs-adr ip )
            find-cfa  dup indirect-call?  if    ( rs-adr xt )
 	       drop                             ( rs-adr )
            else                                ( rs-adr xt )
               nip                              ( rs-adr )
               scrolling-debug?  if             ( xt )
                  cr ." [ Up to " dup .name ." ]" cr
               then                             ( xt )
               (debug                           ( )
               exit                             ( -- )
            then                                ( rs-adr )
         then                                   ( rs-adr )
      else                                      ( rs-adr )
         drop                                   ( rs-adr )
      then                                      ( rs-adr )
   repeat                                       ( rs-adr )
   drop                                         ( )
;

defer to-debug-window  ' noop is to-debug-window
defer restore-window   ' noop is restore-window
: .debug-short-help  ( -- )
  ." Stepper keys: <space> Down Up Continue Forth Go Help ? See $tring Quit" cr
;
: .debug-long-help  ( -- )
   ." Key     Action" cr
   ." <space> Execute displayed word" cr
   ." D       Down: Step down into displayed word" cr
   ." U       Up: Finish current definition and step in its caller" cr
   ." C       Continue: trace current definition without stopping" cr
   ." F       Forth: enter a subordinate Forth interpreter" cr
   ." G       Go: resume normal execution (stop debugging)" cr
   ." H       Help: display this message" cr
   ." ?       Display short list of debug commands" cr
   ." R       RSTrace: Show contents of Forth return stack" cr
   ." S       See: Decompile definition being debugged" cr
   ." $       Display top of stack as adr,len text string" cr
   ." \       Display Forth return stack as numbers (like the data stack)" cr
   ." Q       Quit: abandon execution of the debugged word" cr
   ." V       Visual: toggle between 2-D and scrolling" cr
   ." L       Visual: redisplay" cr
;
d# 24 constant cmd-column
: to-cmd-column  ( -- )  cmd-column to-column  ;

0 value stack-line
d# 45 constant stack-column
\ 0 0 2value result-loc
0 value full-stack-x
0 value full-stack-y
0 value result-line
0 value result-col
: to-stack-location  ( -- )  stack-column stack-line at-xy  kill-line  ;
: show-full-stack  ( -- )
   full-stack-x full-stack-y at-xy kill-line
   depth 0<  if  ." Stack Underflow"   exit  then  \ Don't clear stack here
   depth 0=  if  ." Empty"  exit  then
   depth 7 >  if  ." .. "  then
   depth  depth 7 - 0 max  ?do  depth i - 1- pick n.  loop
;
: show-partial-stack  ( -- )
   show-full-stack

   to-stack-location

   ." \ "
   depth 0<  if  ." Stack Underflow" sp0 @ sp!  exit  then
   depth 0=  if  ." Empty"  exit  then
   depth 3 >  if  ." .. "  then
   depth  depth 4 - 0 max  ?do  depth i - 1- pick n.  loop
;

\ : save-result-loc  ( -- )  #out @ #line @ to result-loc  ;
\ : to-result-loc  ( -- )  result-loc at-xy  ;
: save-result-loc  ( -- )  #out @ to result-col   #line @ to result-line  ;
: to-result-loc  ( -- )  result-col result-line 2dup at-xy  #line !  #out !  ;

: try  ( n acf -- okay? )
   catch  ?dup if  .error drop false  else  true  then
;
defer resolve-method
' noop to resolve-method
: executer  ( xt -- xt' )
   dup ['] execute =  over ['] catch =  or  if  drop dup  then
   resolve-method
;
d# 72 constant /#buf
/#buf buffer: #buf-save
variable hld-save
variable show-rstack  \ Show the return stack along with the data stack?
variable hex-stack    \ Show the data stack in hex?
: save#     ( -- )  #-buf /#buf -  #buf-save  d# 72 move    hld @  hld-save !  ;
: restore#  ( -- )  #buf-save  #-buf /#buf -  d# 72 move    hld-save @  hld !  ;
0 value the-ip
0 value the-rp
: redisplay?  ( -- flag )  displayed-xt  the-ip find-cfa <>  ;

: (.rs  ( -- )
   show-rstack @ 0=  if  exit  then
   ." return-stack: "
   push-hex
   \ Skip the debugger's footprint on the return stack
   rp0 @  the-rp 5 na+  ?do  i @ .  /n +loop
   pop-base
;
: setup-scrolling-display  ( -- )
   ??cr
   the-ip  <ip @ =  if  ." : "  else  ." Inside "  then
   <ip @ find-cfa dup to displayed-xt  .name
;
: setup-2d-display  ( -- )
   page
   d# 78 rmargin !
   .debug-short-help
   d# 70 rmargin !
   ." Callers: "  rp0 @ the-rp na1+ rslist kill-line cr
   d# 40 rmargin !
   ." Stack: " #out @ to full-stack-x #line @ to full-stack-y  cr  \ For stack
   the-ip debug-see
   the-ip find-cfa to displayed-xt
   cr
   \ Display the initial stack on the cursor line
   the-ip ip>position  0=  if   ( col row )
      is stack-line   drop      ( )
   then
;
: setup-debug-display  ( -- )
   redisplay?  if
      scrolling-debug?  if
         setup-scrolling-display
      else
         setup-2d-display
      then
      0 show-rstack !
   then
;
: show-debug-stack  ( -- )
   scrolling-debug?  if
      save#
      cmd-column 2+ to-column

      hex-stack @  if  push-hex  then
      ." ( " .s    \ Show data stack
      hex-stack @  if  pop-base  then
      show-rstack @  if  (.rs  then   \ Show return stack
      ." )"
      restore#

      cr
      ['] noop is indent
      the-ip .token drop		  \ Show word name
      ['] (indent) is indent
      to-cmd-column
   else
      save-result-loc
      show-partial-stack
        
      the-ip ip-set-cursor
      #line @ to stack-line
   then
;
: debug-interact  ( -- )
   save#
   begin
      setup-debug-display
      step? @  if  to-debug-window  then
      show-debug-stack
      step? @  key? or  if
         step? on  res off
         key dup bl <  if  drop bl  then
         scrolling-debug?  if  dup emit  else  to-result-loc  then  upc
         restore-window
[ifdef] reset-page
         scrolling-debug?  if  reset-page  then
[then]
         case
            [char] D  of  the-ip token@ executer  ['] (debug try endof \ Down
	    [char] U  of  the-rp ['] up1 try                     endof \ Up
            [char] C  of                                               \ Continue
               step? @ 0= step? !              
               step? @ 0=  if  true to scrolling-debug?  force-redisplay  then
               true
            endof

            [char] F  of						      \ Forth
               cr ." Type 'resume' to return to debugger" cr
               interact  false
            endof
            [char] G  of  debug-off  cr                 true   endof \ Go
            [char] H  of  cr .debug-long-help           false  endof \ Help
            [char] R  of  cr ." IP "  the-ip .  ip@ .  cr  rp0 @ the-rp na1+ (rstrace false  endof \ RSTrace
            [char] S  of  cr <ip @ body> (see)          false  endof \ See
            [char] ?  of  cr .debug-short-help	       false  endof \ Short Help
            [char] $  of  space 2dup type cr to-cmd-column false endof \ String
            [char] Q  of  cr ." unbug" abort           true   endof \ Quit
            [char] (  of  the-ip set-<ip                  false  endof
            [char] <  of  the-ip ta1+ set-<ip  1 cnt !    false  endof
            [char] )  of  the-ip ip> !  1 cnt !           false  endof
            [char] *  of  the-ip find-cfa dup <ip !  'unnest ip> !  false  endof
            [char] \  of  show-rstack @ 0= show-rstack !  false  endof  \ toggle return stack display
            [char] X  of  hex-stack @ 0= hex-stack !      false  endof  \ toggle heX stack display
            [char] L  of  force-redisplay                 false  endof  \ Redisplay
            [char] V  of						\ toggle Visual (2D) mode
               scrolling-debug? 0= to scrolling-debug?      
               scrolling-debug? 0=  if  force-redisplay  then  false
            endof
            ( default ) true swap
         endcase
      else
         true
      then
   until
   restore#
;
: (trace  ( -- )
   ip@ to the-ip
   rp@ to the-rp
   debug-interact
\   scrolling-debug? 0=  if  to-result-loc  then
   the-ip token@  dup ['] unnest =  swap ['] exit =  or  if
      cr  force-redisplay
   then
;
' (trace  'debug token!

only forth hidden also forth definitions

: debug  \ name (s -- )
   '
   .debug-short-help
   (debug
;
: debugging  ( -- )  ' .debug-short-help  dup (debug  execute  ;
: resume    (s -- )  true 'exit-interact? !  force-redisplay  ;
: stepping  (s -- )  step? on  ;
: tracing   (s -- )  step? off ;

only forth also definitions
