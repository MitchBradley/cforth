h# d4282000 value ic-base  \ Interrupt controller

: ic@  ( offset -- l )  ic-base + l@  ;
: ic!  ( l offset -- )  ic-base + l!  ;

: block-irqs  ( -- )  1 h# 10c ic!  ;
: unblock-irqs  ( -- )  0 h# 10c ic!  ;

: irq-enabled?  ( level -- flag )  /l* ic@ h# 10 and 0<>  ;
: enable-irq  ( level -- )  h# 11 swap /l* ic!  ;  \ Enable for IRQ0
: disable-irq  ( level -- )  0 swap /l* ic!  ;

: setup-interrupts  ( -- )
   \ Take over the vector table which starts out in ROM at ffff0000
   itcm-on  cforth>itcm  \ Shadow address 0 with ITCM and copy cforth to it
   control@ h# 2000 invert and control!  \ vector table at 0
;
: enable-spcmd-irq  ( -- )
   h# d429.021c l@  2 invert and  h# d429.021c l!  \ Unmask command irq
   d# 50 enable-irq         \ IRQ from command transfer block
   h# 100 h# d429.00c4 l!   \ Indicate that it's okay to send commands
;
: send-rdy  ( -- )  h# ff00 h# d429.0040 l!  ;  \ Send downstream ready
: send-ps2  ( byte channel -- )  bwjoin h# d4290040 l!  ;
: event?  ( -- false | data channel true )
   h# d429.00c8 l@ 1 and  if
      h# d429.0080 l@  wbsplit  true
      1 h# d429.00c8 l!  \ Ack interrupt
      send-rdy
   else
      false
   then
;
: matrix-mode  ( -- )
   h# f7 0 send-ps2
   4 ms
   event?  if  ( byte port )
      bwjoin  h# fa  =  if
	 ." Matrix mode on" cr
      else
	 ." Strange response to matrix mode" cr
      then
   else
      ." No ACK from matrix mode" cr
   then
;
: wait-ack?  ( -- timeout? )
   get-msecs  d# 30 +   ( time-limit )
   begin
      event?  if           ( time-limit code port )
	 if                ( time-limit code )
	    drop           ( time-limit )
         else              ( time-limit code )
	    h# fa =  if    ( time-limit )
	       drop false exit  ( -- false )
	    then           ( time-limit )
	 then              ( time-limit )
      then                 ( time-limit )
      dup get-msecs - 0<   ( time-limit )
   until                   ( time-limit )
   drop true
;
: wait-data?  ( -- true | data false )
   get-msecs  d# 30 +   ( time-limit )
   begin
      event?  if           ( time-limit data port )
	 if                ( time-limit data )
	   drop            ( time-limit )
	 else              ( time-limit data )
           false exit      ( -- data false )
	 then              ( time-limit )
      then                 ( time-limit )
      dup get-msecs - 0<   ( time-limit )
   until                   ( time-limit )
   drop true               ( true )
;

: sk  0 send-ps2 wait-ack?  if  ." No ACK"  then  ;
: set-scan-set  h# f0 sk  sk  ;
: ss?  h# f0 sk  0 sk  wait-data?  if  ." No data"  else  .  then  ;

: set-kbd-mode  ( -- )
   h# f2 0 send-ps2          \ Identify command   
   wait-ack?  if  exit  then
   wait-data?  if  exit  then        ( data1 )
   h# ab <>  if  exit  then          ( )
   wait-data?  if  exit  then        ( data2 )
   \ Use matrix mode for EnE
   h# 41 =  if  matrix-mode  then
   \ We default to scan set 1 because our Linux driver pretends to be
   \ controller type SERIO_8042_XL, meaning a scan-set 2 keyboard that is
   \ translated to scan set 1 by an 8042.
   1 set-scan-set
   d# 40 ms
;
: enable-ps2
   init-timer-2s
   init-ps2
   setup-interrupts
   d#  71 gpio-set-fer  \ Keyboard clock
   d# 160 gpio-set-fer  \ Touchpad clock
   d#  71 >gpio-pin  h# 9c +  tuck l@ or  swap l!  \ Unmask edge detect
   d# 160 >gpio-pin  h# 9c +  tuck l@ or  swap l!  \ Unmask edge detect
   d# 49 enable-irq  \ GPIO IRQ
   d# 31 enable-irq  \ first timer in second block
   enable-spcmd-irq
   unblock-irqs
   enable-interrupts
   send-rdy
   set-kbd-mode
;

: rr  begin  event?  if  drop .  then  key? until  ;

[ifdef] testing
: dp2
   ps2-devices l@ dup h# 20 ldump cr h# 20 + l@ 20 ldump
;

: kbd-state  ( -- )  ps2-devices l@ ;
: tpd-state  ( -- )  ps2-devices la1+ l@ ;

: send-kbd  ( byte -- )  0 send-ps2  ;
: send-tpd  ( byte -- )  1 send-ps2 ;

: .event  if ." +" else ." -" then  .  ;
: get-keys  ( -- )
   event?  0=  if  send-rdy  else  .event  then
   begin
      key?  if  key drop exit  then
      event?  if  .event  then
   again
;
[then]
