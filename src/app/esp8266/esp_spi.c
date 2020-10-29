extern void *callback_up;

// #include "stdint.h"
// #include "stdlib.h"
#include <string.h>
#include "pin_map.h"

#define NOPULL 0
#define GPIO_INPUT 0
#define GPIO_OUTPUT 1

#define ESP8266_REG(addr) *((volatile uint32_t *)(0x60000000+(addr)))
#define ESP8266_CLOCK 80000000UL
#define HSPI_REG(offset) ESP8266_REG(0x100 + offset)
#define PINMUX_REG(offset) ESP8266_REG(0x800 + offset)

#define GP_MUX  PINMUX_REG(0x00)

#define HSPI_FUNCTION 2
#define GPIO_FUNCTION 3

// These are the labeled pin numbers on the NodeMCU module,
// not the ESP8266 GPIO numbers 
#define HSPI_SCK_PIN  5
#define HSPI_MISO_PIN 6
#define HSPI_MOSI_PIN 7
#define HSPI_HW_CS_PIN 8

								
static void pin_function_select(int pinnum, int function)
{
    volatile uint32_t *pinmux = (uint32_t *)pin_mux[pinnum];
    ets_delay_us(2000);
    if (function & 4) {
	function = 0x10 | (function & ~4);
    }
    *pinmux = (*pinmux & ~0x130) | (function << 4);
}

#define HSPI_CMD	HSPI_REG(0x00)
// #define HSPIA 	HSPI_REG(0x04)
#define HSPI_CTRL	HSPI_REG(0x08)
#define HSPI_CTRL1	HSPI_REG(0x0C)
// #define HSPI_RS 	HSPI_REG(0x10)
// #define HSPI_C2 	HSPI_REG(0x14)
#define HSPI_CLK 	HSPI_REG(0x18)
#define HSPI_USR	HSPI_REG(0x1C)
#define HSPI_USR1	HSPI_REG(0x20)
// #define HSPI_USR2	HSPI_REG(0x24)
// #define HSPI_WS	HSPI_REG(0x28)
#define HSPI_POL	HSPI_REG(0x2C)
// #define HSPI_S 	HSPI_REG(0x30)  /* Total of 4 registers */
#define HSPI_DATA 	HSPI_REG(0x40)  /* Total of 16 registers */
// #define HSPI_E0 	HSPI_REG(0xF0)  /* Total of 4 registers */

// CMD register bits
#define SPI_BUSY 	(1 << 18)

// USR1 register bits and masks
// #define SPI_LEN_COMMAND	28 //4 bit in SPIxU2 default 7 (8bit)
// #define SPI_LEN_ADDR		26 //6 bit in SPIxU1 default:23 (24bit)
// #define SPI_LEN_DUMMY	0  //8 bit in SPIxU1 default:0 (0 cycles)

#define SPI_MISO_SHIFT	8  //9 bit in SPIxU1 default:0 (1bit)
#define SPI_MOSI_SHIFT	17 //9 bit in SPIxU1 default:0 (1bit)

// #define SPI_MASK_COMMAND	0xF
// #define SPI_MASK_ADDR	0x3F
// #define SPI_MASK_DUMMY	0xFF

#define SPI_MASK_MISO	0x1FF
#define SPI_MASK_MOSI	0x1FF

#define SPI_CPOL	(1 << 29)

#define SPI_WR_BIT_ORDER       (1 << 26)
#define SPI_RD_BIT_ORDER       (1 << 25)
// #define SPI_QIO_MODE       (1 << 24)
// #define SPI_DIO_MODE       (1 << 23)
// #define SPI_TWO_BYTE_STATUS_EN      (1 << 22)
// #define SPI_WP_REG       (1 << 21)
// #define SPI_QOUT_MODE      (1 << 20)
// #define SPI_SHARE_BUS     (1 << 19)
// #define SPI_HOLD_MODE      (1 << 18)
// #define SPI_ENABLE_AHB       (1 << 17)
// #define SPI_SST_AAI    (1 << 16)
// #define SPI_RESANDRES (1 << 15)
// #define SPI_DOUT_MODE      (1 << 14)
// #define SPI_FASTRD_MODE    (1 << 13)


#define SPI_USR_COMMAND	(1 << 31)
// #define SPI_USR_ADDR	(1 << 30)
#define SPI_USR_MISO (1 << 28) // MISO phase
#define SPI_USR_MOSI (1 << 27) //MOSI phase
// #define SPI_USR_DUMMY_IDLE (1 << 26) //SPI_USR_DUMMY_IDLE
// #define SPI_USR_DOUT_HIGHPART (1 << 25) //MOSI phase uses W8-W15
// #define SPI_USR_DIN_HIGHPART (1 << 24) //MISO phase uses W8-W15
// #define SPI_USR_PREP_HOLD (1 << 23)
// #define SPI_USR_CMD_HOLD (1 << 22)
// #define SPI_USR_ADDR_HOLD (1 << 21)
// #define SPI_USR_DUMMY_HOLD (1 << 20)
// #define SPI_USR_DIN_HOLD (1 << 19)
// #define SPI_USR_DOUT_HOLD (1 << 18)
// #define SPI_USR_HOLD_POL (1 << 17)
// #define SPI_SIO (1 << 16)
// #define SPI_FWRITE_QIO (1 << 15)
// #define SPI_FWRITE_DIO (1 << 14)
// #define SPI_FWRITE_QUAD (1 << 13)
// #define SPI_FWRITE_DUAL (1 << 12)
// #define SPI_WR_BYTE_ORDER (1 << 11)
// #define SPI_RD_BYTE_ORDER (1 << 10)
// #define SPI_AHB_ENDIAN_MODE 0x3
// #define SPI_AHB_ENDIAN_MODE_S_S 8
#define SPI_CK_OUT_EDGE (1 << 7) // 0 for falling, 1 for rising
#define SPI_CK_I_EDGE (1 << 6) // 0 for falling, 1 for rising
#define SPI_CS_SETUP (1 << 5) //
#define SPI_CS_HOLD (1 << 4)
// #define SPIUAHBUCMD (1 << 3) //SPI_AHB_USR_COMMAND
// #define SPIUAHBUCMD4B (1 << 1) //SPI_AHB_USR_COMMAND_4BYTE
#define SPI_DOUTDIN (1 << 0)

typedef union {
        uint32_t regValue;
        struct {
                unsigned regL :6;
                unsigned regH :6;
                unsigned regN :6;
                unsigned regPre :13;
                unsigned regEQU :1;
        };
} spiClk_t;

static uint32_t ClkRegToFreq(spiClk_t * reg) {
    return (ESP8266_CLOCK / ((reg->regPre + 1) * (reg->regN + 1)));
}

static void setClockDivider(uint32_t clockDiv) {
    if(clockDiv == 0x80000000) {
        GP_MUX |= (1 << 9); // Set bit 9 if sysclock required
    } else {
        GP_MUX &= ~(1 << 9);
    }
    HSPI_CLK = clockDiv;
}

void spi_setFrequency(uint32_t freq) {
    static uint32_t lastSetFrequency = 0;
    static uint32_t lastSetRegister = 0;

    if(freq >= ESP8266_CLOCK) {
        setClockDivider(0x80000000);
        return;
    }

    if(lastSetFrequency == freq && lastSetRegister == HSPI_CLK) {
        // do nothing (speed optimization)
        return;
    }

    const spiClk_t minFreqReg = { 0x7FFFF000 };
    uint32_t minFreq = ClkRegToFreq((spiClk_t*) &minFreqReg);
    if(freq < minFreq) {
        // use minimum possible clock
        setClockDivider(minFreqReg.regValue);
        lastSetRegister = HSPI_CLK;
        lastSetFrequency = freq;
        return;
    }

    uint8_t calN = 1;

    spiClk_t bestReg = { 0 };
    int32_t bestFreq = 0;

    // find the best match
    while(calN <= 0x3F) { // 0x3F max for N

        spiClk_t reg = { 0 };
        int32_t calFreq;
        int32_t calPre;
        int8_t calPreVari = -2;

        reg.regN = calN;

        while(calPreVari++ <= 1) { // test different variants for Pre (we calculate in int so we miss the decimals, testing is the easiest and fastest way)
            calPre = (((ESP8266_CLOCK / (reg.regN + 1)) / freq) - 1) + calPreVari;
            if(calPre > 0x1FFF) {
                reg.regPre = 0x1FFF; // 8191
            } else if(calPre <= 0) {
                reg.regPre = 0;
            } else {
                reg.regPre = calPre;
            }

            reg.regL = ((reg.regN + 1) / 2);
            // reg.regH = (reg.regN - reg.regL);

            // test calculation
            calFreq = ClkRegToFreq(&reg);
            //os_printf("-----[0x%08X][%d]\t EQU: %d\t Pre: %d\t N: %d\t H: %d\t L: %d = %d\n", reg.regValue, freq, reg.regEQU, reg.regPre, reg.regN, reg.regH, reg.regL, calFreq);

            if(calFreq == (int32_t) freq) {
                // accurate match use it!
		bestReg.regValue = reg.regValue;
                break;
            } else if(calFreq < (int32_t) freq) {
                // never go over the requested frequency
                if(abs(freq - calFreq) < abs(freq - bestFreq)) {
                    bestFreq = calFreq;
		    bestReg.regValue = reg.regValue;
                }
            }
        }
        if(calFreq == (int32_t) freq) {
            // accurate match use it!
            break;
        }
        calN++;
    }

    // os_printf("[0x%08X][%d]\t EQU: %d\t Pre: %d\t N: %d\t H: %d\t L: %d\t - Real Frequency: %d\n", bestReg.regValue, freq, bestReg.regEQU, bestReg.regPre, bestReg.regN, bestReg.regH, bestReg.regL, ClkRegToFreq(&bestReg));

    setClockDivider(bestReg.regValue);
    lastSetRegister = HSPI_CLK;
    lastSetFrequency = freq;
}

// csGPIO is -1 for hardware controlled chip select, otherwise it is the
// chip select GPIO pin number

static int spi_csGPIO;

void spi_open(int csGPIO, uint32_t clock, uint8_t msbfirst, uint8_t dataMode)
{
    spi_csGPIO = csGPIO;

    HSPI_CTRL = 0;
//    setFrequency(1000000); ///< 1MHz
    HSPI_USR = SPI_USR_MOSI | SPI_DOUTDIN | SPI_CK_I_EDGE;
    HSPI_USR1 = (7 << SPI_MOSI_SHIFT) | (7 << SPI_MISO_SHIFT);
    HSPI_CTRL1 = 0;

    spi_setFrequency(clock);

    if(msbfirst) {
        HSPI_CTRL &= ~(SPI_WR_BIT_ORDER | SPI_RD_BIT_ORDER);
    } else {
        HSPI_CTRL |= (SPI_WR_BIT_ORDER | SPI_RD_BIT_ORDER);
    }

    ets_delay_us(1000);
    // Clock phase
    if(dataMode & 0x01) {
        HSPI_USR |= (SPI_CK_OUT_EDGE);
    } else {
        HSPI_USR &= ~(SPI_CK_OUT_EDGE);
    }

    ets_delay_us(1000);
    // Clock polarity
    if (dataMode & 0x02) {
        HSPI_POL |= SPI_CPOL;
    } else {
        HSPI_POL &= ~SPI_CPOL;
    }

    pin_function_select(HSPI_SCK_PIN, HSPI_FUNCTION);
    pin_function_select(HSPI_MISO_PIN, HSPI_FUNCTION);
    pin_function_select(HSPI_MOSI_PIN, HSPI_FUNCTION);

    if(spi_csGPIO == -1) {
        pin_function_select(HSPI_HW_CS_PIN, HSPI_FUNCTION);
        HSPI_USR |= (SPI_CS_SETUP | SPI_CS_HOLD);
    } else {
	if (spi_csGPIO == HSPI_HW_CS_PIN) {
	    pin_function_select(HSPI_HW_CS_PIN, GPIO_FUNCTION);
	}
	HSPI_USR &= ~(SPI_CS_SETUP | SPI_CS_HOLD);
	platform_gpio_mode(spi_csGPIO, GPIO_OUTPUT, NOPULL);
	platform_gpio_write(spi_csGPIO, 1);
    }
}

void spi_close()
{
    pin_function_select(HSPI_SCK_PIN, GPIO_FUNCTION);
    pin_function_select(HSPI_MISO_PIN, GPIO_FUNCTION);
    pin_function_select(HSPI_MOSI_PIN, GPIO_INPUT);
    if(spi_csGPIO == -1) {
	pin_function_select(HSPI_HW_CS_PIN, GPIO_FUNCTION);
    } else {
	platform_gpio_mode(spi_csGPIO, GPIO_INPUT, NOPULL);
    }
}

static inline
void spi_wait_while_busy()
{
    while(HSPI_CMD & SPI_BUSY) {}
}

void spi_begin()
{
    if (spi_csGPIO != -1) {
	platform_gpio_write(spi_csGPIO, 0);
    }
}

void spi_end()
{
    if (spi_csGPIO != -1) {
	platform_gpio_write(spi_csGPIO, 1);
    }
}

static inline void setDataBits(uint16_t bits)
{
    const uint32_t mask = ~((SPI_MASK_MOSI << SPI_MOSI_SHIFT) | (SPI_MASK_MISO << SPI_MISO_SHIFT));
    HSPI_USR1 = ((HSPI_USR1 & mask) | (((bits-1) << SPI_MOSI_SHIFT) | ((bits-1) << SPI_MISO_SHIFT)));
}

int spi_bits_in(int num)
{
    spi_wait_while_busy();
    // Set in/out Bits to transfer

    setDataBits(num);
    HSPI_DATA = 0xffffffff;

    HSPI_CMD |= SPI_BUSY;
    spi_wait_while_busy();

    // XXX this might only work for MSB first
    if (num == 32) {
	return HSPI_DATA;
    } else {
	return (HSPI_DATA >> (8-num)) & ((1<<num)-1);
    }
}

void spi_transfer(uint32_t remaining, uint8_t *in, uint8_t *out)
{
    uint32_t buf[16];
    int cnt;
    uint32_t *ptr;

    while (remaining) {
	int this_size = remaining > 64 ? 64 : remaining;
	remaining -= this_size;

	spi_wait_while_busy();
	// Set in/out Bits to transfer

	setDataBits(this_size * 8);

	volatile uint32_t * fifoPtr = &HSPI_DATA;

	if (out) {
            if ((int)out & 3) {
                memcpy(buf, out, this_size);
                ptr = buf;
            } else {
                ptr = (uint32_t *)out;
            }
            for (cnt = this_size; cnt > 0; cnt -= 4) {
		*fifoPtr++ = *ptr++;
	    }
            out += this_size;
	} else {
	    // Send dummy data if no real data to send
	    for (cnt = this_size; cnt > 0; cnt -= 4) {
		*fifoPtr++ = 0xffffffff;
	    }
	}

	HSPI_CMD |= SPI_BUSY;
	spi_wait_while_busy();

	if (in) {
            ptr = ((int)in & 3) ? buf : (uint32_t *)in;

            for (fifoPtr = &HSPI_DATA, cnt = this_size; cnt >= 4; cnt -= 4) {
                *ptr++ = *fifoPtr++;
            }

            volatile uint8_t *fifoPtr8;
            uint8_t *ptr8 = (uint8_t*)ptr;
            for (fifoPtr8 = (volatile uint8_t *)fifoPtr; cnt; cnt--) {
                *(uint8_t *)ptr8++ = *fifoPtr8++;
            }
            if ((int)in & 3) {
                memcpy(in, buf, this_size);
            }
            in += this_size;
	}
    }
}
