#pragma once

//< SPI interface Read operation in Control Phase
#define AccessModeRead (0x00 << 2)

//< SPI interface Read operation in Control Phase
#define AccessModeWrite (0x01 << 2)

//< Common register block in Control Phase
#define CReg (0x00 << 3)

//< Socket 0 register block in Control Phase
#define SReg (0x01 << 3)

//< Socket 0 Tx buffer address block
#define TxBuf (0x02 << 3)

//< Socket 0 Rx buffer address block
#define RxBuf (0x03 << 3)

/** Common registers */
enum {
    MR = 0x0000,        ///< Mode Register address (R/W)
    SHAR = 0x0009,      ///< Source MAC Register address (R/W)
    INTLEVEL = 0x0013,  ///< Set Interrupt low level timer register address (R/W)
    IR = 0x0015,        ///< Interrupt Register (R/W)
    _IMR_ = 0x0016,     ///< Interrupt mask register (R/W)
    SIR = 0x0017,       ///< Socket Interrupt Register (R/W)
    SIMR = 0x0018,      ///< Socket Interrupt Mask Register (R/W)
    _RTR_ = 0x0019,     ///< Timeout register address (1 is 100us) (R/W)
    _RCR_ = 0x001B,     ///< Retry count register (R/W)
    UIPR = 0x0028,      ///< Unreachable IP register address in UDP mode (R)
    UPORTR = 0x002C,    ///< Unreachable Port register address in UDP mode (R)
    PHYCFGR = 0x002E,   ///< PHY Status Register (R/W)
    VERSIONR = 0x0039,  ///< Chip version register address (R)
};

/** Socket registers */
enum {
    Sn_MR = 0x0000,          ///< Socket Mode register (R/W)
    Sn_CR = 0x0001,          ///< Socket command register (R/W)
    Sn_IR = 0x0002,          ///< Socket interrupt register (R)
    Sn_SR = 0x0003,          ///< Socket status register (R)
    Sn_PORT = 0x0004,        ///< Source port register (R/W)
    Sn_DHAR = 0x0006,        ///< Peer MAC register address (R/W)
    Sn_DIPR = 0x000C,        ///< Peer IP register address (R/W)
    Sn_DPORT = 0x0010,       ///< Peer port register address (R/W)
    Sn_MSSR = 0x0012,        ///< Maximum Segment Size(Sn_MSSR0) register address (R/W)
    Sn_TOS = 0x0015,         ///< IP Type of Service(TOS) Register (R/W)
    Sn_TTL = 0x0016,         ///< IP Time to live(TTL) Register (R/W)
    Sn_RXBUF_SIZE = 0x001E,  ///< Receive memory size register (R/W)
    Sn_TXBUF_SIZE = 0x001F,  ///< Transmit memory size register (R/W)
    Sn_TX_FSR = 0x0020,      ///< Transmit free memory size register (R)
    Sn_TX_RD = 0x0022,       ///< Transmit memory read pointer register address (R)
    Sn_TX_WR = 0x0024,       ///< Transmit memory write pointer register address (R/W)
    Sn_RX_RSR = 0x0026,      ///< Received data size register (R)
    Sn_RX_RD = 0x0028,       ///< Read point of Receive memory (R/W)
    Sn_RX_WR = 0x002A,       ///< Write point of Receive memory (R)
    Sn_IMR = 0x002C,         ///< Socket interrupt mask register (R)
    Sn_FRAG = 0x002D,        ///< Fragment field value in IP header register (R/W)
    Sn_KPALVTR = 0x002F,     ///< Keep Alive Timer register (R/W)
};

/** Mode register values */
enum {
    MR_RST = 0x80,    ///< Reset
    MR_WOL = 0x20,    ///< Wake on LAN
    MR_PB = 0x10,     ///< Ping block
    MR_PPPOE = 0x08,  ///< Enable PPPoE
    MR_FARP = 0x02,   ///< Enable UDP_FORCE_ARP CHECHK
};

/* Interrupt Register values */
enum {
    IR_CONFLICT = 0x80,  ///< Check IP conflict
    IR_UNREACH = 0x40,   ///< Get the destination unreachable message in UDP sending
    IR_PPPoE = 0x20,     ///< Get the PPPoE close message
    IR_MP = 0x10,        ///< Get the magic packet interrupt
};

/* Interrupt Mask Register values */
enum {
    IM_IR7 = 0x80,   ///< IP Conflict Interrupt Mask
    IM_IR6 = 0x40,   ///< Destination unreachable Interrupt Mask
    IM_IR5 = 0x20,   ///< PPPoE Close Interrupt Mask
    IM_IR4 = 0x10,   ///< Magic Packet Interrupt Mask
};

/** Socket Mode Register values @ref Sn_MR */
enum {
    Sn_MR_CLOSE = 0x00,  ///< Unused socket
    Sn_MR_TCP = 0x01,    ///< TCP
    Sn_MR_UDP = 0x02,    ///< UDP
    Sn_MR_MACRAW = 0x04, ///< MAC LAYER RAW SOCK
    Sn_MR_UCASTB = 0x10, ///< Unicast Block in UDP Multicasting
    Sn_MR_ND = 0x20,     ///< No Delayed Ack(TCP), Multicast flag
    Sn_MR_BCASTB = 0x40, ///< Broadcast block in UDP Multicasting
    Sn_MR_MULTI = 0x80,  ///< Support UDP Multicasting
    Sn_MR_MIP6B = 0x10,  ///< IPv6 packet Blocking in @ref Sn_MR_MACRAW mode
    Sn_MR_MMB = 0x20,    ///< Multicast Blocking in @ref Sn_MR_MACRAW mode
    Sn_MR_MFEN = 0x80,   ///< MAC filter enable in @ref Sn_MR_MACRAW mode
};

/** Socket Command Register values */
enum {
    Sn_CR_OPEN = 0x01,      ///< Initialise or open socket
    Sn_CR_LISTEN = 0x02,    ///< Wait connection request in TCP mode (Server mode)
    Sn_CR_CONNECT = 0x04,   ///< Send connection request in TCP mode (Client mode)
    Sn_CR_DISCON = 0x08,    ///< Send closing request in TCP mode
    Sn_CR_CLOSE = 0x10,     ///< Close socket
    Sn_CR_SEND = 0x20,      ///< Update TX buffer pointer and send data
    Sn_CR_SEND_MAC = 0x21,  ///< Send data with MAC address, so without ARP process
    Sn_CR_SEND_KEEP = 0x22, ///< Send keep alive message
    Sn_CR_RECV = 0x40,      ///< Update RX buffer pointer and receive data
};

/** Socket Interrupt register values */
enum {
    Sn_IR_CON = 0x01,      ///< CON Interrupt
    Sn_IR_DISCON = 0x02,   ///< DISCON Interrupt
    Sn_IR_RECV = 0x04,     ///< RECV Interrupt
    Sn_IR_TIMEOUT = 0x08,  ///< TIMEOUT Interrupt
    Sn_IR_SENDOK = 0x10,   ///< SEND_OK Interrupt
};

/** Socket Status Register values */
enum {
    SOCK_CLOSED = 0x00,      ///< Closed
    SOCK_INIT = 0x13,        ///< Initiate state
    SOCK_LISTEN = 0x14,      ///< Listen state
    SOCK_SYNSENT = 0x15,     ///< Connection state
    SOCK_SYNRECV = 0x16,     ///< Connection state
    SOCK_ESTABLISHED = 0x17, ///< Success to connect
    SOCK_FIN_WAIT = 0x18,    ///< Closing state
    SOCK_CLOSING = 0x1A,     ///< Closing state
    SOCK_TIME_WAIT = 0x1B,   ///< Closing state
    SOCK_CLOSE_WAIT = 0x1C,  ///< Closing state
    SOCK_LAST_ACK = 0x1D,    ///< Closing state
    SOCK_UDP = 0x22,         ///< UDP socket
    SOCK_MACRAW = 0x42,      ///< MAC raw mode socket
};


/* PHYCFGR register value */
enum {
    PHYCFGR_RST = (1<<7),
    PHYCFGR_OPMD = (1<<6), // Configure PHY with OPMDC value
    PHYCFGR_OPMDC_ALLA = (7<<3),
    PHYCFGR_OPMDC_PDOWN = (6<<3),
    PHYCFGR_OPMDC_NA = (5<<3),
    PHYCFGR_OPMDC_100FA = (4<<3),
    PHYCFGR_OPMDC_100F = (3<<3),
    PHYCFGR_OPMDC_100H = (2<<3),
    PHYCFGR_OPMDC_10F = (1<<3),
    PHYCFGR_OPMDC_10H = (0<<3),
    PHYCFGR_DPX_FULL = (1<<2),
    PHYCFGR_DPX_HALF = (0<<2),
    PHYCFGR_SPD_100 = (1<<1),
    PHYCFGR_SPD_10 = (0<<1),
    PHYCFGR_LNK_ON = (1<<0),
    PHYCFGR_LNK_OFF = (0<<0),
};

enum {
    PHY_SPEED_10 = 0,     ///< Link Speed 10
    PHY_SPEED_100 = 1,    ///< Link Speed 100
    PHY_DUPLEX_HALF = 0,  ///< Link Half-Duplex
    PHY_DUPLEX_FULL = 1,  ///< Link Full-Duplex
    PHY_LINK_OFF = 0,     ///< Link Off
    PHY_LINK_ON = 1,      ///< Link On
    PHY_POWER_NORM = 0,   ///< PHY power normal mode
    PHY_POWER_DOWN = 1,   ///< PHY power down mode
};
