\ Logs flow (counts) and pressure (ADC)

\needs init-switch fl switch.fth
\needs init-flow fl flow.fth

3 /w* constant /log-entry
#200 constant ms/sample
#10 ( min ) #60 *  ( sec )
#1000 ms/sample */ ( samples )
/log-entry *  constant /log
/log buffer: logbuf
logbuf value 'log

: init-logger  ( -- )
   init-switch
   init-flow
;

: log  ( -- )
   reset-flow
   logbuf to 'log
   begin
      'log logbuf - /log <
   while
       adc@ 'log w!
       flow-counts-a @ 'log 1 wa+ w!
       flow-counts-b @ 'log 2 wa+ w!
       'log /log-entry + to 'log
       switch?  if  exit  then
       ms/sample ms
   repeat
;

: dump-log   ( -- )
   decimal
   ." ADC, Flow1, Flow2," cr
   'log  logbuf  ?do
      i w@ (u.) type ." ,"
      i 1 wa+ w@ (u.) type ." ,"
      i 2 wa+ w@ (u.) type ." ," cr
   /log-entry +loop
;
