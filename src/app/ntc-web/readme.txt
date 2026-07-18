To see the temperature measured by an NTC in a web browser.

Location: ~/cforth/src/app/esp32-extra

Needed hardware: An NTC and an ESP32.
Allow your router to run a local web server.

cp ~/cforth/src/app/ntc-web/app.fth ~/cforth/src/app/esp32-extra
cd ~/cforth/build/esp32-extra
make clean
make   # And flash the application.

Start cForth.
Enter 'transfer <Enter>' to log on to your WiFi network and start an upload session.
Start your web browser. Go to the web page as displayed in the console.
Upload ntc_web.fth to the filesystem of the ESP32.
Close the web browser.
Reboot the ESP32 and compile ntc_web.fth.

Only when you use https://github.com/Jos-Ven/A-smart-home-in-Forth:
  Edit and upload MachineSettings.fth to the filesystem of the ESP32 if you are able to
  handle TcpTime packets. See ~/cforth/src/app/esp32-extra/tools/timediff.fth.
  Disable the servers you do not have.

To auto-run the application:
  hit the ESC key
  Enter 'reboot'
  Enter 'transfer <Enter>'
  Start your web browser. Go to the web page as displayed in the console.
  Upload the file start to the ESP32.
  Reboot the ESP32.
