# C Forth

This is Mitch Bradley's C Forth implementation, derived from the
version at One Laptop per Child, and improved as follows:

a. Host version now has line editing
a. Host version catches exceptions
a. `key` and `key?` implemented property in host versions for Linux and Windows
a. Makefile fragments factored better, and use pattern rules extensively
a. Makefiles in build directories simplified

It has been optimized for embedded use in semi-constrained systems
such as System On Chip processors.  To port it to a new system, you
will need to add some or all of the following new directories and
files:

a. CPU-dependent code and compiler definitions in `src/cpu/*`
a. Platform-dependent code in `src/platform/*`
a. Application-specific code in `app/*`
a. Build directories for your versions in `build/*`

There are two build directories that can be used as templates.  You
can copy these templates to a new name as a starting point for your
version.

Use `build/host-serial-linux64/Makefile` as an example for how to set
up a build directory for a host-resident C Forth on a 64-bit Linux
system.

Use `build/arm-xo-1.75/Makefile` as an example for how to set up a
build directory for an embedded C Forth.

Typing `make` in `build/host-serial-linux64` will build a host image
for the same CPU as the host:

```
   $ cd build/host-serial-linux64
   $ make
   $ ./forth app.dic
   $ C Forth  Copyright (c) 2008 FirmWorks
   ok bye
   $ 
```

The `forth` executable program is a version of the Forth core kernel
(the equivalent of "code words") that runs on the compilation host
system.  It loads a "dictionary file" like `app.dic`, which is a
machine-independent representation of a Forth dictionary containing
compiled colon definitions and other objects.

Read the Makefile in the `build/template` to see how to configure
the CPU, the platform code, and the application code.

# PlatformIO

This repository is a PlatformIO project for several target boards.  We have tested these boards;

* Raspberry Pi Pico RP2040,
* Adafruit Feather M0,
* Teensy 3.1, 3.2, 3.5, 3.6, and 4.0,
* Espressif ESP32.

PlatformIO makes it relatively easy to add support for more boards.  If you can use PlatformIO to make an LED blink using the Arduino framework, and if there is enough RAM on the board, then it should be possible to build C Forth.  Add an environment to the `platformio.ini` file for the board.

## How to build C Forth using PlatformIO

* install a Linux, such as Debian or Ubuntu, (others probably work,
  but we've not tested them recently),
* install the `libc6-dev-i386-cross` package,
* install [PlatformIO](https://platformio.org/),
* clone this repository;

```
git clone https://github.com/MitchBradley/cforth
```

* build and upload;

```
cd cforth
pio run
pio run --environment pico --target upload
```

## How to use C Forth over serial

C Forth has an interactive shell, or REPL, which you can use over serial.  Use any serial USB and terminal emulator, such as screen(1) on Linux;

```
screen /dev/ttyACM0 115200
```

or

```
screen /dev/ttyUSB0 115200
```


Press enter.  The "ok" prompt should appear.

```
ok 
```

Use this shell to iteratively prototype or test hardware.  The shell has command line editing and history.

## How to blink an LED on a Raspberry Pi Pico

Build and upload C Forth.

The Raspberry Pi Pico has an LED attached to GPIO25.  Let's light this LED.

Set the pin as an output:
```
ok #25 p-out
```

This pushes the decimal number twenty five onto the stack, then calls
the predefined `p-out` (pin out) word which is the equivalent of the
Arduino `pinMode` function with the OUTPUT mode.  The number is
consumed from the stack, nothing is left on it.

Turn on the port:
```
ok #1 #25 p!
```

This pushes the decimal number one to the stack, then pushes the
decimal number twenty five, then calls the predefined `p!` (pin store)
word which is the equivalent of the Arduino `digitalWrite` function.
Nothing is left on the stack.

Turn it off:
```
ok #0 #25 p!
```

Notice how #1 is used to turn it on, and #0 is used to turn it off,
but that #25 is used each time.

Here are some of the words we've used.

| Word | Stack Effect | Meaning |
| ---- | ------------ | ------- |
| `p-out` | `( pin# -- )` | set a pin to output, like the Arduino `pinMode` function, |
| `p!` | `( value pin# -- )` | pin store, set the digital state of a pin, like the Arduino `digitalWrite` function<br>zero is low, one is high |

C Forth runs the instructions as soon as you press enter.  But how to write a program?  Let's blink the LED.  Type, or copy and paste this;

```
#25 value led
: setup  led p-out  ;
: thing  #1 led p!  #100 ms  #0 led p!  #400 ms  ;
: blink  setup  begin thing key? until  ;
blink
```

The LED shall blink.  Press a key to stop.

This creates in the temporary dictionary four new words:

* `led` is a new word containing the pin number of the LED,
* `setup` is a new word that will set the pin mode,
* `thing` is a new word to turn the LED on for 100 ms and off for 400 ms,
* `blink` is a new word to blink the LED until a key is pressed.

The new words depend on words already known.  Here are some of the predefined words;

| Word | Stack Effect | Meaning |
| ---- | ------------ | ------- |
| `:` | `word ( -- )` | start defining a new word |
| `;` | `( -- )` | stop defining a new word |
| `ms` | `( n -- )` | delay for n milliseconds, |
| `key?` | `( -- true⎮false )` | report on the stack whether a key is pressed, |
| `begin` | `( -- )` | mark the start of a loop structure, |
| `until` | `( flag -- )` | if the flag on stack is false, repeat the loop, |

At any time you can ask C Forth to show you the meaning of a word:
```
ok decimal see thing
: thing
   #1 #25 p! #100 ms #0 #25 p! #400 ms
;
ok 
```

This works for any words written in Forth.  Words written in C are not shown. For example;
```
ok see :
primitive :    (Body: $63000000   ...const ) 
ok see ;
primitive ;    (Body: $6e6f6e3a   :noname. ) 
immediate
ok 
```

Here are some more words.

| Word | Stack Effect | Meaning |
| ---- | ------------ | ------- |
| `p-in` | `( pin# -- )` | set a pin to input, like the Arduino `pinMode` function, |
| `p-in-p` | `( pin# -- )` | set a pin to input with pullup, like the Arduino `pinMode` function, |
| `p@` | `( pin# -- value )` | pin at, read the digital state of a pin, like the Arduino `digitalRead` function |
| `a@` | `( pin# -- value )` | analog at, read the analog value of an analog pin, like the Arduino `analogRead` function<br>(but check the pinout; digital pin numbers often differ from analog pin numbers) |
| `a!` | `( value pin# -- )` | analog store, set a digital pin to pulse width modulation, like the Arduino `analogWrite` function |
| `.` | `( value -- )` | print, remove the top of stack and display the value in the current base. |
| `us` | `( n -- )` | delay for n microseconds, like the Arduino `delay` function |
| `get-usecs` | `( -- n )` | get the number of microseconds since starting, like the Arduino `micros` function |
| `get-msecs` | `( -- n )` | get the number of milliseconds since starting, like the Arduino `millis` function |

C Forth starts up in hexadecimal base for displaying or entering
numbers.  The word `decimal` will switch to decimal.

| Word | Stack Effect | Meaning |
| ---- | ------------ | ------- |
| `#n` | `( -- n)` | push a decimal number, |
| `$n` | `( -- n)` | push a hexadecimal number, |
| `%n` | `( -- n)` | push a binary number, |
| `n` | `( -- n)` | push a number in the current base, |
| `decimal` | `( -- )` | set the current base to decimal, |
| `hex` | `( -- )` | set the current base to hexadecimal, |
| `binary` | `( -- )` | set the current base to hexadecimal, |

Mixing different number bases in code is quite frequent, so we tend to qualify a number with a base.

You can find more about Forth in many places.  Reading the source code of C Forth is the best way, because not every Forth is the same.

## How to crash

Forth is a language without protections.  Making a mistake will usually crash the system and you'll have to restart.

On a C Forth built for Linux, you can see this;

* type `0 -1 !`, which means to store a zero at address -1, or
  0xffffffffffffffff,
* press enter,

The `ok` prompt won't come back.  The process will terminate with an
_Address exception_.

On the Raspberry Pi Pico, you can see this;

* type `0 -1 !`, which means to store a zero at address -1, or 0xffffffff,
* press enter,

The `ok` prompt won't come back.  The Raspberry Pi Pico will blink the
LED in a pattern; four short, four long.  You have to restart by
plugging it in again, or grounding the RUN pin.

## How to write an application in C Forth for Linux

### In the build

* make changes to the `src/app/host-serial/app.fth` file,
* repeat the build and run,

### As a Forth script

* create a file containing Forth commands,

```
: hello  ." hello world" cr  ;
hello
```

* run the script using Forth,

```
~/bin/forth ~/bin/app.dic script.fth
```

### As a shell script

```
#!/bin/bash
~/bin/forth ~/bin/app.dic - <<EOF
." hello world" cr
EOF
```

### As a dictionary

* define words in the dictionary and save it to a file,

```
ok : hello  ." hello world" cr  ;
ok " test.dic" save
ok 
```

* run it later,

```
~/bin/forth ~/bin/test.dic -s hello
```

### Different ways to start C Forth on an operating system

| Command | Effect |
| ------- | ------ |
| forth dictionary | show banner and prompt ok |
| forth dictionary - | prompt ok |
| forth dictionary file | read from file, execute, and exit |
| forth dictionary -s word | execute a word and exit |
| forth dictionary -s "word word word" | execute words and exit |
| forth dictionary -s "word word word" - | execute words and prompt ok |

## How to write an application in C Forth for a board

* make changes to the `src/app/arduino/app.fth` file,
* repeat the build and upload.

## How to write an application in C, C++ and C Forth for a board

* make changes to the `src/main.cpp` file,
* perhaps add new Forth words to the `src/platform/arduino/extend.c` file,
* repeat the build and upload.

## Filesystems

SPIFFS filesystem support is present in the cross-compiled build for ESP32 and ESP8266.

No filesystem support is present in the PlatformIO build, but can be added for some boards.  For the Raspberry Pi Pico, for example, it may be added using the _arduino-pico_ core, especially once [this pull request](https://github.com/platformio/platform-raspberrypi/pull/36) is merged.

## How the PlatformIO build works

C Forth is unusual.  C Forth is first built for your computer, then run to make a dictionary that is copied into the build for the target device.

C Forth is usually built directly using GNU Make and GCC.  Compiling under PlatformIO brings benefits but makes the build process complicated.

### Clean target

Changes to `extend.c` to add new C calls require a `pio run -t clean` and `pio run`.  Otherwise the old `tccalls.fth` doesn't match the dictionary, which can cause the wrong C function to be called for a Forth word.  It hasn't been irritating enough for me to fix.  Let us know if you can fix this.

### git clean

Some build files are untracked; if something isn't working, consider looking for files that are not part of the git working directory, using `git status --ignored`.  Let us know if you can fix this.

### esp8266

C Forth can be built for esp8266, but the amount of Flash memory limits what can be built.  The default dictionary for the PlatformIO build has to be trimmed.

----
