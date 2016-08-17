\ Pump control & state machine

0 value target-pump
0 value pump-ctl-timeout
defer pump-ctl

\ timers
: pump-ctl-timeout? ( -- flag )
   pump-ctl-timeout get-msecs - 0<
;
: pump-time ( pump# -- ms )
   case
     spritz-gpio  of #1000 endof
     recirc-gpio  of #20000 endof
     pH-up-gpio   of #6000 endof
     pH-down-gpio of #6000 endof
     ( else ) dup 0 \ what do?
   endcase
;

\ manipulate states
defer monitoring-state
defer pumping-state
: set-monitoring ( -- )
   0 to target-pump
   ['] monitoring-state to pump-ctl
;
: set-pumping ( pump# -- )
   dup to target-pump
   dup pump-time get-msecs + to pump-ctl-timeout
   1 swap gpio-pin! \ turn on pump
   ['] pumping-state to pump-ctl
;
: pump-ctl-next ( pump# -- )
   dup  recirc-gpio =
   swap spritz-gpio = or
   if
     \ {recirc,spritz} -> monitor
     set-monitoring
   else
     \ {ph-*, ec-*} -> recirc
     recirc-gpio set-pumping
   then
;

\ monitor sensors
#30000 value pH-ctl-cooldown
0 value last-pH-ctl
: monitor-pH ( -- )
   get-msecs last-pH-ctl -
   pH-ctl-cooldown < if exit then

   pH*10 ph-limit-low < if
     pH-up-gpio set-pumping
     get-msecs to last-pH-ctl
   else
     ph*10 ph-limit-high > if
       pH-down-gpio set-pumping
	     get-msecs to last-pH-ctl
     then
   then
;
: monitor-ec ( -- ) ;


\ state routines
: do-monitoring-state ( -- )
   monitor-pH
   monitor-ec
;
: do-pumping-state ( -- )
   pump-ctl-timeout? if
     0 target-pump gpio-pin!
	   target-pump pump-ctl-next
	 then
;
' do-monitoring-state to monitoring-state
' do-pumping-state to pumping-state


: .pump-ctl ( -- )
   target-pump 0= if
     ." monitoring" cr
   else
     target-pump case
       spritz-gpio  of ." spritzing" endof
       recirc-gpio  of ." recirculating" endof
       pH-up-gpio   of ." pH up" endof
       pH-down-gpio of ." pH down" endof
       ( else ) dup ." etc pumping"
     endcase
     ."  ("
     pump-ctl-timeout get-msecs -
     50 + 100 / nn.n
     ." s)" cr
   then
;
: init-pump-ctl ( -- )
   pH-ctl-cooldown to last-pH-ctl
   set-monitoring
;
: pump-ctl-loop ( -- )
   begin
     pump-ctl
     .pump-ctl
     #1000 ms
     key?
   until
;