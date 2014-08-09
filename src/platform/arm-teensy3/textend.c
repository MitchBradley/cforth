// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

// This is the only thing that we need from forth.h
#define cell long

// Prototypes

cell get_msecs();
cell wfi();
cell spins();
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

cell ((* const ccalls[])()) = {
    (cell (*)())spins,        // Entry # 0
    (cell (*)())wfi,          // Entry # 1
    (cell (*)())get_msecs,    // Entry # 2
    (cell (*)())analogRead,   // Entry # 3
    (cell (*)())digitalWrite, // Entry # 4
    (cell (*)())digitalRead,  // Entry # 5
    (cell (*)())pinMode,      // Entry # 6
    (cell (*)())micros,       // Entry # 7
    (cell (*)())delay,        // Entry # 8  // fixme: hangs
    (cell (*)())_reboot_Teensyduino_, // Entry # 9
    (cell (*)())eeprom_size,
    (cell (*)())eeprom_base,
    (cell (*)())eeprom_length,
    (cell (*)())eeprom_read_byte,
    (cell (*)())eeprom_write_byte,
};

// Forth words to call the above routines may be created by:
//
//  system also
//  0 ccall: sum      { i.a i.b -- i.sum }
//  1 ccall: byterev  { s.in -- s.out }
//
// and could be used as follows:
//
//  5 6 sum .
//  p" hello"  byterev  count type
