#include "Urho3D/Urho3DAll.h"
#include "Console/ConsoleCommandController.h"
#include "Console/Handlers/Requests.h"
#include "Console/Handlers/Debug.h"
#include "Console/Handlers/Client.h"
#include "Console/Handlers/Terminate.h"
#include "Console/Handlers/Physics.h"
#include "Console/Handlers/ConsoleActions.h"
#include "Console/Handlers/SoundActions.h"
#include "Console/Handlers/DriveableActions.h"
#include "Console/Handlers/AIActions.h"
#include <vector>
#include <sstream>

ConsoleCommandController::ConsoleCommandController(Context* context) :
Urho3D::Component(context)
{
	_handlers.push_back(SharedPtr<ConsoleCommandHandler>(new Requests(context)));
	_handlers.push_back(SharedPtr<ConsoleCommandHandler>(new Debug(context)));
	_handlers.push_back(SharedPtr<ConsoleCommandHandler>(new Client(context)));
	_handlers.push_back(SharedPtr<ConsoleCommandHandler>(new Terminate(context)));
	_handlers.push_back(SharedPtr<ConsoleCommandHandler>(new Physics(context)));
    _handlers.push_back(SharedPtr<ConsoleCommandHandler>(new ConsoleActions(context)));
	_handlers.push_back(SharedPtr<ConsoleCommandHandler>(new SoundActions(context)));
    _handlers.push_back(SharedPtr<ConsoleCommandHandler>(new DriveableActions(context)));
    _handlers.push_back(SharedPtr<ConsoleCommandHandler>(new AIActions(context)));

    loadAutocompleteData();
}


ConsoleCommandController::~ConsoleCommandController()
{
}

void ConsoleCommandController::loadAutocompleteData()
{
    Console* console = GetSubsystem<Console>();
    if (console) {
        for (auto it = _handlers.begin(); it != _handlers.end(); ++it) {
            auto command = (*it)->getAllCommands();
            for (auto c = command.begin(); c != command.end(); ++c) {
                console->AddAutoComplete((*c));
            }
        }
    }
}


void ConsoleCommandController::RegisterObject(Context* context)
{
	context->RegisterFactory<ConsoleCommandController>();
	context->RegisterFactory<ConsoleCommandHandler>();
}

void ConsoleCommandController::parse(const String& input)
{

	std::vector<String> params;
	std::stringstream ss(input.ToLower().CString());
	std::string param;
	while (ss >> param) {
		params.push_back(param.c_str());
	}

	//This will print out all available commands in console
	if (params.size() == 1 && params.at(0) == "help") {
        URHO3D_LOGRAW("All available commands:");
		for (auto it = _handlers.begin(); it != _handlers.end(); ++it) {
			auto command = (*it)->getAllCommands();
			for (auto c = command.begin(); c != command.end(); ++c) {
                URHO3D_LOGRAW("    " + (*c));
			}
		}
        URHO3D_LOGRAW("\nType '[command] --help' to see the available options for the specific command");
		return;
	}

	//Check which handler needs to parse this command
	ConsoleCommandHandler* handler = 0;
	for (auto it = _handlers.begin(); it != _handlers.end(); ++it) {
		if ((*it)->checkFirstParam(*params.begin())) {
			if (handler) {
				//We already found one handler for this command
				URHO3D_LOGWARNING("Abstract command: " + *params.begin());
			}
			else {
				handler = (*it);
			}
		}
	}

	if (handler) {
        if (params.back() == "--help") {
            URHO3D_LOGRAW(input);
            handler->showHelp();
        } else {
            //Output the entered command
            URHO3D_LOGRAW(input);
            handler->setParams(params);
            handler->runCommand();
		}
	}
	else {
		URHO3D_LOGERROR("Unknown command " + *params.begin());
	}
}
