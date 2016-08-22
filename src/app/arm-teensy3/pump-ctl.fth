\ Pump control & state machine

0 value target-pump
0 value pump-ctl-timeout
defer pump-ctl

\ timers
: pump-ctl-timeout? ( -- flag )
   pump-ctl-timeout get-msecs - 0<
;
#5000 value wl-fill-ms
#60000 value recirc-ms
#1000 value nutrient-ms
#5000 value pH-up-ms
#5000 value pH-down-ms

#80000 value pH-ctl-cooldown
#100 ( mm ) value wl-threshold


\ manipulate states
defer monitoring-state
defer pumping-state
: set-monitoring ( -- )
   target-pump 0> if
     0 target-pump gpio-pin!
   then
   0 to target-pump
   ['] monitoring-state to pump-ctl
;
: set-pumping ( ms pump# -- )
   dup to target-pump
   1 swap gpio-pin!
   get-msecs + to pump-ctl-timeout
   ['] pumping-state to pump-ctl
;
: pump-ctl-next ( pump# -- )
   dup  recirc-gpio =
   over water-gpio = or
   swap spritz-gpio = or
   if
     \ {recirc,spritz,fill} -> monitor
     set-monitoring
   else
     \ {ph-*, ec-*} -> recirc
     recirc-ms recirc-gpio set-pumping
   then
;

\ monitor sensors
: monitor-water-level ( -- action? )
   vl-avg-dist wl-threshold > dup if
     wl-fill-ms water-gpio set-pumping
   then
;

0 value last-pH-ctl
: monitor-pH ( -- action? )
   get-msecs last-pH-ctl -
   pH-ctl-cooldown < if 0 exit then

   pH*10 pH-limit-low < if
     pH-up-ms pH-up-gpio set-pumping
     get-msecs to last-pH-ctl
     1 exit
   then

   ph*10 pH-limit-high > if
     pH-down-ms pH-down-gpio set-pumping
     get-msecs to last-pH-ctl
     1 exit
   then
   0
;

: monitor-ec ( -- action? )
   0 ( TODO: too low ec? ) dup if
     nutrient-ms nutrient-gpio set-pumping
   then
;


\ state routines
: do-monitoring-state ( -- )
   monitor-water-level if exit then
   monitor-pH if exit then
   monitor-ec if exit then
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
     ." monitoring, ph = " .pH cr
   else
     target-pump case
       water-gpio   of ." filling, dist = " vl-avg-dist . ." mm" endof
       spritz-gpio  of ." spritzing" endof
       recirc-gpio  of ." recirculating" endof
       pH-up-gpio   of ." pH up" endof
       pH-down-gpio of ." pH down" endof
       ( else ) dup ." pump gpio #" target-pump .d
     endcase
     ."  ("
     pump-ctl-timeout get-msecs -
     50 + 100 / nn.n \ round to nearest 0.1s
     ." s)" cr
   then
;
: init-pump-ctl ( -- )
   set-monitoring
;
