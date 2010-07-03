#define LED_PIN                 13
#define INNER_OPEN_PIN          14
#define INNER_RFID_ENABLE_PIN    2
#define OUTER_OPEN_PIN          15
#define OUTER_RFID_RX_PIN        3
#define REX_PIN                  7

#include <NewSoftSerial.h>
#include <EEPROM.h>

NewSoftSerial rollerRfid(OUTER_RFID_RX_PIN, OUTER_RFID_RX_PIN+1); // TX pin not used, put it out of the way

typedef char Rfid[11];
enum AccessType { INVALID, INNER, OUTER, BOTH, NONE };

void setup()
{
  pinMode(REX_PIN, INPUT);     // "request exit" button input
  digitalWrite(REX_PIN, HIGH);
 
  pinMode(LED_PIN, OUTPUT); // status led
  digitalWrite(LED_PIN, LOW);  
 
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
  digitalWrite(LED_PIN, HIGH);
  Serial.println("Opening internal door.");
  delay(2000);
  digitalWrite(INNER_OPEN_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
}

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
        }        
        else
        {
          Serial.println("Insufficient rights.");
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
        }
        else
        {
          Serial.println("Insufficient rights.");
        }
      }
      rollerRfid.flush();
      bytesread = 0;
    }   
  }
 
}


