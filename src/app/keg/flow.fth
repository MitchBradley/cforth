\ Updates variables based on pulses from two flow meters
7 constant flow-pin-a
6 constant flow-pin-b

variable flow-counts-a
variable flow-counts-b

: disable-flow-interrupts  ( -- )
   gpio-int-disable flow-pin-a gpio-enable-interrupt
   gpio-int-disable flow-pin-b gpio-enable-interrupt
;

: enable-flow-interrupts  ( -- )
   gpio-int-posedge flow-pin-a gpio-enable-interrupt
   gpio-int-posedge flow-pin-b gpio-enable-interrupt
;
: flow-cb-a  ( level -- )  drop 1 flow-counts-a +!  ;
: flow-cb-b  ( level -- )  drop 1 flow-counts-b +!  ;
: reset-flow  ( -- )  flow-counts-a off  flow-counts-b off  ;

: init-flow  ( -- )
   reset-flow
   pullup gpio-interrupt flow-pin-a gpio-mode
   ['] flow-cb-a flow-pin-a gpio-callback!
   pullup gpio-interrupt flow-pin-b gpio-mode
   ['] flow-cb-b flow-pin-b gpio-callback!
   enable-flow-interrupts
;
