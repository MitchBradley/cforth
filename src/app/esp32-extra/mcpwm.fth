0 value op#      \ 0 or 1
0 value pwm#     \ 0 or 1
0 value timer#   \ 0, 1, or 2
#17 constant ena-gpio
#21 constant pwm-gpio
#22 constant dir-gpio
#1000 value pwm-frequency

\ Operator A (0) is the PWM signal

: ?err  abort" PWM failed"  ;
: set-duty  ( us -- )
   0 timer# pwm# mcpwm_set_duty_in_us ?err
;
decimal
create mcpwm-config
  pwm-frequency ,
  0E0 sf,  \ Floating 0 - duty for A
  0E0 sf,  \ Floating 0 - duty for B
  0 ,  \ Active high
  1 ,  \ Mode - up counter

0 [if]
: forward  ( -- )  op# timer# pwm# mpcwm_set_signal_high  ;
: backward  ( -- )  op# timer# pwm# mpcwm_set_signal_low  ;
[else]
: forward   ( -- )  1 dir-gpio gpio-pin!  ;
: backward  ( -- )  0 dir-gpio gpio-pin!  ;
[then]

: enable  ( -- )  1 ena-gpio gpio-pin!  ;
: disable  ( -- )  0 ena-gpio gpio-pin!  ;
: init-pwm  ( -- )
   ena-gpio gpio-is-output
   dir-gpio gpio-is-output
   enable
   forward

   pwm-gpio 0 pwm# mcpwm_gpio_init ?err
   mcpwm-config timer# pwm# mcpwm_init ?err
   \ pwm-frequency timer# pwm# mcpwm_set_frequency ?err
   \ dir-gpio 1 pwm# mcpwm_gpio_init ?err
   0 set-duty   
;

: fwd  ( ms speed -- )  forward set-duty ms 0 set-duty ;
: bwd  ( ms speed -- )  backward set-duty ms 0 set-duty ;
