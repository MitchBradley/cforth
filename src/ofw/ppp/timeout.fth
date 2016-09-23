\ See license at end of file
purpose: PPP timeouts

decimal

listnode
   /n field >c_next		\ link
   /n field >c_time		\ time at which to call routine
   /n field >c_arg		\ argument to routine
   /n field >c_func		\ routine
nodetype: callout-node

list: callouts
0 callouts !

: set-callout   ( func arg seconds node -- time )
   >r						( func arg seconds )
   -rot   r@ >c_arg !   r@ >c_func !		( seconds )
   d# 1000 * get-msecs + dup r> >c_time !	( time )
;
: call-after?   ( time node -- time after? )   >c_time @ over u>  ;
: call-before?  ( time node -- time after? )   >c_time @ over u<=  ;

\ Schedule a timeout.
\ Note that this timeout takes the number of seconds,
: timeout   ( func arg seconds -- )
   \ Allocate timeout.
   callout-node allocate-node dup >r		( func arg seconds new ) ( r: new )
   set-callout					( time ) ( r: new )
   r> swap					( new time )
   
   callouts ['] call-after? find-node drop	( new time prev )
   nip insert-after
;

: call-match?   ( func arg node -- func arg match? )
   2dup >c_arg @ =  3 pick rot >c_func @ = and
;
\ Unschedule a timeout.
: untimeout   ( func arg -- )
   callouts ['] call-match? find-node if	( func arg prev )
      delete-after callout-node free-node
   then
   2drop
;

: exec-timeout   ( node -- )
   dup >c_arg @ swap >c_func @ execute
;

\ Call any timeout routines which are now due.
: calltimeout   ( -- )
   get-msecs   					( time )
   begin
      callouts ['] call-before? find-node	( time prev node|0 )
      ?dup while				( time prev node )
      exec-timeout				( time prev )
      delete-after callout-node free-node	( time )
   repeat					( time prev )
   2drop
;

\ return the length of time until the next timeout is due, or 0 if none
: timeleft   ( -- n )
   callouts @ dup if
      >c_time @ get-msecs -
   then
;

: clear-timeouts  ( -- )
   callouts @			( node )
   begin  dup  while		( node )
      dup >next-node swap	( node' node )
      callout-node free-node	( node' )
   repeat			( 0 )
   callouts !
;
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
