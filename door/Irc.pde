#include <Ethernet.h>
#include <WString.h>

#define IRC_BUFSIZE 256

#include <inttypes.h>
extern "C" {
    typedef void (*callbackFunction)(String&);
}

class IrcCommand
{
	String *m_command;
	callbackFunction m_callback;
};

class IrcClient
{
private:
  Client m_client;
  String m_nick;
  String m_response;
  IrcCommand **m_commandList;

public:

};

IrcClient::IrcClient(byte *serverIP, int port, char *nick) :
  m_client(serverIP, port),
  m_nick(nick)
{
}

IrcClient::~IrcClient()
{
  disconnect();
}

void IrcClient::begin()
{
  connect();
}

void IrcClient::connect()
{
  if (m_client.connect())
  {
	  // only do PASS and NICK here; do USER and JOIN as responses later
	  m_client.println("PASS password\n");
	  m_client.print("NICK ");
	  m_client.println(nickname);
  }
}

void IrcClient::disconnect()
{
  if (m_client.connected())
  {
    // quit server
	m_client.println("QUIT :shutting down");
	m_client.disconnect();
  }
}

void IrcClient::process()
{
  if (m_client.available())
  {
    char ch = m_client.read();
    if (ch != 10 && ch != 13)
    {
      m_response.append(ch);
    }
    else
    {
      if (m_response.length() == 0) return;

      if (m_response.startsWith("PING"))
      {
        pingReply();
      }

    }

  }
}

void IrcClient::pingReply()
{
  // convert ping into pong and send it
  m_response.setCharAt(1,'O');
  m_client.println(m_response);
}

// "433 " - nick collision, reissue NICK with modified nickname
// "NOTICE * :*** No Ident response" good spot to fire USER and JOIN msgs
// "PRIVMSG " - msgs from channels and people; parse further if our nick is present
// "ERROR " - something wrong, cap'n!
// "PING " - *must* respond with "PONG " and the params that came with the ping

// TODO: implement custom command callbacks
void IrcClient::registerCommand(char *cmd, callbackFunction function)
{
}
