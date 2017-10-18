#include "Urho3D/Urho3DAll.h"
#include "Console/Handlers/ConsoleActions.h"
#include "Events.h"

ConsoleActions::ConsoleActions(Context* context):
ConsoleCommandHandler(context)
{
	registerCommand("clear");
}


ConsoleActions::~ConsoleActions()
{
}


void ConsoleActions::runCommand()
{
	if (*_params.begin() == "clear") {
		if (_params.size() > 1) {
			URHO3D_LOGERROR("Too much parameters!");
			showHelp();
			return;
		}

        for (unsigned int i = 0; i < GetSubsystem<Console>()->GetNumBufferedRows(); i++) {
            URHO3D_LOGRAW(" ");
        }
	}
}

void ConsoleActions::showHelp()
{
    URHO3D_LOGRAW("Input 'clear' to clear the console window");
}
