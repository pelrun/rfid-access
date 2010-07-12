#include <string.h>

#include <Client.h>
#include <Ethernet.h>

// Libraries from Arduiniana.org
#include <Flash.h>
#include <PString.h>

#include "Irc.h"

// multiply used string literals go here
// FLASH_STRING(endl,"/n");
FLASH_STRING(nickCmd, "NICK ");

IrcClient::IrcClient(byte *serverIP, int port, char *nick) :
  m_client(serverIP, port),
  m_response(m_responseBuffer, sizeof(m_responseBuffer)),
  m_source(m_sourceBuffer, sizeof(m_sourceBuffer)),
  m_nick(m_nickBuffer, sizeof(m_nickBuffer), nick),
  m_originalNick(m_origNickBuffer, sizeof(m_origNickBuffer), nick),
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

    m_client << F("PASS b") << endl;
    m_client << nickCmd << m_nick << endl;
    m_client << F("USER hsbne 8 * hsbne door") << endl;
  }
}

void IrcClient::disconnect(void)
{
  if (m_client.connected())
  {
    // quit server
    m_client << F("QUIT :bye") << endl;
    m_client.stop();
  }
}

boolean startsWith(const char *text, const char *search)
{
	for (int i = 0; i<strlen(search); i++)
	{
		if (text[i] != search[i])
		{
			return false;
		}
	}
	return true;
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
      m_response += ch;
    }
    else
    {
      if (m_response.length() == 0) return;

      m_source.begin();

      if (m_response[0] == ':')
      {
        // Using the buffer directly here because PString forces const access otherwise :P
        char *sourceDelim = strchr(m_responseBuffer, ' ');
        if (sourceDelim != NULL)
        {
          *sourceDelim = 0;
          m_source = m_responseBuffer[1];
          m_response = *(sourceDelim+1);
        }
      }

      if (startsWith(m_response, "PING "))
      {
        // convert PING into PONG in place
        m_responseBuffer[1] = 'O';
        m_client.println(m_response);
      }
      else if (startsWith(m_response, "001 "))
      {
        if (m_onConnect != NULL)
        {
          (*m_onConnect)();
        }
      }
      else if (startsWith(m_response, "433 "))
      {
        // Nick collision; we need to assign a new unique nick
        m_nick += "_";
        m_client << nickCmd << m_nick << endl;
      }
      else
      {
        if (m_onMessage != NULL)
        {
          (*m_onMessage)(m_source, m_response);
        }
      }

      m_response.begin();
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
  m_client << F("PRIVMSG ") << nick << F(" :") << text << endl;
}

const PString & IrcClient::getNick(void)
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

