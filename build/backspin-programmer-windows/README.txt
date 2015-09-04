This program puts new firmware into a Nod Backspin.  It works on
any Windows system from Window 7 onward.

Installation:

* Extract the file backspin-programmer.zip, which will create a
  folder named NodBackspinProgrammer

* Plug the Backspin into a USB port

* Install and run the "Zadig" USB device driver installation
  program from http://zadig.akeo.ie/

* In Zadig, ensure that Options>List All Devices is checked

* In Zadig's device list chooser, select the name "Backspin"

* The USB ID should show 0403 4E4D

* In the Driver selection list, choose "WinUSB (<some version>)"

* Ensure that Install Driver is displayed in the control below,
  then click on the "Install Driver" button.

Usage:

To use the downloader

* Copy a Backspin firmware file - with a name like
  "backspin-<version>.bin" - into the NodBackspinProgrammer
   folder.

* Ensure that exactly one Backspin device is connected.

* Click on "program-backspin".  The program will let you
  choose the desired backspin*.bin file, and will then program
  the Backspin, showing the progress both graphically and
  textually.

Rebooting Backspin:

* Click on "reboot-backspin".
