#pragma once
#if _WIN32
//#include <WinSock2.h>
#endif // _WIN32
#include <mutex>
#include <vector>

using namespace Urho3D;

struct BroadcastMessage {
	unsigned short port;
	unsigned short map;
	unsigned short players; //Current player count
	unsigned short serverSize; //Max player count
};

struct ServerDescription {
	String address;
	BroadcastMessage info;
};

class LanBroadcast
{
private:
	LanBroadcast();
	~LanBroadcast();

	bool _broadcastEnabled;

#if _WIN32
	SOCKET m_clientsocket;
#endif // _WIN32

	/**
	 * List of servers that we receive broadcasts from
	 */
	std::vector<ServerDescription> _serverList;

	/**
	 * Mutex to secure _serverList vector
	 */
	std::mutex _lanServerListMutex;

	/**
	 * If we are broadcasting, we should set some server information to let any of the listeners know about us
	 */
	BroadcastMessage _serverInfo;

public:
	static LanBroadcast& instance()
	{
		static LanBroadcast* instance = new LanBroadcast;
		return *instance;
	}

	/**
	 * Do we have to broadcast/listen to servers
	 * when startListening() or broadcast() methods are called, this value is set to TRUE,
	 * to stop that, this method should be called with the FALSE parameter
	 */
	void toggleBroadcast(bool val);

	/**
	 * Start to listen to any broardcasts to search for available servers
	 */
	void startListening();

	/**
	 * Start broadcating our server to lan
	 */
	void broadcast(unsigned short serverPort = 25019);

	/**
	 * Get list of received servers
	 */
	std::vector<ServerDescription> getServerList();

	/**
	 * Set how many players are available to join this server
	 */
	void setServerSize(unsigned short size);

	/**
	 * Set how many players are currently playing in this server
	 */
	void setCurrentPlayerCount(unsigned short size);
};

