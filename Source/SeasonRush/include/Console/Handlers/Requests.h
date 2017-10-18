#pragma once
#include "Console/ConsoleCommandHandler.h"

class Requests: public ConsoleCommandHandler
{
private:
public:
	Requests(Context* context);
	~Requests();

	virtual void runCommand();

	/**
	 * Show the help
	 */
	virtual void showHelp();
};

