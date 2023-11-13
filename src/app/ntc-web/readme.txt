To see the temperature measured by a NTC in a web browser
For: ~/cforth/src/app/esp32-extra
Needed hardware: A NTC and an esp32

$ Copy ~/cforth/src/app/ntc-web/app.fth   to   ~/cforth/src/app/esp32-extra
$ cd ~/cforth/build/esp32-extra  
$ rm *.*
$ make flash

Upload from ../src/app/ntc-web/
favicon.ico AND ntc_web.fth   to the file system of the ESP32.

Only when you use https://github.com/Jos-Ven/A-smart-home-in-Forth :
  Edit and upload MachineSettings.fth to the file system of the ESP32 IF you are able to 
  handle TcpTime packets. See: ~/cforth/src/app/esp32-extra/tools/timediff.fth
  Disable servers you do not have.

Reboot the ESP32 and compile ntc_web.fth
To auto-run the application hit escape and enter:
s" fl ntc_web.fth" s" start" file-it