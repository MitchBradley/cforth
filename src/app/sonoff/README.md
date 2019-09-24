# Sonoff switch firmware

This application uses cforth to implement an MQTT
client on a Sonoff WiFi switch such as:

- Sonoff S20 (obsolete)
- Sonoff Basic
- Sonoff TH10 / TH16

It could be adapted to pretty much any Sonoff device
or any ESP8266-based WiFi control device.  There is
an extensive database of such devices at 
https://blakadder.github.io/templates/

You would need to add topics and configure GPIOs
to support the features of the new devices.

## MQTT Server

You will need an MQTT server running on some machine
on your network.  I use the "Mosquitto" program for
this purpose, with the default configuration file.
Instructions for how to install it are easily found
on the web.

## Installation

Typically you will need to open up the device and
connect a serial adapter to pads inside.  The database
above has detailed instructions with photographs for
most devices.

Edit the file "wifi-on" to set the SSID and password
of your wifi network, and the IP address or DNS name
of the machine that runs the MQTT server.

With the device disconnected from AC power,
connect the serial adapter and make sure that your
host machine recognizes it.

Go into build/sonoff and execute this:

```COMPORT=/dev/ttyS4 make download```

replacing /dev/ttyS4 with the appropriate port for
your serial adapter (on Windows the name will be
like COM2).

Start a terminal emulator program and connect it
to the serial adapter at 115200 baud, 8 data bits,
1 stop bit, no parity.  Hit ENTER in the terminal
window.  You should see an ok prompt indicating
that Forth is ready to receive input.

At that prompt, enter your WiFi SSID and password,
and MQTT server IP address like this:

```
ok new-file: wifi-on
Enter lines, finish with a . on a line by itself
> " MySSID" " MyPassword" station-connect
> : server$ " 192.168.2.11" ;
> .
ok
```

Of course, you should replace MySSID, MyPassword,
and 192.168.2.11 with the appropriate values for
your network.  Afterwards, you can check that it
worked with

```ok cat wifi-on```

The spaces after opening quotes are mandatory.  If
you omit them and write, for example, "MySSID" without
the initial space, it will not work.  There must not
be a space before the closing quotes.

If you make a mistake or need to change the values,
just repeat the recipe above.

Power cycle the device and it should connect to WiFi
and speak the Mosquitto protocol.  You can test with it powered
from the USB serial adapter.  When it is working - switch sends
On/Off change events, relay and LED can be controlled via MQTT -
you can disconnect the USB serial adapter, close the box, and
power from AC.

## Testing with Mosquitto

You can subscribe to switch presses by running this
Mosquitto command on the server:

```mosquitto_sub -t sonoff/switch```

When you press the switch on the Sonoff device, it
should display "On" when you press that switch and
"Off" when you release it.

You can turn on the relay with:

```mosquitto_pub -t sonoff/relay -m On```
  
or turn it off with the obvious command.

Similarly, the green LED can be controlled via:

```mosquitto_pub -t sonoff/led -m On```

There are some nice programs out there to let you
set up automation scenarios with many MQTT-connected
sensors and actuators.  One popular one is Node-RED.
It lets you create scenarios by drawing diagrams.

## Why not use Tasmota?

Short answer: In most cases you probably **should** use Tasmota.

Tasmota is special purpose ESP8266 firmware for MQTT.
It supports many, many different ESP8266-based automation
devices - switches, sensors, you name it.
It has a lot of nice features, including Over The Air
wireless firmware updates, wireless configuration,
configurable timers, etc.  Its user community is very
active.  It is well-debugged.

So, if you just want to do MQTT on your ESP8266 device,
Tasmota would be an excellent choice.  Forth gives you
the ability to do additional computation that Tasmota
might not support, but for many automation scenarios,
Tasmota will do all that you need.

