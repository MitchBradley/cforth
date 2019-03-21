\needs init-flow  fl flow.fth
\needs init-logger fl logger.fth

#1249 constant counts/gal
#330 constant counts/liter

: u#bl  ( n -- n' )
   dup  if  u#  else  bl hold  then
;
: (3.1d)  ( n -- $ )
    push-decimal    
    <# u# '.' hold u# u#bl u#bl u#>
    pop-base
;
: (3.d)  ( n -- $ )
    push-decimal    
    <# u# u#bl u#bl u#>
    pop-base
;

\ Rational fraction to convert counts to decigallons
#330 constant counts/l
#1000 constant ml/l
#3785 constant ml/gal

ml/l #10 *   counts/l ml/gal *  2constant dg-factor

\ Rational fraction to convert counts/sec to decigallons/min
\ 181.818 is 60 * ml/count
\ 3784.1 is ml/gal
#18182 #37854 2constant dgpm-factor

0 value last-counts-a
0 value last-counts-b
: counts>g$  ( counts -- $ )  dg-factor */  (3.1d)  ;
: .gallons  ( counts -- )  counts>g$ fb-type  ;
: counts>gpm$  ( counts -- $ )  dgpm-factor */ (3.1d)  ;
: .gpm  ( counts -- )  counts>gpm$ fb-type  ;

\ Reads a pressure sensor from the ADC and converts to PSI
\ The sensor range is 0..100 PSI corresponding to 0.5 .. 4.5 V
\ The sensor connects to A0 on Wemos D1 Mini with a 180K
\ resistor in series with the existing 220K/100K voltage divider 
#128 value 0psi
: psi  ( -- n )
   adc@  dup 0psi <  if  dup to 0psi  then
   0psi -  9 /
;

0 value delta-counts-a
0 value delta-counts-b
: .gpm-oled-header  ( -- )
    ssd-clear
    "   Gal  GPM" fb-type
;
: .gpm-oled  ( -- )
   disable-flow-interrupts

   flow-counts-a @                          ( counts )
   dup last-counts-a - to delta-counts-a    ( counts )
   to last-counts-a

   0 1 fb-at-xy  last-counts-a .gallons
   5 1 fb-at-xy  delta-counts-a .gpm

   flow-counts-b @                          ( counts )
   dup last-counts-b - to delta-counts-b    ( counts )
   to last-counts-b
 
   0 2 fb-at-xy  last-counts-b .gallons
   5 2 fb-at-xy  delta-counts-b .gpm

   0 3 fb-at-xy  last-counts-b last-counts-a - abs  .gallons
   5 3 fb-at-xy  delta-counts-b delta-counts-a - abs  .gpm

   1 5 fb-at-xy psi (3.d) fb-type  "  PSI" fb-type

   enable-flow-interrupts
;
: run-logger  ( -- )
   ssd-clear   
   0 1 fb-at-xy  " LOGGING" fb-type  wait-switch-released
   log
   0 1 fb-at-xy  " LOG DONE" fb-type
   #1000 ms
   .gpm-oled-header
;
: .gpm-oled-loop  ( -- )
   .gpm-oled-header
   begin
      .gpm-oled
      5 0  do
         switch?  if  run-logger  leave  then
         #200 ms  
      loop
   key? until
   disable-flow-interrupts
;
: go
   init-flow
   init-logger
   init-wemos-oled
   .gpm-oled-loop
;
go
