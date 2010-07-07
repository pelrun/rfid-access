#include <Client.h>
#include <Ethernet.h>
#include <WString.h>
#include "Irc.h"

IrcClient::IrcClient(byte *serverIP, int port, char *nick) :
  m_client(serverIP, port),
  m_nick(nick),
  m_originalNick(nick),
  m_onConnect(NULL),
  m_onMessage(NULL),
  m_reconnectDelay(0)
{
}

IrcClient::~IrcClient(void)
{
  disconnect();
}

void IrcClient::connect(void)
{
  if (m_client.connect())
  {
	// always try the original nick first
	m_nick = m_originalNick;

    m_client.println("PASS boo");
    m_client.print("NICK ");
    m_client.println(m_nick);
    m_client.println("USER hsbne 8 * hsbne door");
  }
}

void IrcClient::disconnect(void)
{
  if (m_client.connected())
  {
    // quit server
    m_client.println("QUIT :bye");
    m_client.stop();
  }
}

void IrcClient::process(void)
{
  if (!m_client.connected())
  {
	  if (m_reconnectDelay == 0)
	  {
		  m_reconnectDelay = (long)millis()+10000;
	  }
	  if ((long)millis() - m_reconnectDelay >= 0)
	  {
		  m_reconnectDelay = 0;
		  connect();
	  }
  }
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

      String source("");

      if (m_response.charAt(0) == ':')
      {
        source = m_response.substring(1,m_response.indexOf(' '));
        m_response = m_response.substring(m_response.indexOf(' ')+1);
      }

      if (m_response.startsWith("PING "))
      {
    	// be sneaky and convert PING into PONG in-place
        m_response.setCharAt(1,'O');
    	m_client.println(m_response);
      }
      else if (m_response.startsWith("001 "))
      {
    	  if (m_onConnect != NULL)
    	  {
    		  (*m_onConnect)();
    	  }
      }
      else if (m_response.startsWith("433 "))
      {
        // Nick collision; we need to assign a new unique nick
    	m_nick.append('_');
    	m_client.print("NICK ");
    	m_client.println(m_nick);
      }
      else
      {
    	  if (m_onMessage != NULL)
    	  {
    		  (*m_onMessage)(source, m_response);
    	  }
      }

      m_response = "";
    }
  }
}

void IrcClient::setOnConnectCallback(callbackFunctionV func)
{
  m_onConnect = func;
}

void IrcClient::setOnMessageCallback(callbackFunctionSS func)
{
  m_onMessage = func;
}

void IrcClient::msg(char *nick, char *text)
{
  m_client.print("PRIVMSG ");
  m_client.print(nick);
  m_client.print(" :");
  m_client.println(text);
}

const String & IrcClient::getNick(void)
{
  return m_nick;
}

void IrcClient::write(uint8_t b)
{
  m_client.write(b);
}

void IrcClient::write(const char *str)
{
  m_client.write(str);
}

void IrcClient::write(const uint8_t *buf, size_t size)
{
  m_client.write(buf,size);
}

