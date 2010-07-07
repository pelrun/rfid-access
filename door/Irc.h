#ifndef Irc_h
#define Irc_h

#include <WString.h>
#include "Print.h"

typedef void (*callbackFunctionSS)(const String &, const String &);
typedef void (*callbackFunctionV)(void);

class IrcClient : public Print
{
private:
  Client m_client;
  String m_nick;
  String m_originalNick;
  String m_response;
  callbackFunctionSS m_onMessage;
  callbackFunctionV m_onConnect;
  long m_reconnectDelay;

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
  const String & getNick(void);
};

#endif // Irc_h
