#pragma once
#include <vector>
#include "Urho3D/Urho3DAll.h"

using namespace Urho3D;

class ConsoleCommandHandler: public Object
{
protected:
	/**
	 * What parameters did we receive
	 */
	std::vector<String> _params;

	/**
	 * Which are the valid commands for this handler
	 * We basically need to check the 1st entered parameter
	 */
	std::vector<String> _commands;

	/**
	 * Add command for this handler that it can parse
	 */
	void registerCommand(String command);

public:
	ConsoleCommandHandler(Context* context);
	~ConsoleCommandHandler();

    /**
	* Show the help
	*/
	virtual void showHelp() {};

	/// Register object factory and attributes.
	static void RegisterObject(Context* context);

	void setParams(std::vector<String> params);

	virtual void runCommand() {};

	bool checkFirstParam(String param);

	/**
	 * Get all available commands for this handler
	 */
	std::vector<String> getAllCommands();

	URHO3D_OBJECT(ConsoleCommandHandler, Urho3D::Object);
};

