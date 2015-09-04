#include "stm32l1xx_conf.h"

void I2C_Tick(void);

int ms_tick;
int ms10_tick;

void init_systick()
{
  SysTick_Config(SystemCoreClock / 1000);
}

void SysTick_Handler(void)
{ 
  ms_tick++;
  if (++ms10_tick >= 10) {
    ms10_tick = 0;
    I2C_Tick();
  }    
}
