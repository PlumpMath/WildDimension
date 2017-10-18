#pragma once
#include "Console/ConsoleCommandHandler.h"

class Terminate: public ConsoleCommandHandler
{
private:
public:
	Terminate(Context* context);
	~Terminate();

	virtual void runCommand();

	/**
	 * Show the help
	 */
	virtual void showHelp();
};

