#include <Ethernet.h>

#define IRC_BUFSIZE 256

#include <inttypes.h>
extern "C" {
    typedef void (*callbackFunction)(char*);
}

class IrcClient
{
private:
  Client irc;
  char nickname[20];
  char response[IRC_BUFSIZ];
  int responseLength;

public:

};

IrcClient::IrcClient(byte *serverIP, int port, char *nick)
{
  strcpy(nickname, nick);
  irc = new Client(serverIP, port);

  connect();
}

IrcClient::~IrcClient()
{
  disconnect();
}

void IrcClient::connect()
{

}

void IrcClient::disconnect()
{
  if (irc.connected())
  {
    // quit server
    irc.println("QUIT shutting down");
    irc.disconnect();
  }
}

void IrcClient::process()
{
  if (irc.available())
  {
    char ch = irc.read();
    if (ch != 10 && ch != 13)
    {
      response[responseLength++] = ch;
    }
    else
    {
      if (responseLength == 0) return;

      if (strcmp(response, "PING") == 0)
      {
        pingReply();
      }

      responseLength = 0;
    }

    response[responseLength] = 0;
  }
}

void IrcClient::pingReply()
{
  // convert ping into pong and send it
  response[1] = 'O';
  irc.println(response);
}

// TODO: implement custom command callbacks
void IrcClient::registerCommand(char *cmd, callbackFunction function)
{
}

