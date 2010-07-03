// Upload rfid codes into EEPROM

#include <EEPROM.h>

/*
typedef char Rfid[11];
enum AccessType { INVALID, INNER, OUTER, BOTH, NONE };

Rfid codeListBoth[] =
  {
    "ABCDE01234",
    0 // end of list
  };
 
Rfid codeListOuter[] =
  {
    "01234ABCDE",
    0 // end of list
  };
*/

#include "rfidcodes.h"

void writeCode(int address, Rfid &code, int accessLevel)
{
    Serial.print("Writing to address ");
    Serial.println(address);

    Serial.print("Access ");
    Serial.println(accessLevel);
    EEPROM.write(address*11,accessLevel);
    
    Serial.print("Code ");
    for(int i = 1; i<11; i++)
    {
      EEPROM.write(address*11+i,code[i-1]);
      Serial.print(code[i-1]);
    }
    Serial.println("");
    
}

void setup()
{
  int address = 0;

  Serial.begin(2400);
 
  while(codeListBoth[address][0]!=0)
  {
    writeCode(address, codeListBoth[address], BOTH);
    address++;
  }

  int codeIdx = 0;
  while(codeListOuter[codeIdx][0]!=0)
  {
    writeCode(address, codeListOuter[codeIdx], OUTER);
    address++; codeIdx++;
  }
 
  Rfid invalidCode = "          ";
  writeCode(address, invalidCode, INVALID);
  Serial.println("Finished");
}

void loop()
{
  pinMode(13,OUTPUT);
  digitalWrite(13,HIGH);
}
