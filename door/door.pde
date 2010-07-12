#define LED_PIN                 13
#define INNER_OPEN_PIN          14
#define INNER_RFID_ENABLE_PIN    2
#define OUTER_OPEN_PIN          15
#define OUTER_RFID_RX_PIN        3
#define REX_PIN                  7

#define ENABLE_INNER_DOOR
#define ENABLE_OUTER_DOOR

#define IRC_CHANNEL       "#hsbne"

// Libraries from Arduiniana.org
#include <NewSoftSerial.h>
#include <PString.h>
#include <Flash.h>

FLASH_STRING(endl, "/n");

// We're given the Serial object already, name it something sensible
#define innerRfidReader Serial
NewSoftSerial outerRfidReader(OUTER_RFID_RX_PIN, OUTER_RFID_RX_PIN+1); // TX pin not used, put it out of the way

#include "Rfid.h"
RfidProcessor innerDoorCode(10,13), outerDoorCode(2,3);

#include "Ethernet.h"
byte mac[] = {0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED};
byte ip[] = {192, 168, 1, 252};
byte gateway[] = {192, 168, 1, 1};
byte subnet[] = {255, 255, 0, 0};

#include "Irc.h"
byte freenode[] = {128,237,157,136};
IrcClient irc(freenode, 6667, "Hsbne|DoorBot");

FLASH_STRING(ircChannel, IRC_CHANNEL);

void ircOnConnect(void)
{
  // can join one or multiple channels here
  irc << F("JOIN ") << ircChannel << endl;
}

void ircOnMessage(const PString &source, const PString &message)
{
  // look for and respond to triggers
}

void setup()
{
  pinMode(REX_PIN, INPUT);     // "request exit" button input
  digitalWrite(REX_PIN, HIGH);
 
  pinMode(LED_PIN, OUTPUT); // status led
  digitalWrite(LED_PIN, LOW);  
 
  // Door reader
  innerRfidReader.begin(2400); // RFID reader SOUT pin connected to Serial RX pin at 2400bps
  Serial << F("Reset") << endl;

  pinMode(INNER_RFID_ENABLE_PIN, OUTPUT);   // RFID /ENABLE pin
  digitalWrite(INNER_RFID_ENABLE_PIN, LOW);

  pinMode(INNER_OPEN_PIN, OUTPUT); // Setup internal door open
  digitalWrite(INNER_OPEN_PIN, LOW);

  // Rollerdoor reader
  outerRfidReader.begin(9600); // seeedstudio rfid reader

  pinMode(OUTER_OPEN_PIN, OUTPUT); // Setup external door open
  digitalWrite(OUTER_OPEN_PIN, LOW);
 
  // Ethernet services
  Ethernet.begin(mac, ip, gateway, subnet);

  // Irc services
  irc.setOnConnectCallback(ircOnConnect);
  irc.setOnMessageCallback(ircOnMessage);
  irc.connect();
}

// Unlocks the door strike on the inner door for 2s
void unlockDoor()
{
  digitalWrite(INNER_OPEN_PIN, HIGH);
  digitalWrite(LED_PIN, HIGH);
  delay(2000);
  digitalWrite(INNER_OPEN_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
  Serial << F("Internal open.") << endl;
}

// Simulates a press of the open button on the roller door
void openRollerDoor()
{
  digitalWrite(OUTER_OPEN_PIN, HIGH);
  digitalWrite(LED_PIN, HIGH);
  delay(20);
  digitalWrite(OUTER_OPEN_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
  Serial << F("External open.") << endl;
}

void loop()
{
  Rfid code;
  int val;
 
  code[10]=0;
 
  if (!digitalRead(REX_PIN))
  {
    Serial << F("REX button pressed") << endl;
    unlockDoor();
    irc << F("PRIVMSG ") << ircChannel << F(" :!!! REX button pressed.") << endl;
  }

  digitalWrite(LED_PIN, LOW);
  digitalWrite(INNER_OPEN_PIN, LOW);
  digitalWrite(OUTER_OPEN_PIN, LOW);
 
#ifdef ENABLE_INNER_DOOR
  if (innerRfidReader.available())
  {
    if (innerDoorCode.process(innerRfidReader.read()))
    {
      if(innerDoorCode.accessLevel == INNER || innerDoorCode.accessLevel == BOTH)
      {
        unlockDoor();
        irc << F("PRIVMSG ") << ircChannel << F(" :!!! Inner door opened by ") << innerDoorCode.code[6] << endl;
      }        
      else
      {
        Serial << F("Insufficient rights.") << endl;
        irc << F("PRIVMSG ") << ircChannel << F(" :!!! Inner door attempt by ") << innerDoorCode.code[6] << endl;
      }
      innerRfidReader.flush();
    }
  }
#endif // ENABLE_INNER_DOOR

#ifdef ENABLE_OUTER_DOOR
  if (outerRfidReader.available())
  {
    if (outerDoorCode.process(outerRfidReader.read()))
    {
      if (outerDoorCode.accessLevel == OUTER || outerDoorCode.accessLevel == BOTH)
      {
        openRollerDoor();
        irc << F("PRIVMSG ") << ircChannel << F(" :!!! Outer door opened by ") << outerDoorCode.code[6] << endl;
      }
      else
      {
        Serial << F("Insufficient rights.") << endl;
        irc << F("PRIVMSG ") << ircChannel << F(" :!!! Outer door attempt by ") << outerDoorCode.code[6] << endl;
      }
      outerRfidReader.flush();
    }
  }
#endif // ENABLE_OUTER_DOOR

}


