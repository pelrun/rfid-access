#include <EEPROM.h>

// Libraries from arduiniana.org
#include <Flash.h>

#include "Rfid.h"

RfidProcessor::RfidProcessor()
{
  RfidProcessor(10,13);
}

RfidProcessor::RfidProcessor(char sep1, char sep2)
{
  separator[0] = sep1;
  separator[1] = sep2;
  code[10] = 0;
  length = 0;
}

// returns true if a code has been read and looked up
boolean RfidProcessor::process(char ch)
{
  boolean complete = false;

  if (ch == separator[0] || ch == separator[1])
  {
    if (length == 10)
    {
      Serial << F("TAG: ") << code << endl;

      complete = true;
      accessLevel = matchRfid();
      length = 0;
    }
  }
  else
  {
    code[length++] = ch;
  }
  
  return complete;
}

int RfidProcessor::matchRfid()
{
  int address = 0;
  int result = 0;
  boolean match = false;

  while(!match)
  {
    if((result = EEPROM.read(address*11)) == INVALID)
    {
      // end of list
      Serial << F("No match") << endl;
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

  Serial << F("Access ") << result << endl;

  return result;
}
