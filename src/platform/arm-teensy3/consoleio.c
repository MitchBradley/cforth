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

int use_uart; /* data has been received from the UART */
int use_usb;  /* data has been received from the USB host */
int sent_usb; /* data has been sent to the USB layer that is not yet flushed */

void console_uart_on()
{
  use_uart++;
}

void console_uart_off()
{
  use_uart = 0;
}

int console_uart()
{
  return use_uart;
}

void console_usb_on()
{
  use_usb++;
}

void console_usb_off()
{
  use_usb = 0;
}

int console_usb()
{
  return use_usb;
}

void raw_putchar(char c)
{
  if (use_uart) {
    /* pause until transmit data register empty */
    while(!(UART0_S1 & UART_S1_TDRE))
      ;
    UART0_D = c;
  }
  if (use_usb) {
    usb_serial_putchar(c);
    sent_usb++;
  }
}

#if 0
// usb debug
void serial_putchar(char c)
{
  if (!use_usb) return;
  while(!(UART0_S1 & UART_S1_TDRE))
    ;
  UART0_D = c;
}

static void serial_phex1(uint32_t n)
{
  n &= 15;
  if (n < 10) {
    serial_putchar('0' + n);
  } else {
    serial_putchar('A' - 10 + n);
  }
}

void serial_phex(uint32_t n)
{
  serial_phex1(n >> 4);
  serial_phex1(n);
}

void serial_phex32(uint32_t n)
{
  serial_phex(n >> 24);
  serial_phex(n >> 16);
  serial_phex(n >> 8);
  serial_phex(n);
}

void serial_print(const char *p)
{
  while (*p) {
    char c = *p++;
    if (c == '\n') serial_putchar('\r');
    serial_putchar(c);
  }
}
#endif

#if 0
// early debug
const char hexen[] = "0123456789ABCDEF";

void put8(uint32_t c)
{
  emit(hexen[(c >> 4) & 0xf]);
  emit(hexen[c & 0xf]);
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
    emit((int)*str++);
}
#endif

int kbhit()
{
  if (UART0_RCFIFO > 0) {
    use_uart++;
    return 1;
  }
  if (usb_serial_peekchar() != -1) {
    use_usb++;
    return 1;
  }
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
      use_uart++;
      return c;
    }
    c = usb_serial_getchar();
    if (c != -1) {
      use_usb++;
      return c;
    }
  }
}

void init_uart()
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

#ifdef ENABLE_RTS
  // hardware flow control on receive path only, using RTS
  CORE_PIN6_CONFIG = PORT_PCR_DSE | PORT_PCR_SRE | PORT_PCR_MUX(3);
  UART0_MODEM = UART_MODEM_RXRTSE;
#endif

  // baud rate generator, 115200, derived from test build
  // reference, *RM.pdf, table 47-57, page 1275, 38400 baud?
  UART0_BDH = 0;
  UART0_BDL = 0x1a;
  UART0_C4 = 0x1;

  // fifo enable
  UART0_PFIFO = UART_PFIFO_TXFE | UART_PFIFO_RXFE;

  // transmitter enable, receiver enable
  UART0_C2 = UART_C2_TE | UART_C2_RE;

  use_uart = 0;
  use_usb = 0;
  sent_usb = 0;
}

void wfi(void)
{
  asm("wfi"); // __WFI();
}

void yield(void)
{
  asm("wfi"); // __WFI();
}

extern volatile uint32_t systick_millis_count;
int get_msecs(void)
{
  return systick_millis_count;
}

int spins(int i)
{
  while(i--)
    asm("");  // The asm("") prevents optimize-to-nothing
}

#include <stdio.h>

size_t strlen(const char *s)
{
    const char *p = s;
    while (*p) { p++; }
    return p-s;
}
