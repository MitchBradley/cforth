// TODO:
// unchain pbufs

// Defining this makes user_interface.h include the version of
// ip_addr.h from the lwip code.  Otherwise it includes a private
// version and the later includes also include the lwip version,
// resulting in a redefinition of  struct ip_addr .
#define LWIP_OPEN_SRC

#include <user_interface.h>

#include <lwip/init.h>
#include <lwip/netif.h>
#include <netif/etharp.h>
#include <lwip/dhcp.h>

#include "esp_spi.h"

#include "w5500.h"
#include "w5500_impl.h"

// start with dhcp client

#define STATIC
// #define STATIC static

// Set this interface as the default interface for fallback routing
void setDefault();

struct netif _netif;    // Structure that attaches this driver to the netif layer
static uint16_t _mtu = 1500;   // max transmission unit
static bool _default = 1;      // Is this the default interface for fallback routes?
static int8_t _intrPin = -1;   // -1 for no interrupt, else interrupt pin
static uint8_t _macAddress[6]; // MAC address to use

STATIC void spi_run(uint8_t block, uint16_t address, uint32_t len, uint8_t* in, uint8_t *out)
{
    uint8_t spi_buf[3];
    spi_begin();

    spi_buf[0] = (address & 0xFF00) >> 8;
    spi_buf[1] = address & 0x00FF;
    spi_buf[2] = block;
    spi_transfer(3, NULL, (uint32_t*)spi_buf);
    spi_transfer(len, (uint32_t*)in, (uint32_t*)out);
    spi_end();
}

STATIC uint8_t read_byte(uint8_t block, uint16_t address)
{
    uint8_t ret;
    spi_run(block|AccessModeRead, address, 1, &ret, NULL);
    return ret;
}

STATIC uint16_t read_word(uint8_t block, uint16_t address)
{
    uint8_t spi_buf[2];
    spi_run(block|AccessModeRead, address, 2, spi_buf, NULL);
    return (((uint16_t) spi_buf[0] << 8) + spi_buf[1]);
}

static uint16_t read_sreg(uint16_t address)
{
    return read_byte(SReg, address);
}

static uint16_t read_s_word(uint16_t address)
{
    return read_word(SReg, address);
}

STATIC void read_buf(uint8_t block, uint16_t address, uint8_t* pBuf, uint16_t len)
{
    spi_run(block|AccessModeRead, address, len, pBuf, NULL);
}

STATIC void write_byte(uint8_t block, uint16_t address, uint8_t wb)
{
    spi_run(block|AccessModeWrite, address, 1, NULL, &wb);
}

STATIC void write_creg(uint16_t address, uint8_t wb)
{
    write_byte(CReg, address, wb);
}

STATIC void write_sreg(uint16_t address, uint8_t wb)
{
    write_byte(SReg, address, wb);
}

STATIC void write_word(uint8_t block, uint16_t address, uint16_t word)
{
    uint8_t spi_buf[2];
    spi_buf[0] = word>>8;
    spi_buf[1] = word;
    spi_run(block|AccessModeWrite, address, 2, NULL, spi_buf);
}

static void write_s_word(uint16_t address, uint16_t word)
{
    write_word(SReg, address, word);
}

STATIC void write_buf(uint8_t block, uint16_t address, uint8_t* pBuf, uint16_t len)
{
    spi_run(block|AccessModeWrite, address, len, NULL, pBuf);
}

STATIC void setSn_CR(uint8_t cr) {
    // Write the command to the Command Register
    write_sreg(Sn_CR, cr);

    // Now wait for the command to complete
    while (read_sreg(Sn_CR))
        ;
}

STATIC uint16_t getSn_TX_FSR()
{
    uint16_t val=0, val1=0;
    do {
        val1 = read_s_word(Sn_TX_FSR);
        if (val1 != 0) {
            val = read_s_word(Sn_TX_FSR);
        }
    } while (val != val1);
    return val;
}


STATIC uint16_t getSn_RX_RSR()
{
    uint16_t val=0, val1=0;
    do {
        val1 = read_s_word(Sn_RX_RSR);
        if (val1 != 0) {
            val = read_s_word(Sn_RX_RSR);
        }
    } while (val != val1);
    return val;
}

STATIC void send_data(uint8_t *data, uint16_t len)
{
    uint16_t ptr = 0;

    if (len == 0) {
        return;
    }
    ptr = read_s_word(Sn_TX_WR);
    write_buf(TxBuf, ptr, data, len);
    ptr += len;
    write_s_word(Sn_TX_WR, ptr);
}

STATIC void recv_data(uint8_t *data, uint16_t len)
{
    if(len == 0) {
        return;
    }
    uint16_t ptr = read_s_word(Sn_RX_RD);
    read_buf(RxBuf, ptr, data, len);
    ptr += len;
    write_s_word(Sn_RX_RD, ptr);
}

STATIC void recv_ignore(uint16_t len)
{
    uint16_t ptr = read_s_word(Sn_RX_RD);
    ptr += len;
    write_s_word(Sn_RX_RD, ptr);
}

STATIC void sw_reset()
{
    write_byte(CReg, MR, MR_RST);
    read_byte(CReg, MR); // for delay
    write_buf(CReg, SHAR, _macAddress, 6);
}

STATIC uint8_t getPHYCFGR()
{
    return read_byte(CReg, PHYCFGR);
}

int8_t getphylink()
{
    return (getPHYCFGR() & PHYCFGR_LNK_ON) ? PHY_LINK_ON : PHY_LINK_OFF;
}

int8_t getphypmode()
{
    return (getPHYCFGR() & PHYCFGR_OPMDC_PDOWN) ? PHY_POWER_DOWN : PHY_POWER_NORM;
}

STATIC void setPHYCFGR(uint8_t phycfgr) {
    write_byte(CReg, PHYCFGR, phycfgr);
}

STATIC void resetphy()
{
    setPHYCFGR(getPHYCFGR() & ~PHYCFGR_RST);
    setPHYCFGR(getPHYCFGR() |  PHYCFGR_RST);
}

int8_t setphypmode(uint8_t pmode)
{
    uint8_t tmp = 0;

    tmp = getPHYCFGR();
    if((tmp & PHYCFGR_OPMD)== 0) {
        return -1;
    }
    tmp &= ~PHYCFGR_OPMDC_ALLA;
    tmp |= (pmode == PHY_POWER_DOWN) ? PHYCFGR_OPMDC_PDOWN : PHYCFGR_OPMDC_ALLA;
    setPHYCFGR(tmp);

    resetphy();

    tmp = getPHYCFGR();
    if (pmode == PHY_POWER_DOWN) {
        if(tmp & PHYCFGR_OPMDC_PDOWN) {
            return 0;
        }
    } else {
        if (tmp & PHYCFGR_OPMDC_ALLA) {
            return 0;
        }
    }
    return -1;
}

// Don't use the hardware CS pin (-1 i.e. GPIO15/D8), because we need the frame
// to persist over two calls to spi_transfer().
// It is possible to use GPIO15/D8 in software mode by passing 8 as spi_cs, but
// if so, the CS line needs to be isolated with a transistor, because that GPIO
// has special boot-time behavior and the pull-down on the W5500 module will
// prevent normal booting.
w5500_hw_begin(uint8_t spi_cs, uint8_t *mac_address)
{
    spi_open(spi_cs, 4000000, 1, 0);

    sw_reset();

    // Use the full 16Kb of RAM for Socket 0
    write_sreg(Sn_RXBUF_SIZE, 16);
    write_sreg(Sn_TXBUF_SIZE, 16);

    memcpy(_macAddress, mac_address, 6);

    // Set our local MAC address
    write_buf(CReg, SHAR, _macAddress, 6);

    // Open Socket 0 in MACRaw mode
    write_sreg(Sn_MR, Sn_MR_MACRAW | Sn_MR_MFEN);

    setSn_CR(Sn_CR_OPEN);
    if (read_sreg(Sn_SR) != SOCK_MACRAW) {
        // Failed to put socket 0 into MACRaw mode
        return false;
    }

    // Success
    return true;
}

void w5500_end()
{
    setSn_CR(Sn_CR_CLOSE);

    // clear all interrupt of the socket
    write_sreg(Sn_IR, 0xFF & 0x1f);

    // Wait for socket to change to closed
    while (read_sreg(Sn_SR) != SOCK_CLOSED)
        ;
}

STATIC void discardFrame(uint16_t framesize)
{
    recv_ignore(framesize);
    setSn_CR(Sn_CR_RECV);
}

STATIC uint16_t readFrameSize()
{
    uint16_t len = getSn_RX_RSR();

    if (len == 0)
        return 0;

    uint8_t head[2];
    uint16_t data_len=0;

    recv_data(head, 2);
    setSn_CR(Sn_CR_RECV);

    data_len = head[0];
    data_len = (data_len<<8) + head[1];
    data_len -= 2;

    return data_len;
}

void dump(uint8_t* buf, size_t len)
{
    int i;
    for (i = 0; i < len; i++) {
        ets_printf("%02x ", buf[i]);
        if ((i&0xf) == 15) {
            ets_printf("\r\n");
        }
    }
    //    if (len&0xf) {
        ets_printf("\r\n");
        //    }
}

STATIC uint16_t readFrameData(uint8_t *buffer, uint16_t framesize)
{
    recv_data(buffer, framesize);
    setSn_CR(Sn_CR_RECV);

    // Had problems with W5500 MAC address filtering (the Sn_MR_MFEN option)
    // Do it in software instead:
    // Is it addressed to an Ethernet multicast address or our unicast address
    return ((buffer[0] & 0x01) || memcmp(&buffer[0], _macAddress, 6) == 0) ? framesize : 0;
}

STATIC uint16_t sendFrame(uint8_t *buf, uint16_t len)
{
    // Wait for space in the transmit buffer
    while(1) {
        uint16_t freesize = getSn_TX_FSR();
        if(read_sreg(Sn_SR) == SOCK_CLOSED) {
            return -1;
        }
        if (len <= freesize) break;
    };

    send_data(buf, len);
    setSn_CR(Sn_CR_SEND);

    while(1) {
        uint8_t tmp = read_sreg(Sn_IR) & 0x1F;
        if (tmp & Sn_IR_SENDOK) {
            write_sreg(Sn_IR, Sn_IR_SENDOK & 0x1f);
            // Packet sent ok
            break;
        } else if (tmp & Sn_IR_TIMEOUT) {
            write_sreg(Sn_IR, Sn_IR_TIMEOUT&0x1f);
            // There was a timeout
            return -1;
        }
    }

    return len;
}

STATIC err_t linkoutput (struct netif *netif, struct pbuf *pbuf)
{
#if 0
    if (pbuf->len != pbuf->tot_len || pbuf->next) {
        Serial.println("ERRTOT\r\n");
    }
#endif

    uint16_t len = sendFrame(pbuf->payload, pbuf->len);
    // ets_printf("o %d\r\n", pbuf->len);
    // dump(pbuf->payload, pbuf->len);

#if PHY_HAS_CAPTURE
    if (phy_capture) {
        phy_capture(_netif.num, pbuf->payload, pbuf->len, /*out*/1, /*success*/len == pbuf->len);
    }
#endif

    return len == pbuf->len? ERR_OK: ERR_MEM;
}

// --------

STATIC err_t w5500_netif_init ()
{
    _netif.name[0] = 'e';
    _netif.name[1] = '0' + _netif.num;
    _netif.mtu = _mtu;
    _netif.flags =
          NETIF_FLAG_ETHARP
        | NETIF_FLAG_IGMP
        | NETIF_FLAG_BROADCAST
        | NETIF_FLAG_LINK_UP;

    // lwIP's doc: This function typically first resolves the hardware
    // address, then sends the packet.  For ethernet physical layer, this is
    // usually lwIP's etharp_output()
    _netif.output = etharp_output;

    // lwIP's doc: This function outputs the pbuf as-is on the link medium
    // (this must points to the raw ethernet driver, meaning: us)
    _netif.linkoutput = linkoutput;

#if LWIP_NETIF_STATUS_CALLBACK
    _netif.status_callback = netif_status_callback;
#endif

    return ERR_OK;
}

STATIC err_t start_with_dhclient ()
{
    ip_addr_t ip, mask, gw;

    ip_addr_set_zero(&ip);
    ip_addr_set_zero(&mask);
    ip_addr_set_zero(&gw);

    _netif.hwaddr_len = sizeof _macAddress;
    memcpy(_netif.hwaddr, _macAddress, sizeof _macAddress);

    // ets_printf("\r\nMAC\r\n");
    // dump(_macAddress, 6);

    if (!netif_add(&_netif, &ip, &mask, &gw, NULL, w5500_netif_init, ethernet_input)) {
        return ERR_IF;
    }

    _netif.flags |= NETIF_FLAG_UP;

    return dhcp_start(&_netif);
}

static os_timer_t timer;

// called on a regular basis or on interrupt
STATIC err_t handlePackets ()
{
    int pkt = 0;
    while(1) {
        if (++pkt == 10) {
            // prevent starvation
            return ERR_OK;
        }

        uint16_t tot_len = readFrameSize();
        if (!tot_len) {
            return ERR_OK;
        }

        // from doc: use PBUF_RAM for TX, PBUF_POOL from RX
        // however:
        // PBUF_POOL can return chained pbuf (not in one piece)
        // and WiznetDriver does not have the proper API to deal with that
        // so in the meantime, we use PBUF_RAM instead which is currently
        // guarantying to deliver a continuous chunk of memory.
        // TODO: tweak the wiznet driver to allow copying partial chunk
        //       of received data and use PBUF_POOL.
        struct pbuf* pbuf = pbuf_alloc(PBUF_RAW, tot_len, PBUF_RAM);
        if (!pbuf || pbuf->len < tot_len) {
            if (pbuf) {
                pbuf_free(pbuf);
            }
            discardFrame(tot_len);
            return ERR_BUF;
        }

        uint16_t len = readFrameData((uint8_t*)pbuf->payload, tot_len);
        if (len != tot_len) {
            ets_printf("Dropped\r\n");
            // tot_len is given by readFrameSize()
            // and is supposed to be honoured by readFrameData()
            // todo: ensure this test is unneeded, remove the print
            // Serial.println("read error?\r\n");
            pbuf_free(pbuf);
            return ERR_BUF;
        }
        // ets_printf("i %d\r\n", tot_len);
        // dump(pbuf->payload, tot_len);

        err_t err = _netif.input(pbuf, &_netif);

#if PHY_HAS_CAPTURE
        if (phy_capture) {
            phy_capture(_netif.num, pbuf->payload, tot_len, /*out*/0, /*success*/err == ERR_OK);
        }
#endif

        if (err != ERR_OK) {
            pbuf_free(pbuf);
            return err;
        }
        // (else) allocated pbuf is now on lwIP's responsibility
    }
}

int w5500_netif_begin(uint8_t spi_cs, const uint8_t* macAddress)
{
    memset(&_netif, 0, sizeof(_netif));

    // Determine MAC address
    if (macAddress) {
        memcpy(_macAddress, macAddress, 6);
    } else {
        _netif.num = 2;
        struct netif* n;
        for (n = netif_list; n; n = n->next) {
            if (n->num >= _netif.num) {
                _netif.num = n->num + 1;
            }
        }

#if 1
        // make a new mac-address from the esp's wifi sta one
        // I understand this is cheating with an official mac-address
        wifi_get_macaddr(STATION_IF, (uint8*)_macAddress);
#else
        // https://serverfault.com/questions/40712/what-range-of-mac-addresses-can-i-safely-use-for-my-virtual-machines
        // TODO ESP32: get wifi mac address like with esp8266 above
        memset(_macAddress, 0, 6);
        _macAddress[0] = 0xEE;
#endif
        _macAddress[3] += _netif.num;
        memcpy(_netif.hwaddr, _macAddress, 6);
    }

    // Start the hardware
    if (!w5500_hw_begin(spi_cs, _macAddress)){
        return false;
    }

    switch (start_with_dhclient()) {
        case ERR_OK:
            break;
        case ERR_IF:
            return false;
        default:
            netif_remove(&_netif);
            return false;
    }

    if (_intrPin >= 0) {
        _intrPin = -1;
    }

    if (_intrPin >= 0) {
        // attachInterrupt(_intrPin, handlePackets, FALLING);
    } else {
        os_timer_setfn(&timer, handlePackets, NULL);
        os_timer_arm(&timer, 100, true);
    }

    return true;
}

static int connected()
{
    return !!ip4_addr_get_u32(&(_netif.ip_addr));
}

#if LWIP_NETIF_STATUS_CALLBACK
static void netif_status_callback ()
{
    //XXX is it wise ?
    if (_default && connected()) {
        netif_set_default(&_netif);
    } else if (netif_default == &_netif && !connected()) {
        netif_set_default(NULL);
    }
}
#endif

void setDefault ()
{
    _default = true;
    if (connected()) {
        netif_set_default(&_netif);
    }
}

void w5500_ip_addr(uint8_t *ip) {
    memcpy(ip, &(_netif.ip_addr), 4);
    //    return ip4_addr_get_u32(&(_netif.ip_addr));
}
