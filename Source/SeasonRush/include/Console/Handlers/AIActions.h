#pragma once
#include "Console/ConsoleCommandHandler.h"

class AIActions: public ConsoleCommandHandler
{
private:
public:
    AIActions(Context* context);
	~AIActions();

	virtual void runCommand();

	/**
	 * Show the help
	 */
	virtual void showHelp();
};

