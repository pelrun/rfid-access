#ifndef RFID_H_
#define RFID_H_

typedef char Rfid[11];
enum AccessType { INVALID, INNER, OUTER, BOTH, NONE };

class RfidProcessor
{
private:
  int length;
  char separator[2];

  int matchRfid();

public:
  Rfid code;
  int accessLevel;

  RfidProcessor();
  RfidProcessor(char sep1, char sep2);

  boolean process(char ch);

};

#endif /* RFID_H_ */
