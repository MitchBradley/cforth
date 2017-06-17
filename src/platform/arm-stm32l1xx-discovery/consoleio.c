// #define VCOM
// Character I/O stubs

#include "stm32l1xx_conf.h"

USART_TypeDef *consoleUart;

void raw_putchar(char c)
{
  while(!USART_GetFlagStatus(consoleUart, USART_FLAG_TXE))
    ;
  USART_SendData(consoleUart, (uint16_t)c);
}

int kbhit() {
  return USART_GetFlagStatus(consoleUart, USART_FLAG_RXNE);
}

int getkey()
{
  int c;
  while (!kbhit())
    ;
  return USART_ReceiveData(consoleUart);
}

void init_io()
{
  consoleUart = USART1;
        
  RCC_AHBPeriphClockCmd(RCC_AHBPeriph_GPIOA, ENABLE);    // PA9 and PA10
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_USART1, ENABLE);
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource9,  GPIO_AF_USART1);
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource10, GPIO_AF_USART1);

  GPIO_InitTypeDef gpioInit = {
    .GPIO_Mode  = GPIO_Mode_AF,
    .GPIO_PuPd  = GPIO_PuPd_NOPULL,
    .GPIO_OType = GPIO_OType_PP,
    .GPIO_Speed = GPIO_Speed_400KHz
  };

  gpioInit.GPIO_Pin = GPIO_Pin_9;
  GPIO_Init(GPIOA, &gpioInit);

  gpioInit.GPIO_Pin = GPIO_Pin_10;
  GPIO_Init(GPIOA, &gpioInit);

  USART_InitTypeDef uartInit = {
    .USART_BaudRate   = 115200,
    .USART_WordLength = USART_WordLength_8b,
    .USART_StopBits   = USART_StopBits_1,
    .USART_Parity     = USART_Parity_No,
    .USART_Mode       = USART_Mode_Rx | USART_Mode_Tx,
    .USART_HardwareFlowControl = USART_HardwareFlowControl_None
  };

  USART_Init(consoleUart, &uartInit);

  USART_Cmd(consoleUart, ENABLE);

  init_systick();
}

void wfi(void)
{
  __WFI();
}

extern int ms_tick;
int get_msecs(void)
{
  return ms_tick;
}

int spins(int i)
{
  while(i--)
    asm("");  // The asm("") prevents optimize-to-nothing
}
