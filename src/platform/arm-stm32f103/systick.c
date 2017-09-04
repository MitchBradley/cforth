#include "stm32f10x_conf.h"

void I2C_Tick(void);

volatile int ms_tick;
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
  }
}

void wfi(void)
{
  __WFI();
}

int get_msecs(void)
{
  return ms_tick;
}

void ms(int nms)
{
  int target = ms_tick + nms + 1;
  while ((target - ms_tick) > 0) {
    wfi();
  }
}
