#include "forth.h"
#include "compiler.h"

// Character I/O stubs

#define UART3REG ((unsigned int volatile *)0xd4018000)  // UART3 - main board
#define UART1REG ((unsigned int volatile *)0xd4030000)  // UART1 - JTAG board

void tx1(char c)
{
    // send the character to the console output device
    while ((UART1REG[5] & 0x20) == 0)
        ;
    UART1REG[0] = (unsigned int)c;
}
void tx3(char c)
{
    // send the character to the console output device
    while ((UART3REG[5] & 0x20) == 0)
        ;
    UART3REG[0] = (unsigned int)c;
}

void tx(char c)
{
    tx1(c);
    tx3(c);
}

int putchar(int c)
{
    if (c == '\n')
        tx('\r');
    tx(c);
    return c;
}

int kbhit1() {
    return (UART1REG[5] & 0x1) != 0;
}
int kbhit3() {
    return (UART3REG[5] & 0x1) != 0;
}

int kbhit() {
    return kbhit1() || kbhit3();
}

int getchar()
{
    while (!kbhit())
        ;
    // return the next character from the console input device
    
    return (unsigned char) (kbhit1() ? UART1REG[0] : UART3REG[0]);
}

void init_io()
{
    *(int *)0xd4051024 = 0xffffffff;  // PMUM_CGR_PJ - everything on
    *(int *)0xD4015064 = 0x7;         // APBC_AIB_CLK_RST - reset, functional and APB clock on
    *(int *)0xD4015064 = 0x3;         // APBC_AIB_CLK_RST - release reset, functional and APB clock on
    *(int *)0xD401502c = 0x13;        // APBC_UART1_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)
    *(int *)0xD4015034 = 0x13;        // APBC_UART3_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)

//  *(int *)0xd401e120 = 0xc1;        // GPIO51 = af1 for UART3 RXD
//  *(int *)0xd401e124 = 0xc1;        // GPIO52 = af1 for UART3 TXD

    *(int *)0xd401e260 = 0xc4;        // GPIO115 = af4 for UART3 RXD
    *(int *)0xd401e264 = 0xc4;        // GPIO116 = af4 for UART3 TXD

    *(int *)0xd401e0c8 = 0xc1;        // GPIO29 = af1 for UART1 RXD
    *(int *)0xd401e0cc = 0xc1;        // GPIO30 = af1 for UART1 TXD

    UART1REG[1] = 0x40;  // Marvell-specific UART Enable bit
    UART1REG[3] = 0x83;  // Divisor Latch Access bit
    UART1REG[0] = 14;    // 115200 baud
    UART1REG[1] = 00;    // 115200 baud
    UART1REG[3] = 0x03;  // 8n1
    UART1REG[2] = 0x07;  // FIFOs and stuff

    UART3REG[1] = 0x40;  // Marvell-specific UART Enable bit
    UART3REG[3] = 0x83;  // Divisor Latch Access bit
    UART3REG[0] = 14;    // 115200 baud
    UART3REG[1] = 00;    // 11500 baud
    UART3REG[3] = 0x03;  // 8n1
    UART3REG[2] = 0x07;  // FIFOs and stuff
}

#if 1
typedef volatile unsigned long *reg_t;
#define REG(name, address) volatile reg_t name = (reg_t)address
REG(TIMER20_FREEZE, 0xd40800a4);
REG(TIMER20, 0xd4080028);

REG(SP_PARAM,          0xd4290000); /* 16 registers from 00..3c inclusive */
REG(SP_COMMAND,        0xd4290040); /* written last after PARAM registers; auto-set cmd-reg-occupied */
REG(SP_RETURN,         0xd4290080); /* 17 registers from 80..c4 inclusive */
REG(PJ_RST_INTERRUPT,  0xd42900c8); /* 17 registers from 80..c4 inclusive */
REG(SP_INTERRUPT_SET,  0xd4290210); /* 02 bit means cmd reg occupied */
REG(SP_INTERRUPT_RESET,0xd4290218); /* 02 bit means cmd reg occupied - write 02 to ack irq */
REG(SP_INTERRUPT_MASK, 0xd429021c); /* 02 bit means cmd reg occupied - clear 02 to allow irq */
REG(SP_CONTROL,        0xd4290220); /* 01 bit means cmd reg occupied - write 0 to cycle to next cmd */
REG(PJ_INTERRUPT_SET,  0xd4290234); /* write 01 to send interrupt upstream */
REG(TMR2_SR0,          0xd4080034); /* 3 low bits are for comparators 2,1,0 */
REG(TMR2_IER0,         0xd4080040); /* 3 low bits are for comparators 2,1,0 */
REG(TMR2_ICR0,         0xd4080074); /* 3 low bits are for comparators 2,1,0 */
REG(TMR2_MATCH00,      0xd4080004);
REG(TMR2_MATCH01,      0xd4080008);
REG(TMR2_MATCH02,      0xd408000c);

#define PS2_TIMEOUT 13000   /* 2 ms at 6.5 MHz */

#define GPIO71_MASK 0x80
#define GPIO72_MASK 0x100
#define KBDCLK_MASK GPIO71_MASK
#define KBDDAT_MASK GPIO72_MASK

struct queue {
    int put;
    int get;
    unsigned short data[16];
};

struct queue ps2_queue;

struct ps2_state {
    int bit_number;
    int timestamp;
    int byte;
    int parity;
    reg_t dat_gpio;
    reg_t clk_gpio;
    unsigned long dat_mask;
    unsigned long clk_mask;
};

#define GPIO_PLR_INDEX  0x00   /* Pin level */
#define GPIO_PDR_INDEX  0x03   /* Pin direction */
#define GPIO_PSR_INDEX  0x06   /* Pin set */
#define GPIO_PCR_INDEX  0x09   /* Pin clear */
#define GPIO_RER_INDEX  0x0c   /* Rising edge enable */
#define GPIO_FER_INDEX  0x0f   /* Falling edge enable */
#define GPIO_EDR_INDEX  0x12   /* Edge detect */
#define GPIO_SDR_INDEX  0x15   /* Set direction to out */
#define GPIO_CDR_INDEX  0x18   /* Clr direction to in */
#define GPIO_SRER_INDEX 0x1b   /* Set rising  edge detect enable */
#define GPIO_CRER_INDEX 0x1e   /* Clr rising  edge detect enable */
#define GPIO_SFER_INDEX 0x21   /* Set falling edge detect enable */
#define GPIO_CFER_INDEX 0x24   /* Clr falling edge detect enable */
#define GPIO_APMASK_INDEX 0x27
#define GPIO_EXTPROCMASK_INDEX 0x2a

struct ps2_state kbd_state = {
    .bit_number = 0,
    .timestamp = 0,
    .byte = 0,
    .dat_gpio = (reg_t)0xd4019008, // GPIO64-95
    .clk_gpio = (reg_t)0xd4019008, // GPIO64-95
    .dat_mask = GPIO72_MASK,
    .clk_mask = GPIO71_MASK,
};    

#define GPIO107_MASK 0x800
#define GPIO160_MASK 0x001
struct ps2_state tpd_state = {
    .bit_number = 0,
    .timestamp = 0,
    .byte = 0,
    .parity = 0,
    .dat_gpio = (reg_t)0xd4019100, // GPIO96-111
    .clk_gpio = (reg_t)0xd4019108, // GPIO160-181
    .dat_mask = GPIO107_MASK,
    .clk_mask = GPIO160_MASK,
};

struct ps2_state *ps2_devices[] = { &kbd_state, &tpd_state };
#define NUM_PS2_DEVICES (sizeof (ps2_devices) / sizeof (ps2_devices[0]))

void enque(unsigned short w, struct queue *q)
{
    int put = q->put;
    if ((((put+1) - q->get) & 0xf) == 0)
	return;
    q->data[put] = w;
    q->put = (put+1) & 0xf;
}
int deque(struct queue *q)
{
    int get = q->get;
    int ret;

    if (get == q->put)
	return -1;
    ret = (int)q->data[get];
    q->get = (get+1) & 0xf;
    return ret;
}

void init_ps2()
{
    int i;
    struct ps2_state *s;

    for (i = 0; i < NUM_PS2_DEVICES; i++) {
	s = ps2_devices[i];
	s->bit_number = 0;
    }
    ps2_queue.get = ps2_queue.put = 0;
}

#define WAIT_CLK_LOW  while ((*clk_gpio & clk_mask) != 0) {}
#define WAIT_CLK_HIGH while ((*clk_gpio & clk_mask) == 0) {}
#define SEND_BIT(flag,gpio,mask) gpio[(flag) ? GPIO_CDR_INDEX : GPIO_SDR_INDEX] = mask
#define DRIVE_LOW(gpio,mask) gpio[GPIO_SDR_INDEX] = mask    /* Direction out to drive a low */
#define DRIVE_HIGH(gpio,mask) gpio[GPIO_CDR_INDEX] = mask   /* Direction in so pullup pulls high */
#define BIT_OUT(flag)  WAIT_CLK_LOW  SEND_BIT(flag,dat_gpio,dat_mask);  WAIT_CLK_HIGH

void ticks(int n)
{
    int count;
    *TIMER20_FREEZE = 1;                 /* Latch count */
    count = *TIMER20;                    /* Read count */
    do {
	*TIMER20_FREEZE = 1;             /* Latch count */	
    } while ((*TIMER20 - count) <= n);
}

int ps2_out(int device_num, unsigned char byte) {
    struct ps2_state *s = ps2_devices[device_num];
    reg_t clk_gpio = s->clk_gpio;
    reg_t dat_gpio = s->dat_gpio;
    unsigned long dat_mask = s->dat_mask;
    unsigned long clk_mask = s->clk_mask;
    int i;
    int parity = 1;

    clk_gpio[GPIO_CFER_INDEX] = clk_mask; // Turn off receiver interrupts

    DRIVE_LOW(clk_gpio,clk_mask);  // Set direction to out to drive clk low

    ticks(390);   // 60 us delay

    DRIVE_LOW(dat_gpio,dat_mask);     // Data low tells the device to receive data
    DRIVE_HIGH(clk_gpio,clk_mask);    // After clk goes high, device will respond with clk pulses

    ticks(65);    // Delay for 10 us to give clk time to rise before we poll it

    // Now the device should give us some clock pulses
    for (i=0; i<8; i++) {
	BIT_OUT(byte&1);
	parity ^= (byte & 1);
	byte >>= 1;
    }

    // Send parity bit
    BIT_OUT(parity&1);
    
    // Send stop bit
    BIT_OUT(1);

    // Receive ack bit
    WAIT_CLK_LOW;
    byte = (dat_gpio[0] & dat_mask) == 0;
    WAIT_CLK_HIGH;

    clk_gpio[GPIO_SFER_INDEX] = clk_mask; // Turn on receiver interrupts

    return byte;  // Returns true if acked
}

int ok_to_send = 0;

void run_queue()
{
    int data;

    /*
     * The following line make it safe for the host end to send a RDY command at any time,
     * even if data is already waiting in the upstream buffer
     */
    if ((*PJ_RST_INTERRUPT) & 1)  /* Don't overwrite data already in buffer */
	return;

    data = deque(&ps2_queue);
    if (data == -1)
	return;
    SP_RETURN[0] = data;
    *PJ_INTERRUPT_SET = 1;
    ok_to_send = 0;
}

int rxlevel = 0;

void do_command() {
    int port, data;
    
    data = *SP_COMMAND;
    if (data == 0xff00) {
	ok_to_send = 1;
	run_queue();
    } else {
	port = (data >> 8) & 0xff;
	data &= 0xff;
	if (port < 2) {
	    struct ps2_state *s;
	    int ticks;

	    if (++rxlevel == 1) {
		*SP_INTERRUPT_MASK |= 2;  /* Avoid command interrupts while receiving */
	    }

	    s = ps2_devices[port];
	    s->bit_number = 20;
	    s->byte = data;
	    s->parity = 1;

	    /* Schedule a timer interrupt for 60 us from now */
	    *TIMER20_FREEZE = 1;    /* Latch count */
	    s->timestamp = *TIMER20;
	    TMR2_MATCH00[port] = s->timestamp + 780;  /* 60 us */
	    *TMR2_IER0 |= (1 << port);

	    s->clk_gpio[GPIO_CFER_INDEX] = s->clk_mask; // Turn off falling edge interrupts

	    /* Drive the clock low to get the device's attention */
	    /* The timer interrupt handler will later drive it high */
	    DRIVE_LOW(s->clk_gpio, s->clk_mask);
	}
    }
}

void do_timer(int channels) {
    int i;
    for (i=0; i<2; i++) {
	if (channels & (1<<i)) {
	    struct ps2_state *s;
	    s = ps2_devices[i];
	    DRIVE_LOW(s->dat_gpio, s->dat_mask);
	    DRIVE_HIGH(s->clk_gpio, s->clk_mask);
	    s->bit_number = 21;
	    s->clk_gpio[GPIO_SFER_INDEX] = s->clk_mask; // Turn on falling edge interrupts
	}
    }
}

void irq_handler()
{
    struct ps2_state *s;
    int this_timestamp;
    int i;
    int timers;

    if (*SP_INTERRUPT_SET & 2) {
	while (*SP_CONTROL & 1) {
	    do_command();
	    *SP_CONTROL = 0;
	}	
	*SP_INTERRUPT_RESET = 2;
    }

    if ((timers = *TMR2_SR0) & 3) {
	do_timer(timers);
	*TMR2_IER0 &= ~timers;   // Disable timer interrupt
	*TMR2_ICR0 = timers;     // Clear timer interrupt
    }

    *TIMER20_FREEZE = 1;             /* Latch count */
    this_timestamp = *TIMER20;       /* Read count */

    for (i = 0; i < NUM_PS2_DEVICES; i++) {
	s = ps2_devices[i];
	if (((s->clk_gpio)[GPIO_EDR_INDEX] & s->clk_mask) == 0) {
	    continue;
	}
	(s->clk_gpio)[GPIO_EDR_INDEX] = s->clk_mask;	/* Ack the interrupt */

	if ((this_timestamp - s->timestamp) > PS2_TIMEOUT) {
	    s->bit_number = 0;
	    s->byte = 0;
	}

	s->timestamp = this_timestamp;

	switch (s->bit_number)
	{
	case 0:
	    s->bit_number++;
	    if (++rxlevel == 1) {
		*SP_INTERRUPT_MASK |= 2;  /* Avoid command interrupts while receiving */
	    }
	    break;
	case 1: case 2: case 3: case 4:
	case 5:	case 6:	case 7:	case 8:
	    if ((s->dat_gpio)[GPIO_PLR_INDEX] & s->dat_mask) {
		s->byte |= 0x100;
	    }
	    s->byte >>= 1;
	    s->bit_number++;
	    break;
	case 9:
	    /* Should check parity */
	    s->bit_number++;
	    break;
	case 10:
	    enque((unsigned short)((i<<8)|(s->byte & 0xff)), &ps2_queue);
	    if (--rxlevel == 0) {
		*SP_INTERRUPT_MASK &= ~2;  /* Allow command interrupts when receivers are idle */
	    }
	    s->bit_number = 0;
	    s->byte = 0;
	    if (ok_to_send)
		run_queue();
	    break;

	    /* States 20-31 are for sending */
	case 20: /* Shouldn't happen - handled by timer */
	    break;
	case 21: case 22: case 23: case 24:
	case 25: case 26: case 27: case 28:
	    SEND_BIT(s->byte & 1, s->dat_gpio, s->dat_mask);
	    s->parity ^= (s->byte & 1);
	    s->byte >>= 1;
	    s->bit_number++;
	    break;
	case 29:
	    SEND_BIT(s->parity & 1, s->dat_gpio, s->dat_mask);
	    s->bit_number++;
	    break;
	case 30:
	    SEND_BIT(1, s->dat_gpio, s->dat_mask);	/* Stop bit */
	    s->bit_number++;
	    break;
	case 31:
	    /* Could read ack here, but not sure what to do with it */
	    s->bit_number = 0;
	    if (--rxlevel == 0) {
		*SP_INTERRUPT_MASK &= ~2;  /* Allow command interrupts when receivers are idle */
	    }
	    break;
	default:
	    s->bit_number = 0;
	    s->byte = 0;
	}
    }
}

#else
cell irq_dstack[PSSIZE];
cell irq_rstack[RSSIZE];

#define IRQ_BLOCK (0x10c/sizeof(unsigned long))
void irq_handler()
{
    unsigned long *icbase = (unsigned long *)0xd4282000;
    cell spsave;
    cell rpsave;
    extern u_char variables[];
    cell *up = (cell *)(&variables[0]);

    icbase[IRQ_BLOCK] = 1;
//    putchar('I');
    
    spsave = V(XSP);
    rpsave = V(XRP);

    V(XSP) = (cell)&irq_dstack[PSSIZE];
    V(XRP) = (cell)&irq_rstack[RSSIZE];
   
    (void) execute_word("do-irq", up);

    V(XSP) = spsave;
    V(XRP) = rpsave;
}
#endif

void swi_handler()
{
}

void raise()  /* In case __div and friends need it */
{
}
