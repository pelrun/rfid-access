#define LED_PIN                 13
#define INNER_OPEN_PIN          14
#define INNER_RFID_ENABLE_PIN    2
#define OUTER_OPEN_PIN          15
#define OUTER_RFID_RX_PIN        3
#define REX_PIN                  7

#define IRC_CHANNEL       "#hsbne"

#include <WString.h>

#include <NewSoftSerial.h>

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

void ircOnConnect(void)
{
	// can join one or multiple channels here
	irc.println("JOIN " IRC_CHANNEL);
}

void ircOnMessage(const String &source, const String &message)
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
  Serial.println("Internal open.");
}

// Simulates a press of the open button on the roller door
void openRollerDoor()
{
  digitalWrite(OUTER_OPEN_PIN, HIGH);
  digitalWrite(LED_PIN, HIGH);
  delay(20);
  digitalWrite(OUTER_OPEN_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
  Serial.println("External open.");
}

void loop()
{
  Rfid code;
  int val;
 
  code[10]=0;
 
  if (!digitalRead(REX_PIN))
  {
//    Serial.println("REX button pressed");
    unlockDoor();
    irc.println("PRIVMSG " IRC_CHANNEL " :!!! REX button pressed.");
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
        irc.print("PRIVMSG " IRC_CHANNEL " :!!! Inner door opened by ");
        irc.println(innerDoorCode.code[6]);
      }        
      else
      {
        Serial.println("Insufficient rights.");
        irc.print("PRIVMSG " IRC_CHANNEL " :!!! Inner door attempt by ");
        irc.println(innerDoorCode.code[6]);
      }
      innerRfidReader.flush();
    }
  }
   
  if (outerRfidReader.available())
  {
    if (outerDoorCode.process(outerRfidReader.read()))
    {
      if (outerDoorCode.accessLevel == OUTER || outerDoorCode.accessLevel == BOTH)
      {
        openRollerDoor();
        irc.print("PRIVMSG " IRC_CHANNEL " :!!! Outer door opened by ");
        irc.println(outerDoorCode.code[6]);
      }
      else
      {
        Serial.println("Insufficient rights.");
        irc.print("PRIVMSG " IRC_CHANNEL " :!!! Outer door attempt by ");
        irc.println(innerDoorCode.code[6]);
      }
      outerRfidReader.flush();
    }
  }
  
}


