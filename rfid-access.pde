#define LED_PIN                 13
#define INNER_OPEN_PIN          14
#define INNER_RFID_ENABLE_PIN    2
#define OUTER_OPEN_PIN          15
#define OUTER_RFID_RX_PIN        3
#define REX_PIN                  7

#include <NewSoftSerial.h>
#include <EEPROM.h>
#include <PString.h>

#include <Ethernet.h>
#include <EthernetDNS.h>
#include <Twitter.h>
//#include <MsTimer2.h>

// Ethernet/Twitter globals

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 1, 251 };
byte gateway[] = { 192, 168, 1, 254 };
byte subnet[] = { 255, 255, 0, 0 };

#include "twitterconfig.h"

Twitter twitter(TWITTER_AUTH_TOKEN);

char buffer[50];

// Serial globals

NewSoftSerial rollerRfid(OUTER_RFID_RX_PIN, OUTER_RFID_RX_PIN+1); // TX pin not used, put it out of the way

typedef char Rfid[11];
enum AccessType { INVALID, INNER, OUTER, BOTH, NONE };

void setup()
{
  pinMode(REX_PIN, INPUT);     // "request exit" button input
  digitalWrite(REX_PIN, HIGH);
 
//  pinMode(LED_PIN, OUTPUT); // status led
//  digitalWrite(LED_PIN, LOW);  
 
  // Door reader
  Serial.begin(2400); // RFID reader SOUT pin connected to Serial RX pin at 2400bps

  pinMode(INNER_RFID_ENABLE_PIN, OUTPUT);   // RFID /ENABLE pin
  digitalWrite(INNER_RFID_ENABLE_PIN, LOW);

  pinMode(INNER_OPEN_PIN, OUTPUT); // Setup internal door open
  digitalWrite(INNER_OPEN_PIN, LOW);

  // Rollerdoor reader
  rollerRfid.begin(9600); // seeedstudio rfid reader

  pinMode(OUTER_OPEN_PIN, OUTPUT); // Setup external door open
  digitalWrite(OUTER_OPEN_PIN, LOW);
 
  // Ethernet module
  Ethernet.begin(mac,ip,gateway,subnet);
}

int matchRfid(Rfid &code)
{
  int address = 0;
  int result = 0;
  boolean match = false;
 
  while(!match)
  {
    if((result = EEPROM.read(address*11)) == INVALID)
    {
      // end of list
      Serial.println("No tag match");
      return NONE;
    }

    match = true;
    for(int i=0; i<10; i++)
    {
      if(EEPROM.read(address*11+i+1) != code[i])
      {
        match = false;
        break;
      }
    }
    address++;
  }
 
  Serial.print("Match found, access ");
  Serial.println(result);
 
  return result;
}

void unlockDoor()
{
  digitalWrite(INNER_OPEN_PIN, HIGH);
//  digitalWrite(LED_PIN, HIGH);
  Serial.println("Opening internal door.");
  delay(2000);
  digitalWrite(INNER_OPEN_PIN, LOW);
//  digitalWrite(LED_PIN, LOW);
}

void openRollerDoor()
{
  digitalWrite(OUTER_OPEN_PIN, HIGH);
//  digitalWrite(LED_PIN, HIGH);
  Serial.println("Opening external door.");
  delay(20);
  digitalWrite(OUTER_OPEN_PIN, LOW);
//  digitalWrite(LED_PIN, LOW);
}

void tweet(Rfid &code, int access, int door, bool succeeded)
{
  PString tweet(buffer,sizeof(buffer));

  if (twitter.checkStatus())
  {
    // TODO: queue up tweets
    return; // previous tweet still going out, can't send another
  }

  if (door == INNER)
  {
    tweet.print("Inner");
  }
  else if (door == OUTER)
  {
    tweet.print("Outer");
  }
  tweet.print(" door ");

  if (!succeeded)
  {
    tweet.print("NOT ");
  }
  tweet.print("opened: ");
  tweet.println(code+6);

  bool tweetSent = false;

  for (int i=0;i<5 && !tweetSent;i++)
  {
    tweetSent = twitter.post(tweet);
    delay(1000);
  }

  if (!tweetSent)
  {
    Serial.println("Tweet log failed.");
  }
}

void loop()
{
  Rfid code;
  int val;
 
  code[10]=0;
 
  // twitter library needs this called periodically.
  twitter.checkStatus();

  if (!digitalRead(REX_PIN))
  {
    Serial.println("REX button pressed");
    unlockDoor();
  }

//  digitalWrite(LED_PIN, LOW);
  digitalWrite(INNER_OPEN_PIN, LOW);
  digitalWrite(OUTER_OPEN_PIN, LOW);
 
  if (Serial.available() > 0) // input waiting from internal rfid reader
  {
    if ((val = Serial.read()) == 10)
    {
      int bytesread = 0;
      while (bytesread < 10)
      {              // read 10 digit code
        if (Serial.available() > 0)
        {
          val = Serial.read();
          if ((val == 10) || (val == 13))
          {
            break;
          }
          code[bytesread++] = val;
        }
      }

      if(bytesread == 10)
      {
        Serial.print("TAG detected: ");
        Serial.println(code);
        
        int access = matchRfid(code) & 0xF; // high bits for future 'master' card flag
        if(access == INNER || access == BOTH)
        {
          unlockDoor();
          tweet(code,access,INNER,true);
        }        
        else
        {
          Serial.println("Insufficient rights.");
          tweet(code,access,INNER,false);
        }
      }

      Serial.flush();
      bytesread = 0;
    }   
  }
 
  if(rollerRfid.available() > 0) // input waiting from external rfid reader
  {
    if ((val = rollerRfid.read()) == 2)
    {
      int bytesread = 0;
      while (bytesread < 10)
      {
        if (rollerRfid.available() > 0)
        {
          val = rollerRfid.read();
          if ((val == 2) || (val == 3))
          {
            break;
          }
          code[bytesread++] = val;          
        }
      }

      if (bytesread == 10)
      {
        Serial.print("TAG detected: ");
        Serial.println(code);
        
        int access = matchRfid(code) & 0xF; // high bits for future 'master' card flag
        if (access == OUTER || access == BOTH)
        {
          openRollerDoor();
          tweet(code,access,OUTER,true);
        }
        else
        {
          Serial.println("Insufficient rights.");
          tweet(code,access,OUTER,false);
        }
      }
      rollerRfid.flush();
      bytesread = 0;
    }   
  }
 
}
