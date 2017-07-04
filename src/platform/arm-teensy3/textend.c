// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include "forth.h"

// Prototypes

cell get_msecs();
cell wfi();
cell spins();
cell analogWrite();
cell analogRead();
cell digitalWrite();
cell digitalRead();
cell pinMode();
cell micros();
cell delay();
cell _reboot_Teensyduino_();
cell eeprom_size();
cell eeprom_base();
cell eeprom_length();
cell eeprom_read_byte();
cell eeprom_write_byte();
unsigned long rtc_get(void);
void rtc_set(unsigned long t);
void rtc_compensate(int adjust);
void console_uart_on();
void console_uart_off();
int console_uart();
void console_usb_on();
void console_usb_off();
int console_usb();

cell version_adr(void)
{
    extern char version[];
    return (cell)version;
}

cell build_date_adr(void)
{
    extern char build_date[];
    return (cell)build_date;
}

/*
 * "Watchdog Unlock register (WDOG_UNLOCK)"
 * "Writing the unlock sequence values to this register to makes the
 * watchdog write-once registers writable again.  The required unlock
 * sequence is 0xC520 followed by 0xD928 within 20 bus clock cycles.
 * A valid unlock sequence opens a window equal in length to the WCT
 * within which you can update the registers.  Writing a value other
 * than the above mentioned sequence or if the sequence is longer than
 * 20 bus cycles, resets the system or if IRQRSTEN is set, it
 * interrupts and then resets the system.  The unlock sequence is
 * effective only if ALLOWUPDATE is set."
 * -- K20P64M72SF1RM.pdf 23.7.8 page 478
 */
#define WDOG_UNLOCK (*(volatile uint32_t *)0x4005200e)

void restart(void)
{
  WDOG_UNLOCK = 0; /* force system reset */
}

cell ((* const ccalls[])()) = {
        C(spins)                //c spins               { i.nspins -- }
        C(wfi)                  //c wfi                 { -- }
        C(get_msecs)            //c get-msecs           { -- n }
        C(analogWrite)          //c a!                  { i.val i.pin -- }
        C(analogRead)           //c a@                  { i.pin -- n }
        C(digitalWrite)         //c p!                  { i.val i.pin -- }
        C(digitalRead)          //c p@                  { i.pin -- n }
        C(pinMode)              //c m!                  { i.mode i.pin -- }
        C(micros)               //c get-usecs           { -- n }
        C(delay)                //c ms                  { i.#ms -- }
        C(eeprom_size)          //c /nv                 { -- n }
        C(eeprom_base)          //c nv-base             { -- n }
        C(eeprom_length)        //c nv-length           { -- n }
        C(eeprom_read_byte)     //c nv@                 { i.adr -- i.val }
        C(eeprom_write_byte)    //c nv!                 { i.val i.adr -- }
        C(build_date_adr)       //c 'build-date         { -- a.value }
        C(version_adr)          //c 'version            { -- a.value }
        C(rtc_get)              //c rtc@                { -- i.val }
        C(rtc_set)              //c rtc!                { i.val -- }
        C(rtc_compensate)       //c rtc_compensate      { i.adjust -- }
        C(console_uart)         //c uart?               { -- i.bytes }
        C(console_uart_on)      //c uart-on             { -- }
        C(console_uart_off)     //c uart-off            { -- }
        C(console_usb)          //c usb?                { -- i.bytes }
        C(console_usb_on)       //c usb-on              { -- }
        C(console_usb_off)      //c usb-off             { -- }
        C(_reboot_Teensyduino_) //c reflash             { -- }
        C(restart)              //c restart             { -- }
};
