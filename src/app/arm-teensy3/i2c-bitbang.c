#include "forth.h"
#include "i2c-bitbang.h"

void pinMode(uint8_t pin, uint8_t mode);
void digitalWrite(uint8_t pin, uint8_t val);
uint8_t digitalRead(uint8_t pin);
#define HIGH		1
#define LOW		0
#define INPUT		0
#define OUTPUT		1
#define INPUT_PULLUP	2
#define INPUT_PULLDOWN   3
#define OUTPUT_OPENDRAIN 4


volatile uint8_t i2c_sda_pin;
volatile uint8_t i2c_scl_pin;

#define SDA_LOW  pinMode(i2c_sda_pin, OUTPUT_OPENDRAIN)
#define SDA_HIGH  pinMode(i2c_sda_pin, INPUT)
#define SCL_LOW  pinMode(i2c_scl_pin, OUTPUT_OPENDRAIN)
#define SCL_HIGH  pinMode(i2c_scl_pin, INPUT)

// From teensy3/core_pins.h
#define F_CPU 96000000

void delayUs(uint32_t usec);
static void i2c_delay()
{
  delayUs(5);
}

static void i2c_raise_scl(void)
{
  i2c_delay();
  SCL_HIGH;
  i2c_delay();
}

static void i2c_master_setbit(uint8_t bit)
{
    if (bit)
      SDA_HIGH;
    else
      SDA_LOW;
    i2c_raise_scl();
    SCL_LOW;
}

static int i2c_master_getbit(void)
{
  int result;
  i2c_raise_scl();
  result = digitalRead(i2c_sda_pin);
  SCL_LOW;
  return result;
}

static void i2c_master_writeByte(uint8_t value)
{
  uint8_t mask;
  for (mask=0x80; mask; mask >>= 1) {
    i2c_master_setbit(value & mask);
  }
}

static uint8_t i2c_master_readByte()
{
  uint8_t mask;
  uint8_t value = 0;
  SDA_HIGH;
  for (mask=0x80; mask; mask >>= 1) {
    value = (value << 1) | i2c_master_getbit();
  }
  return value;
}

// void i2c_setup(cell sda, cell scl)
void i2c_setup(uint8_t sda, uint8_t scl)
{
  i2c_sda_pin = sda;
  i2c_scl_pin = scl;
  SDA_HIGH;
  SCL_HIGH;
  digitalWrite(i2c_sda_pin, LOW);
  digitalWrite(i2c_scl_pin, LOW);
}

void i2c_master_start()
{
  SDA_LOW;
  i2c_delay();
  SCL_LOW;
}

void i2c_master_stop()
{
  SDA_LOW;
  i2c_raise_scl();
  SDA_HIGH;
  i2c_delay();
}

// Returns nonzero if error
cell i2c_send(cell byte)
{
  i2c_master_writeByte((uint8_t)byte);
  SDA_HIGH;
  uint8_t r = i2c_master_getbit();
  if (r)
    i2c_master_stop();
  return r;
}

cell i2c_recv(cell nack)
{
  uint8_t r = i2c_master_readByte();
  i2c_master_setbit(nack);
  if (nack)
    i2c_master_stop();
  return r;
}

// Start + slave address + reg#
cell i2c_start_write(cell slave, cell reg)
{
  i2c_master_start();
  if (i2c_send(slave<<1))
    return -1;
  if (i2c_send(reg))
    return -1;

  return 0;
}

cell i2c_start_read(cell slave, cell stop)
{
  if (stop)
    i2c_master_stop();
  else {
    SDA_HIGH;
    i2c_delay;
    SCL_HIGH;
    i2c_delay;
  }
  i2c_master_start();
  return i2c_send((slave<<1) | 1);
}

cell i2c_rb(cell stop, cell slave, cell reg)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_start_read(slave, stop))
    return -1;
  return i2c_recv(1);
}

cell i2c_wb(cell slave, cell reg, cell value)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_send(value))
    return -1;
  i2c_master_stop();
  return 0;
}

cell i2c_be_rw(cell stop, cell slave, cell reg)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_start_read(slave, stop))
    return -1;
  cell val = i2c_recv(0);
  val = (val<<8) + i2c_recv(1);
  return val;
}

cell i2c_le_rw(cell stop, cell slave, cell reg)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_start_read(slave, stop))
    return -1;
  cell val = i2c_recv(0);
  val += i2c_recv(1)<<8;
  return val;
}

cell i2c_be_ww(cell slave, cell reg, cell value)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_send(value>>8))
    return -1;
  if (i2c_send(value&0xff))
    return -1;
  i2c_master_stop();
  return 0;
}

cell i2c_le_ww(cell slave, cell reg, cell value)
{
  if (i2c_start_write(slave, reg))
    return -1;
  if (i2c_send(value&0xff))
    return -1;
  if (i2c_send(value>>8))
    return -1;
  i2c_master_stop();
  return 0;
}
