h# 282000 value ic-base  \ Interrupt controller

: ic@  ( offset -- l )  ic-base + io@  ;
: ic!  ( l offset -- )  ic-base + io!  ;

: block-irqs  ( -- )  1 h# 10c ic!  ;
: unblock-irqs  ( -- )  0 h# 10c ic!  ;

: irq-enabled?  ( level -- flag )  /l* ic@ h# 10 and 0<>  ;
: enable-irq  ( level -- )  h# 11 swap /l* ic!  ;  \ Enable for IRQ0
: disable-irq  ( level -- )  0 swap /l* ic!  ;

: all-interrupts-off  ( -- )
   d# 64 0  do  i disable-irq  loop 
;

: setup-interrupts  ( -- )
   all-interrupts-off  \ The MMP boot ROM leaves some interrupts on
   \ Take over the vector table which starts out in ROM at ffff0000
   itcm-on  cforth>itcm  \ Shadow address 0 with ITCM and copy cforth to it
   control@ h# 2000 invert and control!  \ vector table at 0
;
: enable-spcmd-irq  ( -- )
   h# 29.021c io@  2 invert and  h# 29.021c io!  \ Unmask command irq
   d# 50 enable-irq         \ IRQ from command transfer block
   h# 100 h# 29.00c4 io!   \ Indicate that it's okay to send commands
;
[ifdef] use_mmp2_keypad_control
: setup-keypad ( -- )
   h# 017c ic@ 1 invert and h# 017c ic! \ unmask keypad irq
   d# 9 enable-irq  \ Keypad controller IRQ
;
[then]

: send-rdy  ( -- )  h# ff00 h# 29.0040 io!  ;  \ Send downstream ready
: send-ps2  ( byte channel -- )  bwjoin h# 290040 io!  ;
: event?  ( -- false | data channel true )
   h# 29.00c8 io@ 1 and  if
      h# 29.0080 io@  wbsplit  true
      1 h# 29.00c8 io!  \ Ack interrupt
      send-rdy
   else
      false
   then
;
: matrix-mode  ( -- )
   h# f7 0 send-ps2
   4 ms
   event?  if  ( byte port )
      bwjoin  h# fa  <>  if
	 ." Strange response to matrix mode" cr
      then
   else
      ." No ACK from matrix mode" cr
   then
;
: wait-ack?  ( -- timeout? )
   get-msecs  d# 200 +     ( time-limit )
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

: kbd-cmd-ack  ( -- error? )   0 send-ps2  wait-ack?  ;
: sk  kbd-cmd-ack  if  ." No ACK"  then  ;
: ss?  h# f0 sk  0 sk  wait-data?  if  ." No data"  else  .  then  ;

: set-scan-set  ( -- )
   h# f0 kbd-cmd-ack  if  exit  then
   kbd-cmd-ack  drop
;

: (set-kbd-mode)  ( -- )
   h# f2 kbd-cmd-ack  if  exit  then        \ Identify command   

   wait-data?  if  exit  then        ( data1 )
   h# ab <>  if  exit  then          ( )

   wait-data?  if  exit  then        ( data2 )
   \ Use matrix mode for EnE
   h# 41 =  if  matrix-mode  then

   \ We default to scan set 1 because our Linux driver pretends to be
   \ controller type SERIO_8042_XL, meaning a scan-set 2 keyboard that is
   \ translated to scan set 1 by an 8042.
   1 set-scan-set
;
: set-kbd-mode  ( -- )
   h# f5 kbd-cmd-ack drop    \ Tell the keyboard to stop sending
   (set-kbd-mode)
   h# f4 kbd-cmd-ack drop    \ Tell the keyboard to start sending
;
: ps2-xoff  ( -- )
   soc-kbd-clk-gpio# gpio-dir-out  \ Hold down keyboard clock
   soc-kbd-clk-gpio# gpio-dir-out  \ Hold down touchpad clock
;   
: ps2-xon  ( -- )
   soc-kbd-clk-gpio# gpio-dir-in  \ Release keyboard clock
   soc-kbd-clk-gpio# gpio-dir-in  \ Release touchpad clock
;   
[ifdef] soc-en-kbd-pwr-gpio#
: keyboard-power-on  ( -- )
   ps2-xoff
   soc-en-kbd-pwr-gpio# gpio-clr   \ Enable power to keyboard and touchpad
;
[then]
: enable-ps2
   init-ps2
   init-timer-2s
   soc-kbd-clk-gpio#  gpio-set-fer  \ Keyboard clock
   soc-tpd-clk-gpio#  gpio-set-fer  \ Touchpad clock
   setup-interrupts
   soc-kbd-clk-gpio#  >gpio-pin  h# 9c +  tuck io@ or  swap io!  \ Unmask edge detect
   soc-tpd-clk-gpio#  >gpio-pin  h# 9c +  tuck io@ or  swap io!  \ Unmask edge detect
   d# 49 enable-irq  \ GPIO IRQ
   d# 31 enable-irq  \ first timer in second block
   enable-spcmd-irq
[ifdef] use_mmp2_keypad_control
   setup-keypad
[then]
   unblock-irqs
   enable-interrupts
   ps2-xon   
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
