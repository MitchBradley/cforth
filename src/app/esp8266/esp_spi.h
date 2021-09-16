#pragma once
void spi_open(int csGPIO, uint32_t clock, uint8_t msbfirst, uint8_t dataMode);
void spi_close();
void spi_begin();
void spi_end();
void spi_transfer(uint32_t remaining, uint32_t *in, uint32_t *out);
int spi_bits_in(int num);
