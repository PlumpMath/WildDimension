#pragma once
#include "Console/ConsoleCommandHandler.h"

class DriveableActions: public ConsoleCommandHandler
{
public:
    DriveableActions(Context* context);
	~DriveableActions();

	virtual void runCommand();

	/**
	 * Show the help
	 */
	virtual void showHelp();
};

