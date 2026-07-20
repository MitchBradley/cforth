marker -mcpwm.fth lastacf .name #20 to-column .( 10-05-2026 ) 

0 value &mcpwm-channels  
0 value #mcpwm-channels
#11 cells constant /mcpwm-channel
: >mcpwm-&channel ( channel# - &channel ) /mcpwm-channel * &mcpwm-channels + ;

\ Handles filled bij mcpwm_config in interface.c:
: mcpwm-get-timer ( &channel -- timer ) @ ; \ 2
: mcpwm-get-oper  ( &channel -- oper ) cell+ @ ;
: mcpwm-get-gen   ( &channel -- gen ) #2 cells + @ ;
: mcpwm-get-cmpr  ( &channel -- cmpr ) #3 cells + @ ;
: mcpwm-get-period ( &channel -- period ) #4 cells + @ ;

\ Filled by mcpwm-set-config 
: >mcpwm-gpio-pin ( &channel -- &gpio-pin ) #5 cells + ;   
: >mcpwm-resolution-hz ( &channel -- &res-hz ) #6 cells + ;  
: >mcpwm-freq ( &channel -- &mcpwm-freq ) #7 cells + ;     
: >mcpwm-timer-id ( &channel -- &mcpwm-freq ) #8 cells + ;     
: >mcpwm-unit ( &channel -- &mcpwm-freq ) #9 cells + ;     
: >mcpwm-in-use  ( &channel -- &mcpwm-use ) #10 cells + ;

: .mcpwm-header ( -- ) ." Chan Gpio Res   Mcpwm Tid Unit" ; 

: .mcpwm-channel ( #channel - )
   #3 spaces dup . >mcpwm-&channel
    space dup >mcpwm-gpio-pin ?    
   dup >mcpwm-resolution-hz ?    
   dup >mcpwm-freq ?  
   space dup >mcpwm-timer-id ?     
   space >mcpwm-unit ?            
;
: .mcpwm-channels ( -- ) 
   &mcpwm-channels 0= 
   abort" No mcpwm configuration active"
   base @ decimal cr .mcpwm-header #mcpwm-channels 0 do
       cr i .mcpwm-channel  
   loop 
   base !
;
: mcpwm-validation ( channel#  - ) 
   dup >mcpwm-&channel >r  \ The tests are there to prevent crashes while setting up a system
   0 #mcpwm-channels 1+ within 0=    \ Test: mcpwm-valid-channel?
      abort" #mcpwm-channel out of range"    
   r@ >mcpwm-freq @  r@ >mcpwm-resolution-hz @ 1 swap 1+ within 0=    \ Test: mcpwm-valid-freq? 
      abort" ERROR: invalid frequency (must be 0 < freq <= resolution)" cr
   r@ >mcpwm-resolution-hz @ 1 #24000000 1- within 0=    \ Test: mcpwm-valid-resolution?
      abort" ERROR: invalid resolution must be between 1 and 24,000,000 Hz"
   r@ >mcpwm-timer-id @ 0 3 within 0=   \ Test: mcpwm-valid-timer?
      abort" ERROR: invalid timer_id (must be 0, 1, or 2)" 
   r@ >mcpwm-resolution-hz @  r> >mcpwm-freq @ / 2 >= 0=  \ Test: mcpwm-valid-period?
      abort" ERROR: ticks too short (minimum 2 ticks, need resolution/freq >= 2)"
;  
: mcpwm-set-config  { gpio res freq tid unit chan -- } 
   chan >mcpwm-&channel >r
   gpio r@ >mcpwm-gpio-pin !
   freq r@ >mcpwm-freq !
   res  r@ >mcpwm-resolution-hz !
   tid  r@ >mcpwm-timer-id !
   unit r@ >mcpwm-unit !
   r@ >mcpwm-in-use @ abort" ERROR: channel already in use" \ Test: Duplicate usage.  
   chan mcpwm-validation
   true r@ >mcpwm-in-use !
   gpio res freq tid unit r> mcpwm-config  abort" mcpwm-set-config failed."
;
: mcpwm-init-memory ( #mcpwm-channels -- ) 
   dup to #mcpwm-channels /mcpwm-channel * 1+ dup allocate abort" memory allocation failed" 
   dup to &mcpwm-channels swap erase
;
: mcpwm-get-period-ticks ( channel# -- period_ticks )
   >mcpwm-&channel dup >mcpwm-resolution-hz @ swap >mcpwm-freq @ /
;
: mcpwm-start ( channel# - ) 
   true swap >mcpwm-&channel mcpwm-get-timer mcpwm-timer-control abort" mcpwm-start failed." 
;
: mcpwm-stop ( channel# - ) \ Blocks changes in mcpwm-set-comparator until mcpwm-start
   false swap >mcpwm-&channel mcpwm-get-timer mcpwm-timer-control abort" mcpwm-stop failed." 
;
: mcpwm-set-signal-low  ( channel# -- err ) 
   0 swap  >mcpwm-&channel mcpwm-get-cmpr mcpwm-set-comparator 
;
: mcpwm-set-signal-high ( channel# -- err )
   dup mcpwm-get-period-ticks swap >mcpwm-&channel mcpwm-get-cmpr mcpwm-set-comparator 
;
: mcpwm-ratio ( relative_value channel# multiplier -- &mcpwm-get-cmpr ticks )
   >r >mcpwm-&channel dup mcpwm-get-cmpr -rot 
   dup >mcpwm-resolution-hz @ swap >mcpwm-freq @
   r> * */ \ ticks = (resolution*relative_value) / (freq*multiplier) 
;
: mcpwm-set-duty-in-us ( us channel# -- err ) \  us must be <= 1,000,000 / freq_hz.
   >mcpwm-&channel dup >r >mcpwm-resolution-hz @ #1000000 */
   r> mcpwm-get-cmpr mcpwm-set-comparator \ ticks = (resolution*us] / #1000000 )
;
 
0 [if] \ An example for 3 leds (not optimized):

#1000000 value resolution_hz
#1000 value mcpwm-freq  

: led! ( duty-percentage channel# - ) 
   #100 mcpwm-ratio swap mcpwm-set-comparator drop 
; 
: leds-init ( #mcpwm-channels -- ) \ Here all LEDs use timer 0 of unit 0 
  mcpwm-init-memory 
\ channel GpioPin resolution   freq    timer  unit   
   #0 >r   #25   resolution_hz mcpwm-freq  0  0  r@ mcpwm-set-config r>  mcpwm-start 
   #1 >r   #26   resolution_hz mcpwm-freq  0  0  r@ mcpwm-set-config r>  mcpwm-start 
   #2 >r   #27   resolution_hz mcpwm-freq  0  0  r@ mcpwm-set-config r>  mcpwm-start 
;
#3 leds-init
#20 #0 led!
#40 #1 led!
#100 #2 led!
.mcpwm-channels

[then]
\ s
