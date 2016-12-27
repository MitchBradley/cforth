#include "forth.h"
#include "kinetis.h"
#include "core_pins.h"
#include "usb_serial.h"


char * ultoa(unsigned long val, char *buf, int radix)
{
  unsigned digit;
  int i=0, j;
  char t;

  while (1) {
    digit = val % radix;
    buf[i] = ((digit < 10) ? '0' + digit : 'A' + digit - 10);
    val /= radix;
    if (val == 0) break;
    i++;
  }
  buf[i + 1] = 0;
  for (j=0; j < i; j++, i--) {
    t = buf[j];
    buf[j] = buf[i];
    buf[i] = t;
  }
  return buf;
}

int seen_usb; /* data has been received from the USB host */
int sent_usb; /* data has been sent to the USB layer that is not yet flushed */

void tx(char c)
{
  while(!(UART0_S1 & UART_S1_TDRE)) // pause until transmit data register empty
    ;
  UART0_D = c;
  if (seen_usb) {
    usb_serial_putchar(c);
    sent_usb++;
  }
}

int putchar(int c)
{
  if (c == '\n')
    tx('\r');
  tx(c);
}

#if 0
// early debug
const char hexen[] = "0123456789ABCDEF";

void put8(uint32_t c)
{
  putchar(hexen[(c >> 4) & 0xf]);
  putchar(hexen[c & 0xf]);
}

void put32(uint32_t n)
{
  put8(n >> 24);
  put8(n >> 16);
  put8(n >> 8);
  put8(n);
}

void putline(char *str)
{
  while (*str)
    putchar((int)*str++);
}
#endif

int kbhit()
{
  if (UART0_RCFIFO > 0) return 1;
  if (usb_serial_peekchar() != -1) return 1;
  return 0;
}

int getkey()
{
  int c;
  if (sent_usb) {
    usb_serial_flush_output();
    sent_usb = 0;
  }
  while (1) {
    if (UART0_RCFIFO > 0) {
      c = UART0_D;
      return c;
    }
    c = usb_serial_getchar();
    if (c != -1) {
      seen_usb++;
      return c;
    }
  }
}

void init_io(int argc, char **argv, cell *up)
{
  // turn on clock
  SIM_SCGC4 |= SIM_SCGC4_UART0;

  // configure receive pin
  // pfe - passive input filter
  // ps - pull select, enable pullup, p229
  // pe - pull enable, on, p229
  CORE_PIN0_CONFIG = PORT_PCR_PE | PORT_PCR_PS | PORT_PCR_PFE | PORT_PCR_MUX(3);

  // configure transmit pin
  // dse - drive strength enable, high, p228
  // sre - slew rate enable, slow, p229
  CORE_PIN1_CONFIG = PORT_PCR_DSE | PORT_PCR_SRE | PORT_PCR_MUX(3);

  // baud rate generator, 115200, derived from test build
  // reference, *RM.pdf, table 47-57, page 1275, 38400 baud?
  UART0_BDH = 0;
  UART0_BDL = 0x1a;
  UART0_C4 = 0x1;

  // fifo enable
  UART0_PFIFO = UART_PFIFO_TXFE | UART_PFIFO_RXFE;

  // transmitter enable, receiver enable
  UART0_C2 = UART_C2_TE | UART_C2_RE;

  seen_usb = 0;
  sent_usb = 0;
  usb_init();
  analog_init();
}

void wfi(void)
{
  asm("wfi"); // __WFI();
}

void yield(void)
{
  asm("wfi"); // __WFI();
}

volatile uint32_t systick_millis_count = 0;
int get_msecs(void)
{
  return systick_millis_count;
}

int spins(int i)
{
  while(i--)
    asm("");  // The asm("") prevents optimize-to-nothing
}

void pfprint_input_stack(void) {}
void pfmarkinput(void *fp, cell *up) {}

cell pfflush(cell f, cell *up)
{
    return -1;
}

cell pfsize(cell f, u_cell *high, u_cell *low, cell *up)
{
    *high = 0;
    *low = 0;
    return SIZEFAIL;
}

cell isstandalone() { return 1; }

#include <stdio.h>

size_t strlen(const char *s)
{
    const char *p = s;
    while (*p) { p++; }
    return p-s;
}
