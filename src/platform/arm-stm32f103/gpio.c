#include "stm32f10x_conf.h"

GPIO_TypeDef *gpio_ports[] = {
	GPIOA,
	GPIOB,
	GPIOC,
	GPIOD,
	GPIOE,
	GPIOF,
	GPIOG,
//	GPIOH,
};

int gpio_open(unsigned int portno, unsigned int pin, int mode)
{
	if (portno >= sizeof(gpio_ports) / sizeof(gpio_ports[0]))
		return 0;

	GPIO_TypeDef *portp = gpio_ports[portno];
	
	if (pin > 15)
		return 0;

	GPIO_InitTypeDef init = {
		.GPIO_Pin = 1 << pin,
		.GPIO_Speed = GPIO_Speed_50MHz,
		.GPIO_Mode = mode
	};
	GPIO_Init(portp, &init);

	return (int)portp + pin;
}

void gpio_set(int portpin)
{
	GPIO_TypeDef *port = (GPIO_TypeDef *)(portpin & ~0x0f);
	int pin = portpin & 0x0f;
	GPIO_SetBits(port, 1 << pin);
}

void gpio_clr(int portpin)
{
	GPIO_TypeDef *port = (GPIO_TypeDef *)(portpin & ~0x0f);
	int pin = portpin & 0x0f;
	GPIO_ResetBits(port, 1 << pin);
}

void gpio_write(int portpin, int value)
{
	GPIO_TypeDef *port = (GPIO_TypeDef *)(portpin & ~0x0f);
	int pin = portpin & 0x0f;
	GPIO_WriteBit(port, 1 << pin, !!value);
}

int gpio_read(int portpin)
{
	GPIO_TypeDef *port = (GPIO_TypeDef *)(portpin & ~0x0f);
	int pin = portpin & 0x0f;
	return GPIO_ReadInputDataBit(port, 1 << pin) ? -1 : 0;
}
