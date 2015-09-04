/***************************************************************************
                          ftdi_i.h  -  description
                             -------------------
    begin                : Don Sep 9 2011
    copyright            : (C) 2003-2014 by Intra2net AG and the libftdi developers
    email                : opensource@intra2net.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Lesser General Public License           *
 *   version 2.1 as published by the Free Software Foundation;             *
 *                                                                         *
 ***************************************************************************

 Non public definitions here

*/

/* Even on 93xx66 at max 256 bytes are used (AN_121)*/
#define FTDI_MAX_EEPROM_SIZE 256

/** Max Power adjustment factor. */
#define MAX_POWER_MILLIAMP_PER_UNIT 2

/**
    \brief FTDI eeprom structure
*/
struct ftdi_eeprom
{
    /** vendor id */
    int vendor_id;
    /** product id */
    int product_id;

    /** Was the eeprom structure initialized for the actual
        connected device? **/
    int initialized_for_connected_device;

    /** self powered */
    int self_powered;
    /** remote wakeup */
    int remote_wakeup;

    int is_not_pnp;

    /* Suspend on DBUS7 Low */
    int suspend_dbus7;

    /** input in isochronous transfer mode */
    int in_is_isochronous;
    /** output in isochronous transfer mode */
    int out_is_isochronous;
    /** suspend pull downs */
    int suspend_pull_downs;

    /** use serial */
    int use_serial;
    /** usb version */
    int usb_version;
    /** Use usb version on FT2232 devices*/
    int use_usb_version;
    /** maximum power */
    int max_power;

    /** manufacturer name */
    char *manufacturer;
    /** product name */
    char *product;
    /** serial number */
    char *serial;

    /* 2232D/H specific */
    /* Hardware type, 0 = RS232 Uart, 1 = 245 FIFO, 2 = CPU FIFO,
       4 = OPTO Isolate */
    int channel_a_type;
    int channel_b_type;
    /*  Driver Type, 1 = VCP */
    int channel_a_driver;
    int channel_b_driver;
    int channel_c_driver;
    int channel_d_driver;
    /* 4232H specific */
    int channel_a_rs485enable;
    int channel_b_rs485enable;
    int channel_c_rs485enable;
    int channel_d_rs485enable;

    /* Special function of FT232R/FT232H devices (and possibly others as well) */
    /** CBUS pin function. See CBUS_xxx defines. */
    int cbus_function[10];
    /** Select hight current drive on R devices. */
    int high_current;
    /** Select hight current drive on A channel (2232C */
    int high_current_a;
    /** Select hight current drive on B channel (2232C). */
    int high_current_b;
    /** Select inversion of data lines (bitmask). */
    int invert;

    /*2232H/4432H Group specific values */
    /* Group0 is AL on 2322H and A on 4232H
       Group1 is AH on 2232H and B on 4232H
       Group2 is BL on 2322H and C on 4232H
       Group3 is BH on 2232H and C on 4232H*/
    int group0_drive;
    int group0_schmitt;
    int group0_slew;
    int group1_drive;
    int group1_schmitt;
    int group1_slew;
    int group2_drive;
    int group2_schmitt;
    int group2_slew;
    int group3_drive;
    int group3_schmitt;
    int group3_slew;

    int powersave;

    int clock_polarity;
    int data_order;
    int flow_control;

    /** eeprom size in bytes. This doesn't get stored in the eeprom
        but is the only way to pass it to ftdi_eeprom_build. */
    int size;
    /* EEPROM Type 0x46 for 93xx46, 0x56 for 93xx56 and 0x66 for 93xx66*/
    int chip;
    unsigned char buf[FTDI_MAX_EEPROM_SIZE];

    /** device release number */
    int release_number;
};

