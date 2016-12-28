C Forth for Teensy 3.1
======================

C Forth is a Forth implementation by Mitch Bradley, optimised for embedded use in semi-constrained systems such as System-on-Chip processors.  See https://github.com/MitchBradley/cforth.git

The Teensy 3.1 is a Freescale MK20DX256 ARM Cortex-M4 with a Nuvoton MINI54 ARM Cortex-M0 management controller.  Paul Stoffregen maintains a build environment, which can be used with or without an IDE.  See https://github.com/PaulStoffregen/cores.git

This is an initial build of C Forth for the Teensy 3.1, providing;

- multiplexed USB and UART0 serial,

- one I2C peripheral,

- non-volatile EEPROM text execution.
