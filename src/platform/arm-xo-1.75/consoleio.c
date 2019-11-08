#include "forth.h"
#include "compiler.h"

#define DDEBUG 0    // enable for command/response debug
#define CDEBUG 0    // enable for bit-level debug

void gamekey_init();
void gamekey_handle();
void ebook_init();
int  ebook_mode();

#define NO_EBOOK_CHECK

// Character I/O stubs

#define UART4REG ((unsigned int volatile *)0xd4016000)  // UART4 - main board lower (cl2)
#define UART3REG ((unsigned int volatile *)0xd4018000)  // UART3 - main board upper (cl2)
#define UART2REG ((unsigned int volatile *)0xd4017000)  // UART2 - BSL (cl2), main board (cl3)
#define UART1REG ((unsigned int volatile *)0xd4030000)  // UART1 - JTAG board

int dbg_uart_only = 0;

void tx1(char c)
{
    // send the character to the console output device
    while ((UART1REG[5] & 0x20) == 0)
        ;
    UART1REG[0] = (unsigned int)c;
}
void tx2(char c)
{
    // send the character to the console output device
    while ((UART2REG[5] & 0x20) == 0)
        ;
    UART2REG[0] = (unsigned int)c;
}
void tx3(char c)
{
    // send the character to the console output device
    while ((UART3REG[5] & 0x20) == 0)
        ;
    UART3REG[0] = (unsigned int)c;
}
void tx4(char c)
{
    // send the character to the console output device
    while ((UART4REG[5] & 0x20) == 0)
        ;
    UART4REG[0] = (unsigned int)c;
}
#ifdef CL4
void txdbg(char c)
{
    tx1(c);
}
void raw_putchar(char c)
{
    txdbg(c);
    if (dbg_uart_only)
	return;
    tx2(c);
}
#else
void txdbg(char c)
{
    tx4(c);
}
void raw_putchar(char c)
{
    txdbg(c);
    if (dbg_uart_only)
	return;
    tx1(c);
    tx3(c);
}
#endif


void dbgputn(unsigned int c)
{
	char *digits = "0123456789abcdef";
	txdbg(digits[(c>>4)&0x0f]);
	txdbg(digits[c&0x0f]);
}
void dbgputcmd(unsigned int c)
{
	dbgputn(c);
	txdbg('.');
}
void dbgputresp(unsigned int c)
{
	dbgputn(c);
	txdbg(' ');
}

int kbhit1() {
    return (UART1REG[5] & 0x1) != 0;
}
int kbhit2() {
    return (UART2REG[5] & 0x1) != 0;
}
int kbhit3() {
    return (UART3REG[5] & 0x1) != 0;
}
int kbhit4() {
    return (UART4REG[5] & 0x1) != 0;
}

int kbhit() {
#ifdef CL4
    return kbhit2() || kbhit1();
#else
    return kbhit1() || kbhit3() || kbhit4();
#endif
}

int getkey()
{
    // return the next character from the console input device
    do {
#ifdef CL4
	if (kbhit1())
	    return UART1REG[0];
	if ((!dbg_uart_only) && kbhit2())
	    return UART2REG[0];
#else
	if (kbhit4())
	    return UART4REG[0];
	if ((!dbg_uart_only) && kbhit3())
	    return UART3REG[0];
	if ((!dbg_uart_only) && kbhit1())
	    return UART1REG[0];
#endif
    } while (1);
}

void init_io(int argc, char **argv, cell *up)
{
    dbg_uart_only = 0;

    // If the PJ4 processor has already been started, this is an unexpected
    // reset so we skip the SoC init to preserve state for debugging.
    if (((*(int *)0xd4050020) & 0x02) == 0)
	    return;

    *(int *)0xd4051024 = 0xffffffff;  // PMUM_CGR_PJ - everything on
    *(int *)0xD4015064 = 0x7;         // APBC_AIB_CLK_RST - reset, functional and APB clock on
    *(int *)0xD4015064 = 0x3;         // APBC_AIB_CLK_RST - release reset, functional and APB clock on
#ifdef CL4
    *(int *)0xd4051020 = 0x0;         // PMUM_PRR_PJ - Turn off SLAVE_R and WDTR2 (empirically, the WDTR2 bit stays set afterwards)

    *(int *)0xd401e0c8 = 0xc1;        // GPIO29 = af1 for UART1 RXD
    *(int *)0xd401e0cc = 0xc1;        // GPIO30 = af1 for UART1 TXD

    *(int *)0xD401502c = 0x13;        // APBC_UART1_CLK_RST - VCTCXO, functio

    UART1REG[1] = 0x40;  // Marvell-specific UART Enable bit
    UART1REG[3] = 0x83;  // Divisor Latch Access bit
    UART1REG[0] = 14;    // 115200 baud
    UART1REG[1] = 00;    // 115200 baud
    UART1REG[3] = 0x03;  // 8n1
    UART1REG[2] = 0x07;  // FIFOs and stuff


    *(int *)0xd401e018 = 0xc1;        // GPIO127 = af1 for UART2 TXD
    *(int *)0xd401e01c = 0xc1;        // GPIO128 = af1 for UART2 RXD

    *(int *)0xd401e15c = 0xb140;      // SLAVE_RESET_OUT = af0, drive high during suspend (so the EC does not think it is a thermal watchdog)

    *(int *)0xD4015030 = 0x13;        // APBC_UART2_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)

    UART2REG[1] = 0x40;  // Marvell-specific UART Enable bit
    UART2REG[3] = 0x83;  // Divisor Latch Access bit
    UART2REG[0] = 14;    // 115200 baud
    UART2REG[1] = 00;    // 115200 baud
    UART2REG[3] = 0x03;  // 8n1
    UART2REG[2] = 0x07;  // FIFOs and stuff
#else
    *(int *)0xD4015064 = 0x3;         // APBC_AIB_CLK_RST - release reset, functional and APB clock on
    *(int *)0xD401502c = 0x13;        // APBC_UART1_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)
    *(int *)0xD4015034 = 0x13;        // APBC_UART3_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)
    *(int *)0xD4015088 = 0x13;        // APBC_UART4_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)

//  *(int *)0xd401e120 = 0xc1;        // GPIO51 = af1 for UART3 RXD
//  *(int *)0xd401e124 = 0xc1;        // GPIO52 = af1 for UART3 TXD

    *(int *)0xd401e260 = 0xc4;        // GPIO115 = af4 for UART3 RXD
    *(int *)0xd401e264 = 0xc4;        // GPIO116 = af4 for UART3 TXD

    *(int *)0xd401e268 = 0xc3;        // GPIO117 = af3 for UART4 RXD
    *(int *)0xd401e26c = 0xc3;        // GPIO118 = af3 for UART4 TXD

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

    UART4REG[1] = 0x40;  // Marvell-specific UART Enable bit
    UART4REG[3] = 0x83;  // Divisor Latch Access bit
    UART4REG[0] = 14;    // 115200 baud
    UART4REG[1] = 00;    // 11500 baud
    UART4REG[3] = 0x03;  // 8n1
    UART4REG[2] = 0x07;  // FIFOs and stuff
#endif
}


typedef volatile unsigned long *reg_t;
#define REG(name, address) volatile reg_t name = (reg_t)address

/* a note on timers:  2 of the match registers are used for keyboard
 * and touchpad protocol timing.  the third is used to debounce the
 * game keys.
 */

REG(TIMER20_FREEZE, 0xd40800a4);
REG(TIMER20, 0xd4080028);

REG(SP_PARAM,          0xd4290000); /* 16 registers from 00..3c inclusive */
REG(SP_COMMAND,        0xd4290040); /* written last after PARAM registers; auto-set cmd-reg-occupied */
REG(SP_RETURN,         0xd4290080); /* 17 registers from 80..c4 inclusive */
REG(PJ_RST_INTERRUPT,  0xd42900c8); /* 17 registers from 80..c4 inclusive */
REG(SP_INTERRUPT_SET,  0xd4290210); /* 02 bit means cmd reg occupied */
REG(SP_INTERRUPT_RESET,0xd4290218); /* 02 bit means cmd reg occupied - write 02 to ack irq */
REG(SP_INTERRUPT_MASK, 0xd429021c); /* 02 bit means cmd reg irq blocked - clear 02 to allow irq */
REG(SP_CONTROL,        0xd4290220); /* 01 bit means cmd reg occupied - write 0 to cycle to next cmd */
REG(PJ_INTERRUPT_SET,  0xd4290234); /* write 01 to send interrupt upstream */
REG(TMR2_SR0,          0xd4080034); /* 3 low bits are for comparators 2,1,0 */
REG(TMR2_IER0,         0xd4080040); /* 3 low bits are for comparators 2,1,0 */
REG(TMR2_ICR0,         0xd4080074); /* 3 low bits are for comparators 2,1,0 */
REG(TMR2_MATCH00,      0xd4080004);
REG(TMR2_MATCH01,      0xd4080008);
REG(TMR2_MATCH02,      0xd408000c);

#define GPIO_0_31      0xd4019000
#define GPIO_32_63     0xd4019004
#define GPIO_64_95     0xd4019008
#define GPIO_96_127    0xd4019100
#define GPIO_128_159   0xd4019104
#define GPIO_160_191   0xd4019108

#define PS2_TIMEOUT 260000   /* 20 ms at 13 MHz */

#define GPIO71_MASK 0x80
#define GPIO72_MASK 0x100
#define KBDCLK_MASK GPIO71_MASK
#define KBDDAT_MASK GPIO72_MASK

// QUEUE_LEN must be a power of two
#define QUEUE_LEN 64
#define QUEUE_MASK QUEUE_LEN-1
struct queue {
    int put;
    int get;
    unsigned char data[64];
};

struct ps2_state {
    int bit_number;
    int timestamp;
    int byte;
    int parity;
    reg_t dat_gpio;
    reg_t clk_gpio;
    unsigned long dat_mask;
    unsigned long clk_mask;
    int quenched;
    struct queue queue; 
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
    .dat_gpio = (reg_t)GPIO_64_95,
    .clk_gpio = (reg_t)GPIO_64_95,
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
    .dat_gpio = (reg_t)GPIO_96_127,
    .clk_gpio = (reg_t)GPIO_160_191,
    .dat_mask = GPIO107_MASK,
    .clk_mask = GPIO160_MASK,
};

struct ps2_state *ps2_devices[] = { &kbd_state, &tpd_state };
#define NUM_PS2_DEVICES (sizeof (ps2_devices) / sizeof (ps2_devices[0]))

int queue_nearly_full(struct queue *q)
{
    int put = q->put;
    int get = q->get;
    return (((put+1) - get) & QUEUE_MASK) == 0 ||
	   (((put+2) - get) & QUEUE_MASK) == 0;
}

// Silently drops from the head if the queue is full
// It's better to lose down events than subsequent up events
void always_enque(unsigned char b, struct queue *q)
{
    int put = q->put;
    if ((((put+1) - q->get) & QUEUE_MASK) == 0) {
	q->get = (q->get+1) & QUEUE_MASK;
    }
    q->data[put] = b;
    q->put = (put+1) & QUEUE_MASK;
}

void enque(unsigned char b, struct queue *q)
{
    if (!ebook_mode())
	always_enque(b, q);
}

int deque(struct queue *q)
{
    int get = q->get;
    int ret;

    if (get == q->put)
	return -1;
    ret = (int)q->data[get];
    q->get = (get+1) & QUEUE_MASK;
    return ret;
}

const unsigned char set2_to_set1[] =
{
    0xFF, 0x43, 0x41, 0x3F, 0x3D, 0x3B, 0x3C, 0x58,    //0x00
    0x64, 0x44, 0x42, 0x40, 0x3E, 0x0F, 0x29, 0x59,
    0x65, 0x38, 0x2A, 0x70, 0x1D, 0x10, 0x02, 0x5A,    //0x10
    0xb4, 0x71, 0x2C, 0x1F, 0x1E, 0x11, 0x03, 0x5B,
    0x67, 0x2E, 0x2D, 0x20, 0x12, 0x05, 0x04, 0x5C,    //0x20
    0x68, 0x39, 0x2F, 0x21, 0x14, 0x13, 0x06, 0x5D,
    0x69, 0x31, 0x30, 0x23, 0x22, 0x15, 0x07, 0x5E,    //0x30
    0x6A, 0x72, 0x32, 0x24, 0x16, 0x08, 0x09, 0x5F,
    0x6B, 0x33, 0x25, 0x17, 0x18, 0x0B, 0x0A, 0x60,    //0x40
    0x6C, 0x34, 0x35, 0x26, 0x27, 0x19, 0x0C, 0x61,
    0x6D, 0x73, 0x28, 0x74, 0x1A, 0x0D, 0x62, 0x6E,    //0x50
    0x3A, 0x36, 0x1C, 0x1B, 0x75, 0x2B, 0x63, 0x76,
    0x55, 0x56, 0x77, 0x78, 0x79, 0x7A, 0x0E, 0x7B,    //0x60
    0x7C, 0x4F, 0x7D, 0x4B, 0x47, 0x7E, 0x7F, 0x6F,
    0x52, 0x53, 0x50, 0x4C, 0x4D, 0x48, 0x01, 0x45,    //0x70
    0x57, 0x4E, 0x51, 0x4A, 0x37, 0x49, 0x46, 0x54
};

// Translates the matrix values to scan set 2
const unsigned char EnE3867_to_set2[] =
{
// KSI 0     1     2     3     4     5     6     7
    0x80, 0x80, 0x14, 0x80, 0x80, 0x80, 0x80, 0xa2,    //KSO 0
    0x0e, 0x8B, 0x0D, 0x0E, 0x1C, 0x1A, 0xa7, 0x15,    //KSO 1
    0x8C, 0x92, 0x90, 0x8E, 0x23, 0x21, 0xa9, 0x24,    //KSO 2
    0x80, 0xa5, 0x80, 0x80, 0x80, 0xa6, 0x80, 0x8D,    //KSO 3
    0x32, 0x34, 0x2C, 0xab, 0x2B, 0x2A, 0xaa, 0x2D,    //KSO 4
    0x99, 0x97, 0x95, 0x93, 0x1B, 0x22, 0xa8, 0x1D,    //KSO 5
    0x84, 0x93, 0x5B, 0x5d, 0x42, 0x41, 0xae, 0x43,    //KSO 6
    0xa3, 0x9F, 0x9D, 0x81, 0x9B, 0x98, 0x96, 0x8F,    //KSO 7
    0x31, 0x33, 0x35, 0xac, 0x3B, 0x3A, 0xad, 0x3C,    //KSO 8
    0x80, 0x80, 0x80, 0x80, 0x80, 0x12, 0x80, 0x85,    //KSO 9
    0xb2, 0x52, 0x54, 0xb1, 0x4C, 0x4A, 0xb0, 0x4D,    //KSO 10
    0xa0, 0x9E, 0x9C, 0x9A, 0x4B, 0x49, 0xaf, 0x44,    //KSO 11
    0x80, 0x80, 0x80, 0xa1, 0x80, 0x80, 0x80, 0x91,    //KSO 12
    0xa4, 0x80, 0x80, 0x80, 0x80, 0x80, 0x11, 0x94,    //KSO 13
    0x82, 0xb3, 0x80, 0x5D, 0x5A, 0x86, 0x89, 0x88,    //KSO 14
    0x83, 0x95, 0x5B, 0x55, 0x80, 0x52, 0x8A, 0x87     //KSO 15
};

// Special keys - some requiring a 0xe0 prefix, some function-key dependent
// 0x00 means that no event is sent upstream

#define PREFIX(x) ((x)|0x80)   // If the prefix bit is set, an 0xe0 prefix is sent

const struct {
    unsigned char normal;
    unsigned char function;
} function_table[] =
{
//    Normal Function-key
       0x00,        0x00,     // 80    No key
       0x0f,        0x0f,     // 81    Function shift
PREFIX(0x70),PREFIX(0x70),    // 82    Insert
PREFIX(0x71),PREFIX(0x71),    // 83    Delete
       0x51,        0x6D,     // 84    Language,       2nd Language
       0x59, PREFIX(0x70),    // 85    R Shift,        Insert
       0x29, PREFIX(0x61),    // 86    Space,          kbd Light
PREFIX(0x6B),PREFIX(0x6C),    // 87    Left Arrow,     Home
PREFIX(0xf5),PREFIX(0x7D),    // 88    Up Arrow,       Pg Up
PREFIX(0x72),PREFIX(0x7A),    // 89    Down Arrow,     Pg Dn
PREFIX(0x74),PREFIX(0x69),    // 8A    Right Arrow,    End
       0x76, PREFIX(0x76),    // 8B    ESC,            ViewSrc
       0x05, PREFIX(0x05),    // 8C    F1
       0x00, PREFIX(0x62),    // 8D                    F1.5
       0x06, PREFIX(0x06),    // 8E    F2
       0x00, PREFIX(0x5F),    // 8F                    F2.5
       0x04, PREFIX(0x04),    // 90    F3
       0x00, PREFIX(0x5C),    // 91                    F3.5
       0x0C, PREFIX(0x0C),    // 92    F4
       0x03, PREFIX(0x03),    // 93    F5
       0x00, PREFIX(0x53),    // 94                    F5.5
       0x0B, PREFIX(0x0B),    // 95    F6
       0x00, PREFIX(0x51),    // 96                    F6.5
       0x02, PREFIX(0x02),    // 97    F7              0x83 fix to 0x02
       0x00, PREFIX(0x39),    // 98                    F7.5
       0x0A, PREFIX(0x0A),    // 99    F8
       0x01, PREFIX(0x01),    // 9A    F9
       0x00, PREFIX(0x19),    // 9B                    F9.5
       0x09, PREFIX(0x09),    // 9C    F10
       0x00, PREFIX(0x13),    // 9D                    F10.5
       0x78, PREFIX(0x78),    // 9E    F11
       0x00, PREFIX(0x6F),    // 9F                    F11.5
       0x07, PREFIX(0x07),    // A0    F12
PREFIX(0x2F),PREFIX(0x17),    // A1    Frame,          Win-Apr
PREFIX(0x64),PREFIX(0x63),    // A2    Camera,         Mic
PREFIX(0x57),PREFIX(0x08),    // A3    Chat,
PREFIX(0x11),PREFIX(0x11),    // A4    Right alt gr
PREFIX(0x1F),PREFIX(0x1F),    // A5    L-Grab(L-Win)
PREFIX(0x27),PREFIX(0x27),    // A6    R-Grab(R-Win)
       0x16,        0x05,     // A7    1/!             F1
       0x1e,        0x06,     // A8    2/@             F2
       0x26,        0x04,     // A9    3/#             F3
       0x25,        0x0c,     // AA    4/$             F4
       0x2e,        0x03,     // AB    5/%             F5
       0x36,        0x0b,     // AC    6/^             F6
       0x3d,        0x02,     // AD    7/&             F7
       0x3e,        0x0a,     // AE    8/*             F8
       0x46,        0x01,     // AF    9/(             F9
       0x45,        0x09,     // B0    0/)             F10
       0x4e,        0x78,     // B1    -/_             F11
       0x55,        0x07,     // B2    +/=             F12
       0x66, PREFIX(0x71),    // B3    Erase           Delete
};


/* nonzero if the function key is pressed */
int function_shift = 0;

/* nonzero if the last byte was 0xf0, indicating a key break event */
int got_break = 0;

/* 0 if not translating from matrix mode, otherwise the output scan set */
int translate_set = 0;

/* The value of the last downstream command, used to track multi-byte commands */
int last_cmd;

/* The number of result bytes still expected from the most recent command, */
/* used to suppress scan set translation for command responses */
int suppress_count;

#define WAIT_CLK_LOW  while ((*clk_gpio & clk_mask) != 0) {}
#define WAIT_CLK_HIGH while ((*clk_gpio & clk_mask) == 0) {}
#define SEND_BIT(flag,gpio,mask) gpio[(flag) ? GPIO_CDR_INDEX : GPIO_SDR_INDEX] = mask
#define DRIVE_LOW(gpio,mask) do { \
		gpio[GPIO_PCR_INDEX] = mask; /* force 0 */ \
		gpio[GPIO_SDR_INDEX] = mask; /* set output, to drive a low */ \
	    } while(0)    
#define DRIVE_HIGH(gpio,mask) gpio[GPIO_CDR_INDEX] = mask   /* Direction in so pullup pulls high */
#define BIT_OUT(flag)  WAIT_CLK_LOW  SEND_BIT(flag,dat_gpio,dat_mask);  WAIT_CLK_HIGH

void init_ps2()
{
    int i;
    struct ps2_state *s;

    for (i = 0; i < NUM_PS2_DEVICES; i++) {
	s = ps2_devices[i];
        DRIVE_LOW(s->clk_gpio,s->clk_mask);    // Start with clock low to flow-control the devices
	s->quenched = 0;
	s->bit_number = 0;
	s->queue.get = s->queue.put = 0;
//	DRIVE_HIGH(s->clk_gpio,s->clk_mask);    // After clk goes high, device will respond with clk pulses
    }
    translate_set = 0;
    got_break = 0;
    last_cmd = 0;
    suppress_count = 0;
    function_shift = 0;

    gamekey_init();

    ebook_init();
}

// Keyboard translation.
// Mouse events and ALPS keyboard events are passed through untranslated.
// The EnE keyboard controller in normal scan-set-2 mode botches the OLPC
// special keys, so we run it in raw matrix mode and do the translation
// to scan set 2 or 1 ourselves.  We first translate to scan set 2, and
// then if scan set 1 is selected, we post-translate to set 1.

void forward_event(unsigned char byte, int port) {
    unsigned char kv;
    struct ps2_state *s;

    // This block passes bytes through untranslated
    if (port != 0           // Don't translate mouse events
	|| !translate_set   // Don't translate from the ALPS controller
	|| suppress_count   // Don't translate command responses
	) {

	if (port == 0 && suppress_count) {
	    // Spoof the "get scan set" command when translating to set 1
	    // In matrix mode, the ENE controller returns "2" for "get scan set"
	    if (last_cmd == 0 && translate_set == 1 && byte == 2 ) {
		byte = 1;
	    }
	    --suppress_count;  // One fewer byte to pass through untranslated
	}

	s = ps2_devices[port];
	enque(byte, &s->queue);
	if (queue_nearly_full(&s->queue)) {
	    // Flow control the sender
	    DRIVE_LOW(s->clk_gpio,s->clk_mask);  // Set direction to out to drive clk low
	    s->quenched = 1;
	}
	return;
    }

    // If we get here we must translate the raw matrix code to a scan set code

    // We defer the forwarding of the "break" marker until we get the event code
    // because, if we are outputting scan set 1, the break event is denoted by
    // setting the high bit instead of sending a preceding 0xf0

    if (byte == 0xf0) {  // Up marker
        got_break = 1;
	return;
    }

    // Translate from matrix encoding to scan set 2 value
    kv = EnE3867_to_set2[byte];

    // Handle extended codes, some with an e0 prefix, some function-key dependent
    if (kv >= 0x80) {

        // Track the state of the function shift key
	if (kv == 0x81) {  // Fn shift
	    function_shift = !got_break;
	}

        // Lookup the output key sequence depending on the function shift state
	if (function_shift) {
	    kv = function_table[kv-0x80].function;
	} else {
	    kv = function_table[kv-0x80].normal;
	}

        // Some keys do not have associated events for some function shift states
	if (kv == 0) {
	    goto out;
	}

	// If the 0x80 bit is set, it means the output code sequence starts with 0xe0
	if (kv & 0x80) {
	    enque(0xe0, &kbd_state.queue);
	    kv &= 0x7f;
	}
    }

    // Now kv is the final scan set 2 code value.

    if (translate_set == 1) {
        // Scan set 1 - translate scan set 2 value to set 1 and send,
	// possibly with the 0x80 bit set (break)
	kv = set2_to_set1[kv];
	enque(got_break ? kv|0x80 : kv, &kbd_state.queue);
    } else {	            // Scan set 2
        // Scan set 2 - send code value as-is, possibly prefixed by 0xf0 (break)
	if (got_break)
	    enque(0xf0, &kbd_state.queue);
	enque(kv, &kbd_state.queue);
    }
out:
    got_break = 0;
}

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

void run_queue()
{
    int data;
    int i;
    struct ps2_state *s;

    /*
     * The following line make it safe for the host end to send a RDY command at any time,
     * even if data is already waiting in the upstream buffer
     */
    if ((*PJ_RST_INTERRUPT) & 1)  /* Don't overwrite data already in buffer */
	return;

    for(i=0; i<2; i++) {
	s = ps2_devices[i];
	data = deque(&s->queue);
        if (data != -1) {
	    if (s->quenched) {
		s->quenched = 0;
		DRIVE_HIGH(s->clk_gpio, s->clk_mask);
	    }
	    if (DDEBUG) dbgputresp((unsigned int)data);
            SP_RETURN[0] = (i<<8) | data;
            *PJ_INTERRUPT_SET = 1;
	    return;
	}
    }
}

int cmdblock = 0;

void do_command(unsigned int data) {
    int port;
    
    if (data == 0xff00) {
	if (CDEBUG) tx4('r');
	run_queue();
    } else {
	port = (data >> 8) & 0xff;
	if (CDEBUG) tx4(port+'c');
	data &= 0xff;
	if (port < 2) {
	    struct ps2_state *s;
	    int ticks;

	    cmdblock++;         /* prevent commands while transmitting */

	    if (DDEBUG) dbgputcmd(data);

	    // XXX should set a timer to reset the state to 0 if the transmission
	    // doesn't complete within a couple of milliseconds

	    if (port == 0) {
		switch (data) {
		case 0xf7:			/* EnE "enter matrix mode" command */
		    translate_set = 2;		/* Start out translating to scan set 2 */
		    suppress_count = 1;	/* The next byte is an ack; don't translate it */
		    break;
		case 0xf2: 			/* Identify: f1 <ack> <0xab> <NN> */
		    suppress_count = 3;
		    break;
		case 0x00:	/* Get scan set: f0 <ack> 00 <ack> <set#> */
		    suppress_count = (last_cmd == 0xf0) ? 2 : 1;
		    break;
		case 0x01:	/* Set scan set 1: f0 <ack> 01 <ack> */
		    /* If we are translating from raw matrix codes, change the output scan set to 1 */
		    /* If we are not translating, the keyboard controller will take care of it */
		    if (last_cmd == 0xf0 && translate_set) {
			translate_set = 1;
		    }
		    suppress_count = 1;
		    break;
		case 0x02:	/* Set scan set 2: f0 <ack> 02 <ack> */
		    /* If we are translating from raw matrix codes, change the output scan set to 2 */
		    /* If we are not translating, the keyboard controller will take care of it */
		    if (last_cmd == 0xf0 && translate_set) {  /* Don't change translate_set for ALPS */
			translate_set = 2;
		    }
		    suppress_count = 1;
		    break;
		case 0xff: /* Reset - fa aa */
		    suppress_count = 2;
		    break;
//		case 0xf0: /* Set/get scan set - fa */
//		case 0xf1: /* Send nak - fe */
//		case 0xf3: /* Set typematic rate/delay - fa */
//		case 0xf4: /* Enable - fa */
//		case 0xf5: /* Disable - fa */
//		case 0xf6: /* Set default - fa */
//		case 0xf7: /* Set all typematic - fa */
//		case 0xf8: /* Set all make/break - fa */
//		case 0xf9: /* Set all make - fa */
//		case 0xfa: /* Set all typematic/make/break - fa */
//		case 0xfb: /* Set key typematic - fa */
//		case 0xfc: /* Set key make/break - fa */
//		case 0xfd: /* Set key make - fa */
//		case 0xfe: /* Resend - ?? */
		default:
		    suppress_count = 1;
		    break;
		}
		last_cmd = data;
	    }

	    s = ps2_devices[port];
	    s->bit_number = 20;
	    s->byte = data;
	    s->parity = 1;

	    /* Schedule a timer interrupt for 60 us from now */
	    *TIMER20_FREEZE = 1;    /* Latch count */
	    s->timestamp = *TIMER20;
	    /* 60 us should suffice, but is on the hairy edge for the EnE kbd controller */
	    TMR2_MATCH00[port] = s->timestamp + 1500;  /* about 110 us */
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

    if (channels & (1<<2)) {
        gamekey_handle(1);
    }

    // hack alert -- linux reinits all the GPIO edge detection
    //  when it boots.  this call ensures we always get our
    //  button interrupts.
    gamekey_init();
}

void irq_handler()
{
    struct ps2_state *s;
    int this_timestamp;
    int i;
    int timers;
    unsigned long spim;


    spim = *SP_INTERRUPT_MASK;
    *SP_INTERRUPT_MASK |= 2;  // mask for now

    if (*SP_INTERRUPT_SET & ~spim & 2 ) {
        *SP_INTERRUPT_RESET = 2;
	if (*SP_CONTROL & 1) {
	    do_command(*SP_COMMAND);
	    *SP_CONTROL = 0;
	}
    }

    if ((timers = *TMR2_SR0) & 7) {
	if (CDEBUG) tx4('t');
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

	if (s->timestamp != 0 && (this_timestamp - s->timestamp) > PS2_TIMEOUT) {
	    if (CDEBUG) tx4('@');
	    s->bit_number = 0;
	    *SP_INTERRUPT_MASK &= ~2;  // Re-enable command interrupts on a botched rx
	    cmdblock = 0;
	    s->byte = 0;
	    s->timestamp = 0;
	    /* perhaps we should be asserting clock here, to force an abort */
	}

	if (CDEBUG) {  tx4(cmdblock+'A'); }

	s->timestamp = this_timestamp;

	switch (s->bit_number)
	{
	case 0:
	    if ((s->dat_gpio)[GPIO_PLR_INDEX] & s->dat_mask) {
		if (CDEBUG) tx4('s');
		s->timestamp = 0;
		break;  // the start bit must be 0
	    }

	    s->bit_number++;
	    cmdblock++;         /* prevent commands while receiving */

	    // XXX should set a timer to reset the state to 0 if the reception
	    // doesn't complete within a couple of milliseconds
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
	    forward_event(s->byte & 0xff, i);
	    cmdblock--;
	    s->bit_number = 0;
	    s->byte = 0;
	    s->timestamp = 0;
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
	    s->timestamp = 0;
	    cmdblock--;
	    break;
	default:
	    s->bit_number = 0;
	    s->byte = 0;
	    s->timestamp = 0;
	}
    }

    gamekey_handle(0);

    if (!cmdblock) {
	*SP_INTERRUPT_MASK &= ~2;  // allow
    }
}


void swi_handler()
{
}

void raise()  /* In case __div and friends need it */
{
}

#ifdef NO_EBOOK_CHECK
void ebook_init() { }
int ebook_mode() { return 0; }
#else

//
// the ebook switch appears on gpio128
// we check it to suppress keyboard and mouse events

REG(ebook_gpio, GPIO_128_159);
#define GPIO128_MASK 0x0001
#define EBOOK_MASK GPIO128_MASK

void ebook_init()
{
    ebook_gpio[GPIO_CDR_INDEX] = EBOOK_MASK;   // direction == input
}

int ebook_mode()
{
    return !(ebook_gpio[GPIO_PLR_INDEX] & EBOOK_MASK);
}

#endif



//   ----------------

/* the rotate, o, check, x, square, up, right, left, down keys
 * appear on gpio 15 through 23, conveniently in single gpio
 * register.
 */

REG(game_gpio, GPIO_0_31);
#define GAMEBITS 0x00ff8000

void gamekey_init()
{
    game_gpio[GPIO_CDR_INDEX] = GAMEBITS;   // direction == input
    game_gpio[GPIO_SRER_INDEX] = GAMEBITS;  // enable rising edge
    game_gpio[GPIO_SFER_INDEX] = GAMEBITS;  // enable falling edge
    game_gpio[GPIO_APMASK_INDEX] |= GAMEBITS;  // unmask irq
}

int gamekeys[] = { // bit 8 implies 0xe0 prefix is needed
    0x069, // rotate
    0x165, // o
    0x168, // check
    0x166, // x
    0x167, // square
    0x065, // up
    0x068, // right
    0x066, // down
    0x067, // left
};

void gamekey_send(int key, int release)
{
    int e0, scode;

    e0 = gamekeys[key] & 0x100;
    scode = gamekeys[key] & 0xff;
    if (release) scode |= 0x80;

    if (e0) {
	always_enque(0xe0, &kbd_state.queue);
        // dbgputresp(0xe0);
    }

    always_enque(scode, &kbd_state.queue);
    // dbgputresp(scode);

    run_queue();
}

void gamekey_sendbits(unsigned int keybits, int down)
{
    unsigned int bit;
    int i;

    /* "rotate" is bit 15, "left" is bit 23 */
    for (bit = 0x8000, i = 0; i < 9; bit <<= 1, i++) {
	if (keybits & bit) {
	    gamekey_send(i, down);
	}
    }
}

#define DEBOUNCE_MS 60   // msec of debounce

void sched_debounce()
{
    unsigned int now;
    *TIMER20_FREEZE = 1;    /* Latch count */
    now = *TIMER20;
    *TMR2_MATCH02 = now + (DEBOUNCE_MS/3 * 13000); // 6.5 clk/usec
    *TMR2_IER0 |= (1<<2);
}


/*
void dbgputbits(unsigned int c)
{
	char *digits = "0123456789abcdef";
	tx4(digits[(c>>20)&0x0f]);
	tx4(digits[(c>>16)&0x0f]);
	tx4(digits[(c>>12)&0x0f]);
	tx4(' ');
}
*/

static unsigned int chgb, downb;
static unsigned int t1b, t1b_down;
static unsigned int t2b, t2b_down;

/* the keys that have been pressed (or released) are moved
 * through a three stage debouncing "pipeline".  keys that make
 * it to the end of the pipeline intact are sent upstream.
 */
void gamekey_handle(int is_timer)
{
    unsigned int curb, t3b, t3b_down;

    if (is_timer) {

	curb = ~game_gpio[GPIO_PLR_INDEX] & GAMEBITS;

	t3b = t2b & curb;
	t3b_down = t2b_down & ~curb;

	// t3b and t3b_down are the keys that made it all the way through...
	gamekey_sendbits(t3b_down, 1);
	gamekey_sendbits(t3b, 0);

	downb &= ~t3b_down;
	downb |= t3b;

	t2b = t1b & curb;
	t2b_down = t1b_down & ~curb;

	// chgb is the keys whose states have changed "recently"
	t1b = chgb & curb;
	t1b_down = chgb & ~curb;
	chgb = 0;

	/*
	tx4('T'); dbgputb(curbits);
	    dbgputbits(t1b); dbgputbits(t2b); dbgputbits(t3b);
	tx4('t'); dbgputbits(~curb);
	    dbgputbits(t1b_down); dbgputbits(t2b_down); dbgputbits(t3b_down);
	 */

    } else {
	unsigned int changes;
	
	changes = game_gpio[GPIO_EDR_INDEX] & GAMEBITS;
	if (changes) {
	    chgb |= changes;
            game_gpio[GPIO_EDR_INDEX] = chgb;  // clear the int

	    /*
	    tx4('g'); dbgputbits(chgb);
	    */
	}
    }

    if (chgb || t1b || t1b_down || t2b || t2b_down ) {
	sched_debounce();
    }
}

int strlen(const char *s)
{
        const char *p;
        for (p=s; *p != '\0'; *p++) {
        }
        return p-s;
}
