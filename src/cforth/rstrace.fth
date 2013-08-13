\ Forth stack backtrace
\ Implements:
\ (rstrace  ( low-adr high-adr -- )
\    Shows the calling sequence that is stored in memory between the
\    two addresses.  This is assumed to be a saved return stack image.
\ rstrace  ( -- )
\    Shows the calling sequence that is stored on the return stack,
\    without destroying the return stack.
\ atrace  ( -- )
\    Shows the calling sequence saved by the last "throw"

[ifndef] ip>token  : ip>token /token - ;  [then]

only forth also hidden also definitions

[ifndef] .last-executed
: .last-executed  ( ip -- )
   ip>token token@  ( acf )
   dup reasonable-ip?  if   .name   else   drop ." ??"   then
;
[then]
: .traceline  ( ipaddr -- )
   push-hex
   dup reasonable-ip?
   if    dup .last-executed ip>token .caller   else  9 u.r   then   cr
   pop-base
;
: (rstrace  ( bottom-adr top-adr -- )
   ?do   i @  .traceline  exit? ?leave  /n +loop
;
forth definitions
: rstrace  ( -- )  \ Return stack backtrace
   rp@ rp0 @ u>  if
      ." Return Stack Underflow" rp0 @ rp!
   else
      rp0 @ rp@ (rstrace
   then
;
: atrace  ( -- )  \ Abort stack backtrace
   ." Last abort or throw:" cr
   'rsmark @  'rssave @ (rstrace
;
only forth also definitions
