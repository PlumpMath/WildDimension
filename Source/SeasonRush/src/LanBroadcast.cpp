#include "Urho3D/Urho3DAll.h"
#include "LanBroadcast.h"
#include <stdio.h>

#ifdef _WIN32
#include <tchar.h>
#include <atlbase.h>
#endif // _WIN32

#include <string>
#include <iostream>

#ifdef _WIN32
#include <thread>
#endif

static const int BROADCAST_PORT = 25010;

using namespace Urho3D;

LanBroadcast::LanBroadcast():
_broadcastEnabled(false)
{
}


LanBroadcast::~LanBroadcast()
{
}


void LanBroadcast::toggleBroadcast(bool val)
{
	_broadcastEnabled = val;
}

void LanBroadcast::broadcast(unsigned short serverPort)
{
	_broadcastEnabled = true;

#if _WIN32
	int portno = ::BROADCAST_PORT;
	USES_CONVERSION;
	String port(serverPort);


	WORD w = MAKEWORD(1, 1);
	WSADATA wsadata;
	::WSAStartup(w, &wsadata);


	SOCKET s = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (s == -1)
	{
		URHO3D_LOGERROR("Error while creating socket");
		return;
	}

	char opt = 1;
	setsockopt(s, SOL_SOCKET, SO_BROADCAST, (char*)&opt, sizeof(char));
	SOCKADDR_IN brdcastaddr;
	memset(&brdcastaddr, 0, sizeof(brdcastaddr));
	brdcastaddr.sin_family = AF_INET;
	brdcastaddr.sin_port = htons(portno);
	brdcastaddr.sin_addr.s_addr = INADDR_BROADCAST;
	int len = sizeof(brdcastaddr);

	//Set the port for our current server
	_serverInfo.port = serverPort;

	while (_broadcastEnabled) {

		//Store our server information in the char buffer
		char sbuf[sizeof(BroadcastMessage)];
		memcpy_s(sbuf, sizeof(BroadcastMessage), &_serverInfo, sizeof(BroadcastMessage));

		int ret = sendto(s, sbuf, sizeof(BroadcastMessage), 0, (sockaddr*)&brdcastaddr, len);
		if (ret < 0)
		{
			URHO3D_LOGERROR("Error broadcasting to clients");
		}
		else if (ret < strlen(sbuf))
		{
			URHO3D_LOGERROR("Error in broadcasting, not all data is sent");
		}

		//Sleep for some time and the send the broadcast message again
		std::this_thread::sleep_for(std::chrono::milliseconds(2000));
	}
	::closesocket(s);
#endif // _WIN32
}

void LanBroadcast::startListening()
{
	_serverList.clear();

	_broadcastEnabled = true;

#if _WIN32
	m_clientsocket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (m_clientsocket == -1)
	{
		URHO3D_LOGERROR("m_clientsocket == -1");
		return;
	}

	SOCKADDR_IN UDPserveraddr;
	memset(&UDPserveraddr, 0, sizeof(UDPserveraddr));
	UDPserveraddr.sin_family = AF_INET;
	UDPserveraddr.sin_port = htons(BROADCAST_PORT);
	UDPserveraddr.sin_addr.s_addr = INADDR_ANY;

	int len = sizeof(UDPserveraddr);

	if (bind(m_clientsocket, (SOCKADDR*)&UDPserveraddr, sizeof(SOCKADDR_IN)) < 0)
	{
		//URHO3D_LOGRAW("Bind unsuccesfull");
		return;
	}

	while (_broadcastEnabled) {

		fd_set fds;
		struct timeval timeout;
		timeout.tv_sec = 0;
		timeout.tv_usec = 100;

		FD_ZERO(&fds);
		FD_SET(m_clientsocket, &fds);

		int rc = select(sizeof(fds) * 8, &fds, NULL, NULL, &timeout);
		if (rc > 0)
		{
			char rbuf[sizeof(BroadcastMessage)];
			SOCKADDR_IN clientaddr;
			int len = sizeof(clientaddr);

			//Receive the broadcasted message
			if (recvfrom(m_clientsocket, rbuf, sizeof(BroadcastMessage), 0, (sockaddr*)&clientaddr, &len) > 0)
			{
				ServerDescription server;

				//Convert received char buffer to our BroadcastMessage struct
				memcpy_s(&server.info, sizeof(BroadcastMessage), rbuf, sizeof(BroadcastMessage));

				char *p = inet_ntoa(clientaddr.sin_addr);
				int serverportno = ntohs(clientaddr.sin_port);

				//This is the IP of the server
				server.address = p;

				{
					//Lock the server list buffer
					std::lock_guard<std::mutex> guard(_lanServerListMutex);
					bool found = false;
					for (auto it = _serverList.begin(); it != _serverList.end(); ++it) {
						if ((*it).address == server.address && (*it).info.port == server.info.port) {
							//No need to add the server in the received server list, but we should update information about it
							(*it).info = server.info;
							found = true;
						}
					}

					if (!found) {
						//We don't have this server on the list, so we should add it
						_serverList.push_back(server);
					}
				}
			}
		}

		//Sleep for some time and then try to receive information again
		std::this_thread::sleep_for(std::chrono::milliseconds(2000));
	}

	//We should close this socket to let other apps use this port locally
	closesocket(m_clientsocket);
#endif // _WIN32
}

std::vector<ServerDescription> LanBroadcast::getServerList()
{
	std::lock_guard<std::mutex> guard(_lanServerListMutex);
	return _serverList;
}

void LanBroadcast::setServerSize(unsigned short size)
{
	//how many players can join
	_serverInfo.serverSize = size;
}

void LanBroadcast::setCurrentPlayerCount(unsigned short size)
{
	//how many players already are there
	_serverInfo.players = size;
}
