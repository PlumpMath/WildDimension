#pragma once
#include "Console/ConsoleCommandHandler.h"

class Client: public ConsoleCommandHandler
{
private:
public:
	Client(Context* context);
	~Client();

	virtual void runCommand();

	/**
	 * Show the help
	 */
	virtual void showHelp();
};

