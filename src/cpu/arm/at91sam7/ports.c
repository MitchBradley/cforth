#include "ports.h"
#include "pio.h"
#include "types.h"

long data_fetch();
void data_store(long data);
void index_store(long data);

void ms(int);

long get_ticks();


void setup_jtag_ports()
{
    PIO_PER = SPI_PINS;         // Use the dual-purpose pins as GPIOs for JTAG
    PIO_OER = MOSI | SCK_TCK;   // Set the appropriate ones to be outputs
    PIO_CODR = SPI_PINS;        // Everything low
    PIO_SODR = MASK(RESET_BIT); // Release JTAG reset
}
void use_spi()
{
    PIO_PDR = SPI_PINS;   // Drive the dual-purpose pins via the SPI controller
}

void data_set(int index, u_long mask)
{
    index_store(index); 
    data_store(data_fetch() | mask);
}

void data_clr(int index, u_long mask)
{
    index_store(index); 
    data_store(data_fetch() & ~mask);
}

void rem_on()  {  data_set(2, 1);  }
void rem_off() {  data_clr(2, 1);  }
void rcv_on()  {  data_set(2, 2);  }
void rcv_off() {  data_clr(2, 2);  }
void usb_on()  {  data_set(2, 3);  }
void usb_off() {  data_clr(2, 3);  }

void v0() {  rem_off();  }

void v2()
{
    PIO_CODR = MASK(VADJ1_BIT) | MASK(VADJ0_BIT);
    rem_on();
}

void v3()
{
    PIO_CODR = MASK(VADJ1_BIT);
    PIO_SODR = MASK(VADJ0_BIT);
    rem_on();
}

void v6()
{
    PIO_SODR = MASK(VADJ1_BIT) | MASK(VADJ0_BIT);
    rem_on();
}

void power_cycle()
{
    v0();
    ms(400);
    v3();
    rcv_off();  // Bounce the board
    ms(100);
    rcv_on;
    ms(100);
}

void assert_ptt()
{
    PIO_CODR = MASK(PTT_BIT);  // Active low
}

void deassert_ptt()
{
    PIO_SODR = MASK(PTT_BIT);  // Active low
}

void ms(int n)
{
    long target;
    long this;
    target = get_ticks() + ((n+1) << 5);
    while ((target - get_ticks()) > 0) { }
}
