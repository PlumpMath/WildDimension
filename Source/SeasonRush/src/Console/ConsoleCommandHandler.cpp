#include "Urho3D/Urho3DAll.h"
#include "Console/ConsoleCommandHandler.h"


ConsoleCommandHandler::ConsoleCommandHandler(Context* context) :
Urho3D::Object(context)
{
}


ConsoleCommandHandler::~ConsoleCommandHandler()
{
}


void ConsoleCommandHandler::RegisterObject(Context* context)
{
	context->RegisterFactory<ConsoleCommandHandler>();
}

void ConsoleCommandHandler::setParams(std::vector<String> params)
{
	_params = params;
}

bool ConsoleCommandHandler::checkFirstParam(String param)
{
	for (auto it = _commands.begin(); it != _commands.end(); ++it) {
		if ((*it) == param) {	
			//This handler is ready to work with this command
			return true;
		}
	}

	return false;
}

void ConsoleCommandHandler::registerCommand(String command)
{
	for (auto it = _commands.begin(); it != _commands.end(); ++it) {
		//Check if we don't already have this command in the list
		if ((*it) == command) {
			return;
		}
	}
	_commands.push_back(command);
}

std::vector<String> ConsoleCommandHandler::getAllCommands()
{
	return _commands;
}