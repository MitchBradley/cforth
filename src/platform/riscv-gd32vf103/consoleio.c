// Character I/O stubs

#include "gd32vf103_libopt.h"

uint32_t consoleUart;

void raw_putchar(char ch)
{
	usart_data_transmit(consoleUart, ch);
	while (usart_flag_get(consoleUart, USART_FLAG_TBE) == RESET);
}

int kbhit() {
	return usart_flag_get(consoleUart, USART_FLAG_RBNE);
}

int getkey()
{
	while (!kbhit());
	return usart_data_receive(consoleUart);
}

void init_io()
{
	consoleUart = USART0;

	rcu_periph_clock_enable(RCU_GPIOA);
	rcu_periph_clock_enable(RCU_USART0);

	gpio_init(GPIOA, GPIO_MODE_AF_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_9);
	gpio_init(GPIOA, GPIO_MODE_IN_FLOATING, GPIO_OSPEED_50MHZ, GPIO_PIN_10);

	usart_deinit(consoleUart);
	usart_baudrate_set(consoleUart, 115200U);
	usart_word_length_set(consoleUart, USART_WL_8BIT);
	usart_stop_bit_set(consoleUart, USART_STB_1BIT);
	usart_parity_config(consoleUart, USART_PM_NONE);
	usart_hardware_flow_rts_config(consoleUart, USART_RTS_DISABLE);
	usart_hardware_flow_cts_config(consoleUart, USART_CTS_DISABLE);
	usart_receive_config(consoleUart, USART_RECEIVE_ENABLE);
	usart_transmit_config(consoleUart, USART_TRANSMIT_ENABLE);
	usart_enable(consoleUart);
}

// These would drag in obsecenely large "impure_data" symbol from the libc
void exit(int status) { while(1); }
void atexit() {}
void handle_nmi() {}
void handle_trap() {}
