#include "Urho3D/Urho3DAll.h"
#include "Console/Handlers/Terminate.h"
#include "Events.h"

Terminate::Terminate(Context* context):
ConsoleCommandHandler(context)
{
	registerCommand("exit");
}


Terminate::~Terminate()
{
}


void Terminate::runCommand()
{
	if (*_params.begin() == "exit") {
		if (_params.size() > 1) {
			URHO3D_LOGERROR("Too much parameters!");
			showHelp();
			return;
		}

        //Send the actual event
        SendEvent(E_GAME_EXIT);
	}
}

void Terminate::showHelp()
{
    URHO3D_LOGRAW("Input 'exit'");
    URHO3D_LOGRAW("This will close the game");
}
