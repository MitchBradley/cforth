cforth
======
This is Mitch Bradley's CForth implementation.

This branch contains the following extra options for the ESP32:
- An extra vocabulary for HTML tags 
- A HTML request parser 
- Esp-now
- GPO interrupts
- Pre-emptive multitasking
- Usage of the system clock

It does not use PlatformIO. Installation:   
cd ~/cforth/build/esp32   
make flash
