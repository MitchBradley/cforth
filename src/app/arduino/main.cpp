#include <Arduino.h>

extern "C" {
  void forth(void);

  void raw_putchar(char c) {
    Serial.write(c);
  }

  int kbhit(void) {
    return Serial.available();
  }

  int getkey(void) {
    while (!Serial.available()) continue;
    return Serial.read();
  }

  void pin_output(int pin) {
    pinMode(pin, OUTPUT);
  }

  void pin_input(int pin) {
    pinMode(pin, INPUT);
  }

  void pin_input_pullup(int pin) {
    pinMode(pin, INPUT_PULLUP);
  }

  unsigned long get_msecs(void) {
    return millis();
  }

  void delay_microseconds(unsigned int usec) {
    delayMicroseconds(usec);
  }
}

void setup() {
  Serial.begin(115200);

#ifdef DEBUG_SETUP_PAUSE
  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);
  Serial.println("src/main.cpp:setup() pause");
  digitalWrite(13, HIGH);
  while (Serial.read() != ' ') continue;
  digitalWrite(13, LOW);
  Serial.println("src/main.cpp:setup() continue");
#endif
}

void loop() {
  forth();
}
