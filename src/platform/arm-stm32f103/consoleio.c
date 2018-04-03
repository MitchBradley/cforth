// Character I/O stubs

#include "stm32f10x_conf.h"

void init_systick(void);

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
        
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_USART1 | RCC_APB2Periph_AFIO | 
                         RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC, ENABLE);

  GPIO_InitTypeDef gpioInit = {
    .GPIO_Speed = GPIO_Speed_50MHz
  };

  gpioInit.GPIO_Pin = GPIO_Pin_9;
  gpioInit.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(GPIOA, &gpioInit);

  gpioInit.GPIO_Pin = GPIO_Pin_10;
  gpioInit.GPIO_Mode = GPIO_Mode_IN_FLOATING;
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

int spins(int i)
{
  while(i--)
    asm("");  // The asm("") prevents optimize-to-nothing
}

int strlen(const char *s)
{
	const char *p;
	for (p=s; *p != '\0'; *p++) {
	}
	return p-s;
}

int __errno;
