
#ifndef _IRC_H
#define _IRC_H

#include <inttypes.h>
extern "C" {
    typedef void (*callbackFunction)(String &source,String &text);
}

class IrcCommand
{
public:
  char *command;
  callbackFunction *callback;
};

class IrcClient
{
private:
  Client m_client;
  String m_nick;
  String m_response;
  IrcCommand *m_commandList;
  int m_commandListCapacity;
  int m_commandListLength;

  void pingReply(void);
  ~IrcClient(void);

public:
  IrcClient(byte *serverIP, int port, char *nick);
  void begin(void);
  void connect(void);
  void disconnect(void);
  void process(void);
  void initCommandList(int maxCommands);
  void registerCommand(char *cmd, callbackFunction function);
  void msg(char *nick, char *text);
  String getNick(void);
};

#endif // _IRC_H
