#pragma once
#include "Console/ConsoleCommandHandler.h"

class ConsoleActions: public ConsoleCommandHandler
{
private:
public:
    ConsoleActions(Context* context);
	~ConsoleActions();

	virtual void runCommand();

	/**
	 * Show the help
	 */
	virtual void showHelp();
};

