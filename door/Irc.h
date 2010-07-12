#ifndef Irc_h
#define Irc_h

// library from arduiniana.org
#include <PString.h>

#include "Print.h"

typedef void (*callbackFunctionSS)(const PString &, const PString &);
typedef void (*callbackFunctionV)(void);

class IrcClient : public Print
{
private:
  Client m_client;
  PString m_nick;
  PString m_originalNick;
  PString m_response;
  PString m_source;
  callbackFunctionSS m_onMessage;
  callbackFunctionV m_onConnect;
  long m_reconnectDelay;

  char m_responseBuffer[512];
  char m_sourceBuffer[50];
  char m_nickBuffer[20];
  char m_origNickBuffer[20];

public:
  IrcClient(byte *serverIP, int port, char *nick);
  ~IrcClient(void);
  virtual void write(uint8_t);
  virtual void write(const char *str);
  virtual void write(const uint8_t *buf, size_t size);
  void connect(void);
  void disconnect(void);
  void process(void);
  void msg(char *nick, char *text);
  void setOnConnectCallback(callbackFunctionV func);
  void setOnMessageCallback(callbackFunctionSS func);
  const PString & getNick(void);
};

#endif // Irc_h
