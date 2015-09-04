This program puts new firmware into a Nod Backspin.  It works on Linux.

Installation:

* Extract the file backspin-programmer.tgz, which will create a
  directory named NodBackspinProgrammer.  For example:

    $ tar xfz backspin-programmer.tgz

Usage:

To use the downloader

* Copy a Backspin firmware file - with a name like
  "backspin-<version>.bin" - into the NodBackspinProgrammer
  directory.

* Ensure that exactly one Backspin device is connected.

* cd to the NodBackspinProgrammer

* Type
     ./program-backspin backspin-<version>.bin
  replacing <version> with the desired version number.

Rebooting Backspin:

* Type
     ./reboot-backspin
