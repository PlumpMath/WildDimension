#include "Urho3D/Urho3DAll.h"
#include "Console/Handlers/Debug.h"
#include "version.h"
#include "Events.h"


Debug::Debug(Context* context) :
ConsoleCommandHandler(context)
{
	registerCommand("debug");
	registerCommand("version");
}


Debug::~Debug()
{
}


void Debug::runCommand()
{
	if (*_params.begin() == "debug") {
		if (_params.size() < 2) {
			URHO3D_LOGERROR("Mising debug level parameter!");
			showHelp();
			return;
		}
		else if (_params.size() > 2) {
			URHO3D_LOGERROR("Too much parameters");
			showHelp();
			return;
		}

		try {
			int debugLevel = std::atoi(_params.at(1).CString());
			if (debugLevel < 0 || debugLevel > 9) {
				throw std::exception();
			}

			VariantMap map;
			map[P_DEBUG_LEVEL] = debugLevel;
			SendEvent(E_DEBUG_TOGGLE, map);
		}
		catch (std::exception& e) {
			URHO3D_LOGERROR("Second parameter is not valid!");
			URHO3D_LOGERROR("Only numbers between 0-9 are valid");
		}
	}
	else if (*_params.begin() == "version") {
		if (_params.size() > 1) {
			URHO3D_LOGERROR("This command takes no arguments!");
			return;
		}
        URHO3D_LOGRAW("Current version: " + String(VERSION));
	}
}

void Debug::showHelp()
{
    URHO3D_LOGRAW("Input 'debug [0..n]' to specify debug output level");
    URHO3D_LOGRAW("\t'debug 0' will disable any debugging while 'debug 1' will show some of the logs");
}
