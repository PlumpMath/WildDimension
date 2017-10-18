#include <Urho3D/Urho3DAll.h>
#include "Console/Handlers/Client.h"
#include "Events.h"

Client::Client(Context* context):
ConsoleCommandHandler(context)
{
	registerCommand("connect");
}


Client::~Client()
{
}


void Client::runCommand()
{
	if (*_params.begin() == "connect") {
		if (_params.size() < 3) {
			URHO3D_LOGERROR("Missing second parameter!");
			showHelp();
			return;
		}
		else if (_params.size() > 3) {
			URHO3D_LOGERROR("Too much parameters!");
			showHelp();
			return;
		}
		Urho3D::VariantMap map;
        map[P_SERVER_ADDRESS] = _params.at(1);
        map[P_SERVER_PORT] = _params.at(2);

        //Send the actual event
        SendEvent(E_GAME_JOIN, map);
	}
}

void Client::showHelp()
{
    URHO3D_LOGRAW("Usage: connect id_address server_port");
    URHO3D_LOGRAW("Input 'connect 127.0.0.1 25019'");
    URHO3D_LOGRAW("This will allow you to connect to any non-listed server.");
    URHO3D_LOGRAW("In this case server ip address is 127.0.0.1 and the port is 25019");
}
