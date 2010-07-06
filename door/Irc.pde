#include <Client.h>
#include <Ethernet.h>
#include <WString.h>
#include "Irc.h"

IrcClient::IrcClient(byte *serverIP, int port, char *nick) :
  m_client(serverIP, port),
  m_nick(nick)
{
  // insure our internal triggers are registered
  initCommandList(0);
}

IrcClient::~IrcClient(void)
{
  disconnect();
}

void IrcClient::begin(void)
{
  connect();
}

void IrcClient::connect(void)
{
  if (m_client.connect())
  {
    // only do PASS and NICK here; do USER and JOIN as responses later
    m_client.println("PASS password\n");
    m_client.print("NICK ");
    m_client.println(m_nick);
  }
}

void IrcClient::disconnect(void)
{
  if (m_client.connected())
  {
    // quit server
    m_client.println("QUIT :shutting down");
    m_client.stop();
  }
}

void IrcClient::process(void)
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
        return;
      }
      
      String source("");

      if (m_response.charAt(0) == ':')
      {
        source = m_response.substring(1,m_response.indexOf('!'));
        m_response = m_response.substring(m_response.indexOf(' ')+1);
      }

      for (int cmdIndex=0; cmdIndex <= m_commandListLength; cmdIndex++)
      {
        if (m_response.startsWith(m_commandList[cmdIndex].command))
        {
          *(m_commandList[cmdIndex].callback)(source,m_response);
          break;
        }
      }
    }

  }
}

void IrcClient::pingReply(void)
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

void identifyUser(char *source, char *text)
{
  m_client.println("USER arduino 8 * arduino");
}

void retryNick(char *source, char *text)
{
  // FIXME: need to mangle existing nick and recognise it later!
  m_client.println("NICK fakenick");
}

void IrcClient::initCommandList(int maxCommands)
{
  if (m_commandList != NULL)
  {
    free(m_commandList);
  }

  m_commandListCapacity = maxCommands+2;
  m_commandList = (IrcCommand*)malloc(m_commandListCapacity*sizeof(IrcCommand));
  m_commandListLength = 0;

//  registerCommand("PING",pingReply);
  registerCommand("NOTICE * :*** No Ident response", identifyUser);
  registerCommand("433 ", retryNick);
}

void IrcClient::registerCommand(char *cmd, callbackFunction function)
{
  if (m_commandListLength >= m_commandListCapacity)
  {
    return;
  }

  m_commandList[m_commandListLength].command = cmd;
  m_commandList[m_commandListLength].callback = function;
  m_commandListLength++;
}

void msg(char *nick, char *text)
{
  m_client.print("PRIVMSG ");
  m_client.print(nick);
  m_client.print(" :");
  m_client.println(text);
}

String IrcClient::getNick(void)
{
  return m_nick;
}

