// #define VCOM
// Character I/O stubs

#include "forth.h"

#ifdef STANDALONE
#endif

int usb_serial_getchar(void);
int usb_serial_peekchar(void);
int usb_serial_available(void);
int usb_serial_read(void *buffer, uint32_t size);
void usb_serial_flush_input(void);
int usb_serial_putchar(uint8_t c);
int usb_serial_write(const void *buffer, uint32_t size);
int usb_serial_write_buffer_free(void);
void usb_serial_flush_output(void);

extern uint8_t usb_cdc_line_rtsdtr;
#define USB_SERIAL_ON (usb_cdc_line_rtsdtr & 1)

void raw_putchar(char c)
{
    if (USB_SERIAL_ON) {
	usb_serial_putchar(c);
    }
#ifdef USE_UART
    serial_putchar(c);
#endif
}

int kbhit() {
    // return usb_serial_available() != 0;
    if(USB_SERIAL_ON && (usb_serial_available() != 0))
	return 1;
#ifdef USE_UART
    return serial_available() != 0;
#endif
    return 0;
}

int getkey()
{
    while (!kbhit())
        ;
    // return the next character from the console input device
//    return usb_serial_getchar();
    if(USB_SERIAL_ON && (usb_serial_available() != 0)) {
	return usb_serial_getchar();
    }
#ifdef USE_UART
    return serial_getchar();
#endif
    return 0;
}

void init_io(int argc, char **argv, cell *up)
{
}

void irq_handler()
{
}

void swi_handler()
{
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
