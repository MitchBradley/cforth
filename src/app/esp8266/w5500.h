#pragma once

// If macAddress is NULL, the MAC address is inferred from esp8266's STA interface
int w5500_netif_begin(uint8_t spi_cs, const uint8_t *mac_address);

void w5500_end();

void w5500_ip_addr(uint8_t *ip);

/**
 * Get the link status of phy in WIZCHIP
 */
int8_t getphylink();

/**
 * Get the power mode of PHY in WIZCHIP
 */
int8_t getphypmode();

/**
 * set the power mode of phy inside WIZCHIP. Refer to @ref PHYCFGR in W5500, @ref PHYSTATUS in W5200
 * @param pmode Settig value of power down mode.
 */
int8_t setphypmode(uint8_t pmode);
