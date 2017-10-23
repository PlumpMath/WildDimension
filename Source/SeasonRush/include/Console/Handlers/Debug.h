#pragma once
#include "Console/ConsoleCommandHandler.h"

class Debug: public ConsoleCommandHandler
{
private:
public:
	Debug(Context* context);
	~Debug();

	virtual void runCommand();

	/**
	 * Show the help
	 */
	virtual void showHelp();
};

