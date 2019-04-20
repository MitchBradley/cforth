\ Driver for Wemos D1 Motor Shield in stepper mode.
\
\ That shield normally drives a gear motor, but its
\ firmware can be changed to drive a stepper motor using
\ https://github.com/masutokw/WEMOS-MOTOR-SHIELD-I2C-STEPPER.git
\ with the patch given below.
\ Even so, the results are not great, because the motor driver
\ hardware is not optimized for stepper motors.  Steppers like
\ to be driven by a current source, whereas the Wemos shield
\ has a voltage-mode driver chip.  It can be made to work by
\ adjusting the power supply voltage to give the desired current,
\ but the results are marginal and it is altogether better to
\ buy a stepper driver board.

\ The aforementioned patch is given below.  It disables UART
\ output, which is a problem because the UART pin can interfere
\ with a GPIO pin used for other purposes.
\ modified   tb6621.c
\ @@ -59,7 +59,7 @@ static void gpio_setup(void)
\  static void usart_setup(void)
\  {
\  // nvic_enable_irq(NVIC_USART1_IRQ);
\ -    usart_set_baudrate(USART1, 9600);
\ +    usart_set_baudrate(USART1, 115200);
\      usart_set_databits(USART1, 8);
\      usart_set_parity(USART1, USART_PARITY_NONE);
\      usart_set_stopbits(USART1, USART_CR2_STOPBITS_1);
\ @@ -419,7 +419,7 @@ int main(void)
\      generate_wave(50);
\      clock_setup();
\      gpio_setup();
\ -    usart_setup();
\ +    //    usart_setup();
\      i2c_setup();
\      //systick_setup(125); // tim2_setup();
\      tim16_setup();
\ @@ -432,8 +432,10 @@ int main(void)
\      ticks_x=65535;
\      dir=01;
\  
\ +    //    uartwrite("Starting\r\n");
\      while (1)
\      {
\ +#if 0
\          //debug table
\          if (bprint)
\          {
\ @@ -447,6 +449,7 @@ int main(void)
\              }
\              bprint=false;
\          }
\ +#endif
\          for (i = 0; i < delayt; i++)
\          {
\              __asm__("NOP");
\

$32 constant stepper-i2c-slave
: ?err  ( flag -- )  abort" I2C failed"  ;
: stepper-read  ( cmd -- l )
   stepper-i2c-slave i2c-start-write ?err    ( ) 
   true stepper-i2c-slave i2c-start-read ?err  ( )
   false i2c-byte@  false i2c-byte@  false i2c-byte@  true i2c-byte@  ( b b b b )
   bljoin
;
: stepper-write  ( l cmd -- )
   stepper-i2c-slave i2c-start-write ?err  ( l )
   lbsplit  swap 2swap swap
   4 0 do  i2c-byte! ?err  loop
   i2c-stop
;
: stepper-count!  ( n -- )  3 stepper-write  ;
: stepper-count@  ( -- n )  2 stepper-read  ;
: stepper-target!  ( n -- )  4 stepper-write  ;
: stepper-target@  ( -- n )  5 stepper-read  ;
: stepper-ticks!  ( n -- )  6 stepper-write  ;
: stepper-dir-res!  ( n -- )  7 stepper-write  ;
: stepper-prescaler!  ( n -- )  8 stepper-write  ;
: stepper-wave-scale!  ( n -- )  9 stepper-write  ;
: stepper-speed!  ( n -- )  #10 stepper-write  ;
: stepper-target-speed!  ( n -- )  #11 stepper-write  ;
\ 28 is 1 rev/s at 8x but the torque is dodgy
#40 value stepper-speed
: stepto  ( end start -- )
   stepper-count!  dup stepper-target!  ( end )
   stepper-speed stepper-ticks!         ( end )
   begin                                ( end )
      stepper-count@ dup .d (cr         ( end start )
   over <>  while                       ( end )
      key?  if  drop exit  then         ( end )
      #300 ms                           ( end )
   repeat                               ( end )
   drop                                 ( )
;
: stepper-init  ( -- )
   1 2 i2c-setup
   4 stepper-dir-res!  \ 8x microstepping
;

stepper-init
decimal
