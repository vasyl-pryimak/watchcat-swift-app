#include <AltSoftSerial.h>
AltSoftSerial BTserial;

#define pirPin 2 
#define ledPin 13

boolean ping = false;

int SEC = 0;
unsigned long timer;
 
void setup() {
   Serial.begin(9600);
   Serial.print("Sketch:   ");   Serial.println(__FILE__);
   Serial.print("Uploaded: ");   Serial.println(__DATE__);
   Serial.println(" ");
   BTserial.begin(9600);  
   Serial.println("BTserial started at 9600");

   pinMode(pirPin, INPUT);
   pinMode(ledPin, OUTPUT);

   timer = millis();
}
 
void loop() {
   pingSerial();
   timerPing();
    
   // Чтение из Serial Monitor и отправка в модуль Bluetooth:
   if (Serial.available()) {
      int c = Serial.read();
      if(c == 2){
        ping = false;
      }
   }
}

void pingSerial() {
   int pirVal = digitalRead(pirPin);
   if(ping == false && pirVal == HIGH) {
      ping = true;
      digitalWrite(ledPin, HIGH);
      Serial.write(1);
      delay(3000);
    } else {
      digitalWrite(ledPin,LOW);
    }
}

void timerPing() {
  if (ping == true && millis() - timer > 995) {
      timer = millis();
      SEC = SEC + 1;
      if (SEC > 10) { 
        SEC = 1;  
        Serial.write(1);
      }
   }
}
