To see the air quality in a web browser
For: ~/cforth/src/app/esp32-extra
Needed hardware: A SPS30 and an esp32

Backup your: ~/cforth/src/app/esp32-extra/app.fth
$ Copy ~/cforth/src/app/sps30/app.fth   to   ~/cforth/src/app/esp32-extra
$ cd ~/cforth/build/esp32-extra  
$ rm *.*
$ make flash

Upload ../src/app/ntc-web/favicon.ico AND sps30_web.fth to the file system of the ESP32.

Only when you use https://github.com/Jos-Ven/A-smart-home-in-Forth :
  Edit and upload MachineSettings.fth to the file system of the ESP32 IF you are able to 
  handle TcpTime packets. See: ~/cforth/src/app/esp32-extra/tools/timediff.fth
  Disable servers you do not have.

Reboot the ESP32 and compile sps30_web.fth
To auto-run the application hit escape and enter on the Esp32:
s" fl sps30_web.fth" s" start" file-it


The deep sleep of the ESP32 wakes up too early. The schedule handle this as follows:
When the ESP32 wakes up and there is an entry at 00:00 containing sleep then:
If there is no entry of in the running minute it puts the ESP32 into a deep sleep
till the next entry.
Then when it wakes up again it executes the entry of the running minute.
At 00:00 the ESP32 will not go into a deep sleep.

When there is no WiFi connection then the programm puts the esp32 into 
a deep sleep for 30 minutes.
Unless you disable the lines with SleepIfNotConnected in sps30_web.fth


