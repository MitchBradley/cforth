/**
  ******************************************************************************
  * @file    irq.c
  * @author  Mitch Bradley, enimai
  * @version V1.0.0
  * @date    5-October-2013
  * @brief   Interrupt Service Routines for I2C and other peripherals
  ******************************************************************************
  */

#include "stm32l1xx_conf.h"
#include "stm32l1xx.h"
#include "stm32l1xx_it.h"

/* Cortex-M3 Processor Exception Handlers */

void NMI_Handler(void)
{
}

void HardFault_Handler(void)
{
  while (1) {}
}

void MemManage_Handler(void)
{
  while (1) {}
}

void BusFault_Handler(void)
{
  while (1) {}
}

void UsageFault_Handler(void)
{
  while (1) {}
}

void SVC_Handler(void)
{
}

void DebugMon_Handler(void)
{
}

void PendSV_Handler(void)
{
}

// Variables communicating with the interrupt handler
volatile   int  i2c_done;   // Can be polled for completion

static uint32_t i2c_timeout;
static int      i2c_direction;     // Either I2C_Direction_Receiver or I2C_Direction_Transmitter
static uint8_t  i2c_slave_address;  
static uint8_t *i2c_databuf;
static int      i2c_databytes;
static uint8_t *i2c_adrbuf;
static int      i2c_adrbytes;
static int      i2c_dud;
static int      i2c_error;

void I2C_Tick(void)
{
  if (i2c_timeout)
    if (i2c_timeout != 1)
      i2c_timeout--;
    else
      if (!i2c_done)
        i2c_done = -1;
}

/* Use I2C1 on PB8 and PB9 */
#define I2Cx                          I2C1
#define I2Cx_CLK                      RCC_APB1Periph_I2C1
#define I2Cx_EV_IRQn                  I2C1_EV_IRQn
#define I2Cx_ER_IRQn                  I2C1_ER_IRQn
#define I2Cx_EV_IRQHandler            I2C1_EV_IRQHandler
#define I2Cx_ER_IRQHandler            I2C1_ER_IRQHandler

#define I2Cx_SDA_GPIO_CLK             RCC_AHBPeriph_GPIOB                
#define I2Cx_SDA_GPIO_PORT            GPIOB                       
#define I2Cx_SDA_AF                   GPIO_AF_I2C1

#define I2Cx_SCL_GPIO_CLK             RCC_AHBPeriph_GPIOB               
#define I2Cx_SCL_GPIO_PORT            GPIOB                    
#define I2Cx_SCL_AF                   GPIO_AF_I2C1

#define I2Cx_SDA_PIN                  GPIO_Pin_9
#define I2Cx_SDA_SOURCE               GPIO_PinSource9
#define I2Cx_SCL_PIN                  GPIO_Pin_8
#define I2Cx_SCL_SOURCE               GPIO_PinSource8

/**
  * @brief  Enables the I2C Clock and configures the different GPIO ports.
  * @param  None
  * @retval None
  */
static void I2C_Config(void)
{
  GPIO_InitTypeDef GPIO_InitStructure = {
    .GPIO_Mode  = GPIO_Mode_AF,
    .GPIO_Speed = GPIO_Speed_40MHz,
    .GPIO_OType = GPIO_OType_OD,
    .GPIO_PuPd  = GPIO_PuPd_NOPULL,
  };

  NVIC_InitTypeDef NVIC_InitStructure = {
    .NVIC_IRQChannelPreemptionPriority = 1,
    .NVIC_IRQChannelSubPriority        = 0,
    .NVIC_IRQChannelCmd                = ENABLE,
  };

  /*!< I2C Periph clock enable */
  RCC_APB1PeriphClockCmd(I2Cx_CLK, ENABLE);

  /*!< SDA GPIO clock enable */
  RCC_AHBPeriphClockCmd(I2Cx_SDA_GPIO_CLK, ENABLE);
 
  /*!< SCL GPIO clock enable */
  RCC_AHBPeriphClockCmd(I2Cx_SCL_GPIO_CLK, ENABLE);
  
  /* Connect PXx to I2C_SCL */
  GPIO_PinAFConfig(I2Cx_SCL_GPIO_PORT, I2Cx_SCL_SOURCE, GPIO_AF_I2C1);

  /* Connect PXx to I2C_SDA */
  GPIO_PinAFConfig(I2Cx_SDA_GPIO_PORT, I2Cx_SDA_SOURCE, GPIO_AF_I2C1);
  
  /*!< Configure I2C SCL pin */
  GPIO_InitStructure.GPIO_Pin = I2Cx_SCL_PIN;
  GPIO_Init(I2Cx_SCL_GPIO_PORT, &GPIO_InitStructure);

  /*!< Configure I2C SDA pin */
  GPIO_InitStructure.GPIO_Pin = I2Cx_SDA_PIN;
  GPIO_Init(I2Cx_SDA_GPIO_PORT, &GPIO_InitStructure);

  /* Configure the Priority Group to 1 bit */
  NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2);
  
  /* Configure the I2C event priority */
  NVIC_InitStructure.NVIC_IRQChannel = I2Cx_EV_IRQn,
  NVIC_Init(&NVIC_InitStructure);

  /* Configure I2C error interrupt to have the higher priority */
  NVIC_InitStructure.NVIC_IRQChannel = I2Cx_ER_IRQn;
  NVIC_Init(&NVIC_InitStructure);
}

static void SysTickConfig(void)
{
  /* Setup SysTick Timer for 10ms interrupts  */
  if (SysTick_Config(SystemCoreClock / 100)) {
    /* Capture error */
    while (1);
  }

  /* Configure the SysTick handler priority */
  NVIC_SetPriority(SysTick_IRQn, 0x0);
}

#define DEFAULT_I2C_TIMEOUT 35

int i2c_inited = 0;

// XXX put in i2cm.h
enum {
  I2CM_SPEED_100KHZ = 100000,
  I2CM_SPEED_400KHZ = 400000,
};
 
void i2cm_setSpeed(int speed)
{
  I2C_InitTypeDef I2C_InitStructure = {
    .I2C_ClockSpeed  = I2CM_SPEED_400KHZ,
    .I2C_Mode        = I2C_Mode_I2C,
    .I2C_DutyCycle   = I2C_DutyCycle_2,
    .I2C_OwnAddress1 = 0x00,
    .I2C_Ack         = I2C_Ack_Enable,
    .I2C_AcknowledgedAddress = I2C_AcknowledgedAddress_7bit
  };

  I2C_InitStructure.I2C_ClockSpeed = speed;

  I2C_Init(I2Cx, &I2C_InitStructure);
}

void i2c_init(void)
{
  if (i2c_inited)
    return;
  i2c_inited = 1;

  I2C_Config();

  i2cm_setSpeed(I2CM_SPEED_400KHZ);
}

void i2c_start(uint8_t *dbuf, uint32_t dlen,
               uint8_t *abuf, uint32_t alen,
               uint16_t slave_address, int write)
{
  i2c_init();

  i2c_direction = write ? I2C_Direction_Transmitter : I2C_Direction_Receiver;
  i2c_slave_address = slave_address;
  i2c_databuf   = dbuf;
  i2c_databytes = dlen;
  i2c_adrbuf    = abuf;
  i2c_adrbytes  = alen;

  //  i2c_timeout = DEFAULT_I2C_TIMEOUT;
  i2c_timeout = 0;
  i2c_done = 0;

  I2C_Cmd(I2Cx, ENABLE);
  I2C_ITConfig(I2Cx, I2C_IT_ERR , ENABLE); // Enable error interrupts
  I2C_ITConfig(I2Cx, I2C_IT_EVT, ENABLE);  // Enable event interrupts
  I2C_AcknowledgeConfig(I2Cx, ENABLE);     // ACK not NACK
  I2C_NACKPositionConfig(I2Cx, I2C_NACKPosition_Current);
  I2C_GenerateSTART(I2Cx, ENABLE);
}

// Returns nonzero on error
int i2c_wait()
{
  do {
    __WFI();
  } while (!i2c_done);

  return (i2c_done < 0);
}

uint8_t i2cm_comboRead(uint8_t *dbuf, uint16_t dlen,
                       uint8_t *abuf, uint16_t alen,
                       uint8_t slave)
{
  i2c_start(dbuf, dlen, abuf, alen, slave, 0);
  return i2c_wait();
}

uint8_t i2cm_comboWrite(uint8_t *dbuf, uint16_t dlen,
                        uint8_t *abuf, uint16_t alen,
                        uint8_t slave)
{
  i2c_start(dbuf, dlen, abuf, alen, slave, 1);
  return i2c_wait();
}

uint8_t i2cm_read(uint8_t *dbuf, uint16_t dlen, uint8_t slave)
{
  i2c_start(dbuf, dlen, 0, 0, slave, 0);
  return i2c_wait();
}

uint8_t i2cm_write(uint8_t *dbuf, uint16_t dlen, uint8_t slave)
{
  i2c_start(dbuf, dlen, 0, 0, slave, 1);
  return i2c_wait();
}

void I2Cx_ER_IRQHandler(void)
{
  uint16_t error = I2C_ReadRegister(I2Cx, I2C_Register_SR1);

  if (error & 0xFF00) {
    I2Cx->SR1 = error & 0x00FF;   // Clear error flags
    i2c_done = -1;
    i2c_error = error;
  }
}

#define IS_TRANSMIT (i2c_direction == I2C_Direction_Transmitter)
#define IS_RECEIVE  (i2c_direction != I2C_Direction_Transmitter)
#define CLEAR_ADDR  do { (void)I2C_ReadRegister(I2Cx, I2C_Register_SR2); } while (0)

int ntxbytes;
void I2Cx_EV_IRQHandler(void)
{
  uint16_t event = I2C_ReadRegister(I2Cx, I2C_Register_SR1);

  // Bus arbitration has been won (EV5 in datasheet parlance)
  if(event & I2C_SR1_SB) {
    // If there are address bytes, the first phase is always transmit
    int direction = i2c_adrbytes ? I2C_Direction_Transmitter : i2c_direction;
    I2C_Send7bitAddress(I2Cx, i2c_slave_address, direction);
    ntxbytes = i2c_adrbytes;
    if (IS_TRANSMIT)
      ntxbytes += i2c_databytes;
    return;
  }  
  
  // The address byte has been transmitted (EV6 in datasheet parlance)
  if(event & I2C_SR1_ADDR)  {
    if (ntxbytes > 1) {
      // Arrange for a TXE interrupt; otherwise the interrupt will be BTF
      I2C_ITConfig(I2Cx, I2C_IT_BUF, ENABLE);
    }

    // This is the first address byte of either a split transmit
    // or a transmit/receive combo.
    if (i2c_adrbytes) {
      CLEAR_ADDR;
      I2C_SendData(I2Cx, *i2c_adrbuf); 
      i2c_adrbuf++;
      i2c_adrbytes--;
      ntxbytes--;
      return;
    }
    
    // This is the first data byte of an address-less transmit
    if (IS_TRANSMIT && i2c_databytes) {
      CLEAR_ADDR;
      I2C_SendData(I2Cx, *i2c_databuf); 
      i2c_databuf++;
      i2c_databytes--;
      ntxbytes--;
      return;
    }

    // Otherwise this is the beginning of either a pure receive
    // or the receive phase of a transmit/receive combo.
    switch (i2c_databytes) {
      case 0:
        // Error condition
        I2C_ITConfig(I2Cx, I2C_IT_BUF , DISABLE);
        i2c_done = -3;
        break;
      case 2:
      case 3:    
        break;
      case 1:
        I2C_AcknowledgeConfig(I2Cx, DISABLE);
        // Fall through
      default:
        // We enable RXNE interrupts unless i2c_databytes is 2 or 3.
        // When i2c_databytes is 2, we take a final BTF interrupt at the
        // end of the transfer, relying on the POS bit to NACK at the
        // right time.  When i2c_databytes is 3, we take a BTF interrupt
        // just before the final byte, setup NACK, read one byte,
        // then take a final BTF at the end.
        I2C_ITConfig(I2Cx, I2C_IT_BUF, ENABLE);
    }      

    CLEAR_ADDR;

    switch (i2c_databytes) {
      case 1:
        I2C_GenerateSTOP(I2Cx, ENABLE);  
        break;
      case 2:
        // If there are only 2 bytes, we save an interrupt by
        // receiving one into the data register and the other into
        // the shift register.
        // Set up to NACK and thus end the transfer
        I2C_AcknowledgeConfig(I2Cx, DISABLE);

        // .. but defer the NACK for one data byte
        I2C_NACKPositionConfig(I2Cx, I2C_NACKPosition_Next);

        // and turn off the buffer interrupt
        // Unnecessary because we did not turn it on
        // I2C_ITConfig(I2Cx, I2C_IT_BUF , DISABLE);
        break;
    }
    return;
  } 
  
  // BTF means that there is a byte in the data register and another
  // in the shift register.  This happens most commonly either at the
  // very end of the transfer or just before the final byte.
  // Check this before TXE and RXNE because one of those will be set too.
  if(event & I2C_SR1_BTF) {
    // Finished with a transmit-only transaction
    if (IS_TRANSMIT) {
      i2c_done = 1;
      I2C_GenerateSTOP(I2Cx, ENABLE);
      I2C_ITConfig(I2Cx, I2C_IT_EVT | I2C_IT_BUF, DISABLE);
      return;
    }
    
    // Switching from transmit to receive in a transmit/receive combo
    if (IS_RECEIVE && (I2C_ReadRegister(I2Cx, I2C_Register_SR2) & I2C_SR2_TRA)) {
      // Repeated START to switch to receive phase
      I2C_GenerateSTART(I2Cx, ENABLE);
      // Unless you do this you get an immediate repetition of the IRQ
      (void)I2C_ReadRegister(I2Cx, I2C_Register_SR2);
      return;
    }

    // Near the end of a reception sequence
    // If we only need 2 more bytes, this is the end of the transfer.
    if (i2c_databytes == 2) {           
      I2C_GenerateSTOP(I2Cx, ENABLE);    
      
      *i2c_databuf++ = I2C_ReceiveData (I2Cx);
      i2c_databytes--;

      *i2c_databuf++ = I2C_ReceiveData (I2Cx);
      i2c_databytes--;        

      I2C_ITConfig(I2Cx, (I2C_IT_EVT | I2C_IT_BUF), DISABLE);            
      i2c_done = 1;
      return;
    }

    // If we need 3 bytes there is one more byte to go so set up to
    // NACK that final byte.
    if (i2c_databytes == 3) {
      I2C_AcknowledgeConfig(I2Cx, DISABLE);
      // In most cases the following is superfluous because the RXNE
      // interrupt turns off BUF interrupts when i2c_databytes goes from
      // 4 to 3, but there is an outside chance of a race condition
      // where the interrupt service was delayed and we got this BTF
      // instead of the RXNE.
      I2C_ITConfig(I2Cx, I2C_IT_BUF , DISABLE);  // Disable buffer ints
    }

    // Read only one byte from the data register so the final byte
    // will also set BTF.  At this point the RXNE interrupt is off
    // so we need that BTF interrupt.
    *i2c_databuf++ = I2C_ReceiveData (I2Cx);
    i2c_databytes--;

    return;
  }

  if (event & I2C_SR1_TXE) {
    if (ntxbytes == 1) {
      // This is the last Tx byte so turn off buffer interrupts
      // The next interrupt will be BTF
      I2C_ITConfig(I2Cx, I2C_IT_BUF, DISABLE);
    }

    if (i2c_adrbytes) {
      I2C_SendData(I2Cx, *i2c_adrbuf); 
      i2c_adrbuf++;
      i2c_adrbytes--;
      ntxbytes--;
      return;
    }
    if (i2c_databytes) {
      I2C_SendData(I2Cx, *i2c_databuf); 
      i2c_databuf++;
      i2c_databytes--;
      ntxbytes--;
      return;
    }
    // Shouldn't get here
    i2c_done = -4;
    I2C_GenerateSTOP(I2Cx, ENABLE);
    I2C_ITConfig(I2Cx, I2C_IT_EVT | I2C_IT_BUF, DISABLE);
    return;
  }

  // Either several bytes to go, or end of a one-byte transfer
  if(event & I2C_SR1_RXNE)  {
    *i2c_databuf++ = I2C_ReceiveData (I2Cx);  // Store data
    i2c_databytes--;

    if (i2c_databytes == 0x03)
      I2C_ITConfig(I2Cx, I2C_IT_BUF , DISABLE);  // Disable buffer ints

    // This happens if the total transfer length was one byte.  We can't
    // use a BTF interrupt in that case because BTF requires two bytes.
    if (i2c_databytes == 0x00) {
      I2C_ITConfig(I2Cx, (I2C_IT_EVT | I2C_IT_BUF), DISABLE); // Dis buf and error ints
      i2c_done = 1;
    }

    return;
  }    
  i2c_dud = I2C_ReadRegister(I2Cx, I2C_Register_SR2);
}
