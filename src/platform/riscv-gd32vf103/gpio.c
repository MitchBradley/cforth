#include "gd32vf103_libopt.h"
#include "systick.h"

rcu_periph_enum gpio_clocks[] = {
        RCU_GPIOA,
        RCU_GPIOB,
        RCU_GPIOC,
        RCU_GPIOD,
        RCU_GPIOE,
};

uint32_t gpio_ports[] = {
        GPIOA,
        GPIOB,
        GPIOC,
        GPIOD,
        GPIOE,
};

int gpio_open(unsigned int portno, unsigned int pin, int mode)
{
	if (portno >= sizeof(gpio_ports) / sizeof(gpio_ports[0]))
		return 0;

	uint32_t portp = gpio_ports[portno];

	if (pin > 15)
		return 0;

	rcu_periph_clock_enable(gpio_clocks[portno]);
	gpio_init(gpio_ports[portno], mode, GPIO_OSPEED_50MHZ, 1 << pin);

	return (int)portp + pin;
}

void gpio_set(int portpin)
{
	uint32_t port = (uint32_t)(portpin & ~0x0f);
	int pin = portpin & 0x0f;
	gpio_bit_set(port, 1 << pin);
}

void gpio_clr(int portpin)
{
	uint32_t port = (uint32_t)(portpin & ~0x0f);
	int pin = portpin & 0x0f;
	gpio_bit_reset(port, 1 << pin);
}

void gpio_write(int portpin, int value)
{
	uint32_t port = (uint32_t)(portpin & ~0x0f);
	int pin = portpin & 0x0f;
	gpio_bit_write(port, 1 << pin, !!value);
}

int gpio_read(int portpin)
{
	uint32_t port = (uint32_t)(portpin & ~0x0f);
	int pin = portpin & 0x0f;
	return gpio_input_bit_get(port, 1 << pin) == RESET ? 0 : -1;
}
