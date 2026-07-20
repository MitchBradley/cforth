To see the air quality in a web browser.

Needed hardware: A SPS30 and an ESP32.
The SPS30 should be connected to an extra UART on the ESP32. See sps30.fth.

Allow your router to run a local web server.

git clone https://github.com/Jos-Ven/cforth
  Backup your ~/cforth/src/app/esp32-extra/app.fth
  Copy ~/cforth/src/app/sps30/app.fth to ~/cforth/src/app/esp32-extra
$ cd ~/cforth/build/esp32-extra
$ make clean
$ make   # To flash the application.

Enter 'transfer <Enter>' to log on to your WiFi network and start an upload session.
Start your web browser. Go to the web page as displayed in the console.
Upload sps30_web.fth to the filesystem of the ESP32.
Close the web browser.
Reboot the ESP32 and compile sps30_web.fth.

Only when you use https://github.com/Jos-Ven/A-smart-home-in-Forth:
  Edit and upload MachineSettings.fth to the filesystem of the ESP32 if you are able to
  handle TcpTime packets. See ~/cforth/src/app/esp32-extra/tools/timediff.fth.
  Disable the servers you do not have.

When there is no WiFi connection, the program puts the ESP32 into 
a deep sleep for 30 minutes.
Unless you disable the lines with SleepIfNotConnected in sps30_web.fth.

To auto-run the application:
  hit the ESC key
  Enter 'reboot'
  Enter 'transfer <Enter>'
  Start your web browser. Go to the web page as displayed in the console.
  Upload the file start to the ESP32.
  Reboot the ESP32.
