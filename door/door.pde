#define LED_PIN                 13
#define INNER_OPEN_PIN          14
#define INNER_RFID_ENABLE_PIN    2
#define OUTER_OPEN_PIN          15
#define OUTER_RFID_RX_PIN        3
#define REX_PIN                  7

#include <NewSoftSerial.h>

// We're given the Serial object already, name it something sensible
#define innerRfidReader Serial
NewSoftSerial outerRfidReader(OUTER_RFID_RX_PIN, OUTER_RFID_RX_PIN+1); // TX pin not used, put it out of the way

#include "Rfid.h"
RfidProcessor innerDoorCode(10,13), outerDoorCode(2,3);

void setup()
{
  pinMode(REX_PIN, INPUT);     // "request exit" button input
  digitalWrite(REX_PIN, HIGH);
 
  pinMode(LED_PIN, OUTPUT); // status led
  digitalWrite(LED_PIN, LOW);  
 
  // Door reader
  innerRfidReader.begin(2400); // RFID reader SOUT pin connected to Serial RX pin at 2400bps

  pinMode(INNER_RFID_ENABLE_PIN, OUTPUT);   // RFID /ENABLE pin
  digitalWrite(INNER_RFID_ENABLE_PIN, LOW);

  pinMode(INNER_OPEN_PIN, OUTPUT); // Setup internal door open
  digitalWrite(INNER_OPEN_PIN, LOW);

  // Rollerdoor reader
  outerRfidReader.begin(9600); // seeedstudio rfid reader

  pinMode(OUTER_OPEN_PIN, OUTPUT); // Setup external door open
  digitalWrite(OUTER_OPEN_PIN, LOW);
 
}

// Unlocks the door strike on the inner door for 2s
void unlockDoor()
{
  digitalWrite(INNER_OPEN_PIN, HIGH);
  digitalWrite(LED_PIN, HIGH);
  Serial.println("Opening internal door.");
  delay(2000);
  digitalWrite(INNER_OPEN_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
}

// Simulates a press of the open button on the roller door
void openRollerDoor()
{
  digitalWrite(OUTER_OPEN_PIN, HIGH);
  digitalWrite(LED_PIN, HIGH);
  Serial.println("Opening external door.");
  delay(20);
  digitalWrite(OUTER_OPEN_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
}

void loop()
{
  Rfid code;
  int val;
 
  code[10]=0;
 
  if (!digitalRead(REX_PIN))
  {
    Serial.println("REX button pressed");
    unlockDoor();
  }

  digitalWrite(LED_PIN, LOW);
  digitalWrite(INNER_OPEN_PIN, LOW);
  digitalWrite(OUTER_OPEN_PIN, LOW);
 
  if (innerRfidReader.available())
  {
    if (innerDoorCode.process(innerRfidReader.read()))
    {
      if(innerDoorCode.accessLevel == INNER || innerDoorCode.accessLevel == BOTH)
      {
        unlockDoor();
      }        
      else
      {
        Serial.println("Insufficient rights.");
      }
    }
  }
   
  if (outerRfidReader.available())
  {
    if (outerDoorCode.process(outerRfidReader.read()))
    {
      if (outerDoorCode.accessLevel == OUTER || outerDoorCode.accessLevel == BOTH)
      {
        openRollerDoor();
      }
      else
      {
        Serial.println("Insufficient rights.");
      }
    }
  }
  
}


